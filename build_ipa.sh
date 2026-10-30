#!/bin/bash
set -e

APP_NAME="GeraKStore"
BUNDLE_ID="com.gerakstore.ios"

# Чтение версии по SemVer
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION | tr -d '\r\n ')
else
    VERSION="0.4.1"
fi

BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "41")

echo "==> Сборка $APP_NAME v$VERSION (билд $BUILD_NUMBER)..."

echo "==> Подготовка каталогов..."
rm -rf build Payload *.ipa
mkdir -p build/Payload

echo "==> Определение SDK iOS..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

echo "==> Подготовка исходников zsign..."
if [ ! -d "zsign_src" ]; then
    git clone https://github.com/zhlynn/zsign.git zsign_src
fi

# Патчинг путей zsign под Sandbox
python3 - << 'PYEOF'
import os

def patch_file(filepath, old_str, new_str):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    if old_str in content:
        content = content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Пропатчен: {os.path.basename(filepath)}")

patch_file("zsign_src/signing.cpp", 'StringFormat("/tmp/zsign_%llu",', 'StringFormat("%s/zsign_%llu", getenv("TMPDIR") ? getenv("TMPDIR") : "/tmp",')
patch_file("zsign_src/fs.cpp", 'StringFormat("/tmp/zsign_folder_%llu",', 'StringFormat("%s/zsign_folder_%llu", getenv("TMPDIR") ? getenv("TMPDIR") : "/tmp",')
PYEOF

echo "==> Загрузка OpenSSL 3.x XCFramework для iOS..."
if [ ! -d "openssl.xcframework" ]; then
    rm -f openssl.zip
    OPENSSL_URL="https://github.com/krzyzanowskim/OpenSSL/releases/download/3.3.2000/OpenSSL.xcframework.zip"
    OPENSSL_FALLBACK="https://github.com/krzyzanowskim/OpenSSL/releases/download/3.1.5004/OpenSSL.xcframework.zip"

    echo "Загрузка OpenSSL.xcframework..."
    if ! curl -fSL --retry 3 --retry-delay 2 "$OPENSSL_URL" -o openssl.zip; then
        echo "Переключение на стабильное зеркало 3.1.x..."
        curl -fSL --retry 3 --retry-delay 2 "$OPENSSL_FALLBACK" -o openssl.zip
    fi

    unzip -q openssl.zip
    rm -f openssl.zip

    # Унификация имени папки, если распаковалась с заглавной буквы
    if [ -d "OpenSSL.xcframework" ] && [ ! -d "openssl.xcframework" ]; then
        mv OpenSSL.xcframework openssl.xcframework
    fi
fi

if [ -d "openssl.xcframework/ios-arm64/Headers" ]; then
    OPENSSL_INCLUDE="openssl.xcframework/ios-arm64/Headers"
    OPENSSL_LIB="openssl.xcframework/ios-arm64/libcrypto.a"
elif [ -d "openssl.xcframework/ios-arm64/OpenSSL.framework/Headers" ]; then
    OPENSSL_INCLUDE="openssl.xcframework/ios-arm64/OpenSSL.framework/Headers"
    OPENSSL_LIB="openssl.xcframework/ios-arm64/OpenSSL.framework/OpenSSL"
else
    OPENSSL_INCLUDE=$(find openssl.xcframework/ios-arm64 -type d -name "Headers" 2>/dev/null | head -n 1)
    OPENSSL_LIB=$(find openssl.xcframework/ios-arm64 -name "libcrypto.a" -o -name "OpenSSL" 2>/dev/null | head -n 1)
fi

echo "==> Компиляция C/C++ исходников zsign..."
mkdir -p build/obj

# Компилируем все существующие C файлы (если есть)
for c_file in $(find zsign_src -maxdepth 1 -name "*.c" 2>/dev/null); do
    base=$(basename "$c_file" .c)
    echo "Компиляция C: $c_file"
    clang -O3 -isysroot "$SDK_PATH" -arch arm64 -miphoneos-version-min=18.0 \
        -I zsign_src -I "$OPENSSL_INCLUDE" \
        -c "$c_file" -o "build/obj/${base}.o"
done

# Компилируем все CPP файлы zsign (исключая standalone main.cpp, если он есть)
for cpp_file in $(find zsign_src -maxdepth 1 -name "*.cpp" 2>/dev/null); do
    base=$(basename "$cpp_file" .cpp)
    if [ "$base" == "main" ]; then continue; fi
    echo "Компиляция CPP: $cpp_file"
    clang++ -O3 -std=c++11 -isysroot "$SDK_PATH" -arch arm64 -miphoneos-version-min=18.0 \
        -I zsign_src -I "$OPENSSL_INCLUDE" \
        -c "$cpp_file" -o "build/obj/${base}.o"
done

# Компилируем мост zsign_bridge.cpp
clang++ -O3 -std=c++11 -isysroot "$SDK_PATH" -arch arm64 -miphoneos-version-min=18.0 \
    -I zsign_src -I "$OPENSSL_INCLUDE" \
    -c GeraKStore/Services/zsign_bridge.cpp -o build/obj/zsign_bridge.o

echo "==> Поиск Swift-исходников..."
SWIFT_FILES=$(find GeraKStore -name "*.swift")

echo "==> Монолитная компиляция $APP_NAME..."
APP_BUNDLE="build/Payload/$APP_NAME.app"
mkdir -p "$APP_BUNDLE"

swiftc -O -sdk "$SDK_PATH" -target arm64-apple-ios18.0 \
    -import-objc-header GeraKStore/Services/zsign_bridge.h \
    -I GeraKStore/Services \
    $SWIFT_FILES \
    build/obj/*.o \
    "$OPENSSL_LIB" \
    -lz -framework Foundation -framework UIKit -framework SwiftUI -framework Security -framework Network \
    -o "$APP_BUNDLE/$APP_NAME"

echo "==> Автоматическая генерация универсального Info.plist для G-Box..."
cat << PLIST_EOF > "$APP_BUNDLE/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>ru</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>18.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Необходимо для локальной установки и синхронизации приложений внутри GeraKStore.</string>
</dict>
</plist>
PLIST_EOF

# Копируем ассеты и иконки, если есть
if [ -d "GeraKStore/Resources" ]; then
    cp -R GeraKStore/Resources/* "$APP_BUNDLE/" 2>/dev/null || true
fi

echo "==> Упаковка чистого IPA без мусорных файлов..."
cd build
find . -name ".DS_Store" -delete
zip -qr -9 "${APP_NAME}_v${VERSION}_b${BUILD_NUMBER}.ipa" Payload
mv "${APP_NAME}_v${VERSION}_b${BUILD_NUMBER}.ipa" "../${APP_NAME}.ipa"
cd ..

echo "==> Готово: ${APP_NAME}.ipa успешно сформирован (версия $VERSION, билд $BUILD_NUMBER)!"
