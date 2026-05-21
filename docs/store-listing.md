# GoToGolf — App Store 上架文件

> 此文件給 App Store Connect 上架人員直接複製貼上。所有字數已對齊 Apple
> 目前的欄位上限（zh-Hant 與 en 各自獨立計算）。

## 1. App Information

| 欄位 | 值 |
|------|----|
| Name (zh-Hant) | `GoToGolf` |
| Name (en) | `GoToGolf` |
| Bundle ID | `com.gotogolf.GoToGolf` |
| Primary category | Sports |
| Secondary category | Health & Fitness |
| Age rating | 4+ (無暴力、無賭博、無社交內容) |
| Pricing | Free with In-App Subscription |
| Availability | Worldwide; zh-Hant primary, en fallback |

## 2. App Store 列表內容

### 2.1 Subtitle (30 char limit)

**zh-Hant**

```
業餘高爾夫計分・WHS 差點追蹤
```
（13 字）

**en**

```
Casual golf scoring & WHS index
```
（30 char）

### 2.2 Promotional text (170 char limit, 可在任何時間更新)

**zh-Hant**

```
為新手與業餘球友設計。台灣球場一鍵選擇,逐洞輸入桿數與推桿,自動計算
WHS 差點指數。3 場 18 洞即建立人生首個正式差點。
```
（72 字）

**en**

```
Built for beginners. Tap a Taiwan course, enter gross + putts per hole, and let
GoToGolf compute your WHS handicap. Three full rounds = your first real index.
```
（170 char）

### 2.3 Description (4000 char limit)

**zh-Hant**

```
GoToGolf 是專為新手與業餘球友打造的「素雅運動年鑑」風格計分 app。
沒有複雜的 GPS 圖資、沒有付費才能用的基本功能,專注於一件事:讓你
打完一場後,知道自己進步了多少。

【核心功能】

▍逐洞計分卡
打開 app 選擇球場,進入計分頁就能逐洞輸入「桿數」與「推桿」。每洞自
動標記 EAG/BIR/PAR/BOG/DBL,即時顯示對標準桿(±N)、推桿總數、已打洞
數。視覺風格走「球場年鑑」配色,球道綠 × 朱紅 × 米貓黃。

▍世界差點 WHS 追蹤
依 WHS 2024 規則計算 Score Differential、Net Double Bogey、Beginner Cap
(Par+5)、Course Handicap、Stroke Index 與 Progressive Handicap(3 場
起即可建立首個指數)。儲存球局時自動更新差點;刪除球局時重算 ledger,
資料一致性永遠跟得上。

▍8 座台灣球場預設
淡水、林口、大溪、揚昇、桃園、國華、美麗華、東華——常見的台灣會員制
與一般球場,每洞 par 與 stroke index 預先載入。要打的球場不在列表?
「+ 新增球場」一鍵建立,儲存到本機。

▍OpenMoji 風格戰術複盤
打完一場按「結束並儲存本回合」,app 自動切到複盤頁,根據你的成績挑
一張 OpenMoji 插畫(旗桿/星星/獎盃/標靶)當主視覺,搭配桿數摘要、成績
分佈條與每洞詳細記錄。

▍歷史趨勢圖
歷史球局頁面用 Swift Charts 顯示最近 20 場的對標準桿趨勢,bars 顏色跟著
桿差走(birdie 綠/par 灰/bogey 黃/double+ 紅),滑動即可往前回溯。

【GoToGolf Premium】

升級 Premium($X / 年)一次解鎖:
• iCloud 跨裝置同步 — 換手機不丟資料
• CSV / PDF 匯出 — 給教練或自己備檔
• 多球員 group round — 一張卡同時記 4 個人

不訂閱也能完整用所有計分與差點功能。

【為什麼選 GoToGolf】

• 介面用思源黑體 TC、數字 monospaced,讓計分卡像紙本年鑑那樣好讀
• 完全離線即可運作,沒有網路時不影響打球
• Apple Watch 副屏顯示當前洞,腕上看一眼即可
• 開源 GolfCore 計算引擎,WHS 計算結果可逐步驗證

立刻下載,從下一場開始累積屬於你自己的差點。
```

**en**

```
GoToGolf is a quiet "yearbook" scorecard for beginner and casual golfers.
No GPS maps you didn't ask for, no basic features paywalled — just one job:
help you know how much you improved after each round.

WHAT'S INSIDE

▍ Per-hole scorecard
Pick a course, then tap gross + putts on each hole. Live running totals show
holes played, gross, putts, and your relative-to-par with a single tap. Every
hole row tags itself EAG / BIR / PAR / BOG / DBL. Visual language: a fairway-
green × red × cream "sport yearbook" palette.

▍ World Handicap System (WHS) tracking
Computes Score Differential, Net Double Bogey, the beginner cap (Par+5),
Course Handicap, Stroke Index, and the Progressive Handicap table — your
first official index appears as soon as you bank three rounds (54 holes).
The ledger is rebuilt from the persisted rounds, so a deletion never leaves
your handicap inconsistent.

▍ Eight Taiwan courses preloaded
Tamsui, Linkou, Daxi, Sunrise, Taoyuan, Kuo Hua, Miramar, and Tunghua —
the most-played Taiwanese clubs ship in the bundle with per-hole par and
stroke index. Course you want missing? "+" adds a custom one in under a
minute and keeps it on-device forever.

▍ OpenMoji-illustrated debrief
Finish a round, and GoToGolf auto-routes to the debrief tab with an
OpenMoji hero picked by your performance (flag-in-hole / star / trophy /
target), a stat panel, a colour-graded distribution bar, and the full
scorecard grid.

▍ Trend chart
History view renders the last twenty rounds as Swift Charts bars, coloured
by your par-relative finish so the trend (birdie green / par grey / bogey
amber / double+ red) is readable at a glance.

GoToGolf Premium

Upgrade ($X / year) to unlock:
• iCloud cross-device sync — never lose data when you switch phones
• CSV / PDF export — share with your coach or keep your own archive
• Group rounds — track up to 4 players on one card

Free tier keeps full solo scoring + the local WHS index. Forever.

WHY GoToGolf

• Typography uses Noto Sans TC + monospaced digits, so the scorecard reads
  like a paper yearbook
• Works fully offline — score a round when the cell signal drops
• Apple Watch face shows your current hole, no need to dig out the phone
• Open-source GolfCore engine — every WHS step is traceable

Download and start your own yearbook today.
```

### 2.4 Keywords (100 char limit, 不顯示給用戶)

**zh-Hant**

```
高爾夫,計分,差點,WHS,球場,推桿,記分卡,台灣球場,golf,handicap
```
（57 字符）

**en**

```
golf,scoring,handicap,WHS,scorecard,putting,taiwan,beginner,fairway,course
```
（76 char）

### 2.5 What's New (4000 char limit, 每次新版本更新)

**zh-Hant — v1.0 首發**

```
歡迎來到 GoToGolf 1.0!

• 8 座台灣球場預設與「+ 新增自訂球場」流程
• 逐洞計分:桿數 + 推桿,即時 EAG/BIR/PAR/BOG/DBL 標記
• 累積桿數 / 對標準桿即時顯示在計分卡頂部
• WHS 2024 差點計算 + Progressive Handicap (3 場起算)
• OpenMoji 風格戰術複盤,完成回合自動切換到複盤頁
• Swift Charts 桿差趨勢長條圖,顯示最近 20 場
• 歷史球局支援 swipe 刪除,差點 ledger 自動重算
• Apple Watch 副屏顯示當前洞
• 全離線可用、繁中介面、深淺色自動切換
```

**en — v1.0 launch**

```
Welcome to GoToGolf 1.0!

• 8 Taiwan courses preloaded; "+" adds your own in under a minute
• Per-hole scoring with live EAG / BIR / PAR / BOG / DBL tags
• Running gross + to-par bar pinned at the top of the scorecard
• WHS 2024 handicap with progressive handicap (3-round opener)
• OpenMoji-illustrated debrief with auto-route on finish
• Swift Charts last-20-rounds par-diff trend bars
• Swipe-to-delete round history, with full handicap ledger rebuild
• Apple Watch glance — current hole on the wrist
• Works offline, dark mode-ready, Traditional Chinese first-class
```

## 3. URLs

| 欄位 | 用途 | 預備值 |
|------|------|--------|
| Marketing URL | App Store「網站」連結 | `https://github.com/fsc0638/GoToGolf` (or 個人 landing page) |
| Support URL | App Store「支援」連結 | `https://github.com/fsc0638/GoToGolf/issues` |
| Privacy Policy URL | **必填** | 需獨立架,參考 §6 |

## 4. In-App Purchases

| 欄位 | 值 |
|------|----|
| Product ID | `com.gotogolf.premium.annual` |
| Reference Name | `GoToGolf Premium (Annual)` |
| Type | Auto-Renewable Subscription |
| Subscription Group | `GoToGolf Premium` (single tier) |
| Display Name (zh-Hant) | `GoToGolf Premium` |
| Display Name (en) | `GoToGolf Premium` |
| Description (zh-Hant) | `解鎖 iCloud 跨裝置同步、CSV/PDF 匯出、4 人同時記分。` |
| Description (en) | `Unlocks iCloud sync, CSV / PDF export, and group rounds (up to 4 players).` |
| Price tier | App Store Connect 設定;建議 NT$590 / US$19.99 / year |
| Free trial | 7 days(可選,建議開) |

## 5. Screenshots

Apple 至少要求 **6.7" iPhone (1290 × 2796)** 一組。本 app 提供以下建議
順序的 6 張(用 simulator 截圖 + 加上標題覆蓋層):

| # | 畫面 | 標題覆蓋層(zh-Hant) | 標題覆蓋層(en) |
|---|------|---------------------|----------------|
| 1 | CourseListView 選擇淡水 | `台灣球場一鍵選擇` | `One-tap Taiwan courses` |
| 2 | ScoringView 含 summary bar + EAG/BIR tags | `逐洞計分,即時看到 ±par` | `Score each hole, see par-diff live` |
| 3 | DebriefView 含 OpenMoji hero + distribution bar | `戰術複盤,看見每一隻 Birdie` | `Debrief — every Birdie counted` |
| 4 | HistoryView 含 WHS hero + 趨勢圖 | `WHS 差點 + 趨勢圖` | `WHS index + trend chart` |
| 5 | CreateCourseView 表單 | `沒有的球場?一分鐘新增` | `Missing a course? Add yours in 60s` |
| 6 | 訂閱卡(HistoryView upgrade card) | `Premium 跨裝置 / 匯出 / 多人` | `Premium: sync, export, group` |

### 5.1 截圖製作流程(simctl 一鍵)

```sh
# 啟動 6.7" 模擬器並安裝 release build
xcrun simctl boot "iPhone 17 Pro Max"
cd App && xcodebuild build -project GoToGolf.xcodeproj \
  -scheme GoToGolf -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath ./build

xcrun simctl install booted ./build/Build/Products/Release-iphonesimulator/GoToGolf.app
xcrun simctl launch booted com.gotogolf.GoToGolf

# 操作 app 走到對應畫面後:
xcrun simctl io booted screenshot screenshot-1.png
# (重複 6 次)
```

截好後用任何圖片工具(Figma / Sketch / Preview)疊上 §5 表格的雙語標題層
(建議用 DS.fairway 色塊背景 + 米色 1.6× 標題)。

## 6. Privacy & 資料蒐集

| 類別 | 是否蒐集 | 用途 | 是否與身份綁定 |
|------|----------|------|----------------|
| Identifiers (Device ID) | 否(本機 UUID,不上傳) | — | — |
| Purchases | 是(StoreKit 處理) | 訂閱核驗 | 否 |
| User Content (球局/差點) | **僅在用戶啟用 Premium iCloud 同步時** | 跨裝置同步 | 是(綁 iCloud 帳號) |
| Diagnostics | 否 | — | — |
| Tracking | **否** | — | — |

→ App Privacy 段落(App Store Connect → App Privacy)勾選:
- **Purchases — Linked to user**
- **User Content (僅 iCloud 同步啟用時)— Linked to user**
- 其餘全部 "Data Not Collected"

### 6.1 Privacy Policy 模板

需要架在 Marketing URL 同一個 domain。最簡內容:

```
GoToGolf Privacy Policy
Updated: 2026-XX-XX

What we collect on-device:
- Your rounds, scores, and WHS handicap differentials (JSON in the app
  sandbox, never transmitted).
- Subscription transactions (handled entirely by Apple StoreKit).

What we send to iCloud (only if you enable Premium sync):
- Your rounds, scores, and handicap ledger, stored in your own private
  CloudKit container. Anthropic / GoToGolf staff cannot read these
  records.

What we do NOT do:
- No analytics SDKs. No tracking. No advertising IDs. No data sale.

Contact: <your email>
```

## 7. Build & Submit

### 7.1 Archive command

```sh
cd App
xcodebuild archive \
  -project GoToGolf.xcodeproj \
  -scheme GoToGolf \
  -configuration Release \
  -archivePath ./build/GoToGolf.xcarchive \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  DEVELOPMENT_TEAM="<YOUR_TEAM_ID>"
```

### 7.2 Export IPA

```sh
xcodebuild -exportArchive \
  -archivePath ./build/GoToGolf.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/export
```

ExportOptions.plist:

```xml
<plist version="1.0"><dict>
  <key>method</key><string>app-store</string>
  <key>teamID</key><string>YOUR_TEAM_ID</string>
  <key>uploadBitcode</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
```

### 7.3 Upload to App Store Connect

```sh
xcrun altool --upload-app -t ios \
  -f ./build/export/GoToGolf.ipa \
  --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

(或直接在 Xcode → Organizer → Distribute App 走 GUI)

## 8. Pre-submission checklist

- [ ] 1024×1024 AppIcon 已就位(commit 0b1de97)
- [ ] 6.7" iPhone 截圖 × 6 已上傳
- [ ] zh-Hant + en metadata 已填(本文件 §2)
- [ ] Privacy Policy URL 已上線(§6.1)
- [ ] Marketing + Support URL 可訪問
- [ ] StoreKit product ID 在 App Store Connect 建好(§4)
- [ ] Test build 已在 TestFlight 跑過完整 18 洞 smoke (docs/TESTING.md §4)
- [ ] App Privacy 段落已宣告(§6)
- [ ] What's New for v1.0 已填(§2.5)
