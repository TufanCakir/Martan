import SwiftUI

enum CanvasFormat: String, CaseIterable, Identifiable {
    case portrait
    case landscape
    case square

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .portrait: "Hochformat"
        case .landscape: "Querformat"
        case .square: "Quadratisch"
        }
    }

    var icon: String {
        switch self {
        case .portrait: "rectangle.portrait"
        case .landscape: "rectangle"
        case .square: "square"
        }
    }

    var exportSize: CGSize {
        switch self {
        case .portrait: CGSize(width: 2160, height: 3840)
        case .landscape: CGSize(width: 3840, height: 2160)
        case .square: CGSize(width: 3072, height: 3072)
        }
    }

    var aspectRatio: CGFloat {
        exportSize.width / exportSize.height
    }

    var resolution: String {
        "\(Int(exportSize.width)) × \(Int(exportSize.height))"
    }
}

struct ShaderPalette: Equatable {
    var shadow: Color
    var energy: Color
    var highlight: Color

    var colors: [Color] {
        [shadow, energy, highlight]
    }
}

enum FantasyStyle: UInt32, CaseIterable, Identifiable {
    case nebula
    case enchanted
    case ember
    case aurora
    case crystal
    case vortex

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .nebula: "Kosmischer Nebel"
        case .enchanted: "Verzauberter Wald"
        case .ember: "Drachenfeuer"
        case .aurora: "Polarlicht"
        case .crystal: "Kristalltempel"
        case .vortex: "Leerenportal"
        }
    }

    var icon: String {
        switch self {
        case .nebula: "cloud.fog.fill"
        case .enchanted: "tree.fill"
        case .ember: "flame.fill"
        case .aurora: "wave.3.up"
        case .crystal: "diamond.fill"
        case .vortex: "hurricane"
        }
    }

    var defaultPalette: ShaderPalette {
        switch self {
        case .nebula:
            ShaderPalette(
                shadow: Color(red: 0.02, green: 0.01, blue: 0.10),
                energy: Color(red: 0.48, green: 0.05, blue: 0.78),
                highlight: Color(red: 0.08, green: 0.92, blue: 1.00)
            )
        case .enchanted:
            ShaderPalette(
                shadow: Color(red: 0.00, green: 0.06, blue: 0.05),
                energy: Color(red: 0.02, green: 0.45, blue: 0.25),
                highlight: Color(red: 0.50, green: 1.00, blue: 0.70)
            )
        case .ember:
            ShaderPalette(
                shadow: Color(red: 0.08, green: 0.00, blue: 0.02),
                energy: Color(red: 0.85, green: 0.04, blue: 0.01),
                highlight: Color(red: 1.00, green: 0.68, blue: 0.06)
            )
        case .aurora:
            ShaderPalette(
                shadow: Color(red: 0.01, green: 0.02, blue: 0.12),
                energy: Color(red: 0.05, green: 0.55, blue: 0.72),
                highlight: Color(red: 0.35, green: 1.00, blue: 0.55)
            )
        case .crystal:
            ShaderPalette(
                shadow: Color(red: 0.03, green: 0.01, blue: 0.12),
                energy: Color(red: 0.35, green: 0.12, blue: 0.88),
                highlight: Color(red: 0.95, green: 0.55, blue: 1.00)
            )
        case .vortex:
            ShaderPalette(
                shadow: Color(red: 0.00, green: 0.01, blue: 0.04),
                energy: Color(red: 0.02, green: 0.22, blue: 0.65),
                highlight: Color(red: 0.65, green: 0.92, blue: 1.00)
            )
        }
    }
}

struct WallpaperConfiguration: Equatable {
    var format: CanvasFormat = .portrait
    var style: FantasyStyle = .nebula
    var seed: Float = 4.2
    var detail: Float = 0.65
    var glow: Float = 0.72
    var palette = FantasyStyle.nebula.defaultPalette

    mutating func randomizeArtwork() {
        style = FantasyStyle.allCases.randomElement() ?? .nebula
        seed = Float.random(in: 0...1000)
        detail = Float.random(in: 0.45...1)
        glow = Float.random(in: 0.5...1)
        palette = .random()
    }
}

private extension ShaderPalette {
    static func random() -> ShaderPalette {
        let baseHue = Double.random(in: 0...1)
        let energyHue = wrappedHue(baseHue + Double.random(in: 0.08...0.28))
        let highlightHue = wrappedHue(baseHue - Double.random(in: 0.06...0.22))

        return ShaderPalette(
            shadow: Color(
                hue: baseHue,
                saturation: Double.random(in: 0.65...1),
                brightness: Double.random(in: 0.035...0.14)
            ),
            energy: Color(
                hue: energyHue,
                saturation: Double.random(in: 0.65...1),
                brightness: Double.random(in: 0.58...0.9)
            ),
            highlight: Color(
                hue: highlightHue,
                saturation: Double.random(in: 0.35...0.85),
                brightness: Double.random(in: 0.9...1)
            )
        )
    }

    static func wrappedHue(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 1)
        return remainder < 0 ? remainder + 1 : remainder
    }
}
