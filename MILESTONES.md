# Chef It Milestones

This document records the current milestone plan for the native iOS Chef It app so teammates can continue work directly from the repo.

## Global Rules

- `reference/pantry-pal` is read-only reference material.
- Do not modify anything inside `reference/pantry-pal`.
- Transfer Pantry Pal behavior, not Pantry Pal UI.
- Keep Chef It native to Swift/SwiftUI.
- Do not silently expand scope into meal planning, shopping lists, or store lookup unless a milestone explicitly allows it.
- Work milestone by milestone.

## Milestone 1: Native iOS Foundation

Status: likely complete

### Goal

- native SwiftUI shell
- ingredient board
- scan entry placeholder
- recipe workspace
- ready vs almost-there structure
- service/model boundaries

### Exit Criteria

- app builds in Xcode
- launches in Simulator
- manual ingredient entry works
- results sections update from local/mock data
- Pantry Pal reference remains untouched

## Milestone 2: Ingredient Intake MVP

### Goal

Make ingredient entry solid before touching camera or real APIs.

### Build

1. A polished manual ingredient intake flow.
2. Ingredient normalization and deduplication.
3. Add, remove, clear, and edit-friendly pantry interactions.
4. Clean persistence for the ingredient board if the current app structure supports it cleanly.
5. Unit tests for ingredient normalization, duplicate handling, and board state updates.

### Requirements

- Keep the Chef It design distinct from Pantry Pal.
- Keep the architecture modular for upcoming scan and recipe milestones.
- Do not add meal planning, shopping, or store lookup.
- Do not add camera capture or API wiring yet.

### Exit Criteria

- pantry editing feels stable
- duplicate/casing/spacing edge cases handled
- app state survives relaunch if persistence is included
- tests cover board logic

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

Context:
- `reference/pantry-pal` is read-only reference material.
- Do not modify anything inside `reference/pantry-pal`.
- Chef It is a native iOS app in Swift/SwiftUI.
- We are working milestone by milestone.
- Do not implement scanning or real recipe API integration yet.

This milestone is only about ingredient intake.

Build:
1. A polished manual ingredient intake flow.
2. Ingredient normalization and deduplication.
3. Add, remove, clear, and edit-friendly pantry interactions.
4. Clean persistence for the ingredient board if the current app structure supports it cleanly.
5. Unit tests for ingredient normalization, duplicate handling, and board state updates.

Requirements:
- Keep the Chef It design distinct from Pantry Pal.
- Keep the architecture modular for upcoming scan and recipe milestones.
- Do not add meal planning, shopping, or store lookup.
- Do not add camera capture or API wiring yet.

Before editing:
- briefly audit the current milestone 1 implementation
- identify any ingredient-board gaps that would block later milestones

Deliverables:
- summary of what changed
- files changed
- manual test steps
- test/build status
- what is deferred to milestone 3
```

## Milestone 3: Recipe Matching MVP

### Goal

Make Pantry Pal’s core recipe behavior real in Chef It.

### Build

1. Implement the candidate discovery pipeline in Chef It.
2. Keep protein-aware query shaping explicit, based on Pantry Pal’s behavior.
3. Implement recipe match scoring and grouping into:
   - Ready now
   - Almost there
4. Improve the recipe workspace so results are understandable and testable.
5. Add unit tests for:
   - protein-aware planning
   - normalization used for matching
   - ready/almost-there grouping
   - stable ranking behavior

### Requirements

- Prefer a clean service boundary so a real recipe API can plug in later.
- If live API integration is not yet appropriate, use a strong mock/local candidate source with realistic behavior.
- Keep UI native to iOS and distinct from Pantry Pal.
- Do not implement scanning yet.
- Do not add meal planning, shopping, or store lookup.

### Exit Criteria

- recipes update from pantry ingredients
- grouping is correct
- ranking is explainable
- tests lock down core matching behavior

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

Context:
- `reference/pantry-pal` is read-only reference material.
- Use Pantry Pal to transfer behavior, not UI.
- The priority for this milestone is recipe matching.

Build the recipe matching MVP:
1. Implement the candidate discovery pipeline in Chef It.
2. Keep protein-aware query shaping explicit, based on Pantry Pal’s behavior.
3. Implement recipe match scoring and grouping into:
   - Ready now
   - Almost there
4. Improve the recipe workspace so results are understandable and testable.
5. Add unit tests for:
   - protein-aware planning
   - normalization used for matching
   - ready/almost-there grouping
   - stable ranking behavior

Requirements:
- Prefer a clean service boundary so a real recipe API can plug in later.
- If live API integration is not yet appropriate, use a strong mock/local candidate source with realistic behavior.
- Keep UI native to iOS and distinct from Pantry Pal.
- Do not implement scanning yet.
- Do not add meal planning, shopping, or store lookup.

Before editing:
- inspect the current planner, matcher, and recipe service
- identify where the current implementation still differs from Pantry Pal’s real behavior

Deliverables:
- summary of matching behavior
- files changed
- exact manual pantry inputs to test
- test/build status
- what is deferred to milestone 4
```

## Milestone 4: Ingredient Scanning

### Goal

Implement the second core feature well, without bloating scope.

### Build

1. Native iOS scan entry flow.
2. Support photo import and, if appropriate, camera capture.
3. A detect -> review -> confirm flow before ingredients are added.
4. Normalization of detected ingredient names into pantry-friendly values.
5. Clean loading, retry, and no-result states.
6. Service boundaries that allow the scan pipeline to call a real backend later, or wire the backend now if the project is already prepared for it cleanly.

### Requirements

- Do not accept raw AI or raw detection output without user confirmation.
- Keep the scan UX lightweight and trustworthy.
- Keep the implementation modular.
- Do not add meal planning, shopping, or store lookup.
- Do not overbuild image processing if a backend-driven flow is the right architecture.

### Exit Criteria

- user can scan/import and confirm ingredients
- raw scan output is never blindly accepted
- scan results land cleanly in pantry board
- failure cases are handled

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

Context:
- `reference/pantry-pal` is read-only reference material.
- This milestone is focused only on ingredient scanning.
- Pantry Pal’s scan flow is the product reference: capture/upload -> detect -> confirm -> add.

Build:
1. Native iOS scan entry flow.
2. Support photo import and, if appropriate, camera capture.
3. A detect -> review -> confirm flow before ingredients are added.
4. Normalization of detected ingredient names into pantry-friendly values.
5. Clean loading, retry, and no-result states.
6. Service boundaries that allow the scan pipeline to call a real backend later, or wire the backend now if the project is already prepared for it cleanly.

Requirements:
- Do not accept raw AI or raw detection output without user confirmation.
- Keep the scan UX lightweight and trustworthy.
- Keep the implementation modular.
- Do not add meal planning, shopping, or store lookup.
- Do not overbuild image processing if a backend-driven flow is the right architecture.

Before editing:
- audit current Chef It ingredient flow and where scan results should enter the state model
- inspect Pantry Pal scan files again and summarize the transferable behavior

Deliverables:
- summary of scan architecture
- files changed
- manual test scenarios
- build/test status
- what is deferred to milestone 5
```

## Milestone 5: Real Recipe API Integration

### Goal

Replace mock/local recipe sourcing with real search.

### Build

1. Real recipe API integration through a clean service layer.
2. Response adaptation into Chef It’s internal recipe models.
3. Deduplication and match scoring after API candidate retrieval.
4. Stable loading, empty, and error handling in the recipe workspace.
5. Tests for adapters and any deterministic ranking logic.

### Requirements

- Keep the API layer isolated.
- Make candidate retrieval, adaptation, and ranking separate concerns.
- Do not add meal planning, shopping, or store lookup.
- Keep the UI focused on ingredient-first discovery.

### Exit Criteria

- real recipes appear
- adapters are stable
- loading/error states are solid
- app still preserves ready/almost-there behavior

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

Context:
- `reference/pantry-pal` is read-only reference material.
- The current milestone should replace placeholder/local recipe sourcing with a real recipe API integration.
- Preserve Chef It’s own UI and architecture.

Build:
1. Real recipe API integration through a clean service layer.
2. Response adaptation into Chef It’s internal recipe models.
3. Deduplication and match scoring after API candidate retrieval.
4. Stable loading, empty, and error handling in the recipe workspace.
5. Tests for adapters and any deterministic ranking logic.

Requirements:
- Keep the API layer isolated.
- Make candidate retrieval, adaptation, and ranking separate concerns.
- Do not add meal planning, shopping, or store lookup.
- Keep the UI focused on ingredient-first discovery.

Before editing:
- inspect the current recipe service boundary
- identify what must change to support real API-backed discovery

Deliverables:
- summary of the real API integration
- files changed
- configuration/setup notes
- manual test steps
- build/test status
- what is deferred to milestone 6
```

## Milestone 6: Product Polish Around the Core

### Goal

Make scanning + matching feel product-ready before expanding scope.

### Build

1. Better result presentation and hierarchy.
2. Better empty/loading/error states.
3. A cleaner recipe detail experience if needed.
4. Accessibility and small-screen usability improvements.
5. Performance and state cleanup where needed.

### Requirements

- Do not add meal planning, shopping, or store lookup yet.
- Only add filters if they materially improve recipe decision-making.
- Keep the app visually distinct from Pantry Pal.
- Prioritize quality of the core experience over adding more features.

### Exit Criteria

- core flow feels coherent end to end
- app is usable and pleasant on iPhone
- no obvious rough edges in scan -> board -> match flow

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

This milestone is about polish, not feature sprawl.

Focus only on improving the core loop:
- add ingredients
- scan ingredients
- discover recipes
- understand ready-now vs almost-there results

Build:
1. Better result presentation and hierarchy.
2. Better empty/loading/error states.
3. A cleaner recipe detail experience if needed.
4. Accessibility and small-screen usability improvements.
5. Performance and state cleanup where needed.

Requirements:
- Do not add meal planning, shopping, or store lookup yet.
- Only add filters if they materially improve recipe decision-making.
- Keep the app visually distinct from Pantry Pal.
- Prioritize quality of the core experience over adding more features.

Before editing:
- audit the current UX for friction points in the core loop

Deliverables:
- summary of UX improvements
- files changed
- manual test steps
- build/test status
- recommendation on whether the app is ready for optional expansion
```

## Optional Milestone 7: One Lightweight Extension

### Goal

Add only one secondary feature after the core is strong.

### Choose One

- lightweight shopping handoff
- lightweight save/favorites flow
- lightweight cooking session mode

Do not add all of Pantry Pal’s extras.

### Prompt

```text
Continue the Chef It iOS app in SwiftUI.

Only proceed if the core ingredient scanning + recipe matching experience is already solid.

Choose exactly one lightweight extension that fits Chef It naturally:
- favorites/saved recipes
- missing-ingredient shopping handoff
- focused cooking mode

Rules:
- Keep it small.
- Do not add meal planning, grocery store lookup, or broad secondary product surfaces.
- This extension should feel like a natural support feature for the core app.

Before editing:
- state which extension you chose and why it is the best next step

Deliverables:
- summary of the extension
- files changed
- manual test steps
- build/test status
```

## Recommended Order From Here

If the current Swift milestone 1 is real, the recommended order is:

1. Milestone 2: Ingredient intake hardening
2. Milestone 3: Recipe matching MVP refinement
3. Milestone 4: Ingredient scanning
4. Milestone 5: Real recipe API integration
5. Milestone 6: Polish
6. Milestone 7: Optional one-feature extension

That order is important. Do not do camera or API first if pantry state and matching logic are still shaky.
