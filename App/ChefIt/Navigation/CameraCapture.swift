import SwiftUI
import UIKit
import ChefItKit

struct CameraCapture: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    let onImageCaptured: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (Data) -> Void
        let onCancel: () -> Void

        init(onImageCaptured: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
        }

        private static let maxInputBytes = 2 * 1024 * 1024  // 2MB pre-compression guard

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            print("[CameraCapture] didFinishPicking fired")
            guard let image = info[.originalImage] as? UIImage else {
                print("[CameraCapture] No image in info")
                onCancel()
                return
            }
            guard let data = preprocessed(image) else {
                print("[CameraCapture] preprocessed returned nil")
                onCancel()
                return
            }
            print("[CameraCapture] Image ready: \(data.count) bytes")
            onImageCaptured(data)
        }

        private func preprocessed(_ image: UIImage) -> Data? {
            // Use 1024px for label/text legibility; do not upscale
            let resizedImage = resized(image, maxDimension: 1024)

            // Try quality levels until under 500KB (sweet spot for token cost vs clarity)
            for quality in [0.75, 0.60, 0.45] as [CGFloat] {
                if let data = resizedImage.jpegData(compressionQuality: quality),
                   data.count <= 500_000 {
                    return data
                }
            }
            // Last resort: aggressive resize + low quality
            return resized(image, maxDimension: 512).jpegData(compressionQuality: 0.4)
        }

        private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size
            let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
            guard scale < 1.0 else { return image }
            let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
            // UIGraphicsImageRenderer strips EXIF metadata automatically
            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
