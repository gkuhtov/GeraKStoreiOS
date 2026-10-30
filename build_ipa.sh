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

python3 -c "
import os

# 1. Замена int main на int zsign_main
zsign_cpp = 'zsign_src/src/zsign.cpp'
if os.path.exists(zsign_cpp):
    with open(zsign_cpp, 'r') as f:
        c = f.read()
    c = c.replace('int main(', 'int zsign_main(')
    with open(zsign_cpp, 'w') as f:
        f.write(c)

# 2. Подмена пути /tmp на системную переменную TMPDIR песочницы iOS во всех исходниках
for root, _, files in os.walk('zsign_src/src'):
    for f in files:
        if f.endswith(('.cpp', '.h')):
            p = os.path.join(root, f)
            with open(p, 'r', errors='ignore') as file:
                content = file.read()
            
            # Заменяем жесткие шаблоны путей /tmp на %s с передачей TMPDIR
            new_content = content
            new_content = new_content.replace('\"/tmp/zsign_folder_%llu\"', '\"%s/zsign_folder_%llu\", (getenv(\"TMPDIR\") ? getenv(\"TMPDIR\") : \".\")')
            new_content = new_content.replace('\"/tmp/Requirements_%llu.blob\"', '\"%s/Requirements_%llu.blob\", (getenv(\"TMPDIR\") ? getenv(\"TMPDIR\") : \".\")')
            new_content = new_content.replace('\"/tmp\"', '(getenv(\"TMPDIR\") ? getenv(\"TMPDIR\") : \".\")')

            if new_content != content:
                with open(p, 'w') as file:
                    file.write(new_content)
                print(f'Пропатчен: {f}')

print('Патчинг zsign под Sandbox завершен.')
"

echo "==> Загрузка OpenSSL 3.x XCFramework для iOS..."
if [ ! -d "build/OpenSSL.xcframework" ]; then
    curl -sL "https://github.com/krzyzanowskim/OpenSSL/releases/download/3.3.2000/OpenSSL.xcframework.zip" -o build/openssl3.zip
    unzip -q build/openssl3.zip -d build/
fi

OPENSSL_FRAMEWORK_DIR="build/OpenSSL.xcframework/ios-arm64"
OPENSSL_HEADERS="$OPENSSL_FRAMEWORK_DIR/OpenSSL.framework/Headers"

echo "==> Компиляция C-исходников (minizip)..."
MINIZIP_C="zsign_src/src/third-party/minizip/ioapi.c zsign_src/src/third-party/minizip/zip.c zsign_src/src/third-party/minizip/unzip.c"

xcrun --sdk iphoneos clang \
    -target $TARGET \
    -isysroot $SDK_PATH \
    -O3 \
    -Izsign_src/src \
    -Izsign_src/src/third-party \
    -c $MINIZIP_C

mv *.o build/obj/

echo "==> Компиляция C++ исходников zsign..."
ZSIGN_CPP=$(find zsign_src/src -name "*.cpp" ! -path "*/windows/*")

xcrun --sdk iphoneos clang++ \
    -target $TARGET \
    -isysroot $SDK_PATH \
    -O3 -std=c++17 \
    -I$OPENSSL_HEADERS \
    -Izsign_src/src \
    -Izsign_src/src/common \
    -Izsign_src/src/third-party \
    -F $OPENSSL_FRAMEWORK_DIR \
    -framework OpenSSL \
    -c $ZSIGN_CPP GeraKStore/Services/zsign_bridge.cpp

mv *.o build/obj/

echo "==> Поиск Swift-исходников..."
SWIFT_FILES=$(find GeraKStore -name "*.swift" ! -name "GeraKStoreWidgetsBundle.swift" ! -name "InstallActivityWidget.swift")

echo "==> Монолитная сборка GeraKStore..."
xcrun --sdk iphoneos swiftc \
    -target $TARGET \
    -sdk $SDK_PATH \
    -O \
    -parse-as-library \
    -emit-executable \
    -F $OPENSSL_FRAMEWORK_DIR \
    -framework OpenSSL \
    -Xlinker -lz \
    -Xlinker -lc++ \
    -Xlinker build/obj/*.o \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -o Payload/GeraKStore.app/GeraKStore \
    $SWIFT_FILES

echo "==> Встраивание OpenSSL фреймворка в бандл..."
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
    <string>0.4.1</string>
    <key>CFBundleVersion</key>
    <string>41</string>
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
echo "==> Сборка завершена!"
