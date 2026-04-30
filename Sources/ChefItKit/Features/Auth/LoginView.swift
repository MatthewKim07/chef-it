import SwiftUI

public struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    /// When set (e.g. from app `NavigationStack`), pushes register instead of presenting a sheet.
    private let onNavigateToRegister: (() -> Void)?

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    public init(onNavigateToRegister: (() -> Void)? = nil) {
        self.onNavigateToRegister = onNavigateToRegister
    }

    public var body: some View {
        ZStack {
            BrandColor.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(BrandColor.sageGreen)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 24)

                        Image("ChefitSplashWordmark")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 20)
                            .accessibilityLabel("Chefit")

                        VStack(spacing: 10) {
                            Text("Welcome back, Chef.")
                                .font(.custom("Nunito-Bold", size: 28))
                                .foregroundColor(BrandColor.text)
                                .multilineTextAlignment(.center)

                            Text("Log in to your account")
                                .font(.custom("Nunito-Regular", size: 15))
                                .foregroundColor(BrandColor.matcha)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 40)

                        VStack(spacing: 16) {
                            brandEmailField(placeholder: "Email", text: $email)

                            brandSecureField(placeholder: "Password", text: $password)
                                .textContentType(.password)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, errorMessage != nil ? 16 : 32)

                        if let error = errorMessage {
                            Text(error)
                                .font(.custom("Nunito-Regular", size: 13))
                                .foregroundColor(Color(hex: "#B94040"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 16)
                        }

                        Button(action: login) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(isLoading || email.isEmpty || password.isEmpty
                                          ? BrandColor.peach.opacity(0.5)
                                          : BrandColor.peach)
                                    .frame(height: 52)
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Log In")
                                        .font(.custom("Nunito-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                        Button {
                            if let onNavigateToRegister {
                                onNavigateToRegister()
                            } else {
                                showRegister = true
                            }
                        } label: {
                            (Text("New here? ")
                                .foregroundColor(BrandColor.text.opacity(0.6))
                             + Text("Create an account")
                                .foregroundColor(BrandColor.sageGreen))
                            .font(.custom("Nunito-SemiBold", size: 14))
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(authService)
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func login() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                _ = try await authService.login(email: email, password: password)
            } catch let e as AuthError {
                errorMessage = e.errorDescription
            } catch {
                errorMessage = "Something went wrong. Please try again."
            }
            isLoading = false
        }
    }
}

// MARK: - Shared brand field builders

func brandTextField(placeholder: String, text: Binding<String>) -> some View {
    TextField(placeholder, text: text)
        .brandFieldChrome()
}

@ViewBuilder
func brandEmailField(placeholder: String, text: Binding<String>) -> some View {
    #if os(iOS)
    TextField(placeholder, text: text)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .brandFieldChrome()
    #else
    TextField(placeholder, text: text)
        .brandFieldChrome()
    #endif
}

func brandSecureField(placeholder: String, text: Binding<String>) -> some View {
    SecureField(placeholder, text: text)
        .brandFieldChrome()
}

private extension View {
    func brandFieldChrome() -> some View {
        self
        .font(.custom("Nunito-Regular", size: 15))
        .foregroundColor(BrandColor.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(BrandColor.matcha, lineWidth: 1))
    }
}
