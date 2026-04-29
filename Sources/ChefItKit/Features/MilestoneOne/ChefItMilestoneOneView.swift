import SwiftUI

public struct ChefItMilestoneOneView: View {
    @StateObject private var model: ChefItMilestoneOneViewModel

    @MainActor
    public init(model: ChefItMilestoneOneViewModel? = nil) {
        _model = StateObject(wrappedValue: model ?? ChefItMilestoneOneViewModel())
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroPanel

                    if proxy.size.width >= 920 {
                        HStack(alignment: .top, spacing: 20) {
                            leftRail
                                .frame(maxWidth: 360)
                            workspacePanel
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            leftRail
                            workspacePanel
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 1180, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(shellBackground.ignoresSafeArea())
        }
    }

    private var heroPanel: some View {
        ShellPanel(tint: Palette.ink) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Chef It")
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundStyle(Palette.paper)

                        Text("A tighter kitchen workspace shaped by Pantry Pal's real flow, but rebuilt with a different voice.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.paper.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 8) {
                        shellTag("Milestone 01")
                        shellTag("Scan + recipe APIs deferred")
                    }
                }

                Divider()
                    .overlay(Palette.paper.opacity(0.15))

                HStack(spacing: 12) {
                    metricCard(value: model.ingredients.count, label: "ingredients on board")
                    phaseBadge
                }
            }
        }
    }

    private var leftRail: some View {
        VStack(alignment: .leading, spacing: 20) {
            ingredientBoardPanel
            scanEntryPanel
        }
    }

    private var ingredientBoardPanel: some View {
        ShellPanel(tint: Palette.paper) {
            VStack(alignment: .leading, spacing: 16) {
                panelHeader(
                    eyebrow: "Ingredient board",
                    title: "Counter stock",
                    copy: "Manual intake is live now. This keeps the scan lane separate so milestone 2 can plug in capture and confirmation cleanly."
                )

                HStack(alignment: .top, spacing: 10) {
                    TextField("Eggs, garlic, lemon, pasta", text: $model.manualEntry, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Palette.paperLift)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Palette.line, lineWidth: 1)
                        )

                    Button("Add") {
                        model.addManualIngredients()
                    }
                    .buttonStyle(ShellButtonStyle(kind: .primary))
                }

                HStack(spacing: 10) {
                    Button("Clear board") {
                        model.clearBoard()
                    }
                    .buttonStyle(ShellButtonStyle(kind: .ghost))
                    .disabled(model.ingredients.isEmpty)

                    Button("Refresh matches") {
                        Task {
                            await model.refreshWorkspace()
                        }
                    }
                    .buttonStyle(ShellButtonStyle(kind: .secondary))
                    .disabled(model.ingredients.isEmpty)
                }

                if model.ingredients.isEmpty {
                    emptyMessage(
                        title: "Nothing staged yet",
                        body: "Add pantry items manually for now. The workspace on the right is already structured for scan-driven intake later."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Current board")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Spacer()
                            Text("\(model.ingredients.count) total")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Palette.muted)
                        }

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 180), spacing: 8, alignment: .leading)],
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(model.ingredients) { ingredient in
                                ingredientChip(for: ingredient)
                            }
                        }
                    }
                }
            }
        }
    }

    private func ingredientChip(for ingredient: Ingredient) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: ingredient.category))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(ingredient.canonicalName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.muted)
            }

            Button {
                model.removeIngredient(ingredient.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .padding(6)
                    .background(Circle().fill(Palette.paperLift))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Palette.paperLift)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    private var scanEntryPanel: some View {
        ShellPanel(tint: Palette.accentSoft) {
            VStack(alignment: .leading, spacing: 16) {
                panelHeader(
                    eyebrow: "Scan entry point",
                    title: "Photo lane",
                    copy: "Pantry Pal's scan flow is capture or upload -> detect ingredients -> confirm selections. Chef It exposes that lane here without wiring the actual scanner yet."
                )

                HStack(spacing: 10) {
                    milestoneStep(number: "01", title: "Capture")
                    milestoneStep(number: "02", title: "Detect")
                    milestoneStep(number: "03", title: "Confirm")
                }

                Text("Deferred intentionally: no live camera, no image upload, no detection backend call in milestone 1.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.ember)
            }
        }
    }

    private var workspacePanel: some View {
        ShellPanel(tint: Palette.stove) {
            VStack(alignment: .leading, spacing: 18) {
                panelHeader(
                    eyebrow: "Recipe workspace",
                    title: "Ready now vs almost there",
                    copy: "The structure mirrors Pantry Pal's real result framing: ingredients feed a search plan, candidate recipes are matched locally, and the workspace splits into fully-ready and near-miss groups.",
                    foreground: Palette.paper,
                    secondary: Palette.paper.opacity(0.72)
                )

                discoverySummary

                switch model.phase {
                case .needsIngredients:
                    emptyMessage(
                        title: "Waiting on ingredients",
                        body: "The discovery planner stays idle until the board has something to work with."
                    )

                case .staged:
                    stagedWorkspace

                case .loading:
                    loadingWorkspace

                case .failed(let message):
                    emptyMessage(
                        title: "Discovery pipeline placeholder",
                        body: message
                    )

                case .loaded(let snapshot):
                    resultsWorkspace(snapshot: snapshot)
                }
            }
        }
    }

    private var discoverySummary: some View {
        let ingredients = model.ingredients
        let plan = RecipeDiscoveryPlanner().makePlan(from: ingredients)

        return HStack(spacing: 12) {
            summaryBadge(title: "board", value: "\(ingredients.count)")
            summaryBadge(title: "proteins", value: "\(plan.proteins.count)")
            summaryBadge(title: "support", value: "\(plan.supportingIngredients.count)")
        }
    }

    private var stagedWorkspace: some View {
        VStack(alignment: .leading, spacing: 14) {
            emptyMessage(
                title: "Workspace is staged",
                body: "Ingredients are normalized and ready. Run the placeholder discovery step to exercise the real match grouping without any live recipe API dependency yet."
            )

            Button("Run local discovery") {
                Task {
                    await model.refreshWorkspace()
                }
            }
            .buttonStyle(ShellButtonStyle(kind: .primary))
        }
    }

    private var loadingWorkspace: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(Palette.paper)
                Text("Building the discovery plan and matching seed recipes.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.paper.opacity(0.88))
            }
        }
    }

    private func resultsWorkspace(snapshot: DiscoveryWorkspaceSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                summaryBadge(title: "candidates", value: "\(snapshot.candidateCount)")
                summaryBadge(title: "ready", value: "\(snapshot.results.ready.count)")
                summaryBadge(title: "almost", value: "\(snapshot.results.almost.count)")
            }

            if !snapshot.plan.proteins.isEmpty || !snapshot.plan.supportingIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discovery plan")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.paper.opacity(0.7))

                    Text(planDescription(snapshot.plan))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.paper.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            resultColumn(
                title: "Ready to cook",
                subtitle: "All required ingredients are already on the board.",
                matches: snapshot.results.ready,
                tone: Palette.sage
            )

            resultColumn(
                title: "Almost there",
                subtitle: "Recipes with a small missing set stay visible for later fulfillment logic.",
                matches: snapshot.results.almost,
                tone: Palette.gold
            )
        }
    }

    private func resultColumn(
        title: String,
        subtitle: String,
        matches: [RecipeMatch],
        tone: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.paper)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.paper.opacity(0.72))
            }

            if matches.isEmpty {
                emptyMessage(
                    title: "No recipes in this group yet",
                    body: title == "Ready to cook"
                        ? "This is where full matches land once every required ingredient is covered."
                        : "This is reserved for the near-miss set that later milestones can enrich with fulfillment actions."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(matches) { match in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(match.recipe.title)
                                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Palette.paper)
                                    Text(match.recipe.blurb)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Palette.paper.opacity(0.72))
                                }

                                Spacer(minLength: 12)

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(match.recipe.cookingMinutes) min")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(tone)
                                    Text("\(Int((match.coverage * 100).rounded()))% coverage")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Palette.paper.opacity(0.62))
                                }
                            }

                            if !match.missingIngredients.isEmpty {
                                Text("Missing: \(match.missingIngredients.joined(separator: ", "))")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(tone)
                            }

                            if !match.matchedIngredients.isEmpty {
                                Text("Matched: \(match.matchedIngredients.joined(separator: ", "))")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Palette.paper.opacity(0.68))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Palette.stoveLift)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(tone.opacity(0.28), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var phaseBadge: some View {
        let label: String
        switch model.phase {
        case .needsIngredients: label = "idle"
        case .staged: label = "staged"
        case .loading: label = "matching"
        case .loaded: label = "grouped"
        case .failed: label = "placeholder"
        }

        return HStack(spacing: 8) {
            Circle()
                .fill(Palette.gold)
                .frame(width: 9, height: 9)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.paper)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Palette.ink.opacity(0.18))
        )
    }

    private func metricCard(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.paper)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.paper.opacity(0.72))
        }
        .padding(14)
        .frame(maxWidth: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.ink.opacity(0.18))
        )
    }

    private func summaryBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.paper.opacity(0.6))
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.paper)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.stoveLift)
        )
    }

    private func shellTag(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Palette.paper.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Palette.ink.opacity(0.16))
            )
    }

    private func milestoneStep(number: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(number)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ember)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.paper.opacity(0.78))
        )
    }

    private func panelHeader(
        eyebrow: String,
        title: String,
        copy: String,
        foreground: Color = Palette.ink,
        secondary: Color = Palette.muted
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(secondary)

            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(foreground)

            Text(copy)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func emptyMessage(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.paper)
            Text(body)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.paper.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.stoveLift)
        )
    }

    private func planDescription(_ plan: RecipeDiscoveryPlan) -> String {
        if plan.proteins.isEmpty {
            return "No protein-led query split yet. The planner will search broadly from the supporting ingredient set."
        }

        let proteins = plan.proteins.joined(separator: ", ")
        let support = plan.supportingIngredients.joined(separator: ", ")
        if support.isEmpty {
            return "Protein-led query prepared from \(proteins)."
        }
        return "Protein-led query prepared from \(proteins), supported by \(support)."
    }

    private func color(for category: IngredientCategory) -> Color {
        switch category {
        case .produce: return Palette.green
        case .protein: return Palette.gold
        case .dairy: return Palette.blue
        case .pantry: return Palette.ember
        case .spice: return Palette.plum
        case .grain: return Palette.sand
        case .condiment: return Palette.blue
        case .other: return Palette.muted
        }
    }

    private var shellBackground: some View {
        LinearGradient(
            colors: [Palette.canvasTop, Palette.canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Palette.paper.opacity(0.07), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
}

private struct ShellPanel<Content: View>: View {
    let tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(tint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Palette.line.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: Palette.shadow, radius: 22, x: 0, y: 12)
    }
}

private struct ShellButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case ghost
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(background.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(border, lineWidth: kind == .ghost ? 1 : 0)
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Palette.paper
        case .secondary: return Palette.ink
        case .ghost: return Palette.ink
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return Palette.ink
        case .secondary: return Palette.paperLift
        case .ghost: return .clear
        }
    }

    private var border: Color {
        Palette.line
    }
}

private enum Palette {
    static let canvasTop = Color(red: 0.96, green: 0.91, blue: 0.80)
    static let canvasBottom = Color(red: 0.89, green: 0.81, blue: 0.71)
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.90)
    static let paperLift = Color(red: 0.96, green: 0.92, blue: 0.86)
    static let ink = Color(red: 0.17, green: 0.16, blue: 0.18)
    static let muted = Color(red: 0.36, green: 0.33, blue: 0.31)
    static let line = Color(red: 0.76, green: 0.69, blue: 0.61)
    static let accentSoft = Color(red: 0.97, green: 0.80, blue: 0.63)
    static let stove = Color(red: 0.21, green: 0.20, blue: 0.22)
    static let stoveLift = Color(red: 0.27, green: 0.26, blue: 0.29)
    static let shadow = Color.black.opacity(0.12)
    static let ember = Color(red: 0.71, green: 0.31, blue: 0.18)
    static let sage = Color(red: 0.57, green: 0.76, blue: 0.58)
    static let gold = Color(red: 0.90, green: 0.72, blue: 0.34)
    static let green = Color(red: 0.39, green: 0.63, blue: 0.39)
    static let blue = Color(red: 0.43, green: 0.58, blue: 0.74)
    static let plum = Color(red: 0.52, green: 0.43, blue: 0.65)
    static let sand = Color(red: 0.77, green: 0.66, blue: 0.50)
}

#if DEBUG
struct ChefItMilestoneOneView_Previews: PreviewProvider {
    static var previews: some View {
        ChefItMilestoneOneView()
            .frame(minWidth: 1024, minHeight: 900)
    }
}
#endif
