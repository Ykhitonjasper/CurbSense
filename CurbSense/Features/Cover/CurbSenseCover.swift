import SwiftUI

/// Switcher snapshot of the CurbSense hub — same cards, risk chips, and tabs
/// as the native catalog, not a donor workspace.
struct CurbSenseCover: View {
    private let featured = CurbSenseSeedData.runbooks()[0]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        snapshotGrid
                        recentWalks
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }

                tabChrome
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppTheme.displayName)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppTheme.displayName)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Vehicle condition runbooks")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Choose a focused observation path before deciding what to do next.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var snapshotGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            coverTile(title: "Risk", value: "Caution", caption: featured.title, symbol: "exclamationmark.triangle")
            coverTile(title: "Walk", value: "\(featured.durationMinutes) min", caption: "Parked observation", symbol: "clock")
            coverTile(title: "Kit", value: "Flashlight", caption: "Tire gauge · cloth", symbol: "flashlight.on.fill")
            coverTile(title: "Paths", value: "12", caption: "Ready runbooks", symbol: "books.vertical")
        }
    }

    private func coverTile(title: String, value: String, caption: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(caption)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private var recentWalks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent observation paths")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            coverRow(title: "Curb Strike Check", detail: "Caution · 8 min", symbol: "car.rear.and.tire.marks")
            coverRow(title: "Pothole Thump", detail: "Caution · 9 min", symbol: "point.topleft.down.to.point.bottomright.curvepath")
            coverRow(title: "New Steering Pull", detail: "Caution · 7 min", symbol: "steeringwheel")
        }
        .padding(16)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private func coverRow(title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var tabChrome: some View {
        HStack {
            tabGlyph("books.vertical", "Runbooks", selected: true)
            tabGlyph("point.topleft.down.to.point.bottomright.curvepath", "Active", selected: false)
            tabGlyph("clock.arrow.circlepath", "History", selected: false)
            tabGlyph("gearshape", "Settings", selected: false)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(AppTheme.bgElevated.opacity(0.96))
        .overlay(alignment: .top) {
            AppTheme.hairline.frame(height: 1)
        }
    }

    private func tabGlyph(_ symbol: String, _ title: String, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CurbSenseCover()
}
