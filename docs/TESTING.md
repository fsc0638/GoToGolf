# GoToGolf testing

## 1. Automated layers

The CI surface is two flat lanes — both fast, both deterministic:

```sh
# GolfCore logic (no UI, no platform).
swift test                                  # 73 tests, ~0.03s

# App + UI tests on the iPhone 17 simulator.
cd App
xcodegen generate
xcodebuild test \
  -project GoToGolf.xcodeproj \
  -scheme GoToGolf \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
# 6 UI tests, ~2 minutes
```

UI suite covers (see `App/UITests/ScoringUITests.swift`):

- `testScoringTabShowsScorecardGrid` — scorecard grid renders, hole 18 reachable after scroll.
- `testTappingPlusIncrementsHoleGross` — +button drives the gross cell.
- `testSummaryBarReflectsRunningTotals` — running gross / to-par strip updates live.
- `testHistoryAndDebriefTabsLoad` — handicap + debrief identifiers exist.
- `testCreateCustomCourseAndFinishRound` — create course → enter round → finish → debrief auto-routes → trend chart shows.
- `testSavedRoundCanBeSwipeDeleted` — swipe action surfaces and consumes its tagged button.

## 2. Watch context channel (manual)

The phone pushes `WatchContext { currentHole, revision }` via
`WatchConnectivityAdapter.pushContext`; the watch's
`WatchContextReceiver` mirrors it onto `WatchScoreView`. Pairing
requirements rule out a fully-automated UI test, but the channel can be
smoke-tested with a paired iPhone + Apple Watch simulator.

### Build the Watch app

```sh
cd App
xcodebuild build \
  -project GoToGolf.xcodeproj \
  -scheme "GoToGolf Watch" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'
```

### Pair iPhone + Watch simulators

```sh
# Pick a pair of UDIDs from `xcrun simctl list devices available`.
PHONE=$(xcrun simctl list devices available | grep "iPhone 17 " | head -1 | grep -oE '[0-9A-F-]{36}')
WATCH=$(xcrun simctl list devices available | grep "Apple Watch Series 11 (46mm)" | head -1 | grep -oE '[0-9A-F-]{36}')

xcrun simctl pair "$WATCH" "$PHONE"
xcrun simctl bootstatus "$PHONE" -b
xcrun simctl bootstatus "$WATCH" -b
```

Pairing only sticks on the first boot — re-running `simctl pair`
against an already-paired set is a no-op.

### Manual smoke checklist

1. Install + launch the iPhone build on the paired phone simulator.
2. Install + launch the Watch build on the watch simulator.
3. On the phone, pick 淡水高爾夫球場.
4. On the phone scoring grid, tap the +button on hole 5 a few times.
5. The watch face should advance to 「第 5 洞」 within ~1s
   (`WatchContext` is delivered via `updateApplicationContext`, which is
   coalesced — slight delay is normal).
6. Lower wrist on watch sim (⌘+⇧+W twice) → display should collapse to
   the pure-black `isLuminanceReduced` layout with "H5 / gross".
7. Raise wrist → full UI returns.

Pass criterion: hole on the watch matches the phone's current hole
within ~1s after each change; AOD layer renders without flicker.

## 3. CloudKit sync (manual, needs Apple Developer entitlement)

`App/Shared/CloudKitRoundStore.swift` is a compile-only skeleton today
— it requires the CloudKit container entitlement which the simulator
won't grant without a paid developer account. Smoke steps once you
have entitlement:

1. Sign the app with a team that owns the `iCloud.com.gotogolf` container.
2. Run on two devices logged into the same Apple ID.
3. Save a round on device A.
4. Within ~10s the round should appear in 差點 → 歷史球局 on device B.
5. Delete the round on device B; verify it disappears from A.

## 4. TestFlight smoke (manual, real device)

Once the icon + metadata land, push a TestFlight build and run a
single full 18-hole round end-to-end on a real iPhone:

- Score every hole (mix of pars / birdies / bogeys) to populate every
  `RoundStatistics` bucket.
- Tap 結束並儲存; confirm the debrief auto-routes with the OpenMoji
  hero matching the round outcome.
- Force-quit and re-launch; verify the round is still in 歷史球局 and
  the WHS index reflects the new differential.
