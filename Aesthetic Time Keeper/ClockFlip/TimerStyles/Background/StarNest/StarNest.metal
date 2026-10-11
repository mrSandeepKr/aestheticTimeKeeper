// Star Nest — Pablo Roman Andrioli ("Kali"). MIT License.
// Source: https://www.shadertoy.com/view/XlfGRj
// Ported from GLSL to Metal for SwiftUI `.colorEffect`.
//
// ponytail: volsteps/iterations are the GPU-cost knobs (~340 inner steps/pixel).
// If it drops frames on older hardware, lower them (e.g. 12/14); the look barely changes.

#include <metal_stdlib>
using namespace metal;

#define iterations 17
#define formuparam 0.53
#define volsteps   20
#define stepsize   0.1
#define zoom       0.800
#define tile       0.850
#define speed      0.010
#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

// GLSL mat2(a, b, -b, a) — column-major.
static float2x2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return float2x2(float2(c, s), float2(-s, c));
}

// GLSL `v * M` (row-vector × matrix): r[j] = v.x*M[0][j] + v.y*M[1][j].
static float2 mulRow(float2 v, float2x2 m) {
    return float2(v.x * m[0].x + v.y * m[1].x,
                  v.x * m[0].y + v.y * m[1].y);
}

// GLSL mod(): always non-negative for a positive divisor (MSL fmod is not).
static float3 glslMod(float3 x, float3 y) {
    return x - y * floor(x / y);
}

[[ stitchable ]] half4 starNest(float2 position, half4 color, float2 size, float time) {
    // get coords and direction
    float2 uv = position / size - 0.5;
    uv.y *= size.y / size.x;
    float3 dir = float3(uv * zoom, 1.0);
    float t = time * speed + 0.25;

    // mouse rotation (fixed — SwiftUI colorEffect has no pointer uniform)
    float2x2 rot1 = rot2(0.5);
    float2x2 rotA = rot2(0.8);
    float2 d1 = mulRow(float2(dir.x, dir.z), rot1);
    dir = float3(d1.x, dir.y, d1.y);
    float2 d2 = mulRow(float2(dir.x, dir.y), rotA);
    dir = float3(d2.x, d2.y, dir.z);

    float3 from = float3(1.0, 0.5, 0.5);
    from += float3(t * 2.0, t, -2.0);
    float2 f1 = mulRow(float2(from.x, from.z), rot1);
    from = float3(f1.x, from.y, f1.y);
    float2 f2 = mulRow(float2(from.x, from.y), rotA);
    from = float3(f2.x, f2.y, from.z);

    // volumetric rendering
    float s = 0.1, fade = 1.0;
    float3 v = float3(0.0);
    for (int r = 0; r < volsteps; r++) {
        float3 p = from + s * dir * 0.5;
        p = abs(float3(tile) - glslMod(p, float3(tile * 2.0))); // tiling fold
        float pa = 0.0, a = 0.0;
        for (int i = 0; i < iterations; i++) {
            p = abs(p) / dot(p, p) - formuparam; // the magic formula
            a += abs(length(p) - pa);             // absolute sum of average change
            pa = length(p);
        }
        float dm = max(0.0, darkmatter - a * a * 0.001); // dark matter
        a *= a * a;                                       // add contrast
        if (r > 6) fade *= 1.0 - dm;                      // don't render near
        v += fade;
        v += float3(s, s * s, s * s * s * s) * a * brightness * fade;
        fade *= distfading; // distance fading
        s += stepsize;
    }
    v = mix(float3(length(v)), v, saturation); // color adjust
    return half4(half3(v * 0.01), 1.0);
}
