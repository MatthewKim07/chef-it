import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

public struct ScanEntryPanelView: View {
    @ObservedObject private var model: ScanFlowViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoSelectionRevision = 0
    #if os(iOS)
    @State private var isCameraPresented = false
    #endif

    public init(model: ScanFlowViewModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            milestoneSteps
            sourceControls

            if let feedback = model.lastConfirmFeedback, !feedback.isEmpty {
                feedbackBanner(feedback)
            }

            if let draft = model.draft {
                scanPreviewCard(draft)
            }

            switch model.phase {
            case .idle:
                idleCard
            case .analyzing:
                analyzingCard
            case .review:
                reviewCard
            case .empty:
                statusCard(
                    title: "Nothing detected",
                    message: model.message ?? "No ingredients found."
                )
            case .failed:
                statusCard(
                    title: "Scan failed",
                    message: model.message ?? "Try another image."
                )
            }
        }
        .task(id: photoSelectionRevision) {
            await loadSelectedPhoto()
        }
        #if os(iOS)
        .sheet(isPresented: $isCameraPresented) {
            CameraCaptureView(
                onCapture: { data in
                    isCameraPresented = false
                    Task {
                        await model.beginScan(imageData: data, source: .camera)
                    }
                },
                onCancel: {
                    isCameraPresented = false
                }
            )
            .ignoresSafeArea()
        }
        #endif
    }

    private var photoSelectionBinding: Binding<PhotosPickerItem?> {
        Binding(
            get: { selectedPhotoItem },
            set: { newValue in
                selectedPhotoItem = newValue
                photoSelectionRevision += 1
            }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCAN ENTRY POINT")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(ScanPalette.muted)

            Text("Detect, review, confirm")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(ScanPalette.ink)

            Text("Chef It now supports the Pantry Pal scan pattern directly in the shell: import or capture, inspect detections, then choose what actually lands on the board.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(ScanPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var milestoneSteps: some View {
        HStack(spacing: 10) {
            stepBadge(number: "01", title: "Capture")
            stepBadge(number: "02", title: "Detect")
            stepBadge(number: "03", title: "Confirm")
        }
    }

    private var sourceControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start with a pantry photo")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ScanPalette.ink)

            HStack(spacing: 10) {
                PhotosPicker(selection: photoSelectionBinding, matching: .images) {
                    scanActionLabel("Import photo", systemImage: "photo.on.rectangle")
                }

                #if os(iOS)
                Button {
                    isCameraPresented = true
                } label: {
                    scanActionLabel("Use camera", systemImage: "camera")
                }
                .buttonStyle(.plain)
                .disabled(!isCameraAvailable)
                .opacity(isCameraAvailable ? 1 : 0.45)
                #endif

                if model.phase != .idle {
                    Button("Clear") {
                        selectedPhotoItem = nil
                        model.reset()
                    }
                    .buttonStyle(ScanSecondaryButtonStyle())
                }
            }

            #if os(iOS)
            if !isCameraAvailable {
                Text("Camera capture is unavailable on this simulator. Import a photo to test the flow.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ScanPalette.ember)
            }
            #endif
        }
    }

    private var idleCard: some View {
        infoCard(
            title: "Review comes before add",
            message: "Detected ingredients stay in a review queue until you explicitly confirm them. Nothing is written to the pantry board automatically."
        )
    }

    private var analyzingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(ScanPalette.ink)
                Text("Analyzing the image and normalizing ingredient candidates.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(ScanPalette.ink)
            }

            if let draft = model.draft {
                Text("Source: \(draft.source.label)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ScanPalette.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ScanPalette.paperLift)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review detections")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScanPalette.ink)
                    Text("\(model.selectedCount) of \(model.candidates.count) selected")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ScanPalette.muted)
                }
                Spacer()
                if let draft = model.draft {
                    sourcePill(draft.source.label)
                }
            }

            if let message = model.message {
                inlineMessage(message)
            }

            VStack(spacing: 10) {
                ForEach(model.candidates) { candidate in
                    candidateRow(candidate)
                }
            }

            HStack(spacing: 10) {
                Button("Add selected") {
                    model.confirmSelected()
                }
                .buttonStyle(ScanPrimaryButtonStyle())

                Button("Retry") {
                    Task { await model.retry() }
                }
                .buttonStyle(ScanSecondaryButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ScanPalette.paperLift)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private func statusCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            infoCard(title: title, message: message)

            HStack(spacing: 10) {
                if model.draft != nil {
                    Button("Try again") {
                        Task { await model.retry() }
                    }
                    .buttonStyle(ScanPrimaryButtonStyle())
                }

                Button("Reset") {
                    selectedPhotoItem = nil
                    model.reset()
                }
                .buttonStyle(ScanSecondaryButtonStyle())
            }
        }
    }

    private func scanPreviewCard(_ draft: ScanDraft) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Current image")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScanPalette.ink)
                Spacer()
                sourcePill(draft.source.label)
            }

            #if os(iOS)
            if let preview = UIImage(data: draft.imageData) {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 136)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                previewUnavailable
            }
            #else
            previewUnavailable
            #endif
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ScanPalette.paperLift.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private var previewUnavailable: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(ScanPalette.paper)
            .frame(height: 136)
            .overlay(
                Text("Preview unavailable")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(ScanPalette.muted)
            )
    }

    private func candidateRow(_ candidate: ScanCandidate) -> some View {
        Button {
            model.toggleCandidate(candidate.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(candidate.isSelected ? ScanPalette.green : ScanPalette.muted)

                VStack(alignment: .leading, spacing: 6) {
                    Text(candidate.rawName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScanPalette.ink)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        sourcePill(candidate.canonicalName)
                        categoryPill(candidate.category)
                    }

                    Text("\(Int(candidate.confidence * 100))% confidence")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ScanPalette.muted)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(candidate.isSelected ? ScanPalette.paper : ScanPalette.paper.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(candidate.isSelected ? ScanPalette.green.opacity(0.65) : ScanPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func feedbackBanner(_ feedback: AddFeedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(ScanPalette.green)
            Text(feedback.summary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ScanPalette.ink)
            Spacer()
            Button {
                model.dismissFeedback()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ScanPalette.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss scan feedback")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ScanPalette.accentSoft.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private func inlineMessage(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ScanPalette.ember)
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ScanPalette.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ScanPalette.paper)
        )
    }

    private func infoCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(ScanPalette.ink)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(ScanPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ScanPalette.paperLift)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private func stepBadge(number: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(ScanPalette.ink)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ScanPalette.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ScanPalette.paper.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ScanPalette.line, lineWidth: 1)
        )
    }

    private func scanActionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(ScanPalette.paper)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(ScanPalette.ink)
            )
    }

    private func sourcePill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ScanPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(ScanPalette.paper)
            )
    }

    private func categoryPill(_ category: IngredientCategory) -> some View {
        Text(category.rawValue.capitalized)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(categoryColor(for: category))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(categoryColor(for: category).opacity(0.14))
            )
    }

    private func categoryColor(for category: IngredientCategory) -> Color {
        switch category {
        case .produce:
            return ScanPalette.green
        case .protein:
            return ScanPalette.gold
        case .dairy:
            return ScanPalette.blue
        case .pantry:
            return ScanPalette.ember
        case .spice:
            return ScanPalette.plum
        case .grain:
            return ScanPalette.sand
        case .condiment:
            return ScanPalette.blue
        case .other:
            return ScanPalette.muted
        }
    }

    private func loadSelectedPhoto() async {
        guard photoSelectionRevision > 0 else { return }
        guard let selectedPhotoItem else { return }
        guard let data = try? await selectedPhotoItem.loadTransferable(type: Data.self) else {
            await model.beginScan(imageData: Data(), source: .photoLibrary)
            return
        }
        await model.beginScan(imageData: data, source: .photoLibrary)
    }

    #if os(iOS)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    #endif
}

private struct ScanPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(ScanPalette.paper)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(ScanPalette.ink.opacity(configuration.isPressed ? 0.82 : 1))
            )
    }
}

private struct ScanSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(ScanPalette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(ScanPalette.paper.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ScanPalette.line, lineWidth: 1)
            )
    }
}

private enum ScanPalette {
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.90)
    static let paperLift = Color(red: 0.96, green: 0.92, blue: 0.86)
    static let ink = Color(red: 0.17, green: 0.16, blue: 0.18)
    static let muted = Color(red: 0.36, green: 0.33, blue: 0.31)
    static let line = Color(red: 0.76, green: 0.69, blue: 0.61)
    static let accentSoft = Color(red: 0.97, green: 0.80, blue: 0.63)
    static let ember = Color(red: 0.71, green: 0.31, blue: 0.18)
    static let gold = Color(red: 0.90, green: 0.72, blue: 0.34)
    static let green = Color(red: 0.39, green: 0.63, blue: 0.39)
    static let blue = Color(red: 0.43, green: 0.58, blue: 0.74)
    static let plum = Color(red: 0.55, green: 0.42, blue: 0.62)
    static let sand = Color(red: 0.79, green: 0.66, blue: 0.47)
}
