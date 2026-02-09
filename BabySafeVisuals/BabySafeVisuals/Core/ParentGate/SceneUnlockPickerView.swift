import SwiftUI

struct SceneUnlockPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedScenes: Set<SceneID> = []

    private var lockableScenes: [SceneID] {
        SceneID.allCases.filter { !$0.isFree && !appState.isSceneUnlocked($0) }
    }

    private var maxSelections: Int {
        appState.remainingUnlockSlots
    }

    private var canConfirm: Bool {
        !selectedScenes.isEmpty && selectedScenes.count <= maxSelections
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header instruction
                    headerSection

                    // Scene cards grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(lockableScenes) { scene in
                            sceneCard(scene)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Choose Your Scenes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        confirmSelection()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canConfirm)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmBottomBar
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Select \(maxSelections) scene\(maxSelections == 1 ? "" : "s") to unlock")
                .font(.headline)

            Text("\(selectedScenes.count) of \(maxSelections) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Scene Card

    private func sceneCard(_ scene: SceneID) -> some View {
        let isSelected = selectedScenes.contains(scene)

        return Button {
            toggleSelection(scene)
        } label: {
            VStack(spacing: 0) {
                // Preview gradient area with icon
                ZStack {
                    LinearGradient(
                        colors: [scene.previewColor, scene.previewGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 100)

                    Image(systemName: scene.iconSystemName)
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 4)

                    // Checkmark overlay when selected
                    if isSelected {
                        Color.black.opacity(0.25)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 3)
                    }
                }

                // Text info area
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(scene.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.blue : Color(.separator).opacity(0.3),
                        lineWidth: isSelected ? 2.5 : 0.5
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.15) : Color.black.opacity(0.06),
                radius: isSelected ? 6 : 2,
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(scene.displayName): \(scene.description)")
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect." : "Double tap to select.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Confirm Bottom Bar

    private var confirmBottomBar: some View {
        Button {
            confirmSelection()
        } label: {
            HStack {
                Image(systemName: "lock.open.fill")
                Text(confirmButtonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canConfirm ? Color.blue : Color(.systemGray4))
            .foregroundStyle(canConfirm ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canConfirm)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .accessibilityLabel(confirmButtonTitle)
        .accessibilityHint(canConfirm ? "Double tap to unlock selected scenes" : "Select scenes first")
    }

    private var confirmButtonTitle: String {
        if selectedScenes.isEmpty {
            return "Select Scene\(maxSelections == 1 ? "" : "s") to Unlock"
        }
        return "Unlock \(selectedScenes.count) Scene\(selectedScenes.count == 1 ? "" : "s")"
    }

    // MARK: - Actions

    private func toggleSelection(_ scene: SceneID) {
        HapticManager.selection()

        if selectedScenes.contains(scene) {
            selectedScenes.remove(scene)
        } else {
            // Only allow adding if under the max
            guard selectedScenes.count < maxSelections else { return }
            selectedScenes.insert(scene)
        }
    }

    private func confirmSelection() {
        guard canConfirm else { return }

        for scene in selectedScenes {
            appState.unlockScene(scene)
        }

        HapticManager.unlock()
        dismiss()
    }
}
