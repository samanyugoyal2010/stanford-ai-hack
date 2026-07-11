import SwiftUI

/// Reusable card presenting a single subsystem name and its lifecycle status.
struct StatusCardView: View {
    let model: StatusCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(model.status.displayName)
                .font(.title3.weight(.medium))
                .foregroundStyle(statusColor)
                .accessibilityLabel("\(model.title): \(model.status.displayName)")
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch model.status {
        case .notStarted, .idle, .stopped:
            return .secondary
        case .running:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    StatusCardView(
        model: StatusCardModel(title: "Screen Capture Status", status: .notStarted)
    )
    .padding()
    .frame(width: 320)
}
