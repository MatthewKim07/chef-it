import SwiftUI

struct ChefitSplashView: View {
    let onGetStarted: () -> Void

    private let ingredientPlaceholderSymbols: [(String, Color)] = [
        ("flame.fill", ChefitColors.peach),
        ("sparkles", ChefitColors.matcha),
        ("circle.hexagonpath.fill", ChefitColors.splashIconPumpkin),
        ("circle.circle.fill", ChefitColors.splashBrandGreen),
        ("leaf.fill", ChefitColors.splashBrandGreen),
        ("flame.fill", ChefitColors.peach),
        ("leaf.circle.fill", ChefitColors.splashLeafGreen),
        ("carrot.fill", ChefitColors.splashIconTomatoRed)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            Image("ChefitSplashMascot")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityLabel("Chefit mascot, chef hat")

            Image("ChefitSplashWordmark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: 320)
                .padding(.horizontal, ChefitSpacing.lg)
                .padding(.top, 24)
                .padding(.bottom, 36)
                .accessibilityLabel("Chefit, scan cook enjoy")

            HStack(spacing: 14) {
                ForEach(Array(ingredientPlaceholderSymbols.enumerated()), id: \.offset) { _, item in
                    Image(systemName: item.0)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(item.1)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, ChefitSpacing.sm)
            .padding(.bottom, 28)

            HStack(spacing: 10) {
                Circle()
                    .fill(ChefitColors.splashBrandGreen)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(ChefitColors.splashDotInactive)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(ChefitColors.splashDotInactive)
                    .frame(width: 8, height: 8)
            }
            .padding(.bottom, 20)

            Spacer(minLength: 24)

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [
                                ChefitColors.splashButtonGradientTop,
                                ChefitColors.splashButtonGradientBottom
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: ChefitColors.splashButtonGradientTop.opacity(0.45), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ChefitSpacing.xl)
            .padding(.bottom, ChefitSpacing.twoXL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.splashBackground.ignoresSafeArea())
    }
}

// MARK: - Auth

struct ChefitAuthView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Image(systemName: "chevron.left")
                Text("chefit")
                    .font(ChefitTypography.label())
                Spacer()
            }
            .foregroundStyle(ChefitColors.sageGreen)

            Text("Welcome!")
                .font(ChefitTypography.h1())
                .foregroundStyle(ChefitColors.sageGreen)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Let's get cooking")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
                Image(systemName: ChefitSymbol.heart)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ChefitColors.peach)
            }

            authButton(icon: "envelope", title: "Continue with Email")
            authButton(icon: "g.circle", title: "Continue with Google")
            authButton(icon: "apple.logo", title: "Continue with Apple")

            HStack {
                Rectangle().fill(ChefitColors.matcha.opacity(0.4)).frame(height: 1)
                Text("or").font(ChefitTypography.label()).foregroundStyle(ChefitColors.matcha)
                Rectangle().fill(ChefitColors.matcha.opacity(0.4)).frame(height: 1)
            }

            Button("Log In", action: onContinue)
                .font(ChefitTypography.button())
                .foregroundStyle(ChefitColors.sageGreen)
                .underline()

            Spacer()
        }
        .padding(ChefitSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private func authButton(icon: String, title: String) -> some View {
        Button(action: onContinue) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChefitSecondaryButtonStyle())
    }
}

#Preview("Splash") {
    ChefitSplashView(onGetStarted: {})
}
