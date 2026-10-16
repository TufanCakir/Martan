#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float seed;
    float time;
    float detail;
    float glow;
    uint style;
    float4 shadowColor;
    float4 energyColor;
    float4 highlightColor;
};

vertex VertexOut fantasyVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };

    VertexOut output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    output.uv = positions[vertexID] * 0.5 + 0.5;
    return output;
}

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), f.x),
               mix(hash21(i + float2(0, 1)), hash21(i + 1.0), f.x), f.y);
}

float fbm(float2 p, float detail) {
    float value = 0.0;
    float amplitude = 0.5;
    float2x2 rotation = float2x2(0.80, -0.60, 0.60, 0.80);
    int octaves = 4 + int(detail * 3.0);
    for (int i = 0; i < 7; ++i) {
        if (i >= octaves) { break; }
        value += amplitude * noise(p);
        p = rotation * p * 2.03 + 13.7;
        amplitude *= 0.5;
    }
    return value;
}

float lineGlow(float distance, float width) {
    return width / max(distance, 0.001);
}

fragment float4 fantasyFragment(VertexOut input [[stage_in]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = input.uv;
    uv.y = 1.0 - uv.y;
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0);
    float seed = uniforms.seed + uniforms.time * 0.32;

    float warpA = fbm(p * 2.2 + seed, uniforms.detail);
    float warpB = fbm(p * 3.1 - seed * 0.73 + warpA, uniforms.detail);
    float clouds = fbm(p * 2.7 + float2(warpA, warpB) * 2.6 + seed, uniforms.detail);
    float energy = 0.0;
    float atmosphere = clouds;

    if (uniforms.style == 0) {
        // Layered cosmic gas with bright filament ridges.
        float ridges = 1.0 - abs(2.0 * fbm(p * 4.5 - warpB + seed * 0.2, uniforms.detail) - 1.0);
        energy = pow(ridges, 3.0);
    } else if (uniforms.style == 1) {
        // Vertical enchanted light shafts and a misty forest floor.
        float trunks = pow(1.0 - abs(sin((p.x + warpA * 0.18) * 28.0)), 18.0);
        float canopy = smoothstep(0.2, 0.9, fbm(float2(p.x * 4.0, p.y * 1.4) + seed, uniforms.detail));
        float floorMist = exp(-abs(p.y + 0.28 + warpB * 0.12) * 8.0);
        energy = trunks * (0.25 + canopy) + floorMist * 0.9;
        atmosphere = mix(clouds, canopy, 0.55);
    } else if (uniforms.style == 2) {
        // Rising tongues of dragon fire.
        float2 flameP = float2(p.x * 2.2, p.y * 1.45);
        float flameNoise = fbm(flameP * 3.0 + float2(0.0, seed) + warpA, uniforms.detail);
        float taper = 0.42 - abs(flameP.x) + flameNoise * 0.32 - flameP.y * 0.16;
        float flameEdge = 1.0 - abs(taper * 5.0 - floor(taper * 5.0) - 0.5) * 2.0;
        energy = pow(saturate(flameEdge), 5.0) * smoothstep(-0.5, 0.6, taper);
        atmosphere = flameNoise;
    } else if (uniforms.style == 3) {
        // Multiple flowing aurora curtains.
        float curtain = 0.0;
        for (int i = 0; i < 4; ++i) {
            float fi = float(i);
            float wave = sin(p.x * (3.0 + fi * 0.7) + seed * 0.1 + fi) * (0.08 + fi * 0.018);
            wave += (noise(float2(p.x * 2.0 + fi, seed)) - 0.5) * 0.18;
            float bandY = p.y + 0.28 - fi * 0.13 - wave;
            curtain += lineGlow(abs(bandY), 0.007 + uniforms.glow * 0.006);
        }
        energy = saturate(curtain) * smoothstep(0.8, 0.05, abs(p.x));
        atmosphere = fbm(p * float2(1.2, 3.5) + seed, uniforms.detail);
    } else if (uniforms.style == 4) {
        // Kaleidoscopic crystal facets.
        float angle = atan2(p.y, p.x);
        float radius = length(p);
        float sectors = 8.0;
        float foldedAngle = abs(fract(angle / (2.0 * M_PI_F) * sectors + 0.5) - 0.5);
        float facets = abs(sin(radius * 34.0 - foldedAngle * 18.0 + warpA * 3.0));
        float edges = 1.0 - smoothstep(0.02, 0.13, min(facets, 1.0 - facets));
        energy = edges + pow(1.0 - saturate(radius), 8.0);
        atmosphere = fbm(float2(radius * 5.0, foldedAngle * 9.0) + seed, uniforms.detail);
    } else if (uniforms.style == 5) {
        // Spiraling portal rings collapsing into a dark center.
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float spiral = sin(radius * 48.0 - angle * 7.0 + warpA * 6.0 + seed);
        float rings = pow(1.0 - abs(spiral), 7.0);
        float halo = lineGlow(abs(radius - 0.32 - (warpB - 0.5) * 0.04), 0.008);
        energy = (rings * smoothstep(0.72, 0.08, radius) + halo) * smoothstep(0.05, 0.18, radius);
        atmosphere = fbm(float2(radius * 4.0, angle * 0.8) + seed, uniforms.detail);
    } else if (uniforms.style == 6) {
        // Symmetrical angel wings, a warm halo, and soft celestial rays.
        float2 wingP = float2(abs(p.x), p.y + 0.02);
        float featherWave = sin(wingP.x * 31.0 - wingP.y * 13.0 + warpA * 4.0);
        float wingShape = smoothstep(0.48, 0.08, abs(wingP.y + wingP.x * 0.52 - 0.12));
        wingShape *= smoothstep(0.02, 0.16, wingP.x) * smoothstep(0.95, 0.25, wingP.x);
        float feathers = pow(saturate(0.5 + 0.5 * featherWave), 5.0) * wingShape;
        float haloRadius = length(float2(p.x, (p.y + 0.30) * 1.8));
        float halo = lineGlow(abs(haloRadius - 0.22), 0.006 + uniforms.glow * 0.006);
        float rays = pow(saturate(cos(atan2(p.y + 0.2, p.x) * 10.0)), 12.0);
        rays *= smoothstep(0.75, 0.08, length(p));
        energy = feathers * 1.25 + halo + rays * 0.28;
        atmosphere = mix(clouds, 1.0 - length(p) * 0.75, 0.45);
    } else if (uniforms.style == 7) {
        // Divine sunburst and concentric sacred rings.
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float rays = pow(abs(cos(angle * 12.0 + warpA)), 18.0) * smoothstep(0.85, 0.08, radius);
        float rings = lineGlow(abs(fract(radius * 7.0 - seed * 0.01) - 0.5), 0.012);
        energy = rays + rings * smoothstep(0.75, 0.05, radius);
        atmosphere = 1.0 - saturate(radius) + clouds * 0.25;
    } else if (uniforms.style == 8) {
        // Infernal horns, smoke, and a molten core.
        float horns = abs(abs(p.x) - (0.20 + (p.y + 0.15) * (p.y + 0.15) * 0.75));
        float hornGlow = lineGlow(horns, 0.006) * smoothstep(0.65, -0.25, p.y);
        float core = exp(-length(p * float2(1.5, 0.8)) * 5.0);
        energy = hornGlow + core + pow(clouds, 5.0);
        atmosphere = fbm(p * 4.0 + warpB * 2.0, uniforms.detail);
    } else if (uniforms.style == 9) {
        // Rebellious fractured lightning and spray-paint noise.
        float slash = abs(p.y - sin(p.x * 8.0 + seed) * 0.08 - (warpA - 0.5) * 0.22);
        float crossSlash = abs(p.y + p.x * 0.7 + (warpB - 0.5) * 0.18);
        energy = lineGlow(slash, 0.008) + lineGlow(crossSlash, 0.006);
        atmosphere = smoothstep(0.25, 0.85, noise(p * 18.0 + seed));
    } else if (uniforms.style == 10) {
        // Layered heavenly clouds with a distant radiant gate.
        float cloudBank = smoothstep(0.35, 0.82, clouds + (0.15 - p.y) * 0.28);
        float gate = lineGlow(abs(abs(p.x) - 0.18), 0.005) * smoothstep(0.35, -0.15, abs(p.y));
        float horizon = lineGlow(abs(p.y - 0.04), 0.008);
        energy = gate + horizon + pow(cloudBank, 5.0) * 0.35;
        atmosphere = cloudBank;
    } else if (uniforms.style == 11) {
        // RPG magic circle, runic ticks, and mana core.
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float circle = lineGlow(abs(radius - 0.34), 0.006);
        float runes = step(0.72, sin(angle * 18.0 + seed)) * lineGlow(abs(radius - 0.43), 0.009);
        float sigil = lineGlow(abs(sin(angle * 3.0) * radius), 0.004) * smoothstep(0.38, 0.08, radius);
        energy = circle + runes + sigil;
        atmosphere = fbm(p * 3.0 + seed, uniforms.detail);
    } else if (uniforms.style == 12) {
        // Naturalistic mountain silhouettes, fog, and a low sun.
        float mountain = p.y + 0.18 - abs(p.x) * 0.45 - (noise(float2(p.x * 6.0, seed)) - 0.5) * 0.24;
        float ridge = lineGlow(abs(mountain), 0.004);
        float sun = exp(-length(p - float2(0.24, -0.20)) * 14.0);
        energy = ridge + sun;
        atmosphere = mix(clouds * 0.65, smoothstep(-0.15, 0.25, mountain), 0.5);
    } else if (uniforms.style == 13) {
        // Textured ground plane with a calm distant horizon.
        float perspective = 1.0 / max(abs(p.y - 0.08), 0.025);
        float gridX = lineGlow(abs(fract(p.x * perspective * 0.7) - 0.5), 0.006);
        float gridY = lineGlow(abs(fract(perspective * 0.22) - 0.5), 0.006);
        energy = (gridX + gridY) * smoothstep(0.08, 0.6, p.y);
        atmosphere = fbm(p * float2(5.0, 12.0) + seed, uniforms.detail) * smoothstep(0.0, 0.8, p.y);
    } else if (uniforms.style == 14) {
        // Neon street vanishing toward the center.
        float depth = 1.0 / max(p.y + 0.65, 0.05);
        float lanes = lineGlow(abs(abs(p.x) - (p.y + 0.62) * 0.46), 0.007);
        float blocks = step(0.78, noise(float2(floor(p.x * 14.0), floor(depth * 2.0)) + seed));
        energy = lanes + blocks * smoothstep(-0.55, 0.35, p.y);
        atmosphere = fbm(p * float2(2.0, 7.0) + seed, uniforms.detail);
    } else if (uniforms.style == 15) {
        // Violent ragefire with sharper, faster flame tongues.
        float flameNoise = fbm(p * float2(6.0, 3.0) + float2(warpA * 3.0, seed), uniforms.detail);
        float tongues = sin((p.x + flameNoise * 0.24) * 22.0) * 0.12 + flameNoise - p.y * 0.48;
        energy = pow(saturate(tongues), 4.0) + lineGlow(abs(tongues - 0.38), 0.008);
        atmosphere = flameNoise;
    } else if (uniforms.style == 16) {
        // Nearly empty void with sparse unstable filaments.
        float radius = length(p);
        float fracture = abs(sin((atan2(p.y, p.x) + warpA) * 9.0 + radius * 30.0));
        energy = pow(1.0 - fracture, 14.0) * smoothstep(0.8, 0.12, radius);
        atmosphere = clouds * 0.12;
    } else if (uniforms.style == 17) {
        // Deep wormhole tunnel with luminous warped rings.
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float tunnel = sin(log(radius + 0.035) * 18.0 - angle * 5.0 + warpA * 3.0);
        energy = pow(1.0 - abs(tunnel), 8.0) * smoothstep(0.9, 0.04, radius);
        atmosphere = fbm(float2(log(radius + 0.04) * 3.0, angle) + seed, uniforms.detail);
    } else if (uniforms.style == 18) {
        // Bent spacetime grid around a dense center.
        float radius = length(p);
        float bend = 0.16 / max(radius, 0.06);
        float2 warped = p + normalize(p + 0.0001) * bend;
        float grid = min(abs(fract(warped.x * 8.0) - 0.5), abs(fract(warped.y * 8.0) - 0.5));
        energy = lineGlow(grid, 0.008) + lineGlow(abs(radius - 0.28), 0.007);
        atmosphere = fbm(warped * 2.0 + seed, uniforms.detail);
    } else if (uniforms.style == 19) {
        // Interleaved dimensional planes and a central rift.
        float planes = abs(sin((p.x + p.y * 0.55 + warpA * 0.15) * 26.0));
        float rift = lineGlow(abs(p.x + sin(p.y * 8.0 + seed) * 0.08), 0.009);
        float layers = pow(1.0 - planes, 9.0) * smoothstep(0.9, 0.05, length(p));
        energy = layers + rift;
        atmosphere = mix(clouds, fbm(p.yx * 5.0 - seed, uniforms.detail), 0.5);
    } else if (uniforms.style == 20) {
        // ASCII-like glyph cells driven by a radial animated scene.
        float2 grid = uv * uniforms.resolution / 9.0;
        float2 cellID = floor(grid);
        float2 cellUV = fract(grid);
        float2 center = (cellID * 9.0 + 4.5 - uniforms.resolution * 0.5) / uniforms.resolution.y;
        float radius = length(center);
        float level = saturate(0.5 + 0.5 * sin(radius * 18.0 - uniforms.time * 2.0 + atan2(center.y, center.x) * 3.0));
        level *= smoothstep(0.65, 0.08, radius);
        float glyph = min(abs(cellUV.x - 0.5), abs(cellUV.y - 0.5));
        glyph = min(glyph, min(abs(cellUV.x - cellUV.y), abs(cellUV.x - (1.0 - cellUV.y))));
        energy = smoothstep(0.13, 0.025, glyph) * step(0.18, level);
        atmosphere = level * 0.55;
    } else if (uniforms.style == 21) {
        // Elastic nodes reacting to a traveling virtual touch point.
        float2 grid = p * 14.0;
        float2 cellID = floor(grid);
        float2 local = fract(grid) - 0.5;
        float2 poke = float2(sin(uniforms.time * 0.6), cos(uniforms.time * 0.5)) * 2.8;
        float distanceToPoke = length(cellID - poke);
        float power = exp(-distanceToPoke * distanceToPoke * 0.08);
        float wave = sin(distanceToPoke * 1.7 - uniforms.time * 4.0) * power * 0.28;
        float2 displaced = local - normalize(cellID - poke + 0.001) * wave;
        float node = smoothstep(0.12, 0.035, length(displaced));
        float springs = smoothstep(0.035, 0.008, min(abs(displaced.x), abs(displaced.y)));
        energy = node + springs * 0.18;
        atmosphere = power * 0.8 + wave;
    } else if (uniforms.style == 22) {
        // Animated pixel-block mosaic.
        float blockCount = 7.0 + 8.0 * (sin(uniforms.time * 0.3) * 0.5 + 0.5);
        float2 blocks = floor(uv * blockCount) / blockCount;
        float2 orbit = float2(0.5 + 0.2 * sin(uniforms.time), 0.5 + 0.2 * cos(uniforms.time * 0.7));
        float distanceToOrbit = length(blocks - orbit);
        float2 local = fract(uv * blockCount);
        float border = smoothstep(0.02, 0.10, min(min(local.x, local.y), min(1.0 - local.x, 1.0 - local.y)));
        energy = smoothstep(0.32, 0.18, distanceToOrbit) * (0.75 + border * 0.25);
        atmosphere = 0.5 + 0.5 * cos(distanceToOrbit * 18.0 + uniforms.time * 3.0);
    } else if (uniforms.style == 23) {
        // Double-pendulum trail.
        float trail = 0.0;
        for (int i = 0; i < 48; ++i) {
            float age = float(i) * 0.035;
            float t = uniforms.time - age;
            float a1 = 1.5 * sin(t * 1.1) + 0.8 * sin(t * 2.7);
            float a2 = 2.0 * sin(t * 1.7) + sin(t * 3.1);
            float2 point = float2(sin(a1), -cos(a1)) * 0.22 + float2(sin(a2), -cos(a2)) * 0.18;
            trail += 0.0018 / max(length(p - point), 0.002) * (1.0 - float(i) / 48.0);
        }
        energy = saturate(trail);
        atmosphere = fbm(p * 4.0 + uniforms.time * 0.08, uniforms.detail) * 0.35;
    } else if (uniforms.style == 24) {
        // Expanding repeating ripple over a tiled surface.
        float cycle = fmod(uniforms.time, 2.5);
        float waveRadius = cycle * 0.45;
        float distanceToWave = abs(length(p) - waveRadius);
        float ring = smoothstep(0.075, 0.012, distanceToWave) * (1.0 - cycle / 2.5);
        float checker = fmod(floor((p.x + 0.7) * 10.0) + floor((p.y + 0.7) * 10.0), 2.0);
        energy = ring;
        atmosphere = checker * 0.38 + ring * 0.35;
    } else if (uniforms.style == 25) {
        // Flowing underwater caustic interference.
        float causticA = abs(sin(fbm(p * 5.0 + uniforms.time * 0.18, uniforms.detail) * 8.0 + uniforms.time));
        float causticB = abs(sin(fbm(p * 7.0 - uniforms.time * 0.12 + 4.0, uniforms.detail) * 7.0 - uniforms.time * 1.3));
        float caustic = pow(causticA * causticB, 1.7);
        energy = caustic * 1.8;
        atmosphere = fbm(p * 2.5 + uniforms.time * 0.05, uniforms.detail) * 0.7;
    } else if (uniforms.style == 26) {
        // Cyclic ember dissolve edge with rising sparks.
        float progress = fract(uniforms.time / 6.0);
        float burnValue = length(p - float2(sin(uniforms.time * 0.3), cos(uniforms.time * 0.4)) * 0.14) * 0.9 + clouds * 0.45;
        float threshold = progress * 1.25;
        float edge = smoothstep(threshold - 0.07, threshold, burnValue) * (1.0 - smoothstep(threshold, threshold + 0.045, burnValue));
        float sparks = step(0.985, noise(float2(floor(uv.x * 90.0), floor((uv.y - uniforms.time * 0.08) * 90.0)) + uniforms.seed));
        energy = edge * 2.0 + sparks * smoothstep(0.8, 0.2, abs(burnValue - threshold));
        atmosphere = smoothstep(threshold + 0.04, threshold - 0.04, burnValue) * 0.55;
    } else if (uniforms.style == 27) {
        // Six-fold growing crystalline branches.
        float growth = 0.08 + 0.48 * (0.5 + 0.5 * sin(uniforms.time * 0.55));
        float angle = atan2(p.y, p.x);
        float radius = length(p);
        float folded = abs(fract(angle / (2.0 * M_PI_F) * 6.0 + 0.5) - 0.5);
        float branch = folded * radius;
        float mainStem = lineGlow(branch, 0.006) * step(radius, growth);
        float sideBranches = pow(1.0 - abs(sin(radius * 65.0 - folded * 16.0)), 10.0) * step(radius, growth);
        energy = mainStem + sideBranches;
        atmosphere = fbm(p * 5.0 + uniforms.time * 0.04, uniforms.detail) * 0.35;
    } else if (uniforms.style == 28) {
        // Pulsing colored circles in a regular grid.
        float2 grid = p / 0.075;
        float2 cellID = floor(grid);
        float2 local = fract(grid) - 0.5;
        float distanceFromCenter = length(cellID) * 0.075;
        float wave = 0.5 + 0.5 * sin(distanceFromCenter * 16.0 - uniforms.time * 3.0);
        float circle = smoothstep(0.16 + wave * 0.20, 0.08 + wave * 0.12, length(local));
        energy = circle * (0.35 + wave);
        atmosphere = wave * 0.45;
    } else if (uniforms.style == 29) {
        // Hexagonal cells with radial color pulses.
        float2 q = p * 8.0;
        q.x *= 1.1547;
        float row = floor(q.y);
        q.x += fmod(row, 2.0) * 0.5;
        float2 cell = fract(q) - 0.5;
        float2 cellID = floor(q);
        float hexDistance = max(abs(cell.x) * 0.866 + abs(cell.y) * 0.5, abs(cell.y));
        float radial = length(cellID) * 0.12;
        float pulse = pow(0.5 + 0.5 * sin(radial * 5.0 - uniforms.time * 2.0), 3.0);
        float edge = smoothstep(0.48, 0.39, hexDistance) - smoothstep(0.39, 0.31, hexDistance);
        energy = edge * (0.4 + pulse * 1.4);
        atmosphere = pulse * smoothstep(0.45, 0.05, hexDistance);
    } else if (uniforms.style == 30) {
        // Halloween moon, jack-o'-lantern eyes, drifting fog, and bats.
        float moon = exp(-length(p - float2(0.28, -0.24)) * 12.0);
        float2 face = p * float2(1.0, 1.25) + float2(0.0, 0.16);
        float pumpkin = smoothstep(0.43, 0.37, length(face));
        float eyeA = smoothstep(0.09, 0.025, length(face - float2(-0.15, -0.05)));
        float eyeB = smoothstep(0.09, 0.025, length(face - float2(0.15, -0.05)));
        float mouth = smoothstep(0.045, 0.012, abs(face.y - 0.14 - abs(face.x) * 0.18)) * step(abs(face.x), 0.24);
        float bats = step(0.965, noise(floor((p + uniforms.time * float2(-0.08, 0.02)) * 18.0) + uniforms.seed));
        energy = (eyeA + eyeB + mouth) * pumpkin + moon + bats * 0.55;
        atmosphere = clouds * 0.72 + pumpkin * 0.18;
    } else if (uniforms.style == 31) {
        // Birthday confetti, balloons, and a pulsing cake glow.
        float2 confettiGrid = floor((uv + float2(0.0, uniforms.time * 0.12)) * 28.0);
        float confetti = step(0.88, hash21(confettiGrid + uniforms.seed));
        float2 balloonP = p - float2(sin(uniforms.time * 0.7) * 0.18, -0.08 + cos(uniforms.time * 0.45) * 0.04);
        float balloon = smoothstep(0.22, 0.17, length(balloonP * float2(1.0, 1.25)));
        float cake = smoothstep(0.035, 0.012, abs(p.y - 0.25)) * step(abs(p.x), 0.34);
        float candles = pow(saturate(sin((p.x + 0.35) * 45.0)), 18.0) * step(abs(p.x), 0.32) * smoothstep(0.23, 0.05, abs(p.y));
        energy = confetti * 0.65 + balloon + cake + candles;
        atmosphere = 0.35 + 0.35 * sin(p.x * 5.0 + p.y * 4.0 + uniforms.time);
    } else if (uniforms.style == 32) {
        // A deep dark area with barely visible moving fractures.
        float radius = length(p);
        float fracture = abs(sin(p.x * 17.0 + fbm(p * 5.0 + uniforms.time * 0.05, uniforms.detail) * 8.0));
        float cracks = pow(1.0 - fracture, 20.0);
        float distantPulse = exp(-length(p - float2(sin(uniforms.time * 0.2), cos(uniforms.time * 0.17)) * 0.3) * 9.0);
        energy = cracks * 0.3 + distantPulse * 0.18;
        atmosphere = clouds * 0.09 * smoothstep(0.95, 0.12, radius);
    } else if (uniforms.style == 33) {
        // Dragon eye surrounded by animated overlapping scales.
        float2 scaleGrid = p * float2(12.0, 9.0);
        float2 scaleCell = fract(scaleGrid + float2(fmod(floor(scaleGrid.y), 2.0) * 0.5, 0.0)) - 0.5;
        float scales = lineGlow(abs(length(scaleCell * float2(1.0, 1.35)) - 0.42), 0.007);
        float2 eyeP = p * float2(1.0, 2.2);
        float iris = smoothstep(0.29, 0.20, length(eyeP));
        float pupil = smoothstep(0.055, 0.02, abs(eyeP.x + sin(eyeP.y * 7.0 + uniforms.time) * 0.012)) * iris;
        energy = scales * 0.42 + iris * 0.75 + pupil * 1.5;
        atmosphere = fbm(p * 3.0 + uniforms.time * 0.04, uniforms.detail) * 0.5;
    } else if (uniforms.style == 34) {
        // Martial-arts ink circle with fast directional strikes.
        float radius = length(p);
        float inkCircle = lineGlow(abs(radius - 0.30 - (warpA - 0.5) * 0.025), 0.008);
        float strikeA = lineGlow(abs(p.y - p.x * 0.55 - sin(uniforms.time * 3.0) * 0.08), 0.006);
        float strikeB = lineGlow(abs(p.y + p.x * 1.6 + cos(uniforms.time * 2.4) * 0.06), 0.004);
        float yinDot = exp(-length(p - float2(0.0, 0.14)) * 28.0) + exp(-length(p + float2(0.0, 0.14)) * 28.0);
        energy = inkCircle + (strikeA + strikeB) * smoothstep(0.75, 0.08, radius) + yinDot;
        atmosphere = fbm(p * 6.0 + seed, uniforms.detail) * 0.28;
    } else if (uniforms.style == 35) {
        // Arcade beat-'em-up impact burst, speed lines, and hit flash.
        float2 impact = p - float2(sin(uniforms.time * 1.4) * 0.16, cos(uniforms.time * 1.1) * 0.08);
        float radius = length(impact);
        float angle = atan2(impact.y, impact.x);
        float speedLines = pow(abs(cos(angle * 14.0 + uniforms.time * 2.0)), 24.0) * smoothstep(0.75, 0.08, radius);
        float hitRing = lineGlow(abs(radius - 0.22 - 0.035 * sin(uniforms.time * 6.0)), 0.009);
        float slash = lineGlow(abs(impact.y - impact.x * 0.35), 0.008) * smoothstep(0.55, 0.03, radius);
        energy = speedLines + hitRing + slash;
        atmosphere = saturate(0.25 + clouds * 0.45 + sin(angle * 4.0) * 0.12);
    } else if (uniforms.style == 36) {
        // Smooth animated tint wash with luminous contour bands.
        float gradient = saturate(uv.x * 0.58 + uv.y * 0.42 + (warpA - 0.5) * 0.24);
        float contours = pow(1.0 - abs(sin((gradient + uniforms.time * 0.08) * 24.0)), 12.0);
        float softSpot = exp(-length(p - float2(sin(uniforms.time * 0.35), cos(uniforms.time * 0.29)) * 0.26) * 4.5);
        energy = contours * 0.42 + softSpot * 0.55;
        atmosphere = gradient;
    } else {
        // Layered organic brush strokes with rough animated edges.
        float strokeA = abs(p.y - sin(p.x * 5.0 + uniforms.time * 0.55) * 0.16 - (warpA - 0.5) * 0.12);
        float strokeB = abs(p.y + 0.24 - sin(p.x * 7.0 - uniforms.time * 0.42) * 0.11 - (warpB - 0.5) * 0.10);
        float strokeC = abs(p.y - 0.25 + cos(p.x * 4.0 + uniforms.time * 0.35) * 0.13);
        float roughA = smoothstep(0.12 + noise(p * 24.0) * 0.06, 0.025, strokeA);
        float roughB = smoothstep(0.10 + noise(p * 31.0 + 4.0) * 0.05, 0.02, strokeB);
        float roughC = smoothstep(0.09 + noise(p * 27.0 - 8.0) * 0.04, 0.018, strokeC);
        energy = roughA * 0.75 + roughB * 0.62 + roughC * 0.48;
        atmosphere = fbm(p * float2(2.0, 7.0) + uniforms.time * 0.04, uniforms.detail) * 0.55;
    }

    float3 deep = uniforms.shadowColor.rgb;
    float3 mid = uniforms.energyColor.rgb;
    float3 bright = uniforms.highlightColor.rgb;

    float3 color = mix(deep, mid, smoothstep(0.12, 0.88, atmosphere));
    color += bright * energy * (0.30 + uniforms.glow * 1.25);

    float starCell = hash21(floor((uv + uniforms.seed) * uniforms.resolution / 3.0));
    float stars = step(0.994, starCell) * pow(hash21(uv * 913.0 + uniforms.seed), 10.0);
    float starMask = uniforms.style == 1 || uniforms.style == 2 ? 0.3 : 1.0;
    color += bright * stars * starMask * (1.0 + uniforms.glow * 2.2);

    float vignette = smoothstep(0.96, 0.18, length((uv - 0.5) * float2(0.85, 1.0)));
    color *= 0.50 + 0.50 * vignette;
    color = pow(max(color, 0.0), float3(0.88));
    return float4(color, 1.0);
}
