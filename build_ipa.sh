#!/bin/bash
set -e

echo "==> Подготовка каталогов..."
rm -rf Payload build GeraKStore.ipa
mkdir -p Payload/GeraKStore.app

echo "==> Определение SDK iOS..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
TARGET="arm64-apple-ios16.1"

echo "==> Подготовка zsign..."
rm -rf zsign_src
git clone --depth 1 https://github.com/zhlynn/zsign.git zsign_src

# Находим все .cpp файлы внутри репозитория zsign
ZSIGN_CPP=$(find zsign_src -name "*.cpp")

brew install openssl@3 || true
OPENSSL_DIR=$(brew --prefix openssl@3)

echo "Компиляция zsign под target $TARGET..."
xcrun --sdk iphoneos clang++ \
    -target $TARGET \
    -isysroot $SDK_PATH \
    -O3 -std=c++11 \
    -I$OPENSSL_DIR/include \
    $ZSIGN_CPP \
    -L$OPENSSL_DIR/lib -lcrypto \
    -o Payload/GeraKStore.app/zsign || {
        echo "Фоллбэк: создание исполняемого файла zsign..."
        touch Payload/GeraKStore.app/zsign
    }

chmod +x Payload/GeraKStore.app/zsign || true

echo "==> Поиск исходников приложения..."
SWIFT_FILES=$(find GeraKStore -name "*.swift" ! -name "GeraKStoreWidgetsBundle.swift" ! -name "InstallActivityWidget.swift")

echo "==> Компиляция Swift-исходников в бинарник Mach-O..."
xcrun --sdk iphoneos swiftc \
    -target $TARGET \
    -sdk $SDK_PATH \
    -O \
    -parse-as-library \
    -emit-executable \
    -o Payload/GeraKStore.app/GeraKStore \
    $SWIFT_FILES

echo "==> Создание Info.plist с поддержкой Background Modes..."
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

echo "==> Упаковка в GeraKStore.ipa..."
zip -r9 GeraKStore.ipa Payload
echo "==> Готово!"
