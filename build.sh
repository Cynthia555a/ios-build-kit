#!/bin/bash
set -euo pipefail
APP_NAME="calc"
MIN_IOS="14.0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT}/build"
APP_DIR="${BUILD_DIR}/Payload/${APP_NAME}.app"

echo "==> 清理旧产物"
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_DIR}"

echo "==> 查找 iPhoneOS SDK"
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "    SDK: ${SDK_PATH}"
if [ ! -d "${SDK_PATH}" ]; then
  echo "!! 找不到 iOS SDK"
  exit 1
fi

echo "==> 编译 Swift 源码"
xcrun --sdk iphoneos swiftc \
  -target "arm64-apple-ios${MIN_IOS}" \
  -sdk "${SDK_PATH}" \
  -parse-as-library \
  -swift-version 5 \
  -O -whole-module-optimization \
  -module-name "${APP_NAME}" \
  -framework UIKit -framework SwiftUI -framework Combine -framework Foundation \
  -framework CoreGraphics -framework QuartzCore \
  -o "${APP_DIR}/${APP_NAME}" \
  "${ROOT}"/App/*.swift

chmod 755 "${APP_DIR}/${APP_NAME}"

echo "==> 拷贝 Info.plist 与图标"
cp "${ROOT}/Support/Info.plist" "${APP_DIR}/Info.plist"
if ls "${ROOT}"/Support/Icons/*.png >/dev/null 2>&1; then
  cp "${ROOT}"/Support/Icons/*.png "${APP_DIR}/"
fi

echo "==> 检查产物"
file "${APP_DIR}/${APP_NAME}"
ls -1 "${APP_DIR}"

echo "==> ad-hoc 签名（TrollStore 安装更稳，失败也不影响）"
if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "${APP_DIR}/${APP_NAME}" 2>/dev/null || \
    echo "    跳过签名（TrollStore 会自己签）"
else
  echo "    没有 codesign，跳过"
fi

echo "==> 打包 ipa"
rm -f "${ROOT}/${APP_NAME}.ipa"
(cd "${BUILD_DIR}" && zip -qry "${ROOT}/${APP_NAME}.ipa" Payload)
ls -lh "${ROOT}/${APP_NAME}.ipa"
echo "==> 完成"
