import SwiftUI
import SwiftData

/// Expandable "Vitamins & minerals" glass card of the product form (spec §4/§5).
/// Values are edited as raw text keyed by `NutrientDef.id`; the caller parses
/// them with `Format.parse` on submit. Shows only the nutrients the user tracks.
struct MicroFieldsSection: View {
    @Binding var microTexts: [String: String]

    @Query private var settingsList: [UserSettings]

    @State private var isExpanded = false
    @State private var showNutrientSettings = false

    init(microTexts: Binding<[String: String]>) {
        _microTexts = microTexts
    }

    /// Enabled nutrients in catalog order. Falls back to the first-launch default
    /// set if settings have not been created yet (e.g. previews).
    private var enabledDefs: [NutrientDef] {
        if let settings = settingsList.first {
            return settings.enabledNutrientDefs
        }
        return NutrientCatalog.all.filter { NutrientCatalog.defaultEnabled.contains($0.id) }
    }

    /// Number of visible fields containing a valid (parseable, non-empty) value.
    private var validCount: Int {
        enabledDefs.filter { Format.parse(microTexts[$0.id] ?? "") != nil }.count
    }

    private var subtitle: Text {
        validCount > 0
            ? Text("\(validCount) added · tap to edit")
            : Text("Optional · only nutrients you track")
    }

    private var trailingLabel: Text {
        if isExpanded { return Text("Hide") }
        return validCount > 0 ? Text("\(validCount) added") : Text("Add")
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                headerRow
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(enabledDefs) { def in
                    ProductFormHairline()
                    ProductFieldRow(label: Text(def.nameKey),
                                    labelWidth: 110,
                                    text: textBinding(for: def.id),
                                    unit: Text(LocalizedStringKey(def.unit.label)))
                }
                ProductFormHairline()
                trackMoreRow
            }
        }
        .glassCard(cornerRadius: Theme.cornerRadius)
        .sheet(isPresented: $showNutrientSettings) {
            NavigationStack {
                NutrientsSettingsView()
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vitamins & minerals")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                subtitle
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                trailingLabel
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.accentLabel)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var trackMoreRow: some View {
        Button {
            showNutrientSettings = true
        } label: {
            HStack(spacing: 5) {
                Text("Track more nutrients")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Theme.accentLabel)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func textBinding(for id: String) -> Binding<String> {
        Binding(
            get: { microTexts[id] ?? "" },
            set: { microTexts[id] = $0 }
        )
    }
}

#Preview {
    MicroFieldsPreviewHost()
        .modelContainer(PreviewData.container)
}

private struct MicroFieldsPreviewHost: View {
    @State private var microTexts: [String: String] = ["fiber": "10"]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                MicroFieldsSection(microTexts: $microTexts)
                    .padding(20)
            }
        }
    }
}
