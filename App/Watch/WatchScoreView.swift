import SwiftUI
import WatchKit

/// Atomized scoring + AOD 省電圖層. Hole & distance come live from the phone
/// via `WatchContextReceiver`; wrist-down collapses to a pure-black,
/// large-type static layer (no map / no animation) to cut AOD drain.
struct WatchScoreView: View {
    @StateObject private var receiver = WatchContextReceiver()
    @Environment(\.isLuminanceReduced) private var isAOD
    @State private var gross = 0

    var body: some View {
        let hole = receiver.hole
        let distance = receiver.distanceToCenter

        if isAOD {
            VStack(spacing: 2) {
                Text("\(distance)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("H\(hole) · \(gross)")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else {
            VStack(spacing: 6) {
                Text("第 \(hole) 洞 · \(distance) 碼")
                    .font(.caption)
                Text("\(gross)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .monospacedDigit()
                HStack(spacing: 14) {
                    Button {
                        if gross > 0 { gross -= 1 }
                        WKInterfaceDevice.current().play(.click)
                    } label: { Image(systemName: "minus") }
                    Button {
                        gross += 1
                        WKInterfaceDevice.current().play(.click)
                    } label: { Image(systemName: "plus") }
                }
                .font(.title3.weight(.bold))
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
    }
}
