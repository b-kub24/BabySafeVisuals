import SwiftUI
import StoreKit

enum SceneMode: String, CaseIterable {
    case startScene = "Start Scene"
    case freeTest = "Free Test Mode"
}

struct ParentMenuView: View {
    @Environment(AppState.self) private var appState
    @State private var purchaseManager = PurchaseManager()
    @State private var showGuidedAccessHelp = false
    @State private var guidedAccessEnabled = GuidedAccessStatus.isEnabled
    @State private var previewingScene: SceneID? = nil
    @State private var selectedMode: SceneMode = .startScene

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scenesSection
                    modeSelector
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
            .fullScreenCover(item: $previewingScene) { scene in
                ScenePreviewView(scene: scene) {
                    previewingScene = nil
                }
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
        let isInFreeTest = selectedMode == .freeTest
        let isUnlocked = isInFreeTest || appState.isSceneUnlocked(scene)
        let isActive = appState.activeScene == scene
        let showLock = selectedMode == .startScene && !scene.isFree

        return Button {
            if isInFreeTest {
                previewingScene = scene
            } else if isUnlocked {
                appState.activeScene = scene
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scene.previewColor)
                        .frame(height: 80)

                    if !isUnlocked && !isInFreeTest {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Image(systemName: scene.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    // Lock/unlock badge in lower-right for Start Scene mode
                    if showLock {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: appState.isPurchased ? "lock.open.fill" : "lock.fill")
                                        .font(.system(size: 9))
                                    // Price label next to lock
                                    if !appState.isPurchased, let price = purchaseManager.product?.displayPrice {
                                        Text(price)
                                            .font(.system(size: 8, weight: .medium))
                                    }
                                }
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.black.opacity(0.4)))
                                .padding(4)
                            }
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isActive && !isInFreeTest ? Color.blue : Color.clear, lineWidth: 3)
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
        .disabled(!isUnlocked && !isInFreeTest)
        .accessibilityLabel("\(scene.displayName) scene\(isActive ? ", currently active" : "")\(scene.isFree ? ", free" : ", premium")\(isUnlocked ? "" : ", locked")")
    }

    // MARK: - Mode Selector (Start Scene + Free Test)

    private var modeSelector: some View {
        VStack(spacing: 12) {
            // Start Scene option
            Button {
                selectedMode = .startScene
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedMode == .startScene ? "circle.inset.filled" : "circle")
                        .foregroundStyle(selectedMode == .startScene ? .blue : .secondary)
                        .font(.title3)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("Start Scene")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedMode == .startScene ? Color.blue : Color.blue.opacity(0.15))
                )
                .foregroundStyle(selectedMode == .startScene ? .white : .blue)
            }
            
            // When Start Scene selected and tapped, lock parent mode
            if selectedMode == .startScene {
                Button {
                    appState.lockParentMode()
                } label: {
                    Text("Go!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Free Test Mode option
            Button {
                selectedMode = .freeTest
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedMode == .freeTest ? "circle.inset.filled" : "circle")
                        .foregroundStyle(selectedMode == .freeTest ? .orange : .secondary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.callout)
                            Text("Free Test Mode")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        Text("Preview any scene for 30 seconds")
                            .font(.caption)
                            .foregroundStyle(selectedMode == .freeTest ? .white.opacity(0.8) : .secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedMode == .freeTest ? Color.orange : Color.orange.opacity(0.1))
                )
                .foregroundStyle(selectedMode == .freeTest ? .white : .orange)
            }
            
            if selectedMode == .freeTest {
                Text("Tap any scene above to preview it")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
            
            nightModeSection
        }
    }
    
    // MARK: - Night Mode Section
    
    private var nightModeSection: some View {
        @Bindable var state = appState
        return VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Text("Night Mode")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    
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
        }
    }
}
