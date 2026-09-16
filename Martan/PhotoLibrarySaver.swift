import Photos
import UIKit

enum PhotoSaveError: LocalizedError {
    case accessDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Der Zugriff auf deine Fotomediathek wurde nicht erlaubt."
        case .saveFailed: "Das Bild konnte nicht in Fotos gespeichert werden."
        }
    }
}

enum PhotoLibrarySaver {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.accessDenied
        }

        guard let pngData = image.pngData() else {
            throw PhotoSaveError.saveFailed
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = "Mythic-Canvas-\(UUID().uuidString).png"
                request.addResource(with: .photo, data: pngData, options: options)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.saveFailed)
                }
            }
        }
    }
}
