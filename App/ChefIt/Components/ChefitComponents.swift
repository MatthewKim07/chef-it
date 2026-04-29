import SwiftUI

enum ChefitTab: Hashable {
    case home
    case search
    case scan
    case saved
    case profile
    case community
}

struct ChefitBottomNavBar: View {
    let activeTab: ChefitTab
    let onTap: (ChefitTab) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: ChefitSpacing.md) {
            navItem(title: "Home", icon: "house", tab: .home)
            navItem(title: "Search", icon: "magnifyingglass", tab: .search)
            scanButton
            navItem(title: "Saved", icon: "heart", tab: .saved)
            navItem(title: "Profile", icon: "person", tab: .profile)
        }
        .padding(.horizontal, ChefitSpacing.lg)
        .padding(.top, ChefitSpacing.sm)
        .padding(.bottom, ChefitSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(ChefitColors.white)
        .chefitNavShadow()
    }

    private func navItem(title: String, icon: String, tab: ChefitTab) -> some View {
        let isActive = activeTab == tab
        return Button {
            onTap(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive ? ChefitColors.sageGreen : ChefitColors.matcha)
                Text(title)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(isActive ? ChefitColors.sageGreen : ChefitColors.matcha)
                Circle()
                    .fill(isActive ? ChefitColors.sageGreen : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var scanButton: some View {
        Button {
            onTap(.scan)
        } label: {
            ZStack {
                Circle()
                    .fill(ChefitColors.peach)
                    .frame(width: 56, height: 56)
                    .chefitPrimaryButtonShadow()
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(ChefitColors.white)
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct ChefitRecipeCard: View {
    let title: String
    let imageURL: URL?
    let cookingMinutes: Int
    let difficulty: String
    @Binding var isFavorite: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ChefitRadius.md)
                            .fill(ChefitColors.pistachio)
                    }
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isFavorite ? ChefitColors.peach : ChefitColors.matcha)
                            .padding(ChefitSpacing.sm)
                            .background(Circle().fill(ChefitColors.white.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                    .padding(ChefitSpacing.sm)
                }

                Text(title)
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)
                    .lineLimit(2)

                HStack(spacing: ChefitSpacing.xs) {
                    Image(systemName: "clock")
                        .foregroundStyle(ChefitColors.matcha)
                    Text("\(cookingMinutes) min")
                    Text("·")
                    Text(difficulty)
                }
                .font(ChefitTypography.micro())
                .foregroundStyle(ChefitColors.matcha)
            }
            .padding(ChefitSpacing.sm)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            .chefitCardShadow()
        }
        .buttonStyle(.plain)
    }
}

struct ChefitIngredientChip: View {
    let label: String
    let icon: String
    var showsRemove: Bool = false
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: ChefitSpacing.xs) {
            Text(icon)
            Text(label)
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            if showsRemove {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ChefitColors.sageGreen)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ChefitSpacing.sm)
        .padding(.vertical, ChefitSpacing.xs)
        .background(ChefitColors.pistachio)
        .overlay(
            Capsule(style: .continuous)
                .stroke(ChefitColors.matcha, lineWidth: 1)
        )
        .clipShape(Capsule(style: .continuous))
    }
}

struct ChefitSearchBar: View {
    let placeholder: String
    let showsFilter: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ChefitSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ChefitColors.matcha)
                Text(placeholder)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsFilter {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(ChefitColors.sageGreen)
                }
            }
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.vertical, 12)
            .background(ChefitColors.white)
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ChefitSectionHeader: View {
    let title: String
    var showsSeeAll: Bool = true
    var seeAllAction: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(ChefitTypography.h2())
                .foregroundStyle(ChefitColors.sageGreen)
            Spacer()
            if showsSeeAll {
                Button("See all") {
                    seeAllAction?()
                }
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.peach)
            }
        }
    }
}

struct ChefitCategoryBubble: View {
    let icon: String
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: ChefitSpacing.sm) {
                Text(icon)
                    .font(.system(size: 28))
                    .frame(width: 64, height: 64)
                    .background(ChefitColors.pistachio)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))
                Text(label)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.sageGreen)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct ChefitStepRow: View {
    let stepNumber: Int
    let text: String
    var icon: String?

    var body: some View {
        HStack(spacing: ChefitSpacing.sm) {
            Text("\(stepNumber)")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.white)
                .frame(width: 28, height: 28)
                .background(ChefitColors.peach)
                .clipShape(Circle())

            Text(text)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let icon {
                Text(icon)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ChefitColors.matcha)
        }
        .padding(.vertical, ChefitSpacing.xs)
    }
}

struct ChefitProfileMenuRow: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ChefitColors.matcha)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ChefitColors.pistachio)
                .frame(height: 1)
        }
    }
}

struct ChefitPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChefitTypography.button())
            .foregroundStyle(ChefitColors.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(ChefitColors.peach.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous))
            .chefitPrimaryButtonShadow()
    }
}

struct ChefitSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChefitTypography.button())
            .foregroundStyle(ChefitColors.sageGreen)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous)
                    .stroke(ChefitColors.sageGreen, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct FlowLayout: Layout {
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
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
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
