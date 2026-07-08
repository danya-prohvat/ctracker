import SwiftUI
import SwiftData

/// Combined "Goals & nutrients" subpage (prototype): daily kcal/macro goals
/// with steppers, extra options kept from the spec (goal calculator, net
/// carbs) and per-nutrient tracking with mini steppers and toggles.
struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    @State private var calories: Double = 2000
    @State private var protein: Double = 150
    @State private var fat: Double = 67
    @State private var carbs: Double = 200

    @State private var didLoad = false
    @State private var showCalculator = false

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GoalsSectionCaption("Daily goals")
                        .padding(.top, 8)
                    PlanEditor(
                        calories: $calories, protein: $protein, fat: $fat, carbs: $carbs
                    )
                    GoalsExtrasCard(showCalculator: $showCalculator, netCarbs: netCarbsBinding)
                    if let settings {
                        NutrientGoalsSection(settings: settings)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
        }
        .background(AppBackground())
        .toolbar(.hidden, for: .navigationBar)
        .hidesFloatingTabBar()
        .onAppear(perform: loadOnce)
        .onChange(of: calories) { persistGoals() }
        .onChange(of: protein) { persistGoals() }
        .onChange(of: fat) { persistGoals() }
        .onChange(of: carbs) { persistGoals() }
        .sheet(isPresented: $showCalculator) {
            GoalsCalculatorSheet { plan in
                calories = plan.calories
                protein = plan.protein
                fat = plan.fat
                carbs = plan.carbs
            }
            .presentationCornerRadius(26)
            .presentationBackground(.thinMaterial)
        }
    }

    // MARK: - Header (custom, system nav bar hidden)

    private var header: some View {
        ZStack {
            Text("Goals & nutrients")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.subheadline.weight(.semibold))
                        Text("Settings")
                            .font(.callout.weight(.medium))
                    }
                    .foregroundStyle(Theme.accentLabel)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - Bindings & persistence

    private var netCarbsBinding: Binding<Bool> {
        Binding(
            get: { settings?.netCarbsEnabled ?? false },
            set: { newValue in
                settings?.netCarbsEnabled = newValue
                try? context.save()
            }
        )
    }

    private func loadOnce() {
        guard !didLoad else { return }
        if settingsList.isEmpty {
            _ = UserSettings.current(in: context)
            try? context.save()
        }
        calories = settings?.calorieGoal ?? 2000
        protein = settings?.proteinGoal ?? 150
        fat = settings?.fatGoal ?? 67
        carbs = settings?.carbGoal ?? 200
        didLoad = true
    }

    /// Soft validation: only positive values are written back; anything else
    /// leaves the stored goal untouched.
    private func persistGoals() {
        guard didLoad, let settings else { return }
        if calories > 0 { settings.calorieGoal = calories }
        if protein > 0 { settings.proteinGoal = protein }
        if fat > 0 { settings.fatGoal = fat }
        if carbs > 0 { settings.carbGoal = carbs }
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
    .modelContainer(PreviewData.container)
}
