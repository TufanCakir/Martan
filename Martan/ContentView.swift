import SwiftUI

struct ContentView: View {
    @State private var configuration = WallpaperConfiguration()
    @State private var isExporting = false
    @State private var alertMessage = ""
    @State private var isShowingAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.025, green: 0.025, blue: 0.055)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        WallpaperPreview(configuration: configuration)
                        CompactStylePicker(
                            selection: $configuration.style,
                            palette: $configuration.palette
                        )
                        CustomizationGrid(
                            palette: $configuration.palette,
                            detail: $configuration.detail,
                            glow: $configuration.glow
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Mythic Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(red: 0.025, green: 0.025, blue: 0.055), for: .navigationBar)
            .toolbarBackground(.visible, for: .bottomBar)
            .toolbarBackground(Color(red: 0.04, green: 0.04, blue: 0.075), for: .bottomBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    FormatMenu(selection: $configuration.format)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createNewWallpaper) {
                        Label("Alles neu würfeln", systemImage: "wand.and.sparkles")
                    }
                    .accessibilityHint("Erzeugt einen neuen Shader mit zufälllichen Farben und Einstellungen")
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Text(configuration.format.resolution)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: saveWallpaper) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("In Fotos speichern", systemImage: "square.and.arrow.down.fill")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .alert("Mythic Canvas", isPresented: $isShowingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }

    private func createNewWallpaper() {
        withAnimation(.easeInOut(duration: 0.2)) {
            configuration.randomizeArtwork()
        }
    }

    private func saveWallpaper() {
        guard !isExporting else { return }
        isExporting = true
        let snapshot = configuration

        Task {
            do {
                await Task.yield()
                let renderer = MetalWallpaperRenderer()
                let image = try renderer.renderImage(
                    size: snapshot.format.exportSize,
                    configuration: snapshot
                )
                try await PhotoLibrarySaver.save(image)
                alertMessage = "Dein Fantasy-Background wurde in Fotos gespeichert."
            } catch {
                alertMessage = error.localizedDescription
            }
            isExporting = false
            isShowingAlert = true
        }
    }
}

private struct FormatMenu: View {
    @Binding var selection: CanvasFormat

    var body: some View {
        Menu {
            ForEach(CanvasFormat.allCases) { format in
                Button {
                    selection = format
                } label: {
                    Label {
                        Text(format.title)
                    } icon: {
                        Image(systemName: selection == format ? "checkmark" : format.icon)
                    }
                }
            }
        } label: {
            Label {
                Text(selection.title)
            } icon: {
                Image(systemName: selection.icon)
            }
        }
        .accessibilityLabel("Bildformat: \(Text(selection.title))")
    }
}

private struct WallpaperPreview: View {
    let configuration: WallpaperConfiguration

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalWallpaperView(configuration: configuration)
                .aspectRatio(configuration.format.aspectRatio, contentMode: .fit)

            Label(configuration.style.title, systemImage: configuration.style.icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: configuration.format == .landscape ? 220 : 310)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: configuration.palette.energy.opacity(0.25), radius: 20, y: 8)
        .padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vorschau: \(Text(configuration.style.title)), \(Text(configuration.format.title))")
    }
}

private struct CompactStylePicker: View {
    @Binding var selection: FantasyStyle
    @Binding var palette: ShaderPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "SHADER", systemImage: "sparkles")

            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    ForEach(FantasyStyle.allCases) { style in
                        Button {
                            selection = style
                            palette = style.defaultPalette
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: style.icon)
                                    .font(.title3)
                                Text(style.title)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .frame(width: 104, height: 64)
                            .background(
                                selection == style
                                    ? AnyShapeStyle(.cyan.opacity(0.20))
                                    : AnyShapeStyle(.white.opacity(0.05)),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        selection == style ? Color.cyan.opacity(0.8) : .white.opacity(0.07),
                                        lineWidth: 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == style ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct CustomizationGrid: View {
    @Binding var palette: ShaderPalette
    @Binding var detail: Float
    @Binding var glow: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "ANPASSEN", systemImage: "slider.horizontal.3")

            Grid(horizontalSpacing: 10) {
                GridRow {
                    CompactPaletteEditor(palette: $palette)
                    CompactTuningControls(detail: $detail, glow: $glow)
                }
            }
        }
    }
}

private struct CompactPaletteEditor: View {
    @Binding var palette: ShaderPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Farben", systemImage: "paintpalette.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 3)

            ColorPicker("Schatten", selection: $palette.shadow, supportsOpacity: false)
            Divider()
            ColorPicker("Energie", selection: $palette.energy, supportsOpacity: false)
            Divider()
            ColorPicker("Licht", selection: $palette.highlight, supportsOpacity: false)
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CompactTuningControls: View {
    @Binding var detail: Float
    @Binding var glow: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Effekte", systemImage: "wand.and.stars")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            CompactSlider(
                title: "Details",
                value: $detail
            )
            CompactSlider(
                title: "Leuchten",
                value: $glow
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CompactSlider: View {
    let title: LocalizedStringResource
    @Binding var value: Float

    var body: some View {
        VStack(spacing: 1) {
            HStack {
                Text(title)
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)

            Slider(value: $value, in: 0...1)
                .controlSize(.mini)
        }
    }
}

private struct SectionTitle: View {
    let title: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}
