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
echo "==> Step 1/7: アーカイブ..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

echo "    アーカイブ完了: $ARCHIVE_PATH"

# ---- Step 2: エクスポート (Developer ID 署名) ----
echo ""
echo "==> Step 2/7: エクスポート (Developer ID 署名)..."
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
echo "==> Step 3/7: 公証 (Notarization)..."
echo "    ZIP 作成中..."
ditto -c -k --keepParent "${EXPORT_PATH}/${APP_NAME}.app" "${EXPORT_PATH}/${DMG_NAME}.zip"

echo "    Apple に送信中... (数分かかる場合があります)"
xcrun notarytool submit "${EXPORT_PATH}/${DMG_NAME}.zip" \
    --keychain-profile "notarytool" \
    --wait

# ---- Step 4: ステープル ----
echo ""
echo "==> Step 4/7: ステープル..."
xcrun stapler staple "${EXPORT_PATH}/${APP_NAME}.app"

# ---- Step 5: DMG 作成 ----
echo ""
echo "==> Step 5/7: DMG 作成..."
DMG_OUTPUT="${PROJECT_DIR}/build/${DMG_NAME}-${VERSION}.dmg"
DMG_BACKGROUND="${PROJECT_DIR}/scripts/dmg-background.png"
rm -f "$DMG_OUTPUT"

# DMG 用一時ディレクトリ
DMG_TEMP="${PROJECT_DIR}/build/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "${EXPORT_PATH}/${APP_NAME}.app" "$DMG_TEMP/"

# 背景画像がなければ生成
if [ ! -f "$DMG_BACKGROUND" ]; then
    echo "    背景画像を生成中..."
    swift "${PROJECT_DIR}/scripts/generate-dmg-background.swift"
fi

create-dmg \
    --volname "$APP_NAME" \
    --background "$DMG_BACKGROUND" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --text-size 10 \
    --icon "${APP_NAME}.app" 225 165 \
    --app-drop-link 445 165 \
    --hide-extension "${APP_NAME}.app" \
    --no-internet-enable \
    "$DMG_OUTPUT" \
    "$DMG_TEMP"

rm -rf "$DMG_TEMP"

# DMG を公証してステープル
echo ""
echo "==> DMG を公証中..."
xcrun notarytool submit "$DMG_OUTPUT" \
    --keychain-profile "notarytool" \
    --wait

xcrun stapler staple "$DMG_OUTPUT"

# ---- Step 6: Sparkle EdDSA 署名 ----
echo ""
echo "==> Step 6/7: Sparkle EdDSA 署名..."
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -path "*/sparkle/Sparkle/bin/sign_update" -print -quit 2>/dev/null)
if [ -z "$SPARKLE_BIN" ]; then
    echo "    エラー: sign_update が見つかりません。Xcode で一度ビルドしてください。"
    exit 1
fi

SIGN_OUTPUT=$("$SPARKLE_BIN" "$DMG_OUTPUT")
EDDSA_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
DMG_LENGTH=$(stat -f%z "$DMG_OUTPUT")
echo "    EdDSA 署名: ${EDDSA_SIGNATURE:0:20}..."
echo "    ファイルサイズ: $DMG_LENGTH bytes"

# ---- Step 7: appcast.xml 更新 ----
echo ""
echo "==> Step 7/7: appcast.xml 更新..."
APPCAST_FILE="${PROJECT_DIR}/web/public/appcast.xml"
DOWNLOAD_URL="https://github.com/YuheiFUJITA/clip-holder/releases/download/v${VERSION}/ClipHolder-${VERSION}.dmg"
PUB_DATE=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')

# 新しい item エントリを一時ファイルに書き出し
ITEM_TEMP=$(mktemp)
cat > "$ITEM_TEMP" << ITEMEOF
        <item>
            <title>Version ${VERSION}</title>
            <sparkle:version>${BUILD}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <pubDate>${PUB_DATE}</pubDate>
            <enclosure
                url="${DOWNLOAD_URL}"
                sparkle:edSignature="${EDDSA_SIGNATURE}"
                length="${DMG_LENGTH}"
                type="application/octet-stream" />
        </item>
ITEMEOF

# </channel> の直前に新しい item を挿入（最新版が先頭）
APPCAST_TEMP=$(mktemp)
if grep -q '<item>' "$APPCAST_FILE"; then
    # 既存の item がある場合、最初の <item> の前に挿入
    awk -v itemfile="$ITEM_TEMP" '
        /<item>/ && !inserted {
            while ((getline line < itemfile) > 0) print line
            close(itemfile)
            inserted = 1
        }
        { print }
    ' "$APPCAST_FILE" > "$APPCAST_TEMP"
else
    # item がない場合、</channel> の前に挿入
    awk -v itemfile="$ITEM_TEMP" '
        /<\/channel>/ {
            while ((getline line < itemfile) > 0) print line
            close(itemfile)
        }
        { print }
    ' "$APPCAST_FILE" > "$APPCAST_TEMP"
fi
mv "$APPCAST_TEMP" "$APPCAST_FILE"
rm -f "$ITEM_TEMP"

echo "    appcast.xml を更新しました"

echo ""
echo "============================================================"
echo "  リリースビルド完了!"
echo "  DMG: $DMG_OUTPUT"
echo "============================================================"
echo ""
echo "次のステップ:"
echo "  1. git add web/public/appcast.xml && git commit -m 'v${VERSION} の appcast を更新'"
echo "  2. git push origin main"
echo "  3. gh release create v${VERSION} '${DMG_OUTPUT}' --title 'ClipHolder v${VERSION}'"
echo "  4. Cloudflare Pages が自動的に appcast.xml をデプロイします"
