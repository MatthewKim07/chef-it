import SwiftUI
import AuthenticationServices
import ChefItKit

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
                .padding(.bottom, 4)
                .accessibilityLabel("Chefit mascot, chef hat")

            Image("ChefitSplashWordmark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: 320)
                .padding(.horizontal, ChefitSpacing.lg)
                .padding(.top, 12)
                .padding(.bottom, 20)
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
            .padding(.top, 20)
            .padding(.bottom, 28)

            Spacer(minLength: 44)

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

// MARK: - Guest flow (welcome → sign-in options → email auth)

struct ChefitGuestFlowView: View {
    @EnvironmentObject private var authService: AuthService

    /// Linear stack avoids `fullScreenCover` presenting over the welcome screen on some OS versions.
    @State private var path: [GuestDestination] = []
    @State private var isLoadingSocial = false
    @State private var socialError: String?

    private enum GuestDestination: Hashable {
        case authHub
        case emailLogin
        case register
    }

    var body: some View {
        NavigationStack(path: $path) {
            ChefitSplashView {
                path.append(.authHub)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GuestDestination.self) { destination in
                switch destination {
                case .authHub:
                    ChefitAuthView(
                        onBack: {
                            if !path.isEmpty { path.removeLast() }
                        },
                        onEmail: { path.append(.emailLogin) },
                        onGoogle: { performGoogleSignIn() },
                        onApple: { performAppleSignIn() }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .disabled(isLoadingSocial)

                case .emailLogin:
                    LoginView(onNavigateToRegister: {
                        path.append(.register)
                    })
                    .environmentObject(authService)

                case .register:
                    RegisterView()
                        .environmentObject(authService)
                }
            }
        }
        .overlay {
            if isLoadingSocial {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
            }
        }
        .alert("Sign-In Error", isPresented: .constant(socialError != nil)) {
            Button("OK") { socialError = nil }
        } message: {
            Text(socialError ?? "")
        }
    }

    private func performGoogleSignIn() {
        isLoadingSocial = true
        Task {
            let result = await GoogleSignInHandler().signIn()
            switch result {
            case .success(let idToken):
                do {
                    _ = try await authService.signInWithGoogle(idToken: idToken)
                } catch let e as AuthError {
                    socialError = e.errorDescription
                } catch {
                    socialError = "Google sign-in failed. Please try again."
                }
            case .failure(let error):
                socialError = error.localizedDescription
            }
            isLoadingSocial = false
        }
    }

    private func performAppleSignIn() {
        isLoadingSocial = true
        Task {
            let coordinator = AppleSignInCoordinator()
            let result = await coordinator.signIn()
            switch result {
            case .success(let data):
                do {
                    _ = try await authService.signInWithApple(
                        identityToken: data.identityToken,
                        displayName: data.displayName
                    )
                } catch let e as AuthError {
                    socialError = e.errorDescription
                } catch {
                    socialError = "Apple sign-in failed. Please try again."
                }
            case .failure(let error):
                if let authError = error as? ASAuthorizationError,
                   authError.code == .canceled {
                    // User cancelled — no error needed
                } else {
                    socialError = error.localizedDescription
                }
            }
            isLoadingSocial = false
        }
    }
}

// MARK: - Sign-in options (after Get Started)

struct ChefitAuthView: View {
    var onBack: (() -> Void)?
    let onEmail: () -> Void
    var onGoogle: () -> Void = {}
    var onApple: () -> Void = {}

    private let outlineGray = Color(red: 0.78, green: 0.78, blue: 0.78)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    if let onBack {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ChefitColors.sageGreen)
                        .accessibilityLabel("Back to welcome")
                    }
                    Spacer()
                }
                .padding(.horizontal, ChefitSpacing.md)
                .padding(.top, 8)

                Image("ChefitSplashMascot")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ChefitSpacing.md)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .accessibilityLabel("Chefit mascot, chef hat")

                Text("Welcome!")
                    .font(.custom("PlayfairDisplay-Bold", size: 38))
                    .foregroundStyle(ChefitColors.splashBrandGreen)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)

                // Center row + small downward nudge so heart matches text optical midline (PNG sits high in frame).
                HStack(alignment: .center, spacing: 2) {
                    Text("Let's get cooking")
                        .font(.custom("Nunito-Regular", size: 17))
                        .foregroundStyle(Color.black)
                    Image("ChefitAuthHeart")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(.leading, -8)
                        .offset(y: 3)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Let's get cooking")
                .padding(.bottom, 28)

                VStack(spacing: 12) {
                    chefitAuthOutlineButton(
                        title: "Continue with Email",
                        icon: { Image(systemName: "envelope.fill").foregroundStyle(Color.primary) },
                        action: onEmail
                    )
                    chefitAuthOutlineButton(
                        title: "Continue with Google",
                        icon: { googleGlyph },
                        action: onGoogle
                    )
                    chefitAuthOutlineButton(
                        title: "Continue with Apple",
                        icon: { Image(systemName: "apple.logo").font(.system(size: 22, weight: .semibold)) },
                        action: onApple
                    )
                }
                .padding(.horizontal, ChefitSpacing.lg)
                .padding(.bottom, ChefitSpacing.twoXL)
            }
            .frame(maxWidth: .infinity)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private var googleGlyph: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.26, green: 0.52, blue: 0.96),
                        Color(red: 0.92, green: 0.25, blue: 0.21),
                        Color(red: 0.98, green: 0.74, blue: 0.18),
                        Color(red: 0.20, green: 0.66, blue: 0.33)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 24, height: 24)
    }

    private func chefitAuthOutlineButton(
        title: String,
        @ViewBuilder icon: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon()
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.text)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous)
                    .stroke(outlineGray, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Splash") {
    GeometryReader { _ in
        ChefitSplashView(onGetStarted: {})
    }
}

#Preview("Auth options") {
    ChefitAuthView(onBack: {}, onEmail: {})
}
