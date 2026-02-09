import StoreKit
import Foundation

@Observable
final class PurchaseManager {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var products: [Product] = []
    private var hasLoadedProducts = false
    private var isPurchasing = false

    static let oneSceneProductID = "unlock_one_scene"
    static let threeScenesProductID = "unlock_three_scenes"

    private static let allProductIDs: Set<String> = [
        oneSceneProductID,
        threeScenesProductID
    ]

    var oneSceneProduct: Product? {
        products.first { $0.id == Self.oneSceneProductID }
    }

    var threeScenesProduct: Product? {
        products.first { $0.id == Self.threeScenesProductID }
    }

    // MARK: - Load Products

    func loadProducts() async {
        guard !hasLoadedProducts else { return }
        do {
            let fetched = try await Product.products(for: Self.allProductIDs)
            products = fetched.sorted { $0.price < $1.price }
            hasLoadedProducts = true
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                errorMessage = "No internet connection. Please try again later."
            } else {
                errorMessage = "Unable to load products. Please check your connection."
            }
        }
    }

    // MARK: - Purchase

    func purchase(product: Product, appState: AppState) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    appState.purchasedTiers.insert(transaction.productID)
                    HapticManager.unlock()
                    await transaction.finish()
                case .unverified(_, let verificationError):
                    errorMessage = "Purchase verification failed: \(verificationError.localizedDescription)"
                }
            case .userCancelled:
                errorMessage = nil
            case .pending:
                errorMessage = "Purchase pending. Check with your family organizer."
            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch let error as StoreKitError {
            switch error {
            case .networkError:
                errorMessage = "Network error. Please check your connection and try again."
            case .userCancelled:
                errorMessage = nil
            case .notAvailableInStorefront:
                errorMessage = "This purchase is not available in your region."
            case .notEntitled:
                errorMessage = "You don't have permission to make purchases."
            default:
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isLoading = false
        isPurchasing = false
        scheduleErrorDismissal()
    }

    // MARK: - Restore

    func restorePurchases(appState: AppState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var foundPurchase = false
        do {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if Self.allProductIDs.contains(transaction.productID) {
                        appState.purchasedTiers.insert(transaction.productID)
                        foundPurchase = true
                    }
                }
            }

            if !foundPurchase {
                errorMessage = "No previous purchases found for this Apple ID."
            } else {
                HapticManager.unlock()
            }
        } catch {
            errorMessage = "Unable to restore purchases. Please try again."
        }

        isLoading = false
        scheduleErrorDismissal()
    }

    // MARK: - Check Entitlements

    func checkEntitlements(appState: AppState) async {
        do {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if Self.allProductIDs.contains(transaction.productID) {
                        appState.purchasedTiers.insert(transaction.productID)
                    }
                }
            }
        } catch {
            // Silently fail on launch
        }
    }

    // MARK: - Helpers

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
