import SwiftUI
import UIKit

struct ParentMenuView: View {
    @Environment(AppState.self) private var appState
    @State private var purchaseManager = PurchaseManager()
    @State private var showGuidedAccessHelp = false
    @State private var guidedAccessEnabled = GuidedAccessStatus.isEnabled
    @State private var showOneSceneConfirmation = false
    @State private var showThreeScenesConfirmation = false
    @State private var scenesToUnlock: Set<SceneID> = []
    @State private var autoLockTimer: Timer?
    @State private var sessionTick: Date = .now
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var shimmerPhase: CGFloat = 0

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    private let sessionTimerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    unlockBanner
                    scenesSection
                    purchaseSection
                    settingsSection
                    guidedAccessSection
                    usageSection
                    appInfoFooter
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
                    .accessibilityLabel("Lock parent menu")
                    .accessibilityHint("Double tap to lock and return to baby mode")
                }
            }
            .safeAreaInset(edge: .bottom) {
                lockBottomBar
            }
            .sheet(isPresented: $showGuidedAccessHelp) {
                GuidedAccessHelpView()
            }
            .task {
                await purchaseManager.loadProducts()
                await purchaseManager.checkEntitlements(appState: appState)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)) { _ in
                guidedAccessEnabled = GuidedAccessStatus.isEnabled
            }
            .onReceive(sessionTimerPublisher) { now in
                sessionTick = now
                batteryLevel = UIDevice.current.batteryLevel
            }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                batteryLevel = UIDevice.current.batteryLevel
                resetAutoLockTimer()
            }
            .onDisappear {
                autoLockTimer?.invalidate()
                autoLockTimer = nil
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in resetAutoLockTimer() }
            )
            .onTapGesture {
                resetAutoLockTimer()
            }
        }
    }

    // MARK: - Auto-Lock Timer

    private func resetAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: false) { _ in
            Task { @MainActor in
                appState.lockParentMode()
            }
        }
    }

    // MARK: - Unlock Banner

    @ViewBuilder
    private var unlockBanner: some View {
        let remaining = appState.remainingUnlockSlots
        if remaining > 0 {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(.yellow)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You have \(remaining) scene\(remaining == 1 ? "" : "s") to unlock!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Tap locked scenes below to choose.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if !scenesToUnlock.isEmpty {
                    HStack {
                        Text("\(scenesToUnlock.count) of \(remaining) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if scenesToUnlock.count == remaining {
                            Button {
                                HapticManager.unlock()
                                for scene in scenesToUnlock {
                                    appState.unlockScene(scene)
                                }
                                scenesToUnlock.removeAll()
                            } label: {
                                Text("Confirm Unlock")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("Confirm unlock of selected scenes")
                            .accessibilityHint("Double tap to unlock the \(scenesToUnlock.count) selected scenes")
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Scene unlock banner. You have \(remaining) scene\(remaining == 1 ? "" : "s") to unlock.")
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
        let isInUnlockMode = appState.remainingUnlockSlots > 0
        let isSelected = scenesToUnlock.contains(scene)
        let canSelectForUnlock = isInUnlockMode && !isUnlocked && !scene.isFree

        return Button {
            resetAutoLockTimer()
            if canSelectForUnlock {
                HapticManager.selection()
                if isSelected {
                    scenesToUnlock.remove(scene)
                } else if scenesToUnlock.count < appState.remainingUnlockSlots {
                    scenesToUnlock.insert(scene)
                }
            } else if isUnlocked {
                HapticManager.selection()
                appState.activeScene = scene
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    scene.previewColor,
                                    scene.previewGradientEnd
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                        .overlay(
                            GeometryReader { geo in
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.15),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geo.size.width * 0.4)
                                .offset(x: shimmerPhase * (geo.size.width * 1.4) - geo.size.width * 0.4)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .clipped()
                        )
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: false)
                            ) {
                                shimmerPhase = 1
                            }
                        }

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

                    // Checkmark overlay for unlock mode selection
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.3))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isActive ? Color.blue :
                                isSelected ? Color.green :
                                Color.white.opacity(0.1),
                            lineWidth: isActive ? 2.5 : isSelected ? 2 : 0.5
                        )
                )

                Text(scene.displayName)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)

                Text(scene.description)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 24)

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
        .disabled(!isUnlocked && !canSelectForUnlock)
        .accessibilityLabel(
            "\(scene.displayName) scene. \(scene.description)." +
            "\(isActive ? " Currently active." : "")" +
            "\(scene.isFree ? " Free." : " Premium.")" +
            "\(isUnlocked ? "" : " Locked.")" +
            "\(isSelected ? " Selected for unlock." : "")"
        )
        .accessibilityHint(
            canSelectForUnlock
                ? (isSelected ? "Double tap to deselect" : "Double tap to select for unlock")
                : (isUnlocked ? "Double tap to switch to this scene" : "Requires purchase to unlock")
        )
    }

    // MARK: - Purchase Section

    @ViewBuilder
    private var purchaseSection: some View {
        if !appState.allScenesUnlocked {
            VStack(spacing: 12) {
                Text("Unlock Scenes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 1 Scene tier
                if let product = purchaseManager.oneSceneProduct {
                    Button {
                        resetAutoLockTimer()
                        showOneSceneConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1 Scene")
                                    .fontWeight(.semibold)
                                Text("Choose one scene to unlock")
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
                    .accessibilityLabel("Unlock one scene for \(product.displayPrice)")
                    .accessibilityHint("Double tap to purchase one scene unlock")
                    .confirmationDialog(
                        "Unlock 1 Scene",
                        isPresented: $showOneSceneConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Purchase for \(product.displayPrice)") {
                            Task {
                                await purchaseManager.purchase(product: product, appState: appState)
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Purchase one scene unlock slot. You'll choose which scene to unlock after purchase.")
                    }
                }

                // 3 Scenes tier
                if let product = purchaseManager.threeScenesProduct {
                    Button {
                        resetAutoLockTimer()
                        showThreeScenesConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("3 Scenes")
                                        .fontWeight(.semibold)
                                    Text("BEST VALUE")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.yellow.opacity(0.3))
                                        .clipShape(Capsule())
                                }
                                Text("Choose three scenes to unlock")
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
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(purchaseManager.isLoading)
                    .accessibilityLabel("Unlock three scenes for \(product.displayPrice)")
                    .accessibilityHint("Double tap to purchase three scene unlocks")
                    .confirmationDialog(
                        "Unlock 3 Scenes",
                        isPresented: $showThreeScenesConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Purchase for \(product.displayPrice)") {
                            Task {
                                await purchaseManager.purchase(product: product, appState: appState)
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Purchase three scene unlock slots. You'll choose which scenes to unlock after purchase.")
                    }
                }

                // Restore purchases
                Button {
                    resetAutoLockTimer()
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

            // Sound toggle
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: state.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundStyle(state.soundEnabled ? .blue : .secondary)
                        .frame(width: 24)
                    Toggle("Sound Effects", isOn: $state.soundEnabled)
                        .onChange(of: state.soundEnabled) {
                            HapticManager.tap()
                            resetAutoLockTimer()
                        }
                }
                .accessibilityLabel("Sound effects")
                .accessibilityHint("Double tap to toggle sound on or off")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Screen dimming
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                        .frame(width: 24)
                    Text("Night Mode")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.screenDimming * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $state.screenDimming, in: 0...0.8, step: 0.05)
                    .tint(.indigo)
                    .onChange(of: state.screenDimming) {
                        resetAutoLockTimer()
                    }
                    .accessibilityLabel("Screen dimming level")
                    .accessibilityValue("\(Int(state.screenDimming * 100)) percent")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Particle density
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text("Particle Density")
                        .font(.subheadline)
                }
                Picker("Particle Density", selection: $state.particleDensity) {
                    ForEach(ParticleDensity.allCases, id: \.self) { density in
                        Text(density.displayName).tag(density)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: state.particleDensity) {
                    HapticManager.selection()
                    resetAutoLockTimer()
                }
                .accessibilityLabel("Particle density")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Touch sensitivity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(.pink)
                        .frame(width: 24)
                    Text("Touch Sensitivity")
                        .font(.subheadline)
                }
                Picker("Touch Sensitivity", selection: $state.touchSensitivity) {
                    ForEach(TouchSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.displayName).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: state.touchSensitivity) {
                    HapticManager.selection()
                    resetAutoLockTimer()
                }
                .accessibilityLabel("Touch sensitivity")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Auto-cycle
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .foregroundStyle(.teal)
                        .frame(width: 24)
                    Toggle("Auto-Cycle Scenes", isOn: $state.autoCycleEnabled)
                        .onChange(of: state.autoCycleEnabled) {
                            HapticManager.tap()
                            resetAutoLockTimer()
                        }
                }
                .accessibilityLabel("Auto-cycle scenes")
                .accessibilityHint("Double tap to toggle automatic scene cycling")

                if state.autoCycleEnabled {
                    HStack {
                        Text("Interval")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Cycle interval", selection: $state.autoCycleMinutes) {
                            Text("2 min").tag(2)
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                        .onChange(of: state.autoCycleMinutes) {
                            HapticManager.selection()
                            resetAutoLockTimer()
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel("Auto-cycle interval")
                    .accessibilityValue("\(state.autoCycleMinutes) minutes")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .animation(.easeInOut(duration: 0.2), value: state.autoCycleEnabled)

            // Session limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.red)
                        .frame(width: 24)
                    Text("Session Limit")
                        .font(.subheadline)
                    Spacer()
                }
                Picker("Session Limit", selection: $state.sessionLimitMinutes) {
                    Text("Off").tag(0)
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("20 min").tag(20)
                    Text("30 min").tag(30)
                }
                .pickerStyle(.segmented)
                .onChange(of: state.sessionLimitMinutes) {
                    HapticManager.selection()
                    resetAutoLockTimer()
                }
                .accessibilityLabel("Session time limit")
                .accessibilityValue(state.sessionLimitMinutes == 0 ? "Off" : "\(state.sessionLimitMinutes) minutes")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Guided Access is \(guidedAccessEnabled ? "enabled" : "disabled")")

                Divider()

                Button {
                    resetAutoLockTimer()
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

    // MARK: - Usage Section

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Info")
                .font(.headline)

            VStack(spacing: 12) {
                // Usage timer
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text("Session Duration")
                        .font(.subheadline)
                    Spacer()
                    // Force re-evaluation on each tick
                    let _ = sessionTick
                    Text(appState.sessionDurationString)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Session duration: \(appState.sessionDurationString)")

                Divider()

                // Battery level
                HStack {
                    Image(systemName: batteryIconName)
                        .foregroundStyle(batteryColor)
                        .frame(width: 24)
                    Text("Battery Level")
                        .font(.subheadline)
                    Spacer()
                    Text(batteryLevelString)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Battery level: \(batteryLevelString)")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var batteryLevelString: String {
        if batteryLevel < 0 {
            return "Unknown"
        }
        return "\(Int(batteryLevel * 100))%"
    }

    private var batteryIconName: String {
        if batteryLevel < 0 {
            return "battery.0percent"
        } else if batteryLevel <= 0.2 {
            return "battery.25percent"
        } else if batteryLevel <= 0.5 {
            return "battery.50percent"
        } else if batteryLevel <= 0.75 {
            return "battery.75percent"
        } else {
            return "battery.100percent"
        }
    }

    private var batteryColor: Color {
        if batteryLevel < 0 {
            return .secondary
        } else if batteryLevel <= 0.2 {
            return .red
        } else if batteryLevel <= 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    // MARK: - App Info Footer

    private var appInfoFooter: some View {
        VStack(spacing: 6) {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            Text("BabySafeVisuals v\(version)")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("Made with care for little ones")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("BabySafeVisuals version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
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
