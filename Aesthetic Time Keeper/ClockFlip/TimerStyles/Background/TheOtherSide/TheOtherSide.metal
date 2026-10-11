// The Other Side — night sea under an aurora.
// Ported from GLSL (Shadertoy) to Metal for SwiftUI `.colorEffect`.
//
// ponytail: fully procedural, one stitchable fragment shader — no textures, no
// extra uniforms beyond size/time. The heavy layers (aurora raymarch, boat
// sphere-trace, water reflections) are all still here; the GPU-cost knobs are
// AURORA_STEPS / AURORA_STEPS_REFL / BOAT_STEPS below. Water is anchored to the
// bottom band of the frame (HORIZON) so the centred timer sits over the sky.

#include <metal_stdlib>
using namespace metal;

#define PI 3.14159265359
#define TAU 6.28318530718

#define EXPOSURE 1.0

// ---- camera / framing -------------------------------------------------------
constant float CAM_HEIGHT = 1.2;    // eye height above the water plane (y = 0)
constant float HORIZON    = 0.28;   // horizon height as a fraction of the frame, from the bottom
constant float FOCAL      = 1.5;    // focal length in frame heights (larger = narrower FOV)

// ---- quality (GPU-cost knobs; lower them first if it drops frames) ----------
#define AURORA_STEPS      32        // aurora samples for the direct view
#define AURORA_STEPS_REFL 8         // aurora samples inside water reflections
constant float AURORA_REFL_GAIN = 0.3;
#define BOAT_STEPS        48        // sphere-tracing steps inside the boat box

// Per-pixel uniforms, threaded through everything (MSL has no mutable globals).
struct Uni {
    float2 res;    // view size in points
    float2 frag;   // Shadertoy fragCoord: origin at the bottom-left
    float time;
    float3 cam;    // camera position (gCamPos)
};

// ---- math -------------------------------------------------------------------
static float2x2 rot(float a) {
    float c = cos(a), s = sin(a);
    return float2x2(float2(c, s), float2(-s, c)); // GLSL mat2(c, s, -s, c)
}

// GLSL mod(): always non-negative for a positive divisor (MSL fmod is not).
static float  glslMod(float x, float y)  { return x - y * floor(x / y); }
static float2 glslMod(float2 x, float y) { return x - y * floor(x / y); }

// ---- hashes (Dave Hoskins, "Hash without Sine", MIT) ------------------------
static float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
static float hash12(float2 p) {
    float3 p3 = fract(p.xyx * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
static float2 hash22(float2 p) {
    float3 p3 = fract(p.xyx * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
// Integer hash for lattice cells (stable for large coordinates).
static float3 hash33i(int3 q) {
    uint3 p = uint3(q);
    p = p * uint3(374761393u, 1103515245u, 668265263u) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3u));
    return float3(p ^ (p >> 16u)) * (1.0 / 4294967295.0);
}

// ---- value noise ------------------------------------------------------------
static float noise(float2 x) {
    float2 i = floor(x);
    float2 f = fract(x);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + float2(1.0, 0.0));
    float c = hash12(i + float2(0.0, 1.0));
    float d = hash12(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ---- colour -----------------------------------------------------------------
static float3 srgbToLinear(float3 c) { return pow(c, float3(2.2)); }
static float3 linearToSrgb(float3 c) { return pow(max(c, 0.0), float3(1.0 / 2.2)); }
static float3 hexColor(int h) {
    return srgbToLinear(float3(float((h >> 16) & 255), float((h >> 8) & 255), float(h & 255)) / 255.0);
}

// Gradient noise with analytic derivatives (after Inigo Quilez, MIT).
// Returns (value, d/dx, d/dy). Used by the water and the swell height.
static float3 waterNoised(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u  = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);

    float2 ga = hash22(i) * 2.0 - 1.0;
    float2 gb = hash22(i + float2(1.0, 0.0)) * 2.0 - 1.0;
    float2 gc = hash22(i + float2(0.0, 1.0)) * 2.0 - 1.0;
    float2 gd = hash22(i + float2(1.0, 1.0)) * 2.0 - 1.0;

    float va = dot(ga, f);
    float vb = dot(gb, f - float2(1.0, 0.0));
    float vc = dot(gc, f - float2(0.0, 1.0));
    float vd = dot(gd, f - float2(1.0, 1.0));

    float k = va - vb - vc + vd;
    float v = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * k;
    float2 d = ga + u.x * (gb - ga) + u.y * (gc - ga) + u.x * u.y * (ga - gb - gc + gd)
             + du * (u.yx * k + float2(vb, vc) - va);
    return float3(v, d);
}

// Swell height (m), defined in the water layer but needed by the boat's float.
static float waterSwellHeight(float2 xz, float time);

// ---- sky (no aurora) --------------------------------------------------------
constant int   SKY_TOP      = 0x003f5b;
constant int   SKY_LIFT     = 0x007280;
constant float SKY_LIFT_H   = 0.17;
constant int   SKY_HAZE     = 0x8ea5a0;
constant int   SKY_BAND     = 0x262c2c;
constant float SKY_BAND_Y   = 0.016;
constant float SKY_BAND_W   = 0.014;
constant float SKY_SIDE_AZ  = 0.38;
constant float SKY_SIDE_WL  = 0.65;
constant float SKY_HAZE_WL  = 0.42;
constant float SKY_SIDE_WR  = 0.30;
constant float SKY_GAIN_LO  = 0.70;
constant float SKY_GAIN_HI  = 1.58;
constant float SKY_HAZE_LO  = 0.08;
constant float SKY_HAZE_HI  = 0.85;
constant float SKY_HAZE_HLO = 0.065;
constant float SKY_HAZE_HHI = 0.095;
constant float SKY_DIM      = 0.90;
constant float SKY_DIM_TL   = 0.80;
constant float4 SKY_DIM_TL_R = float4(-0.05, -0.45, 0.08, 0.36);

constant float STAR_CELL[3] = {0.0105, 0.020, 0.050};
constant float STAR_PROB[3] = {0.75, 0.6, 0.5};
constant float STAR_PEAK[3] = {0.16, 0.42, 1.1};
constant float STAR_SKEW      = 2.6;
constant float STAR_SIZE      = 2.2e-4;
constant float STAR_AA        = 0.42;
constant float STAR_EXT       = 0.055;
constant float STAR_TWINKLE   = 0.14;
constant float STAR_TW_LOW    = 1.6;
constant float STAR_TW_RATE   = 4.0;
constant float STAR_TW_OCT2   = 0.6;
constant float STAR_TW_FAINT  = 0.25;
constant float STAR_TW_BRIGHT = 0.35;
constant float STAR_TW_CHROMA = 0.4;
constant float STAR_GAIN     = 2.0; // overall star brightness multiplier
constant int   STAR_STARS_PER_CELL = 2; // independent stars per cell => that many times as many

// Smooth 1D value noise for star twinkle: three channels in [-0.5, 0.5].
static float3 starNoise(int2 id, int salt, float t) {
    float n = floor(t);
    float f = t - n;
    f = f * f * (3.0 - 2.0 * f);
    int z = 0x100000 + salt + 8 * int(n); // clear of the position hashes
    return mix(hash33i(int3(int2(id), z)), hash33i(int3(int2(id), z + 8)), f) - 0.5;
}

static float3 skyStars(float3 rd, float az, Uni u) {
    float el = asin(clamp(rd.y, -1.0, 1.0));
    float2 sp = float2(az, el);
    float cosEl = cos(el);

    float pa = 1.0 / (u.res.y * FOCAL);
    float s2 = STAR_SIZE * STAR_SIZE;
    float sigma2 = s2 + (STAR_AA * pa) * (STAR_AA * pa);
    float ref = STAR_AA / (1080.0 * FOCAL);
    float norm = (s2 + ref * ref) / sigma2;

    float airmass = 1.0 / (max(rd.y, 0.0) + 0.012);
    float ext = exp(-STAR_EXT * airmass) * smoothstep(-0.005, 0.01, rd.y);
    float twAmt = STAR_TWINKLE * min(pow(max(airmass * 0.4, 1.0), 0.4), STAR_TW_LOW);
    float twChroma = STAR_TW_CHROMA * smoothstep(0.1, 0.02, rd.y);

    float3 col = float3(0.0);
    for (int i = 0; i < 3; i++) {
        float cell = STAR_CELL[i];
        float2 g = sp / cell;
        float2 id = floor(g);
        // STAR_STARS_PER_CELL independent draws per cell => that many times more stars,
        // with cell size, star size and the lod fade left untouched.
        for (int j = 0; j < STAR_STARS_PER_CELL; j++) {
            int seed = 7919 * (i * STAR_STARS_PER_CELL + j) + 17;
            float3 h = hash33i(int3(int2(id), seed));
            if (h.z > STAR_PROB[i]) continue;
            float3 k = hash33i(int3(int2(id), seed + 1));

            float2 d = (fract(g) - (0.2 + 0.6 * h.xy)) * cell;
            d.x *= cosEl;
            float shape = exp(-dot(d, d) / (2.0 * sigma2));

            float uu = h.z / STAR_PROB[i];
            float b = STAR_PEAK[i] * pow(k.x, STAR_SKEW);
            if (shape * b < 1e-5) continue;

            float3 tint = mix(float3(0.78, 0.9, 1.0), float3(1.0), fract(uu * 7.0));
            tint = uu > 0.95 ? float3(1.0, 0.9, 0.78) : tint;

            float tt = u.time * STAR_TW_RATE * (0.7 + 0.6 * k.y) + 113.0 * k.z;
            int ns = 2 * (i * STAR_STARS_PER_CELL + j) + 1;
            float3 n = starNoise(int2(id), ns, tt) + STAR_TW_OCT2 * starNoise(int2(id), ns + 1, 2.37 * tt);
            n *= 4.02 / sqrt(1.0 + STAR_TW_OCT2 * STAR_TW_OCT2);
            float sig = twAmt * mix(STAR_TW_FAINT, 1.0, smoothstep(0.02, STAR_TW_BRIGHT, b * ext));
            b *= exp(sig * n.x - 0.5 * sig * sig);
            tint *= 1.0 + sig * twChroma * float3(n.y, -0.5 * n.y + 0.866 * n.z, -0.5 * n.y - 0.866 * n.z);

            float lod = smoothstep(3.0, 6.0, cell / pa);
            col += tint * (b * shape * lod);
        }
    }
    return col * norm * ext * STAR_GAIN;
}

static float3 skyBase(float3 rd, float starGain, float dim, Uni u) {
    float y = max(rd.y, 0.0);
    float az = atan2(rd.x, rd.z);
    float s = az - SKY_SIDE_AZ;
    float sh = s / (s < 0.0 ? SKY_HAZE_WL : SKY_SIDE_WR);
    s /= s < 0.0 ? SKY_SIDE_WL : SKY_SIDE_WR;
    float side = exp(-s * s);
    float sideHaze = exp(-sh * sh);

    float3 col = hexColor(SKY_TOP) + hexColor(SKY_LIFT) * exp(-(y * y) / (SKY_LIFT_H * SKY_LIFT_H));
    col *= mix(SKY_GAIN_LO, SKY_GAIN_HI, side);
    float hh = y / mix(SKY_HAZE_HLO, SKY_HAZE_HHI, sideHaze);
    float haze = mix(SKY_HAZE_LO, SKY_HAZE_HI, sideHaze) * exp(-hh * hh);
    col = mix(col, hexColor(SKY_HAZE), haze);
    float band = (y - SKY_BAND_Y) / SKY_BAND_W;
    col += hexColor(SKY_BAND) * max(1.0 - band * band, 0.0);
    float tl = smoothstep(SKY_DIM_TL_R.x, SKY_DIM_TL_R.y, az) * smoothstep(SKY_DIM_TL_R.z, SKY_DIM_TL_R.w, y);
    col *= mix(1.0, mix(SKY_DIM, SKY_DIM_TL, tl), dim);
    if (starGain > 0.0) col += skyStars(rd, az, u) * starGain;
    return col;
}

// ---- aurora (nimitz 2017, CC BY-NC-SA; adapted) -----------------------------
constant float4 AUR_ARC_A      = float4(0.02, 0.50, 0.178, 0.020);
constant float4 AUR_ARC_B      = float4(0.0, 0.88, 0.126, 0.016);
constant float2 AUR_SKEW       = float2(0.95, 0.52);
constant float2 AUR_FALL       = float2(0.0, 2.8);
constant float AUR_FOOT       = 0.8;
constant float AUR_ARC_B_GAIN = 1.25;
constant float AUR_GLOW       = 0.05;
constant float AUR_HALO       = 0.10;
constant float AUR_HALO_W     = 0.22;
constant float AUR_WOBBLE     = 0.010;
constant float AUR_DRIFT      = 0.03;
constant float AUR_TEX_SCALE  = 6.0;
constant float AUR_RAYS       = 0.4;
constant float AUR_RAY_FREQ   = 14.0;
constant float AUR_BODY       = 0.15;
constant float AUR_DENSITY    = 1.3;
constant float AUR_STRIDE     = 0.0015;
constant float AUR_LEAN       = 0.78;
constant float AUR_EXPOSE     = 1.5;
constant float AUR_TOE        = 1.8;
constant float AUR_HORIZON    = 0.65;
constant float AUR_LEFT_BOOST = 1.3;
constant float AUR_INTENSITY  = 0.55;
constant float AUR_OPACITY    = 0.35;
constant float3 AUR_COL_LOW    = float3(0.05, 1.00, 0.62);
constant float3 AUR_COL_HIGH   = float3(0.02, 0.55, 0.65);
constant float3 AUR_COL_CORE   = float3(0.45, 0.85, 0.52);
constant float2 AUR_CORE       = float2(0.55, 0.95);
constant float3 AUR_COL_HALO   = float3(0.006, 0.16, 0.14);

constant float AUR_MOTION     = 0.5;
constant float3 AUR_SLIDE      = float3(0.3, 0.35, 0.07);
constant float2 AUR_SLIDE_VAR  = float2(0.10, 0.06);
constant float2 AUR_SLIDE_RATE = float2(0.26, -0.34);
constant float AUR_WAVE       = 0.012;
constant float2 AUR_WAVE_RATE  = float2(0.70, 0.90);
constant float2 AUR_SURGE      = float2(0.24, 0.16);
constant float AUR_SURGE_OCT  = 0.35;
constant float AUR_SHIMMER    = 0.22;

static float2x2 aurM2() { return float2x2(float2(0.95534, 0.29552), float2(-0.29552, 0.95534)); }
static float aurTri(float x) { return clamp(abs(fract(x) - 0.5), 0.01, 0.49); }
static float2 aurTri2(float2 p) { return float2(aurTri(p.x) + aurTri(p.y), aurTri(p.y + aurTri(p.x))); }

static float triNoise2d(float2 p, float spd, float time) {
    float z = 1.8;
    float z2 = 2.5;
    float rz = 0.0;
    p *= rot(p.x * 0.06);
    float2 bp = p;
    for (float i = 0.0; i < 5.0; i++) {
        float2 dg = aurTri2(bp * 1.85) * 0.75;
        dg *= rot(glslMod(time * spd, TAU)); // wrapped: sin/cos lose precision for large angles
        p -= dg / z2;
        bp *= 1.3;
        z2 *= 0.45;
        z *= 0.42;
        p *= 1.21 + (rz - 1.0) * 0.02;
        rz += aurTri(p.x + aurTri(p.y)) * z;
        p = -(p * aurM2());
    }
    return clamp(1.0 / pow(rz * 29.0, 1.3), 0.0, 0.55);
}

static void aurArcSetup(float phi, float4 arc, float skew, float fall, float t, float tm, float dir,
                        thread float& e, thread float& invW) {
    float hw = arc.y * (phi > arc.x ? skew : 1.0);
    float x = (phi - arc.x) / hw;
    float d = 1.0 / (1.0 + fall * x * x);
    e = arc.z * (1.0 - x * x) * d;
    float slope = -2.0 * arc.z * x * (1.0 + fall) * d * d / hw;
    e += AUR_WOBBLE * (0.6 * sin(phi * 9.0 + t * AUR_DRIFT * 2.3) + 0.4 * sin(phi * 17.0 - t * AUR_DRIFT * 1.7 + 1.3));
    float2 ph = float2(7.0, 12.0) * phi - dir * glslMod(AUR_WAVE_RATE * tm, TAU) + float2(0.7, 2.9) * dir;
    float wa = AUR_WAVE * AUR_MOTION;
    e += wa * (0.6 * sin(ph.x) + 0.4 * sin(ph.y));
    slope += wa * (0.6 * 7.0 * cos(ph.x) + 0.4 * 12.0 * cos(ph.y));
    float w = arc.w * (1.0 + AUR_FOOT * clamp(1.0 - e / arc.z, 0.0, 1.0));
    invW = 1.0 / (w * sqrt(1.0 + slope * slope));
}

static float aurProfile(float y) {
    float y2 = y * y;
    return exp(-y2) + AUR_GLOW * exp(-y2 * 0.15);
}
constant float AUR_CUT = 5.5;

static float4 aurora(float3 ro, float3 rd, int steps, Uni u) {
    if (rd.y <= 0.0) return float4(0.0);

    float t = u.time;
    float tm = t * AUR_MOTION;
    float phi = atan2(rd.x, rd.z);
    float eA, iwA, eB, iwB;
    aurArcSetup(phi, AUR_ARC_A, AUR_SKEW.x, AUR_FALL.x, t, tm, 1.0, eA, iwA);
    aurArcSetup(phi, AUR_ARC_B, AUR_SKEW.y, AUR_FALL.y, t + 50.0, tm, -1.0, eB, iwB);
    float sA = mix(noise(float2(phi * 4.0 + t * AUR_DRIFT * 0.4 - tm * AUR_SURGE.x, 3.1 + tm * AUR_SURGE.y)),
                   noise(float2(phi * 9.0 - tm * AUR_SURGE.x * 1.7, 13.7 + tm * AUR_SURGE.y * 1.6)), AUR_SURGE_OCT);
    float sB = mix(noise(float2(phi * 5.0 - t * AUR_DRIFT * 0.3 + tm * AUR_SURGE.x, 7.3 + tm * AUR_SURGE.y)),
                   noise(float2(phi * 10.0 + tm * AUR_SURGE.x * 1.7, 21.1 + tm * AUR_SURGE.y * 1.6)), AUR_SURGE_OCT);
    float gA = mix(0.4, 0.7, smoothstep(0.42, 0.1, phi));
    gA *= 0.55 + 0.45 * sA;
    gA *= 1.0 + AUR_LEFT_BOOST * smoothstep(-0.15, -0.32, phi) * smoothstep(-0.54, -0.38, phi);
    float gB = AUR_ARC_B_GAIN * smoothstep(-0.34, -0.18, phi) * mix(0.85, 1.05, smoothstep(0.1, 0.3, phi));
    gB *= 0.55 + 0.45 * sB;
    gB *= mix(1.0, 0.15, smoothstep(0.22, 0.45, phi));
    if (gB < 1e-3) eB = -1.0;
    float vHi = max(eA + AUR_CUT / iwA, eB + AUR_CUT / iwB);
    float vLo = min(eA - AUR_CUT / iwA, eB - AUR_CUT / iwB);

    float hz = length(rd.xz);
    float pt0 = 1.0 / (rd.y * 2.0 + 0.4);
    float v0 = (1.0 / (pt0 * hz) - 0.4) * 0.5;
    float2 hy = float2(v0 - eA, v0 - eB) * float2(iwA, iwB) * AUR_HALO_W;
    float3 halo = AUR_COL_HALO * AUR_HALO * (gA * exp(-hy.x * hy.x) + gB * exp(-hy.y * hy.y));
    halo *= clamp(rd.y * 20.0 + AUR_HORIZON, 0.0, 1.0);

    float layMax = 0.8 + pow(50.0, 1.4) * AUR_STRIDE;
    float vMin = (0.8 / (layMax * pt0 * hz * pow(0.8 / layMax, AUR_LEAN)) - 0.4) * 0.5;
    if (vMin > vHi) return float4(halo, 0.0);

    float4 col = float4(0.0);
    float4 avgCol = float4(0.0);
    float k = 50.0 / float(steps);
    float dither = hash12(u.frag);
    float3 origin = float3(ro.x, 0.0, ro.z - 6.7);
    float spd = mix(0.06, AUR_SHIMMER, AUR_MOTION);
    float drift = AUR_MOTION * (AUR_SLIDE.x + AUR_SLIDE.y * sin(glslMod(AUR_SLIDE.z * tm, TAU)));
    float2 slVar = AUR_SLIDE_VAR * AUR_MOTION;
    float2 slPh = glslMod(AUR_SLIDE_RATE * tm, TAU) + float2(2.0, 3.5) * phi + float2(0.0, 1.7);
    float2 sl0 = slVar * sin(slPh);
    float ds = drift + sl0.x + sl0.y;
    float phiT = phi + ds;
    float shiftX = hz * ds;

    for (int j = 0; j < steps; j++) {
        float i = (float(j) + dither) * k;
        float of = 0.006 * k * dither * smoothstep(0.0, 15.0, i);
        float lay = 0.8 + pow(i, 1.4) * AUR_STRIDE;
        float pt = lay * pt0 - of;
        float v = (0.8 / (pt * hz * pow(0.8 / lay, AUR_LEAN)) - 0.4) * 0.5;
        if (v < vLo) break;
        float4 col2 = float4(0.0);
        if (v < vHi) {
            float band = gA * aurProfile((v - eA) * iwA) + gB * aurProfile((v - eB) * iwB);
            float2 bzx = origin.zx + pt * float2(rd.z, rd.x + shiftX);
            float2 tp = bzx * AUR_TEX_SCALE * (1.0 - AUR_RAYS)
                      + float2(phiT * AUR_RAY_FREQ, v * AUR_RAY_FREQ * 0.25) * AUR_RAYS;
            float rzt = (AUR_BODY + triNoise2d(tp, spd, u.time)) * band * AUR_DENSITY;
            col2 = float4(mix(AUR_COL_LOW, AUR_COL_HIGH, smoothstep(0.0, 50.0, i)) * rzt, rzt);
        }
        avgCol = mix(avgCol, col2, 0.5);
        col += avgCol * exp2(-i * 0.065 - 2.5) * smoothstep(0.0, 5.0, i) * k;
    }

    col *= clamp(rd.y * 20.0 + AUR_HORIZON, 0.0, 1.0);
    col = 1.0 - exp(-pow(col * AUR_EXPOSE, float4(AUR_TOE)));
    float core = smoothstep(AUR_CORE.x, AUR_CORE.y, col.a);
    col.rgb = mix(col.rgb, AUR_COL_CORE * col.a, core);
    return float4(col.rgb * AUR_INTENSITY + halo, col.a * AUR_OPACITY);
}

// ---- meteors ----------------------------------------------------------------
constant float METEOR_SLOT      = 1.2;
constant float METEOR_PROB      = 0.9;
constant float2 METEOR_X0        = float2(0.98, 1.12);
constant float2 METEOR_Y0        = float2(0.80, 0.98);
constant float2 METEOR_X1        = float2(-0.10, 0.05);
constant float2 METEOR_SLOPE     = float2(0.13, 0.17);
constant float METEOR_Y_MIN     = 0.45;
constant float2 METEOR_LIFE      = float2(0.6, 1.2);
constant float METEOR_RISE      = 0.08;
constant float2 METEOR_FADE      = float2(0.6, 0.95);
constant float METEOR_FADE_LEN  = 0.3;
constant float METEOR_PEAK      = 1.5;
constant float METEOR_TAIL_GAIN = 0.4;
constant float METEOR_TAIL      = 0.025;
constant float METEOR_WIDTH     = 1.5e-4;
constant float METEOR_AA        = 0.5;
constant float METEOR_HEAD_W    = 1.7;
constant float3 METEOR_HEAD_COL  = float3(1.0, 1.0, 0.97);
constant float3 METEOR_TAIL_COL  = float3(0.78, 0.9, 1.0);
constant float3 METEOR_END_COL   = float3(0.62, 0.95, 0.86);

static float3 meteorDir(float2 f, Uni u) {
    // Use the real view aspect, not a fixed 16:9: in portrait the old mapping
    // launched meteors ~30 deg off-axis and they never crossed the visible sky.
    return normalize(float3((f.x - 0.5) * (u.res.x / u.res.y), f.y - HORIZON, FOCAL));
}

static float3 meteors(float3 rd, Uni u) {
    float pa = 1.0 / (u.res.y * FOCAL);
    float ar = u.res.x / u.res.y;
    float w2 = METEOR_WIDTH * METEOR_WIDTH;
    float sig = sqrt(w2 + (METEOR_AA * pa) * (METEOR_AA * pa));
    float ref = sqrt(w2 + pow(METEOR_AA / (1080.0 * FOCAL), 2.0));
    float sigH = sig * METEOR_HEAD_W;

    float3 col = float3(0.0);
    float slot0 = floor(u.time / METEOR_SLOT);
    for (int i = 0; i < 2; i++) {
        float slot = slot0 - float(i);
        int si = int(slot);
        float3 h = hash33i(int3(si, 4507, 21));
        float3 k = hash33i(int3(si, 4507, 22));
        float3 m = hash33i(int3(si, 4507, 23));
        float life = mix(METEOR_LIFE.x, METEOR_LIFE.y, m.y);
        if (h.x > METEOR_PROB) continue;
        float t0 = slot * METEOR_SLOT + METEOR_SLOT * h.y;
        float uu = (u.time - t0) / life;
        if (uu <= 0.0 || uu >= 1.0) continue;

        float2 f0 = float2(mix(METEOR_X0.x, METEOR_X0.y, k.x), mix(METEOR_Y0.x, METEOR_Y0.y, k.y));
        float x1 = mix(METEOR_X1.x, METEOR_X1.y, k.z);
        float dx = abs(x1 - f0.x) * ar;
        float slope = mix(METEOR_SLOPE.x, min(METEOR_SLOPE.y, (f0.y - METEOR_Y_MIN) / dx), m.x);
        float3 p0 = meteorDir(f0, u);
        float3 p1 = meteorDir(float2(x1, f0.y - slope * dx), u);

        float c = dot(p0, p1);
        float3 tangent = normalize(p1 - c * p0);
        float x = dot(rd, cross(p0, tangent));
        if (abs(x) > 6.0 * sigH) continue;
        float len = acos(c);
        float tl = METEOR_TAIL * (len / life) * mix(0.8, 1.2, m.z);
        float s = atan2(dot(rd, tangent), dot(rd, p0));
        float d = len * uu * (1.1 - 0.1 * uu) - s;
        if (d < -6.0 * sigH || d > 8.0 * tl) continue;

        float fade = mix(METEOR_FADE.x, METEOR_FADE.y, h.z);
        float env = smoothstep(0.0, METEOR_RISE, uu)
                  * (1.0 - smoothstep(fade, min(fade + METEOR_FADE_LEN, 1.0), uu))
                  * mix(0.8, 1.0, smoothstep(0.0, 0.5, uu));
        float bri = METEOR_PEAK * mix(0.45, 1.0, hash12(float2(slot, 4507.0))) * env * (ref / sig);
        float head = exp(-(d * d + x * x) / (2.0 * sigH * sigH));
        float tail = exp(-x * x / (2.0 * sig * sig) - max(d, 0.0) / tl)
                   * smoothstep(-sig, sig, d) * smoothstep(0.0, 0.5 * tl, s);
        float f = 1.0 - exp(-max(d, 0.0) / tl);
        float3 tc = mix(METEOR_TAIL_COL, METEOR_END_COL, f * f);
        col += bri * (METEOR_HEAD_COL * head + tc * (METEOR_TAIL_GAIN * tail));
    }
    return col;
}

// ---- sky composites ---------------------------------------------------------
static float3 skyFull(float3 rd, Uni u) {
    float4 a = aurora(u.cam, rd, AURORA_STEPS, u);
    return skyBase(rd, 1.0, 1.0, u) * (1.0 - a.a) + a.rgb + meteors(rd, u);
}
static float3 skyRefl(float3 rd, float3 rdAur, int steps, Uni u) {
    float4 a = aurora(u.cam, rdAur, steps, u) * AURORA_REFL_GAIN;
    return skyBase(rd, 0.0, 0.0, u) * (1.0 - a.a) + a.rgb;
}

// ---- boat -------------------------------------------------------------------
constant float3 BOAT_POS        = float3(0.0, 0.0, 13.0);
constant float BOAT_YAW        = 0.42;
constant float BOAT_LEN        = 3.8;
constant float BOAT_BEAM       = 1.3;
constant float BOAT_FREEBOARD  = 0.31;
constant float BOAT_BOW_RISE   = 0.24;
constant float BOAT_STERN_RISE = 0.10;
constant float BOAT_BOW_RAKE   = 0.45;
constant float BOAT_STERN_RAKE = 0.18;
constant float BOAT_TRANSOM    = 0.58;
constant float BOAT_WALL       = 0.025;
constant float BOAT_RAIL       = 0.022;
constant float BOAT_RAIL_H     = 0.04;
constant float BOAT_LOCK_X     = -0.12;
constant float BOAT_LOCK_H     = 0.09;
constant float BOAT_OAR_LEN    = 2.2;
constant float BOAT_OAR_IN     = 0.62;
constant float2 BOAT_OAR_SWEEP  = float2(-0.55, -1.25);
constant float BOAT_OAR_FEATHER = 0.6;
constant float BOAT_OAR_DIP    = 0.12;
constant float2 BOAT_BLADE      = float2(0.55, 0.19);
constant float3 BOAT_RIDE       = float3(1.0, 0.85, 0.8);
constant float2 BOAT_PROBE      = float2(1.45, 0.55);
constant float3 BOAT_ALBEDO     = float3(0.09, 0.083, 0.075);
constant float3 BOAT_SKY        = float3(0.004, 0.075, 0.13);
constant float3 BOAT_GLOW       = float3(0.06, 0.24, 0.30);
constant float3 BOAT_SEA        = float3(0.002, 0.10, 0.16);
constant float BOAT_INSIDE_AO  = 0.35;
constant float BOAT_REFL_BLUR  = 0.02;
constant float2 BOAT_SEA_REACH  = float2(3.0, 5.0);

static float boatSheer(float x) {
    float xn = clamp(x / (0.5 * BOAT_LEN) + 0.1, -1.0, 1.0);
    return BOAT_FREEBOARD + xn * xn * (xn > 0.0 ? BOAT_BOW_RISE * (0.7 + 0.3 * xn) : BOAT_STERN_RISE);
}
static float boatStem(float y) {
    float s = clamp(y / (BOAT_FREEBOARD + BOAT_BOW_RISE), 0.0, 1.0);
    return 0.5 * BOAT_LEN - BOAT_BOW_RAKE * (1.0 - s) * (1.0 - s) + 0.6 * min(y, 0.0);
}
static float boatTransom(float y) {
    return -0.5 * BOAT_LEN + BOAT_STERN_RAKE * (1.0 - clamp(y / (BOAT_FREEBOARD + BOAT_STERN_RISE), 0.0, 1.0));
}
static float boatHalfBeam(float x, float y, float xs, float xt, float sheer) {
    float u = clamp((x - xt) / (xs - xt), 0.0, 1.0);
    float a = clamp((u - 0.42) / 0.58, 0.0, 1.0);
    float c = clamp((0.42 - u) / 0.42, 0.0, 1.0);
    float plan = (1.0 - a * a) * (1.0 - (1.0 - BOAT_TRANSOM) * c * c);
    float sect = pow(clamp((y + 0.3) / (sheer + 0.3), 0.0, 1.0), 0.35);
    return 0.5 * BOAT_BEAM * plan * sect;
}
static float boatOar(float3 q, float sweep) {
    float out_ = BOAT_OAR_LEN - BOAT_OAR_IN;
    float drop = asin((boatSheer(BOAT_LOCK_X) + 0.045 + BOAT_OAR_DIP) / out_);
    float3 d = float3(-sin(sweep) * cos(drop), -sin(drop), cos(sweep) * cos(drop));
    float3 w = normalize(cross(float3(0.0, 1.0, 0.0), d));
    float3 n = cross(d, w);
    float cf = cos(BOAT_OAR_FEATHER), sf = sin(BOAT_OAR_FEATHER);
    float3 wf = cf * w + sf * n, nf = cf * n - sf * w;
    float a = dot(q, d);
    float loom = length(q - clamp(a, -BOAT_OAR_IN, out_ - 0.5 * BOAT_BLADE.x) * d)
               - (a < -0.45 ? 0.016 : 0.021);
    float uu = clamp((a - (out_ - BOAT_BLADE.x)) / BOAT_BLADE.x, 0.0, 1.0);
    float hw = BOAT_BLADE.y * (0.3 + 0.2 * sqrt(uu));
    float3 b = float3(abs(a - (out_ - 0.5 * BOAT_BLADE.x)) - 0.5 * BOAT_BLADE.x,
                      abs(dot(q, wf)) - hw, abs(dot(q, nf)) - 0.012);
    float blade = length(max(b, 0.0)) + min(max(b.x, max(b.y, b.z)), 0.0);
    return min(loom, blade);
}
static float boatSdf(float3 p) {
    float sheer = boatSheer(p.x);
    float xs = boatStem(p.y), xt = boatTransom(p.y);
    float hb = boatHalfBeam(p.x, p.y, xs, xt, sheer);
    float ends = max(p.x - xs, xt - p.x);
    float hull = max(max(abs(p.z) - hb, p.y - sheer), max(ends, -0.3 - p.y));
    float cavity = max(max(abs(p.z) - (hb - BOAT_WALL), -0.15 - p.y),
                       max(p.x - (xs - 3.0 * BOAT_WALL), (xt + BOAT_WALL) - p.x));
    hull = max(hull, -cavity);
    float rail = max(max(abs(abs(p.z) - hb + 0.5 * (BOAT_WALL - BOAT_RAIL)) - 0.5 * (BOAT_WALL + BOAT_RAIL),
                         abs(p.y - sheer + 0.5 * BOAT_RAIL_H) - 0.5 * BOAT_RAIL_H),
                     max(p.x - xs + 0.05, xt + 0.01 - p.x));
    hull = min(hull, rail);
    float ls = boatSheer(BOAT_LOCK_X);
    float lz = boatHalfBeam(BOAT_LOCK_X, ls, boatStem(ls), boatTransom(ls), ls) - 0.5 * BOAT_WALL;
    float3 l = float3(p.x - BOAT_LOCK_X, p.y - ls, abs(p.z) - lz);
    float3 b = abs(l - float3(0.0, 0.015, 0.0)) - float3(0.035, 0.015, 0.02);
    float lock = length(max(b, 0.0)) + min(max(b.x, max(b.y, b.z)), 0.0);
    float2 horn = float2(abs(l.x) - 0.028, l.z);
    lock = min(lock, max(length(horn) - 0.009, abs(l.y - 0.5 * BOAT_LOCK_H) - 0.5 * BOAT_LOCK_H));
    float3 pv = float3(BOAT_LOCK_X, ls + 0.045, lz);
    float oar = min(boatOar(float3(p.x, p.y, -p.z) - pv, BOAT_OAR_SWEEP.x),
                    boatOar(p - pv, BOAT_OAR_SWEEP.y));
    return min(min(hull, lock), oar);
}
static float3 boatNormal(float3 p, float e0) {
    float2 e = float2(e0, -e0);
    return normalize(e.xyy * boatSdf(p + e.xyy) + e.yyx * boatSdf(p + e.yyx) +
                     e.yxy * boatSdf(p + e.yxy) + e.xxx * boatSdf(p + e.xxx));
}
static float3 boatShade(float3 p, float3 n, float3 glowDir) {
    float3 e = BOAT_SKY * (0.5 + 0.5 * n.y)
             + BOAT_GLOW * 0.35 * max(dot(n, glowDir), 0.0)
             + BOAT_SEA * 0.6 * (0.5 - 0.5 * n.y);
    float sheer = boatSheer(p.x);
    float hb = boatHalfBeam(p.x, p.y, boatStem(p.y), boatTransom(p.y), sheer);
    float inside = step(abs(p.z), hb - 0.5 * BOAT_WALL) * smoothstep(0.0, 0.25, sheer - p.y);
    return BOAT_ALBEDO * e * mix(1.0, BOAT_INSIDE_AO, inside);
}
static float boatSeaHeight(float2 xz, float time) {
    float r = length(xz - BOAT_POS.xz);
    if (r >= BOAT_SEA_REACH.y) return 0.0;
    return waterSwellHeight(xz, time) * (1.0 - smoothstep(BOAT_SEA_REACH.x, BOAT_SEA_REACH.y, r));
}
static float3 boatRide(float2 axis, float2 nrm, float time) {
    float2 c = BOAT_POS.xz;
    float hBow   = waterSwellHeight(c + BOAT_PROBE.x * axis, time);
    float hStern = waterSwellHeight(c - BOAT_PROBE.x * axis, time);
    float hFar   = waterSwellHeight(c + BOAT_PROBE.y * nrm, time);
    float hNear  = waterSwellHeight(c - BOAT_PROBE.y * nrm, time);
    float hMid   = waterSwellHeight(c, time);
    float heave = (hBow + hStern + hFar + hNear + 2.0 * hMid) / 6.0;
    float pitch = atan2(hBow - hStern, 2.0 * BOAT_PROBE.x);
    float roll  = atan2(hFar - hNear, 2.0 * BOAT_PROBE.y);
    return BOAT_RIDE * float3(heave, pitch, roll);
}
static float4 boat(float3 ro, float3 rd, float footprint, float soft, thread float& t, Uni u) {
    t = 0.0;
    float2 axis = float2(cos(BOAT_YAW), sin(BOAT_YAW));
    float2 nrm = float2(-axis.y, axis.x);
    float3 o = ro - BOAT_POS;
    o = float3(dot(o.xz, axis), o.y, dot(o.xz, nrm));
    float3 d = float3(dot(rd.xz, axis), rd.y, dot(rd.xz, nrm));

    float zo = 0.5 * BOAT_BEAM + (BOAT_OAR_LEN - BOAT_OAR_IN) + 0.15;
    float3 bmin = float3(-0.5 * BOAT_LEN - 0.08, -0.32, -zo);
    float3 bmax = float3( 0.5 * BOAT_LEN + 0.08, BOAT_FREEBOARD + BOAT_BOW_RISE + 0.12, zo);
    float3 inv = 1.0 / d;
    float3 ta = (bmin - 0.35 - o) * inv, tb = (bmax + 0.35 - o) * inv;
    float3 tn = min(ta, tb), tf = max(ta, tb);
    if (max(max(max(tn.x, tn.y), tn.z), 0.0) >= min(min(tf.x, tf.y), tf.z)) return float4(0.0);

    float3 ride = boatRide(axis, nrm, u.time);
    o.y -= ride.x;
    o.xy = rot(-ride.y) * o.xy; d.xy = rot(-ride.y) * d.xy;
    o.zy = rot(-ride.z) * o.zy; d.zy = rot(-ride.z) * d.zy;

    inv = 1.0 / d;
    ta = (bmin - o) * inv; tb = (bmax - o) * inv;
    tn = min(ta, tb); tf = max(ta, tb);
    float t0 = max(max(max(tn.x, tn.y), tn.z), 0.0);
    float t1 = min(min(tf.x, tf.y), tf.z);
    if (t0 >= t1) return float4(0.0);

    float s = t0, best = 1e9, tBest = t0;
    for (int i = 0; i < BOAT_STEPS; i++) {
        float h = 0.7 * boatSdf(o + s * d);
        float w = s * footprint + soft;
        if (h / w < best) { best = h / w; tBest = s; }
        if (h < 0.02 * w) { best = 0.0; break; }
        s += max(h, 0.25 * w);
        if (s > t1) break;
    }
    float cov = clamp(1.0 - best, 0.0, 1.0);
    if (cov <= 0.0) return float4(0.0);
    t = tBest;

    float3 pw = ro + tBest * rd;
    float w = tBest * footprint + soft;
    cov *= clamp((pw.y - waterSwellHeight(pw.xz, u.time)) / w + 1.0, 0.0, 1.0);
    if (cov <= 0.0) return float4(0.0);

    float3 p = o + tBest * d;
    float3 n = boatNormal(p, max(0.004, 0.5 * w));
    float3 g = normalize(float3(0.0, 0.25, 1.0));
    g = float3(dot(g.xz, axis), g.y, dot(g.xz, nrm));
    g.xy = rot(-ride.y) * g.xy; g.zy = rot(-ride.z) * g.zy;
    return float4(boatShade(p, n, g), cov);
}

// ---- water ------------------------------------------------------------------
#define WATER_SWELLS 6
constant float WATER_SWELL_LAMBDA      = 14.0;
constant float WATER_SWELL_DECAY       = 0.68;
constant float WATER_SWELL_SLOPE       = 0.09;
constant float WATER_SWELL_SLOPE_DECAY = 0.85;
constant float WATER_SWELL_SPREAD      = 0.6;
constant float WATER_SWELL_ANGLE       = 0.12;
constant float WATER_WARP_SCALE        = 0.05;
constant float WATER_WARP_AMOUNT       = 2.2;
constant float WATER_SWELL_SHARP       = 1.4;
#define WATER_RIPPLE_OCTAVES 2
constant float2 WATER_RIPPLE_FREQ  = float2(0.32, 1.0);
constant float WATER_RIPPLE_AMP    = 0.014;
constant float WATER_RIPPLE_GAIN   = 0.45;
constant float WATER_RIPPLE_LACUN  = 2.3;
constant float WATER_RIPPLE_REFL   = 0.5;
constant float2 WATER_RIPPLE_DRIFT = float2(0.03, -0.25);
constant float WATER_TIME_SCALE    = 0.55;
constant float WATER_AA            = 0.6;
constant float WATER_MASK_TILT     = 1.2;
constant float WATER_MASK_REACH    = 1.0;
constant float WATER_ROUGH_LOSS    = 30.0;
constant float3 WATER_BODY         = float3(0.000, 0.047, 0.103);
constant float3 WATER_TINT         = float3(0.03, 0.95, 1.05);
constant float WATER_TINT_DIST     = 150.0;
constant float WATER_F0            = 0.02;
constant float WATER_REFL_GAIN     = 0.85;
constant float WATER_AUR_FLATTEN   = 0.5;
constant float WATER_NEAR_DARK     = 0.0;
constant float WATER_NEAR_DIST     = 6.0;

static float waterFilter(float2 kv, float2 v, float2 fp) {
    float kAlong  = dot(kv, v);
    float kAcross = kv.x * v.y - kv.y * v.x;
    float2 s = float2(kAcross, kAlong) * fp * WATER_AA;
    return exp(-0.5 * dot(s, s));
}

static float4 waterGradient(float2 xz, float dist, thread float2& gRipple, Uni u) {
    float t = u.time * WATER_TIME_SCALE;

    float fpAcross = dist / (FOCAL * u.res.y);
    float sinGraze = clamp(u.cam.y / max(dist, 1e-3), 1e-3, 1.0);
    float2 fp = float2(fpAcross, fpAcross / sinGraze);
    float2 toP = xz - u.cam.xz;
    float2 v = toP / max(length(toP), 1e-4);

    float2 grad = float2(0.0);
    float varLost = 0.0;
    float varAll = 0.0;

    float3 w = waterNoised(xz * WATER_WARP_SCALE + float2(0.0, t * 0.01));
    float warp = WATER_WARP_AMOUNT * w.x;
    float2 dWarp = WATER_WARP_AMOUNT * WATER_WARP_SCALE * w.yz;

    float lambda = WATER_SWELL_LAMBDA;
    float slope = WATER_SWELL_SLOPE;
    for (int i = 0; i < WATER_SWELLS; i++) {
        float fi = float(i);
        float ang = WATER_SWELL_ANGLE + (hash11(fi * 7.31 + 1.7) - 0.5) * 2.0 * WATER_SWELL_SPREAD;
        float2 dir = float2(sin(ang), -cos(ang));
        float k = TAU / lambda;
        float omega = sqrt(9.81 * k);
        float2 kv = dir * k;
        float ph = dot(kv, xz) - omega * t + hash11(fi * 3.17 + 0.3) * TAU + warp * (lambda / WATER_SWELL_LAMBDA + 0.3);
        float2 dph = kv + dWarp * (lambda / WATER_SWELL_LAMBDA + 0.3);
        float att = waterFilter(dph, v, fp);
        float a = slope / k;
        float shape = exp(WATER_SWELL_SHARP * (sin(ph) - 1.0));
        grad += att * a * cos(ph) * shape * dph;
        float var = 0.5 * exp(-1.39 * WATER_SWELL_SHARP) * slope * slope;
        varAll += var;
        varLost += var * (1.0 - att * att);
        lambda *= WATER_SWELL_DECAY;
        slope *= WATER_SWELL_SLOPE_DECAY;
    }

    float2 freq = WATER_RIPPLE_FREQ;
    float amp = WATER_RIPPLE_AMP;
    float2 drift = WATER_RIPPLE_DRIFT;
    float2x2 r = float2x2(1.0);
    gRipple = float2(0.0);
    for (int i = 0; i < WATER_RIPPLE_OCTAVES; i++) {
        float2 rxz = r * xz;
        float3 n = waterNoised(rxz * freq + drift * freq * t + float(i) * 31.7);
        float2 gq = n.yz * freq;
        float2 g = gq * r;
        float2 kv = (float2(freq.x, freq.y) * PI) * r;
        float att = waterFilter(kv, v, fp);
        gRipple += att * amp * g;
        float var = 0.36 * amp * amp * dot(freq, freq);
        varAll += var;
        varLost += var * (1.0 - att * att);
        freq *= WATER_RIPPLE_LACUN;
        amp *= WATER_RIPPLE_GAIN;
        drift *= 0.6;
        r = r * rot(0.35);
    }

    return float4(grad + gRipple, varLost, varAll);
}

static float waterSwellHeight(float2 xz, float time) {
    float t = time * WATER_TIME_SCALE;
    float q = max(WATER_SWELL_SHARP, 1e-3);
    float q2 = 0.25 * q * q;
    float mean = exp(-q) * (1.0 + q2 + q2 * q2 / 4.0 + q2 * q2 * q2 / 36.0);
    float warp = WATER_WARP_AMOUNT * waterNoised(xz * WATER_WARP_SCALE + float2(0.0, t * 0.01)).x;
    float lambda = WATER_SWELL_LAMBDA;
    float slope = WATER_SWELL_SLOPE;
    float h = 0.0;
    for (int i = 0; i < WATER_SWELLS; i++) {
        float fi = float(i);
        float ang = WATER_SWELL_ANGLE + (hash11(fi * 7.31 + 1.7) - 0.5) * 2.0 * WATER_SWELL_SPREAD;
        float k = TAU / lambda;
        float ph = dot(float2(sin(ang), -cos(ang)) * k, xz) - sqrt(9.81 * k) * t
                 + hash11(fi * 3.17 + 0.3) * TAU + warp * (lambda / WATER_SWELL_LAMBDA + 0.3);
        h += slope / k / q * (exp(q * (sin(ph) - 1.0)) - mean);
        lambda *= WATER_SWELL_DECAY;
        slope *= WATER_SWELL_SLOPE_DECAY;
    }
    return h;
}

static float3 water(float3 ro, float3 rd, Uni u) {
    float t = -ro.y / min(rd.y, -1e-4);
    float3 p = ro + t * rd;
    float hs = boatSeaHeight(p.xz, u.time);
    t = (hs - ro.y) / min(rd.y, -1e-4);
    p = ro + t * rd;
    float2 gRipple;
    float4 gv = waterGradient(p.xz, t, gRipple, u);
    float2 gRefl = gv.xy - (1.0 - WATER_RIPPLE_REFL) * gRipple;
    float3 n = normalize(float3(-gRefl.x, 1.0, -gRefl.y));
    float3 nFull = normalize(float3(-gv.x, 1.0, -gv.y));

    float sigma = sqrt(gv.w);
    float sinGraze = -rd.y;
    float mask = WATER_MASK_TILT * sigma * exp(-sinGraze / (WATER_MASK_REACH * sigma));
    float2 toCam = -normalize(rd.xz + 1e-6);
    n = normalize(n + float3(toCam.x, 0.0, toCam.y) * mask);
    nFull = normalize(nFull + float3(toCam.x, 0.0, toCam.y) * mask);

    float3 r = reflect(rd, n);
    r.y = abs(r.y);
    float cosI = max(dot(nFull, -rd), 0.0);
    float fres = WATER_F0 + (1.0 - WATER_F0) * pow(1.0 - cosI, 5.0);
    fres /= 1.0 + WATER_ROUGH_LOSS * gv.z;

    float near = 1.0 - WATER_NEAR_DARK * (1.0 - smoothstep(0.0, WATER_NEAR_DIST, t));

    float3 rA = reflect(rd, normalize(mix(n, float3(0.0, 1.0, 0.0), WATER_AUR_FLATTEN)));
    rA.y = abs(rA.y);
    float far = 1.0 - exp(-t / WATER_TINT_DIST);
    float3 tint = mix(WATER_TINT, float3(1.0), far * far);
    float3 refl = skyRefl(r, rA, AURORA_STEPS_REFL, u) * tint * WATER_REFL_GAIN * near;

    float pa = 1.0 / (u.res.y * FOCAL);
    float tb;
    float4 bt = boat(p, r, pa, t * pa + BOAT_REFL_BLUR, tb, u);
    refl = mix(refl, bt.rgb, bt.a);
    return mix(WATER_BODY, refl, fres);
}

// ---- main -------------------------------------------------------------------
static float3 boatCam(float3 col, float3 ro, float3 rd, Uni u) {
    float t;
    float4 b = boat(ro, rd, 1.0 / (u.res.y * FOCAL), 0.0, t, u);
    return mix(col, b.rgb, b.a);
}

static void camera(float2 fragCoord, Uni u, thread float3& ro, thread float3& rd) {
    ro = float3(0.0, CAM_HEIGHT + 0.02 * sin(u.time * 0.4), 0.0);
    float2 uv = (fragCoord - float2(0.5 * u.res.x, HORIZON * u.res.y)) / u.res.y;
    rd = normalize(float3(uv, FOCAL));
    rd.xz = rot(0.02 * sin(u.time * 0.05)) * rd.xz; // slow yaw drift keeps the horizon level
}

static float3 post(float3 col, Uni u) {
    col *= EXPOSURE;
    float3 shoulder = 0.6 + 0.4 * (1.0 - exp(-(max(col, float3(0.6)) - 0.6) / 0.4));
    col = mix(col, shoulder, step(float3(0.6), col));

    float2 q = u.frag / u.res;
    col *= mix(0.78, 1.0, pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25));

    col = linearToSrgb(col);
    col += (hash12(u.frag + fract(u.time * 7.13) * 371.0) - 0.5) * (3.0 / 255.0);
    return col;
}

[[ stitchable ]] half4 theOtherSide(float2 position, half4 color, float2 size, float time) {
    Uni u;
    u.res = size;
    u.frag = float2(position.x, size.y - position.y); // Shadertoy origin: bottom-left
    u.time = time;

    float3 ro, rd;
    camera(u.frag, u, ro, rd);
    u.cam = ro;

    float3 col;
    if (rd.y > 0.0) col = skyFull(rd, u);
    else            col = water(ro, rd, u);
    col = boatCam(col, ro, rd, u);
    return half4(half3(post(col, u)), 1.0);
}
