import MetalKit
import SwiftUI
import UIKit

private extension Color {
    var metalColor: SIMD4<Float> {
        let resolved = UIColor(self).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SIMD4(Float(red), Float(green), Float(blue), Float(alpha))
    }
}

private struct ShaderUniforms {
    var resolution: SIMD2<Float>
    var seed: Float
    var detail: Float
    var glow: Float
    var style: UInt32
    var shadowColor: SIMD4<Float>
    var energyColor: SIMD4<Float>
    var highlightColor: SIMD4<Float>
}

enum WallpaperRenderError: LocalizedError {
    case metalUnavailable
    case shaderUnavailable
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .metalUnavailable: "Metal ist auf diesem Gerät nicht verfügbar."
        case .shaderUnavailable: "Der Metal-Shader konnte nicht geladen werden."
        case .renderingFailed: "Das Bild konnte nicht gerendert werden."
        }
    }
}

final class MetalWallpaperRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    var configuration = WallpaperConfiguration()

    override init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "fantasyVertex"),
              let fragmentFunction = library.makeFunction(name: "fantasyFragment") else {
            fatalError("Metal could not be initialized.")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.device = device
            self.commandQueue = commandQueue
            self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Metal pipeline creation failed: \(error)")
        }
        super.init()
    }

    func configure(_ view: MTKView) {
        view.device = device
        view.delegate = self
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.clearColor = MTLClearColorMake(0.01, 0.01, 0.04, 1)
        view.setNeedsDisplay()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let passDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        encode(
            into: commandBuffer,
            descriptor: passDescriptor,
            size: view.drawableSize,
            configuration: configuration
        )
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func renderImage(size: CGSize, configuration: WallpaperConfiguration) throws -> UIImage {
        let width = Int(size.width)
        let height = Int(size.height)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: textureDescriptor),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw WallpaperRenderError.renderingFailed
        }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        encode(into: commandBuffer, descriptor: passDescriptor, size: size, configuration: configuration)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard commandBuffer.status == .completed else {
            throw WallpaperRenderError.renderingFailed
        }

        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        texture.getBytes(
            &pixels,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue |
                        CGBitmapInfo.byteOrder32Little.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            throw WallpaperRenderError.renderingFailed
        }

        return UIImage(cgImage: cgImage)
    }

    private func encode(
        into commandBuffer: MTLCommandBuffer,
        descriptor: MTLRenderPassDescriptor,
        size: CGSize,
        configuration: WallpaperConfiguration
    ) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        var uniforms = ShaderUniforms(
            resolution: SIMD2(Float(size.width), Float(size.height)),
            seed: configuration.seed,
            detail: configuration.detail,
            glow: configuration.glow,
            style: configuration.style.rawValue,
            shadowColor: configuration.palette.shadow.metalColor,
            energyColor: configuration.palette.energy.metalColor,
            highlightColor: configuration.palette.highlight.metalColor
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ShaderUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }
}

struct MetalWallpaperView: UIViewRepresentable {
    let configuration: WallpaperConfiguration

    func makeCoordinator() -> MetalWallpaperRenderer {
        MetalWallpaperRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        context.coordinator.configuration = configuration
        context.coordinator.configure(view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.configuration = configuration
        view.setNeedsDisplay()
    }
}
