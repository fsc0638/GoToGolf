import Foundation
import StoreKit
import GolfCore

/// StoreKit 2 subscription layer. Locally testable via `GoToGolf.storekit`
/// (no App Store Connect needed). Entitlement decisions delegate to the
/// tested GolfCore `EntitlementService`.
@MainActor
final class SubscriptionStore: ObservableObject {
    static let premiumProductID = "com.gotogolf.premium.annual"

    @Published private(set) var product: Product?
    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var purchasing = false
    @Published private(set) var statusMessage: String?

    private let entitlements = EntitlementService()
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update { await t.finish() }
                await self?.refreshEntitlement()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
            if product == nil { statusMessage = "目前無法載入訂閱方案" }
        } catch {
            statusMessage = "載入方案失敗：\(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard let product else { return }
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                    statusMessage = "訂閱成功,已解鎖雲端同步 / 匯出 / 多球員 group round"
                }
            case .userCancelled:
                statusMessage = nil
            case .pending:
                statusMessage = "購買待核准"
            @unknown default:
                break
            }
        } catch {
            statusMessage = "購買失敗：\(error.localizedDescription)"
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.premiumProductID,
               t.revocationDate == nil {
                active = true
            }
        }
        tier = active ? .premium : .free
    }

    func isAllowed(_ feature: PremiumFeature) -> Bool {
        entitlements.isAllowed(feature, tier: tier)
    }
}
