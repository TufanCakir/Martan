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
    } else {
        // Spiraling portal rings collapsing into a dark center.
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float spiral = sin(radius * 48.0 - angle * 7.0 + warpA * 6.0 + seed);
        float rings = pow(1.0 - abs(spiral), 7.0);
        float halo = lineGlow(abs(radius - 0.32 - (warpB - 0.5) * 0.04), 0.008);
        energy = (rings * smoothstep(0.72, 0.08, radius) + halo) * smoothstep(0.05, 0.18, radius);
        atmosphere = fbm(float2(radius * 4.0, angle * 0.8) + seed, uniforms.detail);
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
