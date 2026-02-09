import SwiftUI

struct ParentMenuView: View {
    @Environment(AppState.self) private var appState
    @State private var purchaseManager = PurchaseManager()
    @State private var showGuidedAccessHelp = false
    @State private var guidedAccessEnabled = GuidedAccessStatus.isEnabled
    @State private var showUnlockConfirmation = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scenesSection
                    purchaseSection
                    settingsSection
                    guidedAccessSection
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Parent Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.tap()
                        appState.lockParentMode()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Lock")
                                .fontWeight(.semibold)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                lockBottomBar
            }
            .sheet(isPresented: $showGuidedAccessHelp) {
                GuidedAccessHelpView()
            }
            .task {
                await purchaseManager.loadProduct()
                await purchaseManager.checkEntitlements(appState: appState)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)) { _ in
                guidedAccessEnabled = GuidedAccessStatus.isEnabled
            }
        }
    }

    // MARK: - Scenes Grid

    private var scenesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenes")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SceneID.allCases) { scene in
                    sceneCell(scene)
                }
            }
        }
    }

    private func sceneCell(_ scene: SceneID) -> some View {
        let isUnlocked = appState.isSceneUnlocked(scene)
        let isActive = appState.activeScene == scene

        return Button {
            if isUnlocked {
                HapticManager.selection()
                appState.activeScene = scene
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    scene.previewColor,
                                    scene.previewColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    RadialGradient(
                                        colors: isActive
                                            ? [.white.opacity(0.15), .clear]
                                            : [.clear, .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                        )

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        Image(systemName: scene.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .white.opacity(0.3), radius: 4)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isActive ? Color.blue : Color.white.opacity(0.1),
                            lineWidth: isActive ? 2.5 : 0.5
                        )
                )

                Text(scene.displayName)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)

                if scene.isFree {
                    Text("FREE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .disabled(!isUnlocked)
        .accessibilityLabel("\(scene.displayName) scene\(isActive ? ", currently active" : "")\(scene.isFree ? ", free" : ", premium")\(isUnlocked ? "" : ", locked")")
        .accessibilityHint(isUnlocked ? "Double tap to switch to this scene" : "Requires purchase to unlock")
    }

    // MARK: - Purchase Section

    @ViewBuilder
    private var purchaseSection: some View {
        if !appState.isPurchased {
            VStack(spacing: 12) {
                if let product = purchaseManager.product {
                    Button {
                        showUnlockConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock All Scenes")
                                    .fontWeight(.semibold)
                                Text("One-time purchase")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .fontWeight(.bold)
                                .font(.title3)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(purchaseManager.isLoading)
                    .accessibilityLabel("Unlock all premium scenes for \(product.displayPrice)")
                    .accessibilityHint("Double tap to purchase")
                    .confirmationDialog(
                        "Unlock All Scenes",
                        isPresented: $showUnlockConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Purchase for \(product.displayPrice)") {
                            Task {
                                await purchaseManager.purchase(appState: appState)
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This is a one-time purchase that unlocks all 6 premium scenes.")
                    }
                }

                Button {
                    Task {
                        await purchaseManager.restorePurchases(appState: appState)
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .disabled(purchaseManager.isLoading)
                .accessibilityLabel("Restore previous purchases")
                .accessibilityHint("Double tap if you already purchased to restore access")

                if let error = purchaseManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                if purchaseManager.isLoading {
                    ProgressView()
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .animation(.easeInOut(duration: 0.3), value: purchaseManager.errorMessage == nil)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        @Bindable var state = appState
        return VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            HStack {
                Image(systemName: state.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(state.soundEnabled ? .blue : .secondary)
                    .frame(width: 24)
                Toggle("Sound Effects", isOn: $state.soundEnabled)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .accessibilityLabel("Sound effects")
            .accessibilityHint("Double tap to toggle sound on or off")
        }
    }

    // MARK: - Guided Access

    private var guidedAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guided Access")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: guidedAccessEnabled ? "checkmark.shield.fill" : "shield.slash")
                        .foregroundStyle(guidedAccessEnabled ? .green : .secondary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guidedAccessEnabled ? "Guided Access is ON" : "Guided Access is OFF")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(guidedAccessEnabled
                             ? "Device is pinned to this app"
                             : "Recommended for safe handoff")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                Button {
                    showGuidedAccessHelp = true
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("How to enable Guided Access")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .accessibilityLabel("How to enable Guided Access")
                .accessibilityHint("Double tap to view instructions")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Lock Bottom Bar

    private var lockBottomBar: some View {
        Button {
            HapticManager.tap()
            appState.lockParentMode()
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                Text("Lock & Return to Baby Mode")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .accessibilityLabel("Lock and return to scene")
        .accessibilityHint("Double tap to close parent menu and return to the active scene")
    }
}
