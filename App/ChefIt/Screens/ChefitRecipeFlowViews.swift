import SwiftUI
import ChefItKit

struct ChefitRecipeDetailsPayload: Hashable {
    let id: String
    let title: String
    let imageURL: URL?
    let minutes: Int
    let difficulty: String
    let servings: Int
    let ingredients: [String]
    let blurb: String
    let sourceURL: URL?

    static func fromSample(_ recipe: ChefitRecipeItem) -> ChefitRecipeDetailsPayload {
        ChefitRecipeDetailsPayload(
            id: recipe.id,
            title: recipe.title,
            imageURL: recipe.imageURL,
            minutes: recipe.minutes,
            difficulty: recipe.difficulty,
            servings: 2,
            ingredients: ChefitSampleData.recipeDetailIngredients.map(\.1),
            blurb: "A chef-it favorite built from your pantry-ready picks.",
            sourceURL: nil
        )
    }

    static func fromRecipe(_ recipe: Recipe) -> ChefitRecipeDetailsPayload {
        ChefitRecipeDetailsPayload(
            id: recipe.id,
            title: recipe.title,
            imageURL: recipe.imageURL,
            minutes: recipe.cookingMinutes,
            difficulty: recipe.difficulty.rawValue.capitalized,
            servings: recipe.servings,
            ingredients: recipe.ingredients,
            blurb: recipe.blurb,
            sourceURL: recipe.sourceURL
        )
    }
}

struct ChefitRecipeDiscoveryView: View {
    let recipe: ChefitRecipeItem
    let onViewRecipe: (ChefitRecipeDetailsPayload) -> Void
    @State private var isFavorite: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: recipe.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                    Text(recipe.title)
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.white)
                        .padding(ChefitSpacing.md)
                }
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: ChefitSpacing.sm) {
                        Button { isFavorite.toggle() } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                        }
                        Button {} label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ChefitColors.white)
                    .padding(ChefitSpacing.md)
                }

                Text(recipe.title)
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)

                HStack(spacing: 6) {
                    Image(systemName: ChefitSymbol.clock)
                    Text("\(recipe.minutes) min")
                    Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                    Image(systemName: ChefitSymbol.star)
                    Text(recipe.difficulty)
                    Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                    Image(systemName: ChefitSymbol.personServings)
                    Text("2 servings")
                }
                .font(ChefitTypography.micro())
                .foregroundStyle(ChefitColors.matcha)

                HStack {
                    Text("Ingredients")
                        .font(ChefitTypography.h3())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Text("See all")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.peach)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ChefitSpacing.sm) {
                        ForEach(ChefitSampleData.ingredientChips, id: \.0) { item in
                            ChefitIngredientChip(label: item.0, systemImage: item.1)
                        }
                    }
                }

                Button("View Recipe") {
                    onViewRecipe(.fromSample(recipe))
                }
                    .buttonStyle(ChefitPrimaryButtonStyle())
                    .padding(.top, ChefitSpacing.md)
            }
            .padding(ChefitSpacing.md)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}

struct ChefitRecipeDetailsView: View {
    enum RecipeTab: String, CaseIterable {
        case ingredients = "Ingredients"
        case steps = "Steps"
        case notes = "Notes"
    }

    let recipe: ChefitRecipeDetailsPayload
    @State private var selectedTab: RecipeTab = .ingredients

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ChefitColors.sageGreen)
                }

                if let imageURL = recipe.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                }

                VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
                    Text(recipe.title)
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Text(recipe.blurb)
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.matcha)
                    HStack(spacing: 6) {
                        Image(systemName: ChefitSymbol.clock)
                        Text("\(recipe.minutes) min")
                        Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                        Image(systemName: ChefitSymbol.star)
                        Text(recipe.difficulty)
                        Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                        Image(systemName: ChefitSymbol.personServings)
                        Text("\(recipe.servings) servings")
                    }
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
                }

                tabSelector

                ScrollView {
                    tabContent
                        .padding(.bottom, ChefitSpacing.twoXL + ChefitSpacing.lg)
                }
            }
            .padding(ChefitSpacing.md)

            if let sourceURL = recipe.sourceURL {
                Link(destination: sourceURL) {
                    HStack {
                        Text("Open Full Recipe")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                    }
                }
                .buttonStyle(ChefitPrimaryButtonStyle())
                .padding(ChefitSpacing.md)
                .background(ChefitColors.cream.ignoresSafeArea())
            } else {
                Button {
                } label: {
                    HStack {
                        Text("Start Cooking")
                        Spacer()
                        Image(systemName: "play.fill")
                    }
                }
                .buttonStyle(ChefitPrimaryButtonStyle())
                .padding(ChefitSpacing.md)
                .background(ChefitColors.cream.ignoresSafeArea())
            }
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private var tabSelector: some View {
        HStack(spacing: ChefitSpacing.md) {
            ForEach(RecipeTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(ChefitTypography.label())
                            .foregroundStyle(selectedTab == tab ? ChefitColors.sageGreen : ChefitColors.matcha)
                        Rectangle()
                            .fill(selectedTab == tab ? ChefitColors.peach : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .ingredients:
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { item in
                    HStack {
                        Image(systemName: symbol(for: item.element))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ChefitColors.matcha)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 28, alignment: .center)
                        Text(item.element.capitalized)
                            .font(ChefitTypography.body())
                            .foregroundStyle(ChefitColors.sageGreen)
                        Spacer()
                        Text("•")
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.matcha)
                    }
                    .padding(.vertical, ChefitSpacing.sm)
                    Divider().overlay(ChefitColors.pistachio)
                }
            }
        case .steps:
            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                ChefitStepRow(stepNumber: 1, text: "Prep the ingredients from the list.", systemImage: ChefitSymbol.stepTomatoes)
                ChefitStepRow(stepNumber: 2, text: "Cook based on the recipe source timing (\(recipe.minutes) min).", systemImage: ChefitSymbol.stepBoilPasta)
                ChefitStepRow(stepNumber: 3, text: "Season and adjust with pantry staples.", systemImage: ChefitSymbol.stepSaute)
                ChefitStepRow(stepNumber: 4, text: "Plate and serve \(recipe.servings) portion(s).", systemImage: ChefitSymbol.stepServe)
            }
        case .notes:
            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                Text(recipe.blurb)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if recipe.sourceURL != nil {
                    Text("Open the source link below for full instructions.")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                } else {
                    Text("No source link provided for this recipe.")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }
            }
            .padding(.top, ChefitSpacing.sm)
        }
    }

    private func symbol(for ingredient: String) -> String {
        let lowered = ingredient.lowercased()
        if lowered.contains("tomato") { return ChefitSymbol.tomato }
        if lowered.contains("garlic") { return ChefitSymbol.garlic }
        if lowered.contains("pasta") || lowered.contains("noodle") { return ChefitSymbol.pasta }
        if lowered.contains("chicken") || lowered.contains("beef") || lowered.contains("shrimp") || lowered.contains("tofu") {
            return ChefitSymbol.chicken
        }
        if lowered.contains("onion") { return ChefitSymbol.onion }
        if lowered.contains("broccoli") { return ChefitSymbol.broccoli }
        if lowered.contains("egg") { return ChefitSymbol.egg }
        if lowered.contains("oil") { return ChefitSymbol.oliveOil }
        if lowered.contains("milk") || lowered.contains("cream") || lowered.contains("butter") { return ChefitSymbol.milk }
        return "leaf.fill"
    }
}
