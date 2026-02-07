import StoreKit

@Observable
final class PurchaseManager {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var product: Product?
    private var hasLoadedProduct = false
    private var isPurchasing = false

    static let productID = "unlock_all_scenes"

    func loadProduct() async {
        guard !hasLoadedProduct else { return }
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            hasLoadedProduct = true
        } catch {
            errorMessage = "Unable to load product info."
        }
    }

    func purchase(appState: AppState) async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    appState.isPurchased = true
                    HapticManager.unlock()
                case .unverified:
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break // Silently handle cancel
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isLoading = false
        isPurchasing = false
        scheduleErrorDismissal()
    }

    func restorePurchases(appState: AppState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var foundPurchase = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                appState.isPurchased = true
                foundPurchase = true
            }
        }

        if !foundPurchase {
            errorMessage = "No purchases found for this Apple ID."
        } else {
            HapticManager.unlock()
        }

        isLoading = false
        scheduleErrorDismissal()
    }

    func checkEntitlements(appState: AppState) async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                appState.isPurchased = true
                return
            }
        }
    }

    private func scheduleErrorDismissal() {
        guard errorMessage != nil else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if errorMessage != nil {
                errorMessage = nil
            }
        }
    }
}
