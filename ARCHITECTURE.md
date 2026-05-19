# GoToGolf — Architecture & API Guide

跨裝置（iOS / iPadOS / watchOS）初學者高爾夫定位・計分・差點平台。

## 分層原則

```
┌──────────────────────────────────────────────────────────┐
│  App 層 (Xcode only)  SwiftUI 畫面 + 系統框架轉接          │
│  CoreLocation / CoreMotion / WatchConnectivity / CoreData │
└───────────────▲──────────────────────────────────────────┘
                │  只依賴 GolfCore 的純型別與協定
┌───────────────┴──────────────────────────────────────────┐
│  GolfCore (純 Swift SPM，零系統框架，swift test 可驗證)    │
└──────────────────────────────────────────────────────────┘
```

核心鐵則：**`GolfCore` 不 import 任何 UI 或系統框架**（只用 Foundation）。
所有業務規則都在這層，因此能在命令列以 `swift test` 完整驗證，App 層
維持薄殼。框架型別（`CLLocation`、`CMAccelerometerData`、`WCSession`…）
在 App 層轉接成 `GolfCore` 的純型別（`GeoCoordinate`、`MotionSample`、
`SyncEnvelope`…）。

## 模組地圖

| 範疇 | 型別 | 對應產品痛點 |
|------|------|--------------|
| Models | `GeoCoordinate` `Course` `Hole` `Round` `HoleScore` | — |
| Handicap | `WHSEngine` `ProgressiveHandicap` `ExpectedScore` `HandicapService` | WHS 2024 全路徑 |
| Location | `ProxyLocationDecider` `DynamicAccuracyController` | 手錶耗電 |
| Motion | `SwingDetector` | 等待隊友誤增桿 |
| Scoring | `GeofenceLock` `ScorecardManager` | iCaddie 自動跳洞 / 一鍵微調 |
| Weather | `WindCompensationEngine` `WeatherSnapshot` | 初學者風向判斷 |
| Strategy | `AimAdvisor` | 三色同心圓・避險 |
| Session | `RoundSession` | 回合中樞編排器 |
| Sync | `DirtyQueue` `RoundReconciler` `RoundStore` `WatchSyncProtocol` | 斷線不丟桿 / CloudKit 衝突 / 防跳洞 |
| API | `HTTPTransport` `IGolfClient` `WeatherClient` `DTOs` | 外部圖資・氣象 |
| Stats | `RoundAnalyzer` | 賽後複盤資料層 |
| Power | `PowerBudgetEstimator` | Phase-1 電量 KPI |
| Monetization | `ConversionTrigger` `EntitlementService` | 54 洞升級轉換 |
| Group | `GroupScorecard` `CoachInvite` | B2B2C 學院・多人計分卡 |

## 資料流（一場球局）

```
iGolfClient.courseLayout ─► Course ─► RoundSession
   │                                     │ updateLocation()  ◄─ CoreLocation 轉接
   │                                     │ ingest(motion)    ◄─ CoreMotion 轉接
   │                                     │ confirmSwing()    ─► ScorecardManager
   │                                     │ → ScoreUpdate ───► DirtyQueue ─► WCSession 轉接
   ▼                                     ▼
WeatherClient.currentWeather ─► WindCompensationEngine     finishRound()
                                                              │
                                          HandicapService.submit ─► 差點
                                          RoundAnalyzer.analyze  ─► 賽後統計
                          CloudKit pull ─► RoundReconciler ─► RoundStore（桿數保護）
```

## API 使用範例

### 1. 載入球場並開始一回合

```swift
let igolf = IGolfClient(config: .init(baseURL: base, apiKey: key))
let course = try await igolf.courseLayout(courseID: "iG-900")
let session = RoundSession(course: course, teeBox: .white)
```

### 2. 揮桿偵測 → 記桿（App 層把 CoreMotion 餵進來）

```swift
session.ingest(motion: MotionSample(g: accel.magnitude, timestamp: t))
if session.confirmSwing(displacementMeters: gpsDelta, at: t) {
    // 一桿已記錄並進入同步佇列
}
```

### 3. 防跳洞推進（App 層把 CoreLocation 餵進來）

```swift
switch session.updateLocation(playerCoord, now: Date().timeIntervalSince1970) {
case .advanced(let hole): // 圍欄停留滿 30 秒才會到這
case .blockedStillLocked: break
default: break
}
// 手動切洞需安全手勢
session.manualJump(to: 7, gesture: SafeGesture(twoFingerLongPress: true, swipe: true))
```

### 4. 結束 → 差點 + 統計

```swift
let round = session.finishRound()
let result = try HandicapService().submit(
    round: round, course: course,
    priorDifferentials: history, currentHandicapIndex: hi)
let stats = RoundAnalyzer.analyze(round: round, course: course)
```

### 5. 斷線同步與 CloudKit 衝突

```swift
session.drainSync { update in watchSession.send(update) }   // 失敗自動留在佇列
let merged = RoundReconciler().reconcile(store: localStore, incoming: cloudKitPull)
// 已記錄的桿數永不被較舊裝置的 0 覆蓋
```

## 測試

```bash
swift test                       # 107 個單元/整合測試
swift test --filter <SuiteName>  # 單一套件
swift run golfcore-demo          # 一場模擬球局完整報告
```

關鍵保證皆有自動化案例：WHS 全路徑數值、防跳洞 0 誤觸、斷線 18 洞無損、
CloudKit 桿數保護、Phase-1 電量 KPI。

## Xcode App 層整合計畫

1. Xcode 專案以 **local SPM** 引入此套件（`.package(path: "..")`）。
2. Targets：`GoToGolf`(iOS+iPad)、`GoToGolf Watch`。
3. 轉接層（App 層，需 Xcode 驗證）：
   - `CoreLocationAdapter` → 餵 `GeoCoordinate` 給 `RoundSession`
   - `MotionAdapter` → 餵 `MotionSample` 給 `SwingDetector`
   - `WatchConnectivityAdapter` → `SyncEnvelope` / `DirtyQueue` 橋接 WCSession
   - `CloudKitRoundStore` → conform `RoundStore`，配 `RoundReconciler`
4. SwiftUI 畫面只綁定 `RoundSession` / 各 Service，不重寫邏輯。

App 殼層骨架見 `App/`（XcodeGen `project.yml` + SwiftUI 來源）；該層
無法以 `swift test` 驗證，需 Xcode 開啟建置。
