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
        try await save([image])
    }

    static func save(_ images: [UIImage]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.accessDenied
        }

        let pngImages = try images.map { image in
            guard let data = image.pngData() else {
                throw PhotoSaveError.saveFailed
            }
            return data
        }

        guard !pngImages.isEmpty else {
            throw PhotoSaveError.saveFailed
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                for (index, pngData) in pngImages.enumerated() {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.originalFilename = "Mythic-Canvas-\(String(format: "%04d", index)).png"
                    request.addResource(with: .photo, data: pngData, options: options)
                }
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
