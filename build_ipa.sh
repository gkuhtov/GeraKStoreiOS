#!/bin/bash
set -e

echo "==> Подготовка каталогов..."
rm -rf Payload build GeraKStore.ipa
mkdir -p Payload/GeraKStore.app build/obj

echo "==> Определение SDK iOS..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
TARGET="arm64-apple-ios16.1"

echo "==> Подготовка исходников zsign..."
rm -rf zsign_src
git clone --depth 1 https://github.com/zhlynn/zsign.git zsign_src

# Заменяем точку входа main -> zsign_main в zsign.cpp
python3 -c "
import os

target_file = None
for root, _, files in os.walk('zsign_src/src'):
    for f in files:
        if f in ['zsign.cpp', 'main.cpp']:
            target_file = os.path.join(root, f)
            break

if target_file:
    with open(target_file, 'r') as f:
        content = f.read()
    content = content.replace('int main(', 'int zsign_main(')
    with open(target_file, 'w') as f:
        f.write(content)
    print(f'Точка входа изменена в: {target_file}')
"

echo "==> Загрузка OpenSSL.xcframework..."
if [ ! -d "build/OpenSSL.xcframework" ]; then
    curl -sL "https://github.com/krzyzanowskim/OpenSSL/releases/download/1.1.2301/OpenSSL.xcframework.zip" -o build/openssl.zip
    unzip -q build/openssl.zip -d build/
fi

OPENSSL_FRAMEWORK_DIR="build/OpenSSL.xcframework/ios-arm64"
OPENSSL_HEADERS="$OPENSSL_FRAMEWORK_DIR/OpenSSL.framework/Headers"

echo "==> Выборка исходников zsign для iOS..."
# Берём C/C++ файлы строго из src, игнорируя каталоги Windows/VS
ZSIGN_CPP=$(find zsign_src/src -name "*.cpp" ! -path "*/windows/*")
ZSIGN_C=$(find zsign_src/src -name "*.c" ! -path "*/windows/*" 2>/dev/null || true)

echo "==> Компиляция C++ компонентов zsign..."
xcrun --sdk iphoneos clang++ \
    -target $TARGET \
    -isysroot $SDK_PATH \
    -O3 -std=c++11 \
    -I$OPENSSL_HEADERS \
    -Izsign_src/src \
    -Izsign_src/src/common \
    -Izsign_src/src/third-party \
    -F $OPENSSL_FRAMEWORK_DIR \
    -framework OpenSSL \
    -c $ZSIGN_CPP $ZSIGN_C GeraKStore/Services/zsign_bridge.cpp

mv *.o build/obj/

echo "==> Поиск Swift-исходников..."
SWIFT_FILES=$(find GeraKStore -name "*.swift" ! -name "GeraKStoreWidgetsBundle.swift" ! -name "InstallActivityWidget.swift")

echo "==> Монолитная линковка GeraKStore..."
xcrun --sdk iphoneos swiftc \
    -target $TARGET \
    -sdk $SDK_PATH \
    -O \
    -parse-as-library \
    -emit-executable \
    -F $OPENSSL_FRAMEWORK_DIR \
    -framework OpenSSL \
    -Xlinker build/obj/*.o \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -o Payload/GeraKStore.app/GeraKStore \
    $SWIFT_FILES

echo "==> Встраивание фреймворка OpenSSL в бандл..."
mkdir -p Payload/GeraKStore.app/Frameworks
cp -R "$OPENSSL_FRAMEWORK_DIR/OpenSSL.framework" Payload/GeraKStore.app/Frameworks/

echo "==> Создание Info.plist..."
cat << 'PLIST' > Payload/GeraKStore.app/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>ru</string>
    <key>CFBundleExecutable</key>
    <string>GeraKStore</string>
    <key>CFBundleIdentifier</key>
    <string>com.gkuhtov.gerakstore</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GeraKStore</string>
    <key>CFBundleIcons</key>
    <dict>
        <key>CFBundlePrimaryIcon</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon</string>
            </array>
            <key>CFBundleIconName</key>
            <string>AppIcon</string>
        </dict>
    </dict>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiresFullScreen</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>16.1</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSFaceIDUsageDescription</key>
    <string>Используется для защиты доступа к GeraKStore</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Используется для локальной установки подписанных приложений через OTA сервис</string>
    <key>NSSupportsLiveActivities</key>
    <true/>
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>processing</string>
    </array>
    <key>UILaunchScreen</key>
    <dict>
        <key>UIColorName</key>
        <string>black</string>
    </dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
PLIST

echo "==> Упаковка GeraKStore.ipa..."
zip -r9 GeraKStore.ipa Payload
echo "==> Готово! Сформирован монолитный IPA с прямой интеграцией zsign."
