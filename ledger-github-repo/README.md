# 記帳

無印風的個人記帳 App：收支分類、年度總覽、房屋貸款攤還、每月預算與桌面小工具。

| 版本 | 說明 |
|---|---|
| **網頁版（PWA）** | 本 repo 根目錄。用 Safari 開啟即可加入主畫面，離線可用 |
| **原生版（SwiftUI）** | `ios/`，含自動更新的 WidgetKit 桌面小工具 |

## 網頁版

👉 **https://martinzz666.github.io/ledger/**

用 Safari 開啟後「分享 → 加入主畫面」即可。安裝方式、描述檔與 Scriptable 小工具說明見 [安裝說明.md](安裝說明.md)。

- `index.html`　App 本體（單一檔案）
- `manifest.webmanifest`、`sw.js`　PWA 設定與離線快取
- `記帳.mobileconfig`　iOS 描述檔，安裝後主畫面直接產生圖示（需先把裡面的 URL 改成你的 Pages 網址）
- `記帳小工具.js`、`寫入記帳資料.js`　Scriptable 版桌面小工具

## 原生版

見 [ios/README.md](ios/README.md)。需要 Mac 與 Xcode；用免費 Apple ID 簽署即可裝到自己的 iPhone，小工具會自動更新。

## 功能

- 支出 13 類、收入 7 類，收入以綠色與 `+` 區隔
- 月明細、月／年分類統計、12 個月收支比較、儲蓄率
- 房貸：本息平均或本金平均攤還、寬限期、逐期攤還表、繳款與逾期狀態，繳款會自動寫回明細
- 預算：每月總預算與分類預算、每日可花、可自由支配餘額、預估月底支出、進度超前／落後
- 資料存在本機，可匯出 CSV

## 授權

個人使用，無保固。
