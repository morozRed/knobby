import Foundation
import RevenueCat

/// Manages in-app purchases via RevenueCat.
/// Purchases are automatically synced via iCloud/App Store receipt,
/// so they persist across reinstalls and devices with the same Apple ID.
@Observable
final class PurchaseManager: NSObject {
    static let shared = PurchaseManager()

    // MARK: - Configuration

    static let apiKey = "appl_JdMLVeAeOuKJfAuYndZuCZflgom"
    static let lifetimeProductID = "lifetime_access"
    static let entitlementID = "pro"

    // MARK: - State

    /// Whether the user has lifetime access (pro)
    private(set) var isProUser: Bool = false

    /// The lifetime product package
    private(set) var lifetimePackage: Package?

    /// Formatted price string fetched from RevenueCat
    private(set) var lifetimePrice: String?

    /// Whether offerings have been fetched
    private(set) var isPriceFetched: Bool = false

    /// Loading state for purchase/restore operations
    private(set) var isLoading: Bool = false

    /// Error message if something went wrong
    private(set) var errorMessage: String?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    /// Configure RevenueCat - call this at app launch
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)

        // Set delegate to listen for customer info updates
        // This handles purchases synced from other devices or restored after reinstall
        Purchases.shared.delegate = self

        // Check initial entitlement status and fetch offerings
        Task {
            await checkEntitlementStatus()
            await fetchOfferings()
        }
    }

    // MARK: - Entitlement Check

    /// Check if user has pro entitlement.
    /// RevenueCat automatically checks the App Store receipt which syncs via iCloud.
    @MainActor
    func checkEntitlementStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateProStatus(from: customerInfo)
        } catch {
            print("[PurchaseManager] Failed to check entitlements: \(error)")
        }
    }

    /// Update pro status from customer info
    @MainActor
    private func updateProStatus(from customerInfo: CustomerInfo) {
        let wasProUser = isProUser

        // Check entitlement first (if configured in RevenueCat dashboard)
        if customerInfo.entitlements[Self.entitlementID]?.isActive == true {
            isProUser = true
            print("[PurchaseManager] Pro entitlement active")
        }
        // Fallback: check if user has purchased the lifetime product directly
        // nonSubscriptions is an array of NonSubscriptionTransaction
        else {
            let hasLifetimePurchase = customerInfo.nonSubscriptions.contains {
                $0.productIdentifier == Self.lifetimeProductID
            }
            isProUser = hasLifetimePurchase
            if hasLifetimePurchase {
                print("[PurchaseManager] Lifetime product found in nonSubscriptions")
            }
        }

        // Log status change
        if isProUser && !wasProUser {
            print("[PurchaseManager] ✅ Pro access granted - unlocking all controls")
        } else if !isProUser {
            let entitlementKeys = customerInfo.entitlements.all.keys.joined(separator: ", ")
            let productIds = customerInfo.nonSubscriptions.map { $0.productIdentifier }.joined(separator: ", ")
            print("[PurchaseManager] User is not pro. Entitlements: [\(entitlementKeys)]")
            print("[PurchaseManager] NonSubscriptions: [\(productIds)]")
        }
    }

    // MARK: - Fetch Offerings

    /// Fetch available packages from RevenueCat
    @MainActor
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()

            // Look for the lifetime package in current offering
            if let offering = offerings.current {
                // Try standard lifetime package type first
                if let lifetime = offering.lifetime {
                    lifetimePackage = lifetime
                    lifetimePrice = lifetime.localizedPriceString
                    isPriceFetched = true
                }
                // Try by package identifier
                else if let lifetime = offering.package(identifier: Self.lifetimeProductID) {
                    lifetimePackage = lifetime
                    lifetimePrice = lifetime.localizedPriceString
                    isPriceFetched = true
                }
                // Search all packages by product ID
                else {
                    for package in offering.availablePackages {
                        if package.storeProduct.productIdentifier == Self.lifetimeProductID {
                            lifetimePackage = package
                            lifetimePrice = package.localizedPriceString
                            isPriceFetched = true
                            break
                        }
                    }
                }

                // Log available packages for debugging
                print("[PurchaseManager] Available packages: \(offering.availablePackages.map { $0.identifier })")
            }

            if lifetimePackage == nil {
                print("[PurchaseManager] Warning: lifetime_access package not found in offerings")
            }
        } catch {
            print("[PurchaseManager] Failed to fetch offerings: \(error)")
            errorMessage = "Unable to load pricing"
        }
    }

    // MARK: - Purchase

    /// Purchase the lifetime access
    @MainActor
    func purchaseLifetime() async -> Bool {
        guard let package = lifetimePackage else {
            errorMessage = "Product not available"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            updateProStatus(from: result.customerInfo)
            isLoading = false
            return isProUser
        } catch let error as RevenueCat.ErrorCode {
            isLoading = false

            switch error {
            case .purchaseCancelledError:
                // User cancelled - not an error to show
                return false
            default:
                errorMessage = "Purchase failed. Please try again."
                print("[PurchaseManager] Purchase error: \(error)")
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed. Please try again."
            print("[PurchaseManager] Purchase error: \(error)")
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases.
    /// This syncs with App Store/iCloud to recover purchases after reinstall.
    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateProStatus(from: customerInfo)
            isLoading = false

            if !isProUser {
                errorMessage = "No purchases to restore"
            }

            return isProUser
        } catch {
            isLoading = false
            errorMessage = "Restore failed. Please try again."
            print("[PurchaseManager] Restore error: \(error)")
            return false
        }
    }
}

// MARK: - PurchasesDelegate

extension PurchaseManager: PurchasesDelegate {
    /// Called whenever customer info is updated.
    /// This handles:
    /// - Purchases made on other devices syncing via iCloud
    /// - Purchases restored after app reinstall
    /// - Subscription renewals or expirations
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateProStatus(from: customerInfo)
        }
    }
}
