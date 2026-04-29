import SwiftUI

public struct ChefItMilestoneOneView: View {
    @StateObject private var model: ChefItMilestoneOneViewModel
    @StateObject private var scanModel: ScanFlowViewModel
    @State private var selectedRecipeMatch: RecipeMatch?

    @MainActor
    public init(model: ChefItMilestoneOneViewModel? = nil) {
        let resolvedModel = model ?? ChefItMilestoneOneViewModel()
        _model = StateObject(wrappedValue: resolvedModel)
        _scanModel = StateObject(
            wrappedValue: ScanFlowViewModel(ingredientStore: resolvedModel.ingredientStore)
        )
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
                .padding(proxy.size.width < 430 ? 12 : 20)
                .frame(maxWidth: 1180, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(shellBackground.ignoresSafeArea())
            .sheet(isPresented: editSheetBinding) {
                renameSheet
            }
            .sheet(item: $selectedRecipeMatch) { match in
                recipeDetailSheet(match)
            }
        }
    }

    private var editSheetBinding: Binding<Bool> {
        Binding(
            get: {
                if case .idle = model.editState { return false }
                return true
            },
            set: { isPresented in
                if !isPresented { model.cancelEdit() }
            }
        )
    }

    private var renameSheet: some View {
        let draft = Binding<String>(
            get: {
                switch model.editState {
                case .editing(_, let d), .duplicateConflict(_, let d, _): return d
                case .idle: return ""
                }
            },
            set: { model.updateEditDraft($0) }
        )

        let conflictName: String? = {
            if case .duplicateConflict(_, _, let existingID) = model.editState {
                return model.ingredients.first { $0.id == existingID }?.name
            }
            return nil
        }()

        return VStack(alignment: .leading, spacing: 18) {
            Text("Rename ingredient")
                .font(.system(size: 22, weight: .semibold, design: .serif))

            TextField("Ingredient name", text: draft)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit { model.commitEdit() }

            if let conflictName {
                Text("Already on board as \(conflictName). Cancel and remove the duplicate first.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") { model.cancelEdit() }
                    .buttonStyle(ShellButtonStyle(kind: .ghost))
                Spacer()
                Button("Save") { model.commitEdit() }
                    .buttonStyle(ShellButtonStyle(kind: .primary))
            }
        }
        .padding(24)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func recipeDetailSheet(_ match: RecipeMatch) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(match.recipe.title)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(match.recipe.blurb)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FlowLayout(spacing: 8) {
                    detailPill("\(match.recipe.cookingMinutes) min")
                    detailPill("\(match.recipe.servings) servings")
                    detailPill("\(match.coveragePercent)% coverage")
                    if !match.recipe.cuisine.isEmpty {
                        detailPill(match.recipe.cuisine)
                    }
                    detailPill(match.recipe.difficulty.rawValue.capitalized)
                }

                coverageBarForDetail(match: match)

                if !match.rationale.isEmpty {
                    detailSection(title: "Why this recipe") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(match.rationale.enumerated()), id: \.offset) { _, line in
                                Label(line, systemImage: "sparkle")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                    }
                }

                detailSection(title: "Have") {
                    detailIngredientList(match.matchedIngredients, tone: Palette.green)
                }

                if !match.missingIngredients.isEmpty {
                    detailSection(title: "Need") {
                        detailIngredientList(match.missingIngredients, tone: Palette.ember)
                    }
                }

                if let sourceURL = match.recipe.sourceURL {
                    Link(destination: sourceURL) {
                        Label("Open recipe source", systemImage: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.paper)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Palette.ink)
                            )
                    }
                    .accessibilityLabel("Open source for \(match.recipe.title)")
                }
            }
            .padding(24)
        }
        .background(Palette.paper.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailIngredientList(_ items: [String], tone: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(tone.opacity(0.16))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(tone.opacity(0.38), lineWidth: 1)
                    )
            }
        }
    }

    private func detailPill(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Palette.paperLift)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Palette.line, lineWidth: 1)
            )
    }

    private func coverageBarForDetail(match: RecipeMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Coverage")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.muted)
                Spacer()
                Text("\(match.matchedIngredients.count)/\(match.recipe.ingredients.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.muted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Palette.line.opacity(0.45))
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(match.status == .ready ? Palette.green : Palette.gold)
                        .frame(width: max(0, geo.size.width * match.coverage))
                }
            }
            .frame(height: 10)
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
                        shellTag("Milestone 06")
                        shellTag("Core loop polish")
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
                    copy: "Manual intake is solid. Type to add, tap a suggestion, long-press a chip to rename. Data persists across launches."
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

                if !model.suggestions.isEmpty {
                    suggestionStrip
                }

                if let feedback = model.lastAddFeedback, !feedback.isEmpty {
                    feedbackBanner(feedback)
                }

                if let snapshot = model.undoableClearSnapshot {
                    undoBanner(count: snapshot.count)
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
            .accessibilityLabel("Remove \(ingredient.name)")
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
        .contentShape(Capsule(style: .continuous))
        .contextMenu {
            Button {
                model.beginEdit(ingredient.id)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                model.removeIngredient(ingredient.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var suggestionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.suggestions, id: \.self) { suggestion in
                    Button {
                        model.acceptSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Palette.paperLift)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Palette.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add suggestion \(suggestion)")
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func feedbackBanner(_ feedback: AddFeedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.duplicates > 0 && feedback.added == 0
                  ? "exclamationmark.circle"
                  : "checkmark.circle")
                .foregroundStyle(feedback.duplicates > 0 && feedback.added == 0 ? Palette.ember : Palette.green)
            Text(feedback.summary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.ink)
            Spacer()
            Button {
                model.dismissAddFeedback()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.paperLift)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    private func undoBanner(count: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.uturn.backward.circle")
                .foregroundStyle(Palette.ember)
            Text("Cleared \(count). Restore?")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.ink)
            Spacer()
            Button("Undo") {
                model.undoClear()
            }
            .buttonStyle(ShellButtonStyle(kind: .secondary))
            Button {
                model.dismissUndo()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss undo")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.accentSoft.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    private var scanEntryPanel: some View {
        ShellPanel(tint: Palette.accentSoft) {
            ScanEntryPanelView(model: scanModel)
        }
    }

    private var workspacePanel: some View {
        ShellPanel(tint: Palette.stove) {
            VStack(alignment: .leading, spacing: 18) {
                panelHeader(
                    eyebrow: "Recipe workspace",
                    title: "Ready now vs almost there",
                    copy: "Ingredients feed live recipe search, then Chef It explains what you can cook now and what needs a few additions.",
                    foreground: Palette.paper,
                    secondary: Palette.paper.opacity(0.72)
                )

                discoverySummary

                switch model.phase {
                case .needsIngredients:
                    emptyMessage(
                        title: "Waiting on ingredients",
                        body: "Add pantry items manually or scan a photo. Recipe search starts once the board has ingredients."
                    )

                case .staged:
                    stagedWorkspace

                case .loading:
                    loadingWorkspace

                case .failed(let message):
                    failedWorkspace(message)

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
                body: "Ingredients are normalized and ready. Run discovery to search the recipe API, adapt candidates, and match them against the board."
            )

            Button("Run discovery") {
                Task {
                    await model.refreshWorkspace()
                }
            }
            .buttonStyle(ShellButtonStyle(kind: .primary))
        }
    }

    private var loadingWorkspace: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(Palette.paper)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Searching live recipes")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.paper)
                        Text("Chef It is adapting API candidates and ranking them against your board.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.paper.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 8) {
                    loadingBar(widthRatio: 0.82)
                    loadingBar(widthRatio: 0.64)
                    loadingBar(widthRatio: 0.48)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.stoveLift)
            )
        }
    }

    private func failedWorkspace(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            emptyMessage(
                title: "Recipe search needs attention",
                body: message
            )

            HStack(spacing: 10) {
                Button("Try again") {
                    Task {
                        await model.refreshWorkspace()
                    }
                }
                .buttonStyle(ShellButtonStyle(kind: .primary))
                .disabled(model.ingredients.isEmpty)

                if model.ingredients.isEmpty {
                    Text("Add ingredients first.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.paper.opacity(0.68))
                }
            }
        }
    }

    private func resultsWorkspace(snapshot: DiscoveryWorkspaceSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 112), spacing: 10, alignment: .leading)],
                alignment: .leading,
                spacing: 10
            ) {
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

            if snapshot.candidateCount == 0 {
                emptyMessage(
                    title: "No recipes returned",
                    body: "The recipe API did not return candidates for this board. Try fewer ingredients or a broader pantry mix."
                )
            } else if snapshot.results.ready.isEmpty && snapshot.results.almost.isEmpty {
                emptyMessage(
                    title: "Candidates found, but no close matches",
                    body: "Chef It found recipes, but they had too many missing ingredients to be useful yet."
                )
            }

            resultColumn(
                title: "Ready to cook",
                subtitle: "All required ingredients are already on the board.",
                matches: snapshot.results.ready,
                tone: Palette.sage
            )

            resultColumn(
                title: "Almost there",
                subtitle: "API recipes with a manageable missing set stay visible for comparison.",
                matches: snapshot.results.almost,
                tone: Palette.gold
            )
        }
    }

    private func loadingBar(widthRatio: CGFloat) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Palette.paper.opacity(0.12))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Palette.paper.opacity(0.24))
                        .frame(width: geo.size.width * widthRatio)
                }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
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
                        : "This is reserved for recipes that match your board but still need a few additions."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(matches) { match in
                        recipeMatchCard(match, tone: tone)
                    }
                }
            }
        }
    }

    private func recipeMatchCard(_ match: RecipeMatch, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(match.recipe.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.paper)
                    .fixedSize(horizontal: false, vertical: true)

                recipeMetaRow(match, tone: tone)

                Text(match.recipe.blurb)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.paper.opacity(0.72))
                    .lineLimit(3)
            }

            coverageBar(match: match, tone: tone)

            if !match.rationale.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(match.rationale.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("·")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(tone)
                            Text(line)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.paper.opacity(0.86))
                        }
                    }
                }
            }

            if !match.matchedIngredients.isEmpty || !match.missingIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    if !match.matchedIngredients.isEmpty {
                        ingredientChipRow(
                            label: "have",
                            items: match.matchedIngredients,
                            tone: Palette.sage
                        )
                    }
                    if !match.missingIngredients.isEmpty {
                        ingredientChipRow(
                            label: "need",
                            items: match.missingIngredients,
                            tone: Palette.ember
                        )
                    }
                }
            }

            if let sourceURL = match.recipe.sourceURL {
                Link(destination: sourceURL) {
                    compactLinkLabel("Source", systemImage: "arrow.up.right", tone: tone)
                }
                .accessibilityLabel("Open source for \(match.recipe.title)")
            }

            Button {
                selectedRecipeMatch = match
            } label: {
                compactLinkLabel("Details", systemImage: "list.bullet.rectangle", tone: Palette.paper.opacity(0.86))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show details for \(match.recipe.title)")
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(match.recipe.title), \(match.coveragePercent) percent coverage")
    }

    private func recipeMetaRow(_ match: RecipeMatch, tone: Color) -> some View {
        FlowLayout(spacing: 6) {
            recipePill("\(match.recipe.cookingMinutes) min", tone: tone)
            recipePill("\(match.coveragePercent)%", tone: tone)
            recipePill("\(match.matchedIngredients.count)/\(match.recipe.ingredients.count)", tone: Palette.paper.opacity(0.7))
            if !match.recipe.cuisine.isEmpty {
                recipePill(match.recipe.cuisine, tone: Palette.paper.opacity(0.7))
            }
        }
    }

    private func recipePill(_ label: String, tone: Color) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(tone)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Palette.paper.opacity(0.08))
            )
    }

    private func compactLinkLabel(_ label: String, systemImage: String, tone: Color) -> some View {
        Label(label, systemImage: systemImage)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(tone)
    }

    private func coverageBar(match: RecipeMatch, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(match.coveragePercent)% coverage")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.paper.opacity(0.7))
                Spacer()
                Text("\(match.matchedIngredients.count)/\(match.recipe.ingredients.count) ingredients")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.paper.opacity(0.55))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Palette.paper.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(tone)
                        .frame(width: max(0, geo.size.width * match.coverage))
                }
            }
            .frame(height: 6)
        }
    }

    private func ingredientChipRow(label: String, items: [String], tone: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(tone)
                .padding(.top, 5)
                .frame(width: 38, alignment: .leading)
            FlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.paper.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(tone.opacity(0.18))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(tone.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var phaseBadge: some View {
        let label: String
        switch model.phase {
        case .needsIngredients: label = "idle"
        case .staged: label = "staged"
        case .loading: label = "searching"
        case .loaded: label = "grouped"
        case .failed: label = "needs api"
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

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                widestRow = max(widestRow, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        widestRow = max(widestRow, rowWidth - spacing)
        return CGSize(width: widestRow, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
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
