import SwiftUI

struct GuidedAccessHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    stepSection(
                        number: 1,
                        title: "Enable Guided Access",
                        steps: [
                            "Open the Settings app",
                            "Go to Accessibility > Guided Access",
                            "Turn on Guided Access",
                            "Set a passcode (or enable Face ID / Touch ID)"
                        ]
                    )

                    stepSection(
                        number: 2,
                        title: "Start Guided Access",
                        steps: [
                            "Open BabySafe Visuals",
                            "Triple-click the Side Button (or Home Button)",
                            "Tap Start in the top-right corner",
                            "The device is now locked to this app"
                        ]
                    )

                    stepSection(
                        number: 3,
                        title: "End Guided Access",
                        steps: [
                            "Triple-click the Side Button (or Home Button)",
                            "Enter your Guided Access passcode or use Face ID",
                            "Tap End in the top-left corner"
                        ]
                    )

                    tipsSection
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Guided Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keep your device locked to BabySafe Visuals")
                .font(.headline)
            Text("Guided Access is a built-in iOS feature that pins your device to a single app, preventing your child from switching apps or accessing other content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func stepSection(number: Int, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.blue))
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .trailing)
                        Text(step)
                            .font(.subheadline)
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

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.headline)
            Text("With Guided Access active, your child cannot exit the app, access notifications, or use Control Center. This pairs perfectly with BabySafe Visuals for worry-free handoff.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
