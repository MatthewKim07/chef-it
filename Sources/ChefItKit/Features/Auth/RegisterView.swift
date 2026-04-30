import SwiftUI

public struct RegisterView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init() {}

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
                        Spacer().frame(height: 20)

                        Image("ChefitSplashWordmark")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(maxWidth: 176)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 22)
                            .accessibilityLabel("Chefit")

                        VStack(spacing: 12) {
                            Text("Welcome, Chef.")
                                .font(.custom("Nunito-Bold", size: 28))
                                .foregroundColor(BrandColor.text)
                                .multilineTextAlignment(.center)

                            Text("Create your account")
                                .font(.custom("Nunito-Bold", size: 17))
                                .foregroundColor(BrandColor.sageGreen)
                                .multilineTextAlignment(.center)

                            Text("Join the kitchen, Chef.")
                                .font(.custom("Nunito-Regular", size: 15))
                                .foregroundColor(BrandColor.matcha)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 36)

                        VStack(spacing: 16) {
                            brandTextField(placeholder: "Your chef name (optional)", text: $displayName)
                                .textContentType(.name)

                            brandEmailField(placeholder: "Email", text: $email)

                            brandSecureField(placeholder: "Password", text: $password)
                                .textContentType(.newPassword)
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

                        Button(action: register) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(isLoading || email.isEmpty || password.isEmpty
                                          ? BrandColor.peach.opacity(0.5)
                                          : BrandColor.peach)
                                    .frame(height: 52)
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .font(.custom("Nunito-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                        Button { dismiss() } label: {
                            (Text("Already have an account? ")
                                .foregroundColor(BrandColor.text.opacity(0.6))
                             + Text("Log in")
                                .foregroundColor(BrandColor.sageGreen))
                            .font(.custom("Nunito-SemiBold", size: 14))
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func register() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                _ = try await authService.register(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                // AuthService.isLoggedIn flips to true → RootView transitions automatically
            } catch let e as AuthError {
                errorMessage = e.errorDescription
                isLoading = false
            } catch {
                errorMessage = "Something went wrong. Please try again."
                isLoading = false
            }
        }
    }
}
