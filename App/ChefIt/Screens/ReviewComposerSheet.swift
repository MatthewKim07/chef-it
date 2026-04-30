import SwiftUI
import ChefItKit

struct ReviewComposerSheet: View {
    let recipeId: String
    let currentUserId: Int?
    let onSaved: (Review) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var rating = 0
    @State private var bodyText = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var hasExistingReview = false

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            header
            ratingPicker
            reviewBodyField

            if let errorMessage {
                Text(errorMessage)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            }

            Spacer()

            saveButton
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
        .task { await loadExistingReview() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hasExistingReview ? "Update Review" : "Write Review")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)

                Text("Tell other Chefs how it turned out.")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ChefitColors.sageGreen)
                    .frame(width: 34, height: 34)
                    .background(ChefitColors.pistachio)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var ratingPicker: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Text("Your rating")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)

            HStack(spacing: ChefitSpacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(value <= rating ? ChefitColors.honey : ChefitColors.matcha)
                            .frame(width: 40, height: 40)
                            .background(ChefitColors.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
        }
    }

    private var reviewBodyField: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
            Text("Review")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)

            TextEditor(text: $bodyText)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .padding(ChefitSpacing.sm)
                .background(ChefitColors.white)
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous)
                        .stroke(ChefitColors.pistachio, lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveReview() }
        } label: {
            if isSaving {
                HStack(spacing: ChefitSpacing.sm) {
                    ProgressView().tint(ChefitColors.white)
                    Text(hasExistingReview ? "Updating..." : "Saving...")
                }
            } else {
                Text(hasExistingReview ? "Update Review" : "Share Review")
            }
        }
        .buttonStyle(ChefitPrimaryButtonStyle())
        .disabled(isLoading || isSaving || rating == 0)
        .opacity((isLoading || isSaving || rating == 0) ? 0.6 : 1)
    }

    private func loadExistingReview() async {
        guard let currentUserId else {
            isLoading = false
            return
        }

        do {
            let reviews = try await ReviewService.shared.fetchReviews(recipeId: recipeId)
            if let review = reviews.first(where: { $0.userId == currentUserId }) {
                rating = review.rating
                bodyText = review.body ?? ""
                hasExistingReview = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveReview() async {
        isSaving = true
        errorMessage = nil
        do {
            let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
            let review = try await ReviewService.shared.upsertReview(
                recipeId: recipeId,
                rating: rating,
                body: trimmedBody.isEmpty ? nil : trimmedBody
            )
            onSaved(review)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct ReviewRowView: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            HStack(spacing: ChefitSpacing.sm) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.displayName ?? "Chef")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.sageGreen)

                    Text(RelativePostDateFormatter.string(from: review.createdAt))
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(index <= review.rating ? ChefitColors.honey : ChefitColors.matcha)
                    }
                }
            }

            if let body = review.body, !body.isEmpty {
                Text(body)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.text)
            }
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }

    private var avatarView: some View {
        Group {
            if let urlStr = review.avatarURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .overlay(Circle().stroke(ChefitColors.pistachio, lineWidth: 2))
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }
}
