import SwiftUI

struct ChefitSplashView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: ChefitSpacing.md) {
            Spacer()
            RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous)
                .fill(ChefitColors.white)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .fill(ChefitColors.pistachio)
                        .frame(width: 76, height: 76)
                        .overlay(Text("🍞👨‍🍳").font(.system(size: 28)))
                )

            Text("chefit 🌱")
                .font(.custom("PlayfairDisplayRoman-Bold", size: 32))
                .foregroundStyle(ChefitColors.sageGreen)

            Text("scan. cook. enjoy. ❤️")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.sageGreen)
            Text("Smart recipes from what you have.")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.matcha)

            Spacer()

            Text("🍅 🧅 🥑 🌶️ 🧄")
                .font(.system(size: 30))

            Button("Get Started", action: onGetStarted)
                .buttonStyle(ChefitPrimaryButtonStyle())
                .padding(.top, ChefitSpacing.sm)
        }
        .padding(ChefitSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream)
    }
}

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
            Text("Let's get cooking ❤️")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.matcha)

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
        .background(ChefitColors.cream)
    }

    private func authButton(icon: String, title: String) -> some View {
        Button(action: onContinue) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChefitSecondaryButtonStyle())
    }
}
