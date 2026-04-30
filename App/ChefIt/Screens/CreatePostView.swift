import SwiftUI
import PhotosUI
import UIKit
import ChefItKit

// MARK: - Create Post

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var previewImage: Image?
    @State private var caption = ""
    @State private var recipeId = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    var onPosted: ((Post) -> Void)?
    private let previewHeight: CGFloat = 320

    private var canPost: Bool {
        imageData != nil && !caption.trimmingCharacters(in: .whitespaces).isEmpty && !isPosting
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: ChefitSpacing.md) {
                    navBar
                    imagePicker
                    captionField
                    recipeField
                    if let msg = errorMessage { errorBanner(msg) }
                    postButton
                        .padding(.bottom, ChefitSpacing.twoXL)
                }
                .frame(width: proxy.size.width)
            }
            .scrollClipDisabled(false)
            .scrollBounceBehavior(.basedOnSize)
            .background(ChefitColors.cream.ignoresSafeArea())
        }
    }

    // MARK: Nav

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ChefitColors.sageGreen)
                    .frame(width: 34, height: 34)
                    .background(ChefitColors.pistachio)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("New Post")
                .font(ChefitTypography.h2())
                .foregroundStyle(ChefitColors.sageGreen)

            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.md)
    }

    // MARK: Image picker

    private var imagePicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                if let previewImage {
                    previewImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(ChefitColors.pistachio.opacity(0.35))

                    VStack {
                        HStack {
                            Spacer()
                            Label("Change", systemImage: "photo")
                                .font(ChefitTypography.label())
                                .foregroundStyle(ChefitColors.white)
                                .padding(.horizontal, ChefitSpacing.sm)
                                .padding(.vertical, ChefitSpacing.xs)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Capsule())
                                .padding(ChefitSpacing.sm)
                        }
                        Spacer()
                    }
                } else {
                    VStack(spacing: ChefitSpacing.sm) {
                        Image(systemName: "camera.circle")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(ChefitColors.matcha)
                        Text("Tap to add your photo")
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.matcha)
                        Text("Share what you cooked!")
                            .font(ChefitTypography.micro())
                            .foregroundStyle(ChefitColors.matcha.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .background(ChefitColors.pistachio.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                            .foregroundStyle(ChefitColors.matcha)
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))
            .padding(.horizontal, ChefitSpacing.md)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task { await loadSelectedImage(item) }
        }
    }

    // MARK: Caption

    private var captionField: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
            Text("Caption")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            TextEditor(text: $caption)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .scrollContentBackground(.hidden)
                .frame(height: 96)
                .padding(ChefitSpacing.sm)
                .background(ChefitColors.pistachio.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous)
                        .stroke(ChefitColors.matcha, lineWidth: 1)
                )
        }
        .padding(.horizontal, ChefitSpacing.md)
    }

    // MARK: Recipe field

    private var recipeField: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
            Text("Recipe link (optional)")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            TextField("Recipe ID from Edamam", text: $recipeId)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .padding(.horizontal, ChefitSpacing.md)
                .padding(.vertical, 12)
                .background(ChefitColors.pistachio.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous)
                        .stroke(ChefitColors.matcha, lineWidth: 1)
                )
        }
        .padding(.horizontal, ChefitSpacing.md)
    }

    // MARK: Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: ChefitSpacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(ChefitColors.peach)
            Text(message)
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ChefitColors.matcha)
            }
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.peach.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
        .padding(.horizontal, ChefitSpacing.md)
    }

    // MARK: Post button

    private var postButton: some View {
        Button {
            Task { await submitPost() }
        } label: {
            if isPosting {
                HStack(spacing: ChefitSpacing.sm) {
                    ProgressView().tint(ChefitColors.white)
                    Text("Posting…")
                }
            } else {
                Text("Share Post")
            }
        }
        .buttonStyle(ChefitPrimaryButtonStyle())
        .disabled(!canPost)
        .opacity(canPost ? 1 : 0.55)
        .padding(.horizontal, ChefitSpacing.md)
    }

    // MARK: Submit

    private func submitPost() async {
        guard let data = imageData else { return }
        isPosting = true
        errorMessage = nil
        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespaces)
            let trimmedRecipe  = recipeId.trimmingCharacters(in: .whitespaces)
            let post = try await PostService.shared.createPost(
                caption: trimmedCaption,
                imageData: data,
                recipeId: trimmedRecipe.isEmpty ? nil : trimmedRecipe
            )
            onPosted?(post)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPosting = false
    }

    private func loadSelectedImage(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let (uiImage, normalizedData) = normalizeImageData(data) else { return }
        imageData = normalizedData
        previewImage = Image(uiImage: uiImage)
    }

    private func normalizeImageData(_ data: Data) -> (UIImage, Data)? {
        guard let sourceImage = UIImage(data: data) else { return nil }

        // Force a stable orientation and cap large dimensions so preview/upload
        // behave consistently across image types and aspect ratios.
        let maxDimension: CGFloat = 1600
        let largestSide = max(sourceImage.size.width, sourceImage.size.height)
        let scale = largestSide > 0 ? min(1, maxDimension / largestSide) : 1
        let targetSize = CGSize(
            width: max(1, sourceImage.size.width * scale),
            height: max(1, sourceImage.size.height * scale)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalizedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        let normalizedData = normalizedImage.jpegData(compressionQuality: 0.9) ?? data

        return (normalizedImage, normalizedData)
    }
}

// MARK: - Post Detail Sheet

struct PostDetailSheet: View {
    let post: Post
    let isOwnPost: Bool
    let onDelete: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                // Nav
                HStack {
                    authorRow
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ChefitColors.sageGreen)
                            .frame(width: 34, height: 34)
                            .background(ChefitColors.pistachio)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Image
                if let urlStr = post.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                        } else {
                            RoundedRectangle(cornerRadius: ChefitRadius.lg)
                                .fill(ChefitColors.pistachio)
                                .overlay {
                                    ProgressView().tint(ChefitColors.matcha)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(ChefitColors.pistachio.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))
                }

                // Caption
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption)
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.text)
                }

                // Recipe link
                if let recipeId = post.recipeId, !recipeId.isEmpty {
                    HStack(spacing: ChefitSpacing.xs) {
                        Image(systemName: "link")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ChefitColors.matcha)
                        Text(recipeId)
                            .font(ChefitTypography.micro())
                            .foregroundStyle(ChefitColors.matcha)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, ChefitSpacing.sm)
                    .padding(.vertical, ChefitSpacing.xs)
                    .background(ChefitColors.pistachio)
                    .clipShape(Capsule())
                }

                // Delete (own post only)
                if isOwnPost {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        if isDeleting {
                            HStack(spacing: ChefitSpacing.sm) {
                                ProgressView().tint(ChefitColors.peach)
                                Text("Deleting…")
                            }
                        } else {
                            Label("Delete Post", systemImage: "trash")
                        }
                    }
                    .font(ChefitTypography.button())
                    .foregroundStyle(ChefitColors.peach)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous)
                            .stroke(ChefitColors.peach, lineWidth: 1.5)
                    )
                    .disabled(isDeleting)
                    .padding(.top, ChefitSpacing.sm)
                }
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, ChefitSpacing.twoXL)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    await onDelete()
                    isDeleting = false
                    dismiss()
                }
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var authorRow: some View {
        HStack(spacing: ChefitSpacing.sm) {
            Group {
                if let urlStr = post.avatarURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else { avatarPlaceholder }
                    }
                } else { avatarPlaceholder }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(ChefitColors.pistachio, lineWidth: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(post.displayName ?? "Chef")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)
                Text(relativeDate(from: post.createdAt))
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }
        }
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

    private func relativeDate(from iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return "" }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60  { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
