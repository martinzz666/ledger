# 記帳 — 原生 iOS 版（SwiftUI + WidgetKit）

桌面小工具會**自動更新**：資料一存檔，App 就呼叫 `WidgetCenter.reloadAllTimelines()`；
時間軸另外預排未來七天每日凌晨的更新，所以「剩餘天數」「每日可花」每天自己重算，不需要任何手動同步。

## 先確認兩件事

1. **需要一台 Mac**。iOS App 只能用 macOS 上的 Xcode 建置，Windows 無法（雲端 Mac 服務如 MacStadium、MacinCloud 也可以）。
2. **不需要付費開發者帳號**。用你自己的 Apple ID 免費簽署就能裝到自己的 iPhone 上，小工具完全可用；
   限制是簽章 7 天到期，過期後用 Xcode 重新 Run 一次即可。
   USD 99／年的 Apple Developer Program 只有在要上架 App Store 或發 TestFlight 時才需要。

## 建立專案（約 10 分鐘）

1. Xcode → **File → New → Project → iOS → App**
   - Product Name：`Ledger`
   - Interface：**SwiftUI**、Language：**Swift**
   - Organization Identifier：例如 `tw.lin` → Bundle ID 會是 `tw.lin.Ledger`
2. 刪掉樣板產生的 `ContentView.swift` 與 `LedgerApp.swift`
3. 把 `Shared/` 與 `App/` 裡的所有 `.swift` 拖進專案（勾選 Copy items if needed，Target 勾 **Ledger**）
4. **File → New → Target → Widget Extension**
   - Product Name：`LedgerWidget`
   - **取消勾選** Include Live Activity 與 Include Configuration App Intent
   - 刪掉樣板產生的 `LedgerWidget.swift`、`LedgerWidgetBundle.swift`
5. 把 `Widget/LedgerWidget.swift` 拖進專案，Target 勾 **LedgerWidgetExtension**
6. **重要**：在左側檔案列表選取 `Shared/` 的四個檔案（Model、Amortization、Stats、Theme），
   右側 Inspector → **Target Membership** 兩個 target 都要打勾

## 設定 App Group（App 與小工具共用資料的關鍵）

對 **Ledger** 與 **LedgerWidgetExtension** 兩個 target 各做一次：

Signing & Capabilities → **+ Capability** → **App Groups** → **+** → 輸入
```
group.tw.lin.ledger
```

若你改用別的名稱，請同步修改 `Shared/Model.swift` 裡的 `SharedStore.appGroup`，兩邊必須完全一致。

## 簽署與執行

1. 兩個 target 的 Signing & Capabilities → Team 選你的 Apple ID
   （未加入過：Xcode → Settings → Accounts → **+** → Apple ID 登入）
2. Bundle ID 若衝突，改成獨一無二的字串，例如 `tw.lin.yc.Ledger`
3. iPhone 用線接上或同網路無線偵錯，選裝置 → **Run**
4. 首次安裝：iPhone → 設定 → 一般 → VPN 與裝置管理 → 信任你的開發者憑證
5. 主畫面長按空白處 → 左上「＋」→ 搜尋「記帳」→ 加入小型或中型小工具

## 已知事項

- 這份程式碼在本機沒有 Xcode 可編譯，尚未經過實際建置驗證；若有編譯錯誤多半是很小的型別或 API 調整，把錯誤訊息貼給我即可修。
- 攤還與預算的計算邏輯與網頁版一致，已用相同數值交叉驗算過
  （1,000 萬、2.185%、30 年、本息平均攤還 → 每期 37,894，末期餘額歸零）。
- 資料存在 App Group 的 UserDefaults，資料量大時可改為寫入 App Group 容器內的 JSON 檔或改用 SwiftData。

## 檔案

```
Shared/   Model.swift          資料模型 + App Group 共用儲存
          Amortization.swift   房貸攤還表
          Stats.swift          預算與每日可花計算
          Theme.swift          無印風配色、細線元件
App/      LedgerApp.swift      進入點
          AppState.swift       唯一資料來源，存檔即刷新小工具
          ContentView.swift    分頁
          MonthView.swift      明細
          BudgetView.swift     預算
          YearView.swift       年度
          LoanView.swift       房貸
          Editors.swift        記一筆／房貸／預算三個編輯表單
Widget/   LedgerWidget.swift   小工具（小型、中型）
```
