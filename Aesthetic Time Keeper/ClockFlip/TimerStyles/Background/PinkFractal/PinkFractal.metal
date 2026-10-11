// Pink Fractal raymarcher — ported from Shadertoy-style GLSL to Metal for
// SwiftUI `.colorEffect`. Tint recolored from warm yellow/orange to pink.
//
// ponytail: measured on M3 at 1179x2556 — `samples 3` was 230 ms/frame (~4 fps).
// `samples 1` is 25 ms; the view renders it at half-res and upscales, so AA here
// is wasted anyway. Next knobs if still slow: the two loop counts (100/30) below.

#include <metal_stdlib>
using namespace metal;

#define samples 1

// Animation speed multiplier: 1.0 = original Shadertoy rate, 0.5 = half, 2.0 = double.
constant float SPEED = 0.5;

// Palette: a low-saturation dusty rose, tuned to read calm behind the clock
// (the hot-magenta original was ~3x more saturated and distracting).
// Measured lit-pixel average: ~RGB(156,131,139) — gentle, warm, cohesive.
constant float3 KEY_COLOR    = float3(1.00, 0.84, 0.88); // soft rose highlight
constant float3 RIM_COLOR    = float3(0.98, 0.78, 0.86); // warm rose rim
constant float3 STRIPE_COLOR = float3(0.92, 0.70, 0.76); // muted rose stripes

// GLSL mat2(c, -s, s, c) — column-major, so it matches Metal's float2x2 layout.
static float2x2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return float2x2(float2(c, -s), float2(s, c));
}

// GLSL mod(): always non-negative for a positive divisor (Metal's fmod is not).
static float2 glslMod(float2 x, float2 y) {
    return x - y * floor(x / y);
}

// cir1 hands back its final x/y — the caller reads them for the rim/stripe color.
static float cir1(float2 p, thread float &ox, thread float &oy) {
    float x = 1000.0, y = 1000.0;
    for (float i = 0.0; i < 7.0; i++) {
        p = abs(p) / clamp(p.x * p.y, 0.3, 5.0) - 1.0;
        x = min(x, abs(p.x));
        y = min(y, abs(p.y));
    }
    x = exp(-0.5 * x);
    y = exp(-1.0 * y);
    ox = x;
    oy = y;
    return x - y * 0.1;
}

static float cir2(float2 p) {
    p.x -= 1.5;
    float x = 1000.0, y = 1000.0;
    for (float i = 0.0; i < 5.0; i++) {
        p = abs(p) / clamp(abs(p.x * p.y), 0.2, 2.0) - 1.0;
        x = min(x, abs(p.x));
        y = min(y, abs(p.y));
    }
    return exp(-0.7 * y) - x * 0.1;
}

static float struc(float3 p) {
    float d = length(p + float3(0.0, -3.0, 0.0)) + 0.6;
    d = min(d, length(p.xy + float2(0.0, -3.0)) + 1.3);
    d = min(d, length(p.zy + float2(0.0, -3.0)) + 1.5);
    float2 s = sign(p.xz);
    p.xz = abs(p.xz);
    d = min(d, max(length(p.xz - 5.0 - s * 0.5) + 0.5 + p.y * 0.2, p.y - 2.0));
    return d;
}

static float de(float3 p, float time, thread float &ox, thread float &oy) {
    // GLSL `p.yz *= rot(.6)` is `p.yz * rot(.6)` (row-vec × matrix), NOT
    // `rot(.6) * p.yz`. That transpose matters: with the order flipped the rays
    // sweep away from the geometry and the whole frame renders black.
    p.yz = p.yz * rot2(0.6);
    p.xz = p.xz * rot2(0.6);
    p.xy += time * 0.7 * SPEED + 15.0;
    p.x += time * 0.3 * SPEED;
    p.xz = glslMod(p.xz, float2(16.0)) - 8.0;
    float r1 = cir1(p.xz * 0.1, ox, oy);
    float r2 = cir2(p.yz * 0.02);
    float d = min(p.y, struc(p));
    d -= r1 * 0.7 + r2 * 1.2;
    return d * 0.5;
}

static float3 normal(float3 p, float time, thread float &ox, thread float &oy) {
    const float det = 0.005;
    float2 e = float2(0.0, det);
    return normalize(float3(de(p + e.yxx, time, ox, oy),
                            de(p + e.xyx, time, ox, oy),
                            de(p + e.xxy, time, ox, oy)) - de(p, time, ox, oy));
}

static float3 march(float3 from, float3 dir, float time) {
    const float det = 0.005;
    float ox = 0.0, oy = 0.0;
    from.xy *= 5.0;
    float3 p = from;
    float3 col = float3(0.0);
    float d = 0.0;
    for (int i = 0; i < 100; i++) {
        p += d * dir;
        d = de(p, time, ox, oy);
        if (d < det) break;
    }
    if (d < det) {
        float cx = ox, cy = oy;
        float3 n = normal(p, time, ox, oy);
        float3 ldir = normalize(float3(-1.0, 1.0, -1.0));
        float dif = smoothstep(0.8, 1.0, max(0.0, dot(ldir, n)));
        dif += smoothstep(0.5, 0.8, max(0.0, dot(-dir, n))) * 0.35;
        col = KEY_COLOR * dif;
        float shadow = 1.0;
        float3 shadowRay = p + n * 0.01;
        for (int i = 0; i < 30; i++) {
            float sd = de(shadowRay, time, ox, oy);
            if (sd < 0.005) { shadow = 0.0; break; }
            shadowRay += ldir * sd;
        }
        col += step(cx, 0.87) * RIM_COLOR * 0.5;
        col *= 0.3 + shadow * 0.7;
        col += step(fract(cy * 3.0), 0.25) * STRIPE_COLOR;
    }
    return col;
}

static float3 antialiasedMarch(float3 from, float3 dir, float2 res, float time) {
    float3 color = float3(0.0);
    float2 offsetScale = 2.0 / res;
    for (int i = 0; i < samples; i++) {
        for (int j = 0; j < samples; j++) {
            float2 offset = float2(float(i), float(j)) / float(samples) - 0.5;
            float3 displacedFrom = from + float3(offset * offsetScale, 0.0);
            color += march(displacedFrom, dir, time);
        }
    }
    return color / float(samples * samples);
}

[[ stitchable ]] half4 pinkFractal(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position - size * 0.5) / size.y;
    float3 from = float3(uv, -6.0);
    float3 dir = normalize(float3(0.0, 0.0, 1.0));
    float3 col = antialiasedMarch(from, dir, size, time) + 0.05;
    col *= exp(-3.0 * length(position / size - 0.5)) * 1.3 + 0.2;
    return half4(half3(col), 1.0);
}
