import SwiftUI

/// Branded startup splash while StartupRouter resolves native vs experiment.
struct CurbSenseWarmupView: View {
    @State private var messageIndex = 0

    private let messages = [
        "Opening runbook rail...",
        "Staging observation steps...",
        "Calibrating branch map..."
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                AppBackground()

                curbGlowField(time: time)

                VStack(spacing: 36) {
                    brandHeader

                    ObservationRailAnimation(time: time)
                        .frame(height: 168)
                        .padding(.horizontal, 28)

                    VStack(spacing: 10) {
                        Text(messages[messageIndex])
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .id(messageIndex)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .accessibilityLabel(messages[messageIndex])

                        RailProgressCapsule(time: time)
                            .frame(width: 156, height: 4)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading \(AppTheme.displayName)")
    }

    private var brandHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.rear.and.tire.marks")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            Text(AppTheme.displayName)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Post-impact observation rail")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func curbGlowField(time: TimeInterval) -> some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 44)
                .offset(x: sin(time * 0.65) * 26, y: cos(time * 0.5) * 20)

            Circle()
                .fill(AppTheme.danger.opacity(0.06))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: cos(time * 0.55) * -22, y: sin(time * 0.7) * 28)
        }
        .accessibilityHidden(true)
    }
}

private struct ObservationRailAnimation: View {
    let time: TimeInterval

    private let steps: [(icon: String, label: String)] = [
        ("eye", "Observe"),
        ("arrow.triangle.branch", "Branch"),
        ("list.bullet.clipboard", "Record"),
        ("checkmark.shield", "Verdict")
    ]

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                curbSilhouette(time: time)

                VStack(spacing: 0) {
                    railTrack(time: time)
                        .padding(.horizontal, 8)

                    HStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            stepNode(step, index: index, time: time)
                            if index < steps.count - 1 {
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private func curbSilhouette(time: TimeInterval) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(AppTheme.bgElevated.opacity(0.55))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(AppTheme.hairline.opacity(0.45))
                    .frame(height: 6)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
                    .offset(y: sin(time * 1.4) * 1.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private func railTrack(time: TimeInterval) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let travel = width - 18
            let progress = (sin(time * 1.35) + 1) / 2
            let markerX = progress * travel

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.hairline.opacity(0.35))
                    .frame(height: 4)

                Capsule()
                    .fill(AppTheme.accent)
                    .frame(width: max(24, markerX + 18), height: 4)

                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 14, height: 14)
                    .shadow(color: AppTheme.accent.opacity(0.45), radius: 8)
                    .offset(x: markerX)
            }
        }
        .frame(height: 14)
        .padding(.top, 28)
        .accessibilityHidden(true)
    }

    private func stepNode(_ step: (icon: String, label: String), index: Int, time: TimeInterval) -> some View {
        let cycle = (time * 0.9 + Double(index) * 0.55).truncatingRemainder(dividingBy: 4.0) / 4.0
        let active = cycle < 0.28
        let scale = active ? 1.06 : 0.94

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(active ? AppTheme.accent.opacity(0.18) : AppTheme.bgBase)
                    .frame(width: 46, height: 46)

                Circle()
                    .stroke(active ? AppTheme.accent : AppTheme.hairline, lineWidth: active ? 2 : 1)
                    .frame(width: 46, height: 46)

                Image(systemName: step.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(active ? AppTheme.accent : AppTheme.textSecondary)
                    .scaleEffect(active ? 1.05 : 1)
            }
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.25), value: active)

            Text(step.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(active ? AppTheme.textPrimary : AppTheme.textSecondary)
        }
        .frame(width: 64)
        .accessibilityHidden(true)
    }
}

private struct RailProgressCapsule: View {
    let time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let travel = width + 36
            let x = (sin(time * 2.0) + 1) / 2 * travel - 18

            Capsule()
                .fill(AppTheme.hairline.opacity(0.35))

            Capsule()
                .fill(AppTheme.accent)
                .frame(width: 44)
                .offset(x: x)
                .mask(Capsule())
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    CurbSenseWarmupView()
}
