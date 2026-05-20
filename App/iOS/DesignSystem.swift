import SwiftUI
import GolfCore

/// 「素雅運動年鑑」設計系統。色票走「球道綠 + 朱紅 + 米貓黃」三色路線，
/// 字體沿用 PingFang TC，數字一律 monospaced 以對齊計分卡欄位。
/// 所有顏色都用 UIColor dynamic provider，自動跟著系統 light / dark 切。
enum DS {

    // MARK: - Brand colors

    /// 球道綠 — 主色：tab tint、選定狀態、Birdie 標示。
    static let fairway = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.49, green: 0.74, blue: 0.52, alpha: 1)
            : UIColor(red: 0.20, green: 0.46, blue: 0.28, alpha: 1)
    })

    /// 朱紅 — 警示色：Double Bogey 以上、CTA hover。
    static let bogey = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.42, blue: 0.42, alpha: 1)
            : UIColor(red: 0.66, green: 0.18, blue: 0.18, alpha: 1)
    })

    /// 米貓黃 — Card / List 背景色,輕微紙感。
    static let cream = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.15, blue: 0.13, alpha: 1)
            : UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
    })

    /// 焦糖 — Bogey 一桿過標。
    static let amber = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.65, blue: 0.30, alpha: 1)
            : UIColor(red: 0.78, green: 0.46, blue: 0.16, alpha: 1)
    })

    /// 暗金 — Eagle / Hole-in-One 等罕見好球。
    static let gold = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.79, blue: 0.36, alpha: 1)
            : UIColor(red: 0.68, green: 0.52, blue: 0.12, alpha: 1)
    })

    // MARK: - Helpers

    /// 桿差對應的顯示色（用於計分卡 cell、複盤分佈條）。
    static func scoreColor(diff: Int) -> Color {
        switch diff {
        case ..<(-1): return gold         // Eagle 以上
        case -1:      return fairway      // Birdie
        case 0:       return .primary     // Par
        case 1:       return amber        // Bogey
        default:      return bogey        // Double 以上
        }
    }

    /// 桿差簡稱（顯示在計分卡 cell 右下角）。
    static func scoreTag(diff: Int) -> String? {
        switch diff {
        case ..<(-1): return "EAG"
        case -1:      return "BIR"
        case 0:       return nil
        case 1:       return "BOG"
        case 2:       return "DBL"
        default:      return "+\(diff)"
        }
    }
}

// MARK: - View modifiers

/// 年鑑風卡片：米色底 + 圓角 + 內距,給 ScrollView 內的區塊用
/// (List 內請改用 .listRowBackground(DS.cream))。
struct YearbookCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(DS.cream)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func yearbookCard() -> some View { modifier(YearbookCard()) }
}
