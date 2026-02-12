import SwiftUI
import StoreKit

struct ParentMenuView: View {
    @Environment(AppState.self) private var appState
    @State private var purchaseManager = PurchaseManager()
    @State private var showGuidedAccessHelp = false
    @State private var guidedAccessEnabled = GuidedAccessStatus.isEnabled

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scenesSection
                    startSceneButton
                    purchaseSection
                    sessionTimerSection
                    settingsSection
                    guidedAccessSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Parent Menu")
            .navigationBarTitleDisplayMode(.inline)
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
                appState.activeScene = scene
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scene.previewColor)
                        .frame(height: 80)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Image(systemName: scene.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isActive ? Color.blue : Color.clear, lineWidth: 3)
                )

                Text(scene.displayName)
                    .font(.caption)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)

                if scene.isFree {
                    Text("FREE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
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
                        Task {
                            await purchaseManager.purchase(appState: appState)
                        }
                    } label: {
                        HStack {
                            Text("Unlock All Scenes")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(product.displayPrice)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(purchaseManager.isLoading)
                    .accessibilityLabel("Unlock all premium scenes for \(product.displayPrice)")
                    .accessibilityHint("Double tap to purchase")
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
                }

                if purchaseManager.isLoading {
                    ProgressView()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Session Timer
    
    private var sessionTimerSection: some View {
        SessionTimerSettingsView()
    }
    
    // MARK: - Settings

    private var settingsSection: some View {
        @Bindable var state = appState
        return VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            Toggle("Sound", isOn: $state.soundEnabled)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .accessibilityLabel("Sound effects")
                .accessibilityHint("Double tap to toggle sound on or off")
            
            nightModeSection
        }
    }
    
    // MARK: - Night Mode Section
    
    private var nightModeSection: some View {
        @Bindable var state = appState
        return VStack(spacing: 12) {
            // Night Mode Preference Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Text("Night Mode")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    
                    // Show current status when on Auto
                    if state.nightModePreference == .auto {
                        Text(state.isNightModeActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundStyle(state.isNightModeActive ? .indigo : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(state.isNightModeActive ? Color.indigo.opacity(0.15) : Color.gray.opacity(0.1))
                            )
                    }
                }
                
                Picker("Night Mode", selection: $state.nightModePreference) {
                    ForEach(NightModePreference.allCases, id: \.self) { preference in
                        HStack {
                            Image(systemName: preference.icon)
                            Text(preference.displayName)
                        }
                        .tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                
                Text("Reduces brightness and uses warm colors for nighttime use")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
            // Red-Shift Filter Toggle (only visible when night mode can be active)
            if state.nightModePreference != .off {
                Toggle(isOn: $state.preserveNightVision) {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preserve Night Vision")
                                .font(.subheadline.weight(.medium))
                            Text("Adds red tint to protect eyes in darkness")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .accessibilityLabel("Preserve Night Vision")
                .accessibilityHint("Adds a red filter to help maintain dark adaptation")
            }
        }
    }

    // MARK: - Guided Access

    private var guidedAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guided Access")
                .font(.headline)

            HStack {
                Image(systemName: guidedAccessEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(guidedAccessEnabled ? .green : .secondary)
                Text(guidedAccessEnabled ? "Guided Access is ON" : "Guided Access is OFF")
                    .font(.subheadline)
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            Button {
                showGuidedAccessHelp = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("How to enable Guided Access")
                        .font(.subheadline)
                }
            }
            .accessibilityLabel("How to enable Guided Access")
            .accessibilityHint("Double tap to view instructions")
        }
    }

    // MARK: - Start Scene Button

    private var startSceneButton: some View {
        Button {
            appState.lockParentMode()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.title3)
                Text("Start Scene")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Start scene and lock")
        .accessibilityHint("Double tap to start the selected scene and lock the screen")
    }
}
