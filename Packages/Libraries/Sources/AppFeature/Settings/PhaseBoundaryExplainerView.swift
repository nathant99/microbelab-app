import SwiftUI
import Models
import Services

/// Parent/educator-facing consumer view for the
/// `PhaseBoundaryExplainerService` catalog. Renders one row per
/// `PhaseBoundaryNoteRecord` and surfaces the right affordance per the
/// service's `BoundaryPresentation`:
///
/// - **`.notReached`** — gate session-day floor not yet hit; the row stays
///   muted with a "Not yet" status. Parents don't need to think about it
///   until the kid is close.
/// - **`.awaitingConsent`** — gate is open + the note requires consent
///   (disease-story or historical context) + the grown-up has NOT yet
///   opted in. Surfaces an "Open consents" affordance pointing back into
///   the parental consent flow.
/// - **`.readyToInvite`** — gate is open + (consent granted OR not
///   required). Surfaces the "What your kid will see" explainer + a
///   one-tap acknowledgement.
/// - **`.alreadyAccepted`** — gate open + grown-up has already
///   acknowledged the explainer (non-consent notes) OR consent already
///   granted (consent-required notes). Collapses to a quieter row with
///   a check-glyph.
///
/// **Reachability**: surfaced from `SettingsView` "For parents" section
/// behind the existing parental-gate math wall. The view itself is NOT
/// gated again — it's assumed reachable only after gate-passed since
/// SettingsView won't link to it otherwise.
///
/// **Trauma-informed posture** (load-bearing per
/// `.claude/rules/trauma-informed-content.md` + ADR-016): every copy
/// string the view renders avoids warfare / shame / threat /
/// fear-induction lexicon. Notes are framed as invitations to the
/// grown-up, never as punitive prerequisites.
public struct PhaseBoundaryExplainerView: View {
    let explainer: PhaseBoundaryExplainerService
    let progression: ProgressionService?
    let consent: ParentalConsentService?

    public init(
        explainer: PhaseBoundaryExplainerService,
        progression: ProgressionService? = nil,
        consent: ParentalConsentService? = nil
    ) {
        self.explainer = explainer
        self.progression = progression
        self.consent = consent
    }

    public var body: some View {
        Form {
            Section {
                Text(verbatim: introCopy)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 4)
            } header: {
                Text("About these notes")
            } footer: {
                Text(verbatim: "Each note lives behind a session-day floor so the explainer surfaces calmly only when your kid is close. Reviewer-signed-off body content lands story by story.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Boundary notes") {
                ForEach(explainer.catalog) { record in
                    noteRow(for: record)
                }
            }

            Section {
                Button("Reset acknowledgements") {
                    explainer.resetAcknowledgements()
                }
                .accessibilityHint("Re-surface the explainer affordances you've already opened")
            } footer: {
                Text(verbatim: "Resets the acknowledgement check-glyphs only. Doesn't change consent.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Boundary explainers")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var introCopy: String {
        // Trauma-informed parent intro: names the why (transparency before
        // unlock) + names the kid's pace + names the SAMHSA review pathway.
        "Before your kid sees a new kind of content, this menu names what's coming. Stories about disease, history, and global ecology each surface on a different cadence. Body copy lands after an external reviewer signs off on the trauma-informed register."
    }

    @ViewBuilder
    private func noteRow(for record: PhaseBoundaryNoteRecord) -> some View {
        let gateOpen = progression?.isUnlocked(record.gateID) ?? false
        let parentConsented = record.requiresConsent
            ? (consent?.hasValidConsent(for: .diseaseStoryArcs) ?? false)
            : true
        let presentation = explainer.presentation(
            for: record,
            gateOpen: gateOpen,
            parentConsented: parentConsented
        )
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: record.displayTitle)
                    .font(.headline)
                Spacer()
                statusChip(for: presentation)
            }
            presentationBody(for: presentation, record: record)
                .font(.callout)
                .foregroundStyle(.primary)
            if case .readyToInvite = presentation, !record.requiresConsent {
                Button("Got it — don't show again") {
                    explainer.acknowledge(record.note)
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
                .accessibilityHint("Mark this boundary explainer as acknowledged")
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: presentation, record: record))
    }

    @ViewBuilder
    private func presentationBody(
        for presentation: PhaseBoundaryExplainerService.BoundaryPresentation,
        record: PhaseBoundaryNoteRecord
    ) -> some View {
        switch presentation {
        case .notReached:
            // Calm, low-volume: the kid isn't close yet, so no need to
            // pull the grown-up's attention.
            if let hint = progression?.unlockHint(for: record.gateID) {
                Text(verbatim: hint)
                    .foregroundStyle(.secondary)
            } else {
                Text(verbatim: "Your kid hasn't reached this boundary yet.")
                    .foregroundStyle(.secondary)
            }
        case .awaitingConsent:
            Text(verbatim: "Your kid is ready. Open Parental consents to turn this on.")
                .foregroundStyle(.secondary)
        case .readyToInvite:
            switch record.authoring {
            case .placeholder, .draftAwaitingReview:
                Text(verbatim: "Coming soon — a reviewer is reading the body copy now. The structural surface is in place for the moment it lands.")
                    .foregroundStyle(.secondary)
            case .reviewerSignedOff:
                Text(verbatim: "Your kid will see this on next play. Tap the boundary explainer in the kid surface to preview it together.")
                    .foregroundStyle(.secondary)
            }
        case .alreadyAccepted:
            Text(verbatim: "Already turned on. You can reset acknowledgements below to see this row again.")
                .foregroundStyle(.secondary)
        }
    }

    private func statusChip(
        for presentation: PhaseBoundaryExplainerService.BoundaryPresentation
    ) -> some View {
        let (label, systemImage): (String, String)
        switch presentation {
        case .notReached:
            label = "Not yet"
            systemImage = "hourglass"
        case .awaitingConsent:
            label = "Needs consent"
            systemImage = "person.2.fill"
        case .readyToInvite:
            label = "Ready"
            systemImage = "checkmark.seal"
        case .alreadyAccepted:
            label = "Turned on"
            systemImage = "checkmark.circle.fill"
        }
        return Label(label, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }

    private func accessibilityLabel(
        for presentation: PhaseBoundaryExplainerService.BoundaryPresentation,
        record: PhaseBoundaryNoteRecord
    ) -> String {
        let statusPhrase: String
        switch presentation {
        case .notReached:        statusPhrase = "not yet reached"
        case .awaitingConsent:   statusPhrase = "needs consent"
        case .readyToInvite:     statusPhrase = "ready to invite"
        case .alreadyAccepted:   statusPhrase = "already turned on"
        }
        return "\(record.displayTitle). \(statusPhrase)."
    }
}
