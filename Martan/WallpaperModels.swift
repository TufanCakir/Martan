import SwiftUI

enum CanvasFormat: String, CaseIterable, Identifiable {
    case portrait
    case landscape
    case square
    case logo
    case custom

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .portrait: "Hochformat"
        case .landscape: "Querformat"
        case .square: "Quadratisch"
        case .logo: "Logo 1204 × 1024"
        case .custom: "Eigene Größe"
        }
    }

    var icon: String {
        switch self {
        case .portrait: "rectangle.portrait"
        case .landscape: "rectangle"
        case .square: "square"
        case .logo: "app.dashed"
        case .custom: "aspectratio"
        }
    }

    var exportSize: CGSize {
        switch self {
        case .portrait: CGSize(width: 2160, height: 3840)
        case .landscape: CGSize(width: 3840, height: 2160)
        case .square: CGSize(width: 3072, height: 3072)
        case .logo: CGSize(width: 1204, height: 1024)
        case .custom: CGSize(width: 1024, height: 1024)
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
    case angel
    case divine
    case infernal
    case rebel
    case celestial
    case rpg
    case realisticFantasy
    case plainGround
    case street
    case ragefire
    case void
    case wormhole
    case spacetime
    case dimension
    case ascii
    case springGrid
    case pixelBlocks
    case pendulum
    case ripple
    case caustics
    case emberDissolve
    case crystalGrowth
    case circleGrid
    case hexPulse
    case halloween
    case birthday
    case darkArea
    case fantasyDragon
    case martialArts
    case beatEmUp
    case tint
    case brushStrokes

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .nebula: "Kosmischer Nebel"
        case .enchanted: "Verzauberter Wald"
        case .ember: "Drachenfeuer"
        case .aurora: "Polarlicht"
        case .crystal: "Kristalltempel"
        case .vortex: "Leerenportal"
        case .angel: "Engelslicht"
        case .divine: "Göttlich"
        case .infernal: "Teuflisch"
        case .rebel: "Rebellisch"
        case .celestial: "Himmlisch"
        case .rpg: "RPG Game"
        case .realisticFantasy: "Fantasy Realistisch"
        case .plainGround: "Ebener Boden"
        case .street: "Fantasy Street"
        case .ragefire: "Ragefire"
        case .void: "Void"
        case .wormhole: "Wurmloch"
        case .spacetime: "Zeitraum"
        case .dimension: "Dimension"
        case .ascii: "ASCII Portal"
        case .springGrid: "Feder-Gitter"
        case .pixelBlocks: "Pixelblöcke"
        case .pendulum: "Pendelspur"
        case .ripple: "Ripple-Welle"
        case .caustics: "Wasser-Caustics"
        case .emberDissolve: "Ember Dissolve"
        case .crystalGrowth: "Kristallwachstum"
        case .circleGrid: "Kreisraster"
        case .hexPulse: "Hex-Pulse"
        case .halloween: "Halloween"
        case .birthday: "Birthday"
        case .darkArea: "Dark Area"
        case .fantasyDragon: "Fantasy Dragon"
        case .martialArts: "Martial Arts"
        case .beatEmUp: "Beat ’em Up"
        case .tint: "Tint Shader"
        case .brushStrokes: "Pinselstreifen"
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
        case .angel: "sparkles.rectangle.stack.fill"
        case .divine: "sun.max.trianglebadge.exclamationmark.fill"
        case .infernal: "flame.circle.fill"
        case .rebel: "bolt.shield.fill"
        case .celestial: "cloud.sun.fill"
        case .rpg: "gamecontroller.fill"
        case .realisticFantasy: "mountain.2.fill"
        case .plainGround: "square.split.bottomrightquarter.fill"
        case .street: "road.lanes"
        case .ragefire: "flame.fill"
        case .void: "circle.dotted.circle.fill"
        case .wormhole: "circle.hexagongrid.fill"
        case .spacetime: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .dimension: "square.3.layers.3d"
        case .ascii: "textformat.abc"
        case .springGrid: "circle.grid.3x3.fill"
        case .pixelBlocks: "square.grid.3x3.square"
        case .pendulum: "metronome.fill"
        case .ripple: "water.waves"
        case .caustics: "drop.triangle.fill"
        case .emberDissolve: "sparkles"
        case .crystalGrowth: "snowflake"
        case .circleGrid: "circle.grid.3x3"
        case .hexPulse: "hexagon.fill"
        case .halloween: "moon.stars.fill"
        case .birthday: "birthday.cake.fill"
        case .darkArea: "moon.fill"
        case .fantasyDragon: "lizard.fill"
        case .martialArts: "figure.martial.arts"
        case .beatEmUp: "burst.fill"
        case .tint: "paintpalette.fill"
        case .brushStrokes: "paintbrush.pointed.fill"
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
        case .angel:
            ShaderPalette(
                shadow: Color(red: 0.12, green: 0.16, blue: 0.34),
                energy: Color(red: 0.56, green: 0.76, blue: 1.00),
                highlight: Color(red: 1.00, green: 0.88, blue: 0.58)
            )
        case .divine:
            ShaderPalette(shadow: Color(red: 0.16, green: 0.12, blue: 0.28), energy: Color(red: 0.96, green: 0.68, blue: 0.22), highlight: .white)
        case .infernal:
            ShaderPalette(shadow: Color(red: 0.08, green: 0.00, blue: 0.01), energy: Color(red: 0.72, green: 0.01, blue: 0.02), highlight: Color(red: 1.00, green: 0.30, blue: 0.02))
        case .rebel:
            ShaderPalette(shadow: Color(red: 0.03, green: 0.03, blue: 0.04), energy: Color(red: 0.86, green: 0.02, blue: 0.30), highlight: Color(red: 0.15, green: 0.90, blue: 1.00))
        case .celestial:
            ShaderPalette(shadow: Color(red: 0.08, green: 0.16, blue: 0.34), energy: Color(red: 0.38, green: 0.72, blue: 1.00), highlight: Color(red: 1.00, green: 0.96, blue: 0.78))
        case .rpg:
            ShaderPalette(shadow: Color(red: 0.03, green: 0.08, blue: 0.04), energy: Color(red: 0.18, green: 0.62, blue: 0.24), highlight: Color(red: 1.00, green: 0.78, blue: 0.20))
        case .realisticFantasy:
            ShaderPalette(shadow: Color(red: 0.05, green: 0.08, blue: 0.12), energy: Color(red: 0.20, green: 0.42, blue: 0.38), highlight: Color(red: 0.84, green: 0.76, blue: 0.58))
        case .plainGround:
            ShaderPalette(shadow: Color(red: 0.08, green: 0.06, blue: 0.04), energy: Color(red: 0.32, green: 0.26, blue: 0.16), highlight: Color(red: 0.70, green: 0.58, blue: 0.34))
        case .street:
            ShaderPalette(shadow: Color(red: 0.01, green: 0.02, blue: 0.04), energy: Color(red: 0.55, green: 0.04, blue: 0.58), highlight: Color(red: 0.02, green: 0.92, blue: 1.00))
        case .ragefire:
            ShaderPalette(shadow: Color(red: 0.12, green: 0.00, blue: 0.00), energy: Color(red: 1.00, green: 0.08, blue: 0.00), highlight: Color(red: 1.00, green: 0.82, blue: 0.05))
        case .void:
            ShaderPalette(shadow: .black, energy: Color(red: 0.12, green: 0.00, blue: 0.28), highlight: Color(red: 0.64, green: 0.18, blue: 1.00))
        case .wormhole:
            ShaderPalette(shadow: Color(red: 0.00, green: 0.01, blue: 0.08), energy: Color(red: 0.04, green: 0.42, blue: 0.88), highlight: Color(red: 0.82, green: 0.98, blue: 1.00))
        case .spacetime:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.00, blue: 0.10), energy: Color(red: 0.42, green: 0.10, blue: 0.72), highlight: Color(red: 1.00, green: 0.42, blue: 0.72))
        case .dimension:
            ShaderPalette(shadow: Color(red: 0.00, green: 0.04, blue: 0.08), energy: Color(red: 0.00, green: 0.70, blue: 0.64), highlight: Color(red: 0.92, green: 1.00, blue: 0.62))
        case .ascii:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.02, blue: 0.04), energy: Color(red: 0.12, green: 0.72, blue: 0.86), highlight: Color(red: 1.00, green: 0.32, blue: 0.72))
        case .springGrid:
            ShaderPalette(shadow: Color(red: 0.04, green: 0.05, blue: 0.08), energy: Color(red: 0.18, green: 0.46, blue: 0.82), highlight: Color(red: 0.96, green: 0.32, blue: 0.18))
        case .pixelBlocks:
            ShaderPalette(shadow: Color(red: 0.05, green: 0.05, blue: 0.08), energy: Color(red: 0.22, green: 0.42, blue: 0.92), highlight: Color(red: 1.00, green: 0.42, blue: 0.18))
        case .pendulum:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.02, blue: 0.05), energy: Color(red: 0.24, green: 0.52, blue: 0.92), highlight: Color(red: 1.00, green: 0.28, blue: 0.38))
        case .ripple:
            ShaderPalette(shadow: Color(red: 0.08, green: 0.14, blue: 0.32), energy: Color(red: 0.20, green: 0.48, blue: 0.82), highlight: Color(red: 0.62, green: 0.82, blue: 1.00))
        case .caustics:
            ShaderPalette(shadow: Color(red: 0.00, green: 0.05, blue: 0.15), energy: Color(red: 0.05, green: 0.48, blue: 0.70), highlight: Color(red: 0.32, green: 0.92, blue: 1.00))
        case .emberDissolve:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.02, blue: 0.03), energy: Color(red: 0.92, green: 0.18, blue: 0.02), highlight: Color(red: 1.00, green: 0.82, blue: 0.18))
        case .crystalGrowth:
            ShaderPalette(shadow: Color(red: 0.01, green: 0.02, blue: 0.10), energy: Color(red: 0.25, green: 0.52, blue: 0.92), highlight: Color(red: 0.90, green: 0.96, blue: 1.00))
        case .circleGrid:
            ShaderPalette(shadow: Color(red: 0.05, green: 0.05, blue: 0.08), energy: Color(red: 0.24, green: 0.72, blue: 0.82), highlight: Color(red: 0.98, green: 0.34, blue: 0.74))
        case .hexPulse:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.02, blue: 0.03), energy: Color(red: 0.14, green: 0.62, blue: 0.92), highlight: Color(red: 0.92, green: 0.24, blue: 1.00))
        case .halloween:
            ShaderPalette(shadow: Color(red: 0.03, green: 0.00, blue: 0.05), energy: Color(red: 0.72, green: 0.16, blue: 0.02), highlight: Color(red: 1.00, green: 0.62, blue: 0.04))
        case .birthday:
            ShaderPalette(shadow: Color(red: 0.08, green: 0.02, blue: 0.16), energy: Color(red: 0.96, green: 0.18, blue: 0.58), highlight: Color(red: 0.22, green: 0.92, blue: 1.00))
        case .darkArea:
            ShaderPalette(shadow: .black, energy: Color(red: 0.03, green: 0.06, blue: 0.12), highlight: Color(red: 0.22, green: 0.32, blue: 0.52))
        case .fantasyDragon:
            ShaderPalette(shadow: Color(red: 0.03, green: 0.08, blue: 0.04), energy: Color(red: 0.08, green: 0.56, blue: 0.22), highlight: Color(red: 1.00, green: 0.72, blue: 0.08))
        case .martialArts:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.02, blue: 0.025), energy: Color(red: 0.72, green: 0.04, blue: 0.04), highlight: Color(red: 0.98, green: 0.92, blue: 0.72))
        case .beatEmUp:
            ShaderPalette(shadow: Color(red: 0.04, green: 0.02, blue: 0.10), energy: Color(red: 0.94, green: 0.06, blue: 0.34), highlight: Color(red: 1.00, green: 0.84, blue: 0.08))
        case .tint:
            ShaderPalette(shadow: Color(red: 0.02, green: 0.06, blue: 0.12), energy: Color(red: 0.08, green: 0.68, blue: 0.82), highlight: Color(red: 0.92, green: 0.28, blue: 0.72))
        case .brushStrokes:
            ShaderPalette(shadow: Color(red: 0.04, green: 0.03, blue: 0.02), energy: Color(red: 0.78, green: 0.16, blue: 0.08), highlight: Color(red: 1.00, green: 0.78, blue: 0.28))
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
    var customWidth = 1024
    var customHeight = 1024
    var animationEnabled = true
    var animationSpeed: Float = 1
    var animationDuration: Double = 2
    var framesPerSecond = 24
    var spriteFrameWidth = 256
    var spriteFrameHeight = 256

    var animationFrameCount: Int {
        min(max(Int(animationDuration * Double(framesPerSecond)), 1), 120)
    }

    var spriteColumns: Int {
        Int(ceil(sqrt(Double(animationFrameCount))))
    }

    var spriteRows: Int {
        Int(ceil(Double(animationFrameCount) / Double(spriteColumns)))
    }

    var spriteSheetSize: CGSize {
        CGSize(
            width: spriteColumns * spriteFrameWidth,
            height: spriteRows * spriteFrameHeight
        )
    }

    var exportSize: CGSize {
        guard format == .custom else { return format.exportSize }
        return CGSize(
            width: min(max(customWidth, 64), 8192),
            height: min(max(customHeight, 64), 8192)
        )
    }

    var aspectRatio: CGFloat {
        exportSize.width / exportSize.height
    }

    var resolution: String {
        "\(Int(exportSize.width)) × \(Int(exportSize.height))"
    }

    mutating func randomizeCurrentStyle() {
        seed = Float.random(in: 0...1000)
        detail = Float.random(in: 0.45...1)
        glow = Float.random(in: 0.5...1)
    }
}
