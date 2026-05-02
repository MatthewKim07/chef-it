import SwiftUI
import ChefItKit

struct ChefitSettingsView: View {
    let onBack: () -> Void
    let onAccountDeleted: () -> Void

    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: ChefitSpacing.lg) {
                    accountSection
                    dangerSection
                }
                .padding(.horizontal, ChefitSpacing.md)
                .padding(.top, ChefitSpacing.md)
                .padding(.bottom, ChefitSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream.ignoresSafeArea())
        .sheet(isPresented: $showChangeEmail) {
            ChefitChangeEmailSheet()
        }
        .sheet(isPresented: $showChangePassword) {
            ChefitChangePasswordSheet()
        }
        .sheet(isPresented: $showDeleteAccount) {
            ChefitDeleteAccountSheet(onAccountDeleted: onAccountDeleted)
        }
    }

    private var header: some View {
        ZStack {
            Text("Settings")
                .font(.custom("Nunito-Bold", size: 22))
                .foregroundStyle(ChefitColors.text)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ChefitColors.sageGreen)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.sm)
        .padding(.bottom, ChefitSpacing.md)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Text("Account")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.matcha)
                .padding(.leading, ChefitSpacing.xs)

            VStack(spacing: 0) {
                ChefitProfileMenuRow(label: "Change Email") { showChangeEmail = true }
                ChefitProfileMenuRow(label: "Change Password") { showChangePassword = true }
            }
            .padding(.horizontal, ChefitSpacing.md)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            .chefitCardShadow()
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Text("Danger Zone")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.peach)
                .padding(.leading, ChefitSpacing.xs)

            Button {
                showDeleteAccount = true
            } label: {
                HStack {
                    Text("Delete Account")
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.peach)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ChefitColors.peach.opacity(0.6))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, ChefitSpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            .chefitCardShadow()
        }
    }
}

// MARK: - Change Email

struct ChefitChangeEmailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newEmail = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private var canSubmit: Bool {
        !newEmail.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Text("Change Email")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Button("Cancel") { dismiss() }
                    .foregroundStyle(ChefitColors.matcha)
            }

            Text("New Email")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            TextField("you@example.com", text: $newEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .settingsField()

            Text("Current Password")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            SecureField("Enter your password", text: $password)
                .settingsField()

            if let error {
                Text(error)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            }

            Button {
                Task { await submit() }
            } label: {
                if isSubmitting {
                    ProgressView().tint(ChefitColors.white)
                } else {
                    Text("Update Email")
                }
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)

            Spacer()
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
        .alert("Email Updated", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your email has been changed.")
        }
    }

    private func submit() async {
        error = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await AuthService.shared.changeEmail(
                password: password,
                newEmail: newEmail.trimmingCharacters(in: .whitespaces)
            )
            showSuccess = true
        } catch let authError as AuthError {
            error = authError.userMessage
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Change Password

struct ChefitChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var error: String?
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private var canSubmit: Bool {
        !current.isEmpty && new.count >= 6 && new == confirm && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Text("Change Password")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Button("Cancel") { dismiss() }
                    .foregroundStyle(ChefitColors.matcha)
            }

            Text("Current Password")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            SecureField("Enter current password", text: $current)
                .settingsField()

            Text("New Password")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            SecureField("At least 6 characters", text: $new)
                .settingsField()

            Text("Confirm New Password")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            SecureField("Re-enter new password", text: $confirm)
                .settingsField()

            if !confirm.isEmpty && new != confirm {
                Text("Passwords don't match")
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            }

            if let error {
                Text(error)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            }

            Button {
                Task { await submit() }
            } label: {
                if isSubmitting {
                    ProgressView().tint(ChefitColors.white)
                } else {
                    Text("Update Password")
                }
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)

            Spacer()
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been changed.")
        }
    }

    private func submit() async {
        error = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await AuthService.shared.changePassword(currentPassword: current, newPassword: new)
            showSuccess = true
        } catch let authError as AuthError {
            error = authError.userMessage
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Delete Account

struct ChefitDeleteAccountSheet: View {
    let onAccountDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmText = ""
    @State private var error: String?
    @State private var isSubmitting = false
    @State private var showFinalConfirm = false

    private var canSubmit: Bool {
        !password.isEmpty
            && confirmText == "DELETE"
            && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Text("Delete Account")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.peach)
                Spacer()
                Button("Cancel") { dismiss() }
                    .foregroundStyle(ChefitColors.matcha)
            }

            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                HStack(spacing: ChefitSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ChefitColors.peach)
                    Text("This cannot be undone")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.peach)
                }

                Text("Deleting your account will permanently remove your profile, posts, comments, reviews, and follows. This action is irreversible.")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.text.opacity(0.75))
            }
            .padding(ChefitSpacing.md)
            .background(ChefitColors.peach.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

            Text("Password")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            SecureField("Enter your password", text: $password)
                .settingsField()

            Text("Type DELETE to confirm")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            TextField("DELETE", text: $confirmText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .settingsField()

            if let error {
                Text(error)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            }

            Button {
                showFinalConfirm = true
            } label: {
                if isSubmitting {
                    ProgressView().tint(ChefitColors.white)
                } else {
                    Text("Delete My Account")
                }
            }
            .buttonStyle(ChefitDangerButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)

            Spacer()
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
        .alert("Permanently Delete Account?", isPresented: $showFinalConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                Task { await submit() }
            }
        } message: {
            Text("This will erase your account and all associated content. You won't be able to recover it.")
        }
    }

    private func submit() async {
        error = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await AuthService.shared.deleteAccount(password: password)
            dismiss()
            onAccountDeleted()
        } catch let authError as AuthError {
            error = authError.userMessage
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Helpers

private struct ChefitDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChefitTypography.button())
            .foregroundStyle(ChefitColors.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(ChefitColors.peach.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous))
    }
}

private extension View {
    func settingsField() -> some View {
        self
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.vertical, 12)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous)
                    .stroke(ChefitColors.matcha.opacity(0.4), lineWidth: 1)
            )
    }
}

private extension AuthError {
    var userMessage: String {
        switch self {
        case .invalidCredentials: return "Incorrect password."
        case .emailAlreadyRegistered: return "That email is already in use."
        case .networkError(let m): return m
        case .serverError(let m): return m
        }
    }
}
