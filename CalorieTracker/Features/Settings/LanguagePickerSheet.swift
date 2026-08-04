import SwiftUI

/// Modal language picker: a native inset-grouped list with an always-visible
/// search field (the catalog will grow), rows showing the endonym over the
/// English name — the iOS Settings "Language & Region" pattern.
struct LanguagePickerSheet: View {
    let selected: SettingsLanguage
    let onSelect: (SettingsLanguage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var languages: [SettingsLanguage] {
        SettingsLanguage.allCases.filter { $0 != .system }
    }

    private var filtered: [SettingsLanguage] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return languages }
        return languages.filter {
            $0.englishName.localizedCaseInsensitiveContains(trimmed)
                || $0.endonym.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        row(
                            title: Text("System"),
                            subtitle: Text("Follow the iOS language"),
                            isSelected: selected == .system
                        ) { choose(.system) }
                    }
                }
                Section {
                    ForEach(filtered) { language in
                        row(
                            title: Text(verbatim: language.endonym),
                            subtitle: Text(verbatim: language.englishName),
                            isSelected: selected == language
                        ) { choose(language) }
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search languages")
            )
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func choose(_ language: SettingsLanguage) {
        onSelect(language)
        dismiss()
    }

    private func row(
        title: Text, subtitle: Text, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                    subtitle
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accentLabel)
                }
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LanguagePickerSheet(selected: .system) { _ in }
        }
}
