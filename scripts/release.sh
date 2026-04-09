#!/bin/bash
set -euo pipefail

# ============================================================
# Clip Holder リリースビルドスクリプト
# アーカイブ → エクスポート → 公証 → ステープル → DMG 作成
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClipHolder"
ARCHIVE_PATH="${PROJECT_DIR}/build/ClipHolder.xcarchive"
EXPORT_PATH="${PROJECT_DIR}/build/export"
EXPORT_OPTIONS="${PROJECT_DIR}/ExportOptions.plist"
APP_NAME="ClipHolder"
DMG_NAME="ClipHolder"

cd "$PROJECT_DIR"

# バージョン情報取得
VERSION=$(xcodebuild -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | head -1 | awk '{print $3}')
BUILD=$(xcodebuild -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep CURRENT_PROJECT_VERSION | head -1 | awk '{print $3}')
echo "==> Building ${APP_NAME} v${VERSION} (${BUILD})"

# クリーンアップ
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

# ---- Step 1: アーカイブ ----
echo ""
echo "==> Step 1/5: アーカイブ..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

echo "    アーカイブ完了: $ARCHIVE_PATH"

# ---- Step 2: エクスポート (Developer ID 署名) ----
echo ""
echo "==> Step 2/5: エクスポート (Developer ID 署名)..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -quiet

echo "    エクスポート完了: $EXPORT_PATH"

# 署名確認
echo ""
echo "==> 署名確認:"
codesign -dvv "${EXPORT_PATH}/${APP_NAME}.app" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier"

# ---- Step 3: 公証 (Notarization) ----
echo ""
echo "==> Step 3/5: 公証 (Notarization)..."
echo "    ZIP 作成中..."
ditto -c -k --keepParent "${EXPORT_PATH}/${APP_NAME}.app" "${EXPORT_PATH}/${DMG_NAME}.zip"

echo "    Apple に送信中... (数分かかる場合があります)"
xcrun notarytool submit "${EXPORT_PATH}/${DMG_NAME}.zip" \
    --keychain-profile "notarytool" \
    --wait

# ---- Step 4: ステープル ----
echo ""
echo "==> Step 4/5: ステープル..."
xcrun stapler staple "${EXPORT_PATH}/${APP_NAME}.app"

# ---- Step 5: DMG 作成 ----
echo ""
echo "==> Step 5/5: DMG 作成..."
DMG_OUTPUT="${PROJECT_DIR}/build/${DMG_NAME}-v${VERSION}.dmg"
rm -f "$DMG_OUTPUT"

# DMG 用一時ディレクトリ
DMG_TEMP="${PROJECT_DIR}/build/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "${EXPORT_PATH}/${APP_NAME}.app" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_OUTPUT"

rm -rf "$DMG_TEMP"

# DMG にもステープル
xcrun stapler staple "$DMG_OUTPUT"

echo ""
echo "============================================================"
echo "  リリースビルド完了!"
echo "  DMG: $DMG_OUTPUT"
echo "============================================================"
