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

            ChefitSplashChefHatPlaceholder()
                .padding(.bottom, 28)

            Text("chefit")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(ChefitColors.splashBrandGreen)
                .tracking(-0.5)
                .padding(.bottom, 14)

            HStack(alignment: .center, spacing: 6) {
                Text("scan. cook. enjoy.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.black)
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ChefitColors.splashButtonGradientTop)
            }
            .padding(.bottom, 36)

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

// MARK: - Chef hat placeholder (replace with asset when ready)

private struct ChefitSplashChefHatPlaceholder: View {
    private let outline: CGFloat = 5

    var body: some View {
        ZStack {
            ZStack {
                Ellipse()
                    .fill(ChefitColors.white)
                    .stroke(ChefitColors.splashHatOutline, lineWidth: outline)
                    .frame(width: 168, height: 122)
                    .offset(y: -44)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ChefitColors.white)
                    .stroke(ChefitColors.splashHatOutline, lineWidth: outline)
                    .frame(width: 178, height: 54)
                    .offset(y: 36)
            }

            HStack(spacing: -2) {
                ChefitSplashLeafShape()
                    .fill(ChefitColors.splashLeafGreen)
                    .frame(width: 24, height: 30)
                    .rotationEffect(.degrees(-28))
                ChefitSplashLeafShape()
                    .fill(ChefitColors.splashLeafGreen)
                    .frame(width: 24, height: 30)
                    .rotationEffect(.degrees(28))
            }
            .offset(y: -72)

            ZStack {
                HStack(spacing: 56) {
                    Circle()
                        .fill(ChefitColors.splashBlush.opacity(0.55))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(ChefitColors.splashBlush.opacity(0.55))
                        .frame(width: 16, height: 16)
                }
                .offset(y: 34)

                HStack(spacing: 30) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 9, height: 9)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 9, height: 9)
                }
                .offset(y: 24)

                ChefitSplashSmileCurve()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 30, height: 14)
                    .offset(y: 38)
            }
            .offset(y: 4)
        }
        .frame(width: 220, height: 210)
        .accessibilityLabel("Chefit logo, chef hat with a smile")
    }
}

private struct ChefitSplashLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

private struct ChefitSplashSmileCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
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
    GeometryReader { _ in
        ChefitSplashView(onGetStarted: {})
    }
}
