import StoreKit

@Observable
final class PurchaseManager {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var product: Product?

    static let productID = "unlock_all_scenes"

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = "Unable to load product."
        }
    }

    func purchase(appState: AppState) async {
        guard let product else { return }
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    appState.isPurchased = true
                case .unverified:
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                errorMessage = "Purchase canceled."
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isLoading = false
    }

    func restorePurchases(appState: AppState) async {
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
            errorMessage = "No purchases found."
        }

        isLoading = false
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
}
