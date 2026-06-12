import SwiftUI
import Services

/// Settings-surface card listing portfolio-canonical safety hotlines
/// (988 / Childhelp / Crisis Text Line) per `Docs/FEATURE_PLAN.md`
/// § Accessibility & Trauma-Informed Polish → "Crisis-resource list
/// (988 / Childhelp / Crisis Text Line) surfaced from Settings".
///
/// **Trauma-informed framing** per `.claude/rules/trauma-informed-content.md`:
/// validate-then-inform copy in the section header acknowledges that
/// kids who reach this surface may already be experiencing distress.
/// Resources are presented as gentle options, not as alarms. Taps open
/// the system phone / messages app via the canonical `tel:` / `sms:`
/// URLs surfaced by `CrisisResources` — no in-app modal that could trap
/// a kid mid-crisis.
///
/// Future Phase 3 disease-story arcs surface the same list via this
/// reusable card so the trauma-safe register stays one definition wide.
struct CrisisResourceCard: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            ForEach(CrisisResources.all) { resource in
                row(for: resource)
            }
        } header: {
            Text("If you need to talk to someone")
        } footer: {
            Text("These reach a real person any time of day. You don't have to be in a crisis to call — \"not sure\" is reason enough.")
                .font(.caption)
        }
    }

    private func row(for resource: CrisisResource) -> some View {
        Button {
            openURL(resource.actionURL)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: resourceIcon(for: resource))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(resource.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Text(resource.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(resource.title). \(resource.subtitle)")
        .accessibilityHint(resource.actionLabel)
    }

    private func resourceIcon(for resource: CrisisResource) -> String {
        switch resource.id {
        case "crisis-text-line": return "message"
        default: return "phone"
        }
    }
}

#Preview {
    Form {
        CrisisResourceCard()
    }
}
