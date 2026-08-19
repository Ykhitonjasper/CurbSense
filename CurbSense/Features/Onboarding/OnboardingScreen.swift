import SwiftUI

struct OnboardingScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var tourPage = 0

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header

                    pageContent

                    pageIndicator
                        .frame(maxWidth: .infinity)

                    Button(action: handlePrimaryAction) {
                        Text(tourPage == 2 ? "Get Started" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .accessibilityHint(tourPage == 2 ? "Opens the Runbooks tab." : "Shows the next tour page.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .safeAreaPadding(.horizontal, 24)
                .safeAreaPadding(.vertical, 24)
            }
        }
        .sensoryFeedback(.selection, trigger: tourPage)
        .sensoryFeedback(.success, trigger: store.hasCompletedOnboarding)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppTheme.displayName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("A practical guide for careful observations")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "car.rear.and.tire.marks")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch tourPage {
        case 0:
            tourPage(
                image: "eye",
                eyebrow: "OBSERVE FIRST",
                title: "Start with what you can see",
                detail: "Use a short runbook to note visible changes after a curb contact, sharp road impact, or unfamiliar vehicle behavior.",
                highlight: "12 ready-to-use runbooks"
            )
        case 1:
            tourPage(
                image: "list.clipboard",
                eyebrow: "FOLLOW THE PATH",
                title: "Keep the record clear",
                detail: "Each step focuses on a single observation, helping you compare what is present without guessing at a cause.",
                highlight: "Simple choices at every step"
            )
        default:
            tourPage(
                image: "checkmark.shield",
                eyebrow: "CHOOSE CAREFULLY",
                title: "Leave with a useful next step",
                detail: "Finish with a concise action pack you can keep nearby when a condition needs a closer local review.",
                highlight: "Guidance for calm decisions"
            )
        }
    }

    private func tourPage(
        image: String,
        eyebrow: String,
        title: String,
        detail: String,
        highlight: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: image)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 82, height: 82)
                .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityHidden(true)

            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(detail)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Label(highlight, systemImage: "sparkle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.bgElevated, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == tourPage ? AppTheme.accent : AppTheme.hairline)
                    .frame(width: index == tourPage ? 28 : 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tour page \(tourPage + 1) of 3")
    }

    private func handlePrimaryAction() {
        if tourPage < 2 {
            tourPage += 1
        } else {
            store.completeOnboarding()
            store.selectedTab = "Runbooks"
        }
    }
}

#Preview {
    OnboardingScreen()
        .environment(CurbSenseStore(dependencies: .preview()))
}
