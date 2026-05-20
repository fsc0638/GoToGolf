import SwiftUI
import WatchKit

/// Atomized scoring + AOD 省電圖層. Hole comes live from the phone via
/// `WatchContextReceiver`; gross is entered locally on the wrist.
/// Wrist-down collapses to a pure-black static layer.
struct WatchScoreView: View {
    @StateObject private var receiver = WatchContextReceiver()
    @Environment(\.isLuminanceReduced) private var isAOD
    @State private var gross = 0

    var body: some View {
        let hole = receiver.hole

        if isAOD {
            VStack(spacing: 2) {
                Text("H\(hole)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(gross)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else {
            VStack(spacing: 8) {
                Text("第 \(hole) 洞").font(.caption)
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
