# FileShelf

macOS用のファイルシェルフアプリです。仮想デスクトップ（Spaces）間でファイルやフォルダを移動する際に、一時的に置いておけるクリップボードのように使えます。

## 機能

- メニューバーに常駐するフローティングウィンドウ
- Finderからファイル・フォルダをドラッグ&ドロップで受け取れる
- 受け取ったファイルをFinderへ再ドラッグして持っていける
- ドラッグ中にマウスが画面端に触れると自動でシェルフが開く
- 個別削除・全クリアボタン
- Escapeキーでシェルフを閉じる

## 動作環境

- macOS 14 (Sonoma) 以降
- Apple Silicon / Intel 両対応

## インストール

[Releases](../../releases) から最新の `FileShelf.zip` をダウンロードして展開し、`/Applications` フォルダに移動してください。

> **Note**: 配布バイナリはアドホック署名のみのため、初回起動時に右クリック → 「開く」で起動してください。

## ビルド方法

Xcode不要。macOS Command Line Tools のみで動作します。

```bash
git clone https://github.com/yousuisui/FileShelf.git
cd FileShelf
./build.sh
```

`build/FileShelf.app` が生成されます。

## ライセンス

[MIT](LICENSE)
