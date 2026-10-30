#!/usr/bin/env bash
set -euo pipefail

APP_NAME="GeraKStore"
BUNDLE_ID="com.gerak.store"

if [ -f "VERSION" ]; then
    VERSION=$(tr -d '[:space:]' < VERSION)
else
    VERSION="0.5.0"
fi
BUILD_NUM="${GITHUB_RUN_NUMBER:-1}"

echo "==> Сборка $APP_NAME v$VERSION (билд $BUILD_NUM)..."

echo "==> Подготовка каталогов..."
rm -rf build "$APP_NAME.ipa"
mkdir -p build/obj build/Payload

echo "==> Определение SDK iOS..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
if [ -z "$SDK_PATH" ]; then
    echo "Ошибка: iPhoneOS SDK не найден!"
    exit 1
fi
echo "Используется SDK: $SDK_PATH"

echo "==> Подготовка исходников zsign..."
if [ ! -d "zsign_src" ]; then
    git clone --depth 1 https://github.com/zhlynn/zsign.git zsign_src
fi

rm -rf zsign_src/build zsign_src/install.sh zsign_src/CMakeLists.txt
rm -f zsign_src/src/third-party/minizip/iowin32.*
rm -f zsign_src/third-party/minizip/iowin32.*

perl -pi -e 's|StringFormat\("/tmp/zsign_|StringFormat("%s/zsign_", getenv("TMPDIR") ? getenv("TMPDIR") : "/tmp", |g' zsign_src/*.cpp zsign_src/common/*.cpp 2>/dev/null || true

echo "==> Загрузка OpenSSL 3.x XCFramework для iOS..."
if [ ! -d "openssl.xcframework" ]; then
    rm -f openssl.zip
    OPENSSL_URL="https://github.com/krzyzanowskim/OpenSSL/releases/download/3.3.2000/OpenSSL.xcframework.zip"
    curl -L "$OPENSSL_URL" -o openssl.zip
    unzip -q openssl.zip -d openssl_extracted
    mv openssl_extracted/OpenSSL.xcframework openssl.xcframework
    rm -rf openssl.zip openssl_extracted
fi

OPENSSL_INCLUDE=$(find openssl.xcframework/ios-arm64 -type d -name "Headers" | head -n 1)
OPENSSL_LIB=$(find openssl.xcframework/ios-arm64 -name "libcrypto.a" -o -name "OpenSSL" | head -n 1)

if [ -z "$OPENSSL_INCLUDE" ] || [ -z "$OPENSSL_LIB" ]; then
    echo "Ошибка: Не удалось найти заголовки или библиотеку OpenSSL"
    exit 1
fi

echo "==> Компиляция C/C++ исходников zsign..."
ZSIGN_INCLUDES="-I zsign_src -I zsign_src/src -I zsign_src/src/common -I zsign_src/src/third-party/minizip -I $OPENSSL_INCLUDE"
COMMON_FLAGS="-O3 -isysroot $SDK_PATH -arch arm64 -miphoneos-version-min=18.0 $ZSIGN_INCLUDES"

for c_file in $(find zsign_src -name "*.c" 2>/dev/null); do
    base=$(basename "$c_file" .c)
    echo "  [C] $c_file -> build/obj/${base}.o"
    xcrun --sdk iphoneos clang $COMMON_FLAGS -c "$c_file" -o "build/obj/${base}.o"
done

for cpp_file in $(find zsign_src -name "*.cpp" 2>/dev/null); do
    base=$(basename "$cpp_file" .cpp)
    echo "  [CXX] $cpp_file -> build/obj/${base}.o"
    xcrun --sdk iphoneos clang++ -std=c++14 $COMMON_FLAGS -Dmain=zsign_main -c "$cpp_file" -o "build/obj/${base}.o"
done

echo "  [CXX] GeraKStore/Services/zsign_bridge.cpp -> build/obj/zsign_bridge.o"
xcrun --sdk iphoneos clang++ -std=c++14 $COMMON_FLAGS -c GeraKStore/Services/zsign_bridge.cpp -o build/obj/zsign_bridge.o

echo "==> Проверка символа zsign_main в объектном файле..."
nm build/obj/*.o | grep "zsign_main" | head -n 1

echo "==> Сбор списка Swift-исходников (исключая точку входа WidgetBundle)..."
SWIFT_FILES=$(find GeraKStore -name "*.swift" ! -name "GeraKStoreWidgetsBundle.swift")
OBJ_FILES=$(find build/obj -name "*.o")

echo "==> Монолитная компиляция и линковка $APP_NAME..."
APP_BUNDLE="build/Payload/$APP_NAME.app"
mkdir -p "$APP_BUNDLE"

xcrun --sdk iphoneos swiftc -O -sdk "$SDK_PATH" -target arm64-apple-ios18.0     -import-objc-header GeraKStore/Services/zsign_bridge.h     -I GeraKStore/Services     $SWIFT_FILES     $OBJ_FILES     "$OPENSSL_LIB"     -Xlinker -lc++     -Xlinker -lz     -framework Foundation     -framework UIKit     -framework SwiftUI     -framework Security     -framework Network     -framework ActivityKit     -framework WidgetKit     -o "$APP_BUNDLE/$APP_NAME"

echo "==> Формирование Info.plist..."
cat <<PLIST > "$APP_BUNDLE/Info.plist"
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
    <string>$BUILD_NUM</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>18.0</string>
    <key>NSSupportsLiveActivities</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>UIFileSharingEnabled</key>
    <true/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Упаковка $APP_NAME.ipa..."
cd build
zip -qr "../$APP_NAME.ipa" Payload
cd ..

echo "==> Сборка успешно завершена: $APP_NAME.ipa (v$VERSION, билд $BUILD_NUM)"
