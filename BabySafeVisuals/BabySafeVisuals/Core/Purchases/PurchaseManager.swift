import StoreKit
import Foundation

@Observable
final class PurchaseManager {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var product: Product?
    private var hasLoadedProduct = false
    private var isPurchasing = false

    static let productID = "unlock_all_scenes"

    /// Load the product from the App Store
    func loadProduct() async {
        guard !hasLoadedProduct else { return }
        do {
            let products = try await Product.products(for: [Self.productID])
            if let foundProduct = products.first {
                product = foundProduct
                hasLoadedProduct = true
            } else {
                errorMessage = "Product not found. Please check your App Store Connect configuration."
            }
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                errorMessage = "No internet connection. Please try again later."
            } else {
                errorMessage = "Unable to load product information. Please check your connection."
            }
        }
    }

    /// Purchase the product
    func purchase(appState: AppState) async {
        guard let product else {
            errorMessage = "Product not available. Please restart the app."
            return
        }
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
                    appState.isPurchased = true
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
                errorMessage = "An unexpected error occurred. Please contact support."
            }
        } catch let error as StoreKitError {
            switch error {
            case .networkError:
                errorMessage = "Network error. Please check your connection."
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
            errorMessage = "Purchase failed. Please try again or contact support."
        }

        isLoading = false
        isPurchasing = false
        scheduleErrorDismissal()
    }

    /// Restore previous purchases
    func restorePurchases(appState: AppState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var foundPurchase = false
        do {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID {
                    appState.isPurchased = true
                    foundPurchase = true
                    break
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

    /// Check for existing entitlements on app launch
    func checkEntitlements(appState: AppState) async {
        do {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID {
                    appState.isPurchased = true
                    return
                }
            }
        } catch {
            print("⚠️ Failed to check entitlements: \(error.localizedDescription)")
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
