<h1 align="center">ClipHolder</h1>

<p align="center">
  macOS 向けのネイティブなクリップボード履歴マネージャー。<br />
  メニューバーに常駐し、過去のコピーをキーボードだけで素早く呼び出せます。
</p>

<p align="center">
  <a href="https://github.com/YuheiFUJITA/clip-holder/releases/latest">
    <img alt="Latest release" src="https://img.shields.io/github/v/release/YuheiFUJITA/clip-holder?include_prereleases&sort=semver" />
  </a>
  <a href="LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/github/license/YuheiFUJITA/clip-holder" />
  </a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2026.2%2B-blue" />
  <img alt="Architecture" src="https://img.shields.io/badge/arch-Apple%20Silicon-lightgrey" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange?logo=swift" />
</p>

---

## ✨ Features

- 📋 **自動キャプチャ** — テキスト・画像・PDF・ファイル参照の 4 種類を自動で蓄積
- ⌨️ **キーボードファースト** — グローバルショートカットから履歴パネルを呼び出し、インクリメンタル検索 & 矢印キー + Return で貼り付け
- 🎯 **キャレット位置にパネル表示** — アクセシビリティ API でキャレットを検出し、入力中の場所の近くにパネルを表示
- 👀 **リアルタイムプレビュー** — リッチテキスト / 画像 / PDF をその場で確認
- 🧹 **重複を自動除去** — SHA-256 ハッシュで同一コンテンツをまとめる
- 🔒 **除外アプリ設定** — パスワードマネージャーなど監視から外したいアプリを指定可能
- 📝 **プレーンテキスト貼り付け** — `⌘⇧V` で書式を除去して貼り付け
- 🔄 **自動アップデート** — Sparkle による署名付き自動更新
- 🌏 **11 言語対応** — 英語・日本語・中国語（簡体/繁体）・韓国語・フランス語・ドイツ語・スペイン語・イタリア語・ポルトガル語 (BR)・ロシア語

## 📦 Installation

### DMG をダウンロード

署名・公証済みの DMG を [GitHub Releases](https://github.com/YuheiFUJITA/clip-holder/releases) から入手できます。ダウンロードした `ClipHolder.dmg` を開き、`ClipHolder.app` を `Applications` フォルダへドラッグ &amp; ドロップしてください。

### 動作環境

| 項目 | 要件 |
| ---- | ---- |
| OS | macOS **26.2** 以降 |
| アーキテクチャ | **Apple Silicon** のみ（Intel Mac は非対応） |
| 権限 | アクセシビリティ権限（キャレット位置取得・ペースト実行に使用。オンボーディングから付与可能） |

## 🚀 Usage

### 初回セットアップ

1. `ClipHolder.app` を起動するとメニューバーにアイコンが表示されます。
2. オンボーディング画面に従い、**アクセシビリティ権限**と（任意で）**ログイン時の自動起動**を設定します。
3. 以降はバックグラウンドでクリップボード監視が始まり、コピーした内容が自動で履歴に蓄積されます。

### 履歴パネルを呼び出す

デフォルトのグローバルショートカットは **`⌥⌘V`** です。どのアプリで作業中でもパネルが現れ、アクティブなアプリのフォーカスを奪うことなく履歴を選択できます。

| 操作 | ショートカット |
| ---- | -------------- |
| 履歴パネルを開く / 閉じる | `⌥⌘V`（設定で変更可） |
| 項目を移動 | `↑` / `↓` |
| 検索 | そのまま文字入力（インクリメンタル検索） |
| 選択した項目を貼り付け | `Return` |
| プレーンテキストとして貼り付け | `⌘⇧V`（書式を除去） |
| パネルを閉じる | `Esc` |

選択中のエントリはプレビューペインでリッチテキスト・画像・PDF としてリアルタイムに確認できます。

### 設定

メニューバーアイコンから **Settings…** を開くと、以下を調整できます。

- **General** — ログイン時起動、メニューバーアイコン、自動アップデート
- **Shortcuts** — 履歴パネルを呼び出すグローバルショートカット
- **History** — 履歴の保持件数、除外アプリの追加 / 削除
- **About** — バージョン情報、ライセンス

### 除外アプリ

パスワードマネージャーや機密情報を扱うアプリからのコピーを履歴に残したくない場合は、**Settings → History → Excluded Apps** から対象アプリを追加してください。追加後、そのアプリがフロントにある間のクリップボード変更はキャプチャされません。

## 📄 License

[MIT License](LICENSE) — Copyright © Yuhei FUJITA
