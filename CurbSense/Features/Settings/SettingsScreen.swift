import SwiftUI

struct SettingsScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var isDeleteConfirmationPresented = false
    @State private var didDeleteAllData = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                aboutSection
                legalSection
                dataSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppBackground())
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete all local data?", isPresented: $isDeleteConfirmationPresented) {
            Button("Delete All Data", role: .destructive) {
                store.deleteAllData()
                didDeleteAllData = true
            }
            Button("Keep Data", role: .cancel) {}
        } message: {
            Text("Your saved runbooks, completed checks, and action packs will be removed. The product tour will restart.")
        }
        .sensoryFeedback(.warning, trigger: isDeleteConfirmationPresented)
        .sensoryFeedback(.success, trigger: didDeleteAllData)
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            VStack(alignment: .leading, spacing: 10) {
                Label(AppTheme.displayName, systemImage: "car.rear.and.tire.marks")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("A practical reference for recording visible vehicle changes and choosing a calm next step.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Version \(appVersion)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("About \(AppTheme.displayName), version \(appVersion)")
        }
    }

    private var legalSection: some View {
        settingsSection(title: "Legal") {
            VStack(spacing: 0) {
                if let privacyURL = Legal.privacy {
                    Link(destination: privacyURL) {
                        legalRow(title: "Privacy Policy", icon: "hand.raised")
                    }
                    .accessibilityLabel("Open Privacy Policy")
                    .accessibilityHint("Opens the privacy policy in your browser")
                }

                if let privacyURL = Legal.privacy, Legal.terms != nil {
                    Divider()
                        .overlay(AppTheme.hairline)
                        .padding(.leading, 44)
                }

                if let termsURL = Legal.terms {
                    Link(destination: termsURL) {
                        legalRow(title: "Terms of Use", icon: "doc.text")
                    }
                    .accessibilityLabel("Open Terms of Use")
                    .accessibilityHint("Opens the terms of use in your browser")
                }
            }
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Local Data") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Remove every saved item from this device and return to the three-page product tour.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.danger)
                .accessibilityLabel("Delete all local data")
                .accessibilityHint("Asks for confirmation before removing saved content and restarting the product tour")
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(AppTheme.textSecondary)

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                }
        }
    }

    private func legalRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(title)
                .font(.body.weight(.medium))

            Spacer(minLength: 12)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(AppTheme.accent)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version?.isEmpty == false ? version ?? "1.0" : "1.0"
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
    .environment(CurbSenseStore(dependencies: .preview(), hasCompletedOnboarding: true))
}
