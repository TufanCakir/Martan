#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float seed;
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
    float seed = uniforms.seed;

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
    } else {
        // Interleaved dimensional planes and a central rift.
        float planes = abs(sin((p.x + p.y * 0.55 + warpA * 0.15) * 26.0));
        float rift = lineGlow(abs(p.x + sin(p.y * 8.0 + seed) * 0.08), 0.009);
        float layers = pow(1.0 - planes, 9.0) * smoothstep(0.9, 0.05, length(p));
        energy = layers + rift;
        atmosphere = mix(clouds, fbm(p.yx * 5.0 - seed, uniforms.detail), 0.5);
    }

    float3 deep = uniforms.shadowColor.rgb;
    float3 mid = uniforms.energyColor.rgb;
    float3 bright = uniforms.highlightColor.rgb;

    float3 color = mix(deep, mid, smoothstep(0.12, 0.88, atmosphere));
    color += bright * energy * (0.30 + uniforms.glow * 1.25);

    float starCell = hash21(floor((uv + seed) * uniforms.resolution / 3.0));
    float stars = step(0.994, starCell) * pow(hash21(uv * 913.0 + seed), 10.0);
    float starMask = uniforms.style == 1 || uniforms.style == 2 ? 0.3 : 1.0;
    color += bright * stars * starMask * (1.0 + uniforms.glow * 2.2);

    float vignette = smoothstep(0.96, 0.18, length((uv - 0.5) * float2(0.85, 1.0)));
    color *= 0.50 + 0.50 * vignette;
    color = pow(max(color, 0.0), float3(0.88));
    return float4(color, 1.0);
}
