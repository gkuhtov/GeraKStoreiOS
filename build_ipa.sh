#!/bin/bash
set -e

echo "==> Подготовка каталогов сборки..."
rm -rf Payload build GeraKStore.ipa
mkdir -p Payload/GeraKStore.app

echo "==> Копирование исходников и ресурсов..."
cp -r GeraKStore/* Payload/GeraKStore.app/ 2>/dev/null || true

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
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSFaceIDUsageDescription</key>
    <string>Требуется Face ID для безопасного входа в GeraKStore</string>
</dict>
</plist>
PLIST

echo "==> Упаковка в GeraKStore.ipa..."
zip -r9 GeraKStore.ipa Payload
echo "==> Сборка завершена успешно!"
