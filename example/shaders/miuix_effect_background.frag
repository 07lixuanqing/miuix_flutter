#version 320 es

// Direct Flutter runtime-effect port of the original example's OS2_BG_FRAG
// and OS3_BG_FRAG. The demo always resolves DeviceType.PHONE, so the exact
// light/dark phone presets live here and Dart supplies the source spring stage.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_resolution;
uniform float u_anim_time;
uniform float u_dark;
uniform vec4 u_bound;
uniform float u_os3;
uniform float u_color_stage;

out vec4 frag_color;

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(
    abs(q.z + (q.w - q.y) / (6.0 * d + e)),
    d / (q.x + e),
    q.x
  );
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash_value(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.13);
  p3 += dot(p3, p3.yzx + 3.333);
  return fract((p3.x + p3.y) * p3.z);
}

float perlin(vec2 x) {
  vec2 i = floor(x);
  vec2 f = fract(x);
  float a = hash_value(i);
  float b = hash_value(i + vec2(1.0, 0.0));
  float c = hash_value(i + vec2(0.0, 1.0));
  float d = hash_value(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) +
      (c - a) * u.y * (1.0 - u.x) +
      (d - b) * u.x * u.y;
}

float gradient_noise(vec2 uv) {
  return fract(52.9829189 * fract(dot(uv, vec2(0.06711056, 0.00583715))));
}

vec4 cycle_color(int cycle, vec4 color1, vec4 color2, vec4 color3) {
  if (cycle == 1) return color1;
  if (cycle == 3) return color3;
  return color2;
}

void main() {
  vec2 frag_coord = FlutterFragCoord().xy;
  vec2 v_uv = frag_coord / u_resolution;
  v_uv.y = 1.0 - v_uv.y;

  // BgEffectPainter derives this domain from BgEffectBackground.isFullSize.
  // The foreground preview uses (0,0,1,1), while About keeps the source's
  // default (0,0.22,1,0.78) domain.
  vec2 uv = v_uv;
  uv -= u_bound.xy;
  uv /= u_bound.zw;

  vec3 points[4];
  vec4 colors[4];
  float light_offset;
  float saturate_offset = 0.2;
  float point_offset = 0.1;

  if (u_os3 > 0.5 && u_dark > 0.5) {
    points[0] = vec3(0.8, 0.2, 1.0);
    points[1] = vec3(0.8, 0.9, 1.0);
    points[2] = vec3(0.2, 0.9, 1.0);
    points[3] = vec3(0.2, 0.2, 1.0);
    vec4 color1[4];
    color1[0] = vec4(0.20, 0.06, 0.88, 0.40);
    color1[1] = vec4(0.30, 0.14, 0.55, 0.50);
    color1[2] = vec4(0.00, 0.64, 0.96, 0.50);
    color1[3] = vec4(0.11, 0.16, 0.83, 0.40);
    vec4 color2[4];
    color2[0] = vec4(0.07, 0.15, 0.79, 0.50);
    color2[1] = vec4(0.62, 0.21, 0.67, 0.50);
    color2[2] = vec4(0.06, 0.25, 0.84, 0.50);
    color2[3] = vec4(0.00, 0.20, 0.78, 0.50);
    vec4 color3[4];
    color3[0] = vec4(0.58, 0.30, 0.74, 0.40);
    color3[1] = vec4(0.27, 0.18, 0.60, 0.50);
    color3[2] = vec4(0.66, 0.26, 0.62, 0.50);
    color3[3] = vec4(0.12, 0.16, 0.70, 0.60);
    int start_cycle = int(mod(floor(u_color_stage), 4.0));
    int end_cycle = start_cycle == 3 ? 0 : start_cycle + 1;
    float stage = fract(u_color_stage);
    for (int i = 0; i < 4; i++) {
      colors[i] = mix(
        cycle_color(start_cycle, color1[i], color2[i], color3[i]),
        cycle_color(end_cycle, color1[i], color2[i], color3[i]),
        stage
      );
    }
    light_offset = 0.0;
    saturate_offset = 0.17;
    point_offset = 0.4;
  } else if (u_os3 > 0.5) {
    points[0] = vec3(0.8, 0.2, 1.0);
    points[1] = vec3(0.8, 0.9, 1.0);
    points[2] = vec3(0.2, 0.9, 1.0);
    points[3] = vec3(0.2, 0.2, 1.0);
    vec4 color1[4];
    color1[0] = vec4(1.00, 0.90, 0.94, 1.0);
    color1[1] = vec4(1.00, 0.84, 0.89, 1.0);
    color1[2] = vec4(0.97, 0.73, 0.82, 1.0);
    color1[3] = vec4(0.64, 0.65, 0.98, 1.0);
    vec4 color2[4];
    color2[0] = vec4(0.58, 0.74, 1.00, 1.0);
    color2[1] = vec4(1.00, 0.90, 0.93, 1.0);
    color2[2] = vec4(0.74, 0.76, 1.00, 1.0);
    color2[3] = vec4(0.97, 0.77, 0.84, 1.0);
    vec4 color3[4];
    color3[0] = vec4(0.98, 0.86, 0.90, 1.0);
    color3[1] = vec4(0.60, 0.73, 0.98, 1.0);
    color3[2] = vec4(0.92, 0.93, 1.00, 1.0);
    color3[3] = vec4(0.56, 0.69, 1.00, 1.0);
    int start_cycle = int(mod(floor(u_color_stage), 4.0));
    int end_cycle = start_cycle == 3 ? 0 : start_cycle + 1;
    float stage = fract(u_color_stage);
    for (int i = 0; i < 4; i++) {
      colors[i] = mix(
        cycle_color(start_cycle, color1[i], color2[i], color3[i]),
        cycle_color(end_cycle, color1[i], color2[i], color3[i]),
        stage
      );
    }
    light_offset = 0.1;
    point_offset = 0.2;
  } else if (u_dark > 0.5) {
    points[0] = vec3(0.63, 0.50, 0.88);
    points[1] = vec3(0.69, 0.75, 0.80);
    points[2] = vec3(0.17, 0.66, 0.81);
    points[3] = vec3(0.14, 0.24, 0.72);
    colors[0] = vec4(0.0, 0.31, 0.58, 1.0);
    colors[1] = vec4(0.53, 0.29, 0.15, 1.0);
    colors[2] = vec4(0.46, 0.06, 0.27, 1.0);
    colors[3] = vec4(0.16, 0.12, 0.45, 1.0);
    light_offset = -0.1;
  } else {
    points[0] = vec3(0.67, 0.42, 1.0);
    points[1] = vec3(0.69, 0.75, 1.0);
    points[2] = vec3(0.14, 0.71, 0.95);
    points[3] = vec3(0.14, 0.27, 0.80);
    colors[0] = vec4(0.57, 0.76, 0.98, 1.0);
    colors[1] = vec4(0.98, 0.85, 0.68, 1.0);
    colors[2] = vec4(0.98, 0.75, 0.93, 1.0);
    colors[3] = vec4(0.73, 0.70, 0.98, 1.0);
    light_offset = 0.1;
  }

  float noise_value = perlin(v_uv * 1.5 + vec2(-u_anim_time));
  vec4 color = vec4(0.0);

  for (int i = 0; i < 4; i++) {
    vec4 point_color = colors[i];
    point_color.rgb *= point_color.a;
    vec2 point = points[i].xy;
    float radius = points[i].z;
    point.x += sin(u_anim_time + point.y) * point_offset;
    point.y += cos(u_anim_time + point.x) * point_offset;
    float pct = smoothstep(radius, 0.0, distance(uv, point));
    color.rgb = mix(color.rgb, point_color.rgb, pct);
    color.a = mix(color.a, point_color.a, pct);
  }

  float opposite_noise = smoothstep(0.0, 1.0, noise_value);
  color.rgb /= max(color.a, 0.00001);
  vec3 hsv = rgb2hsv(color.rgb);
  hsv.y = mix(hsv.y, 0.0, opposite_noise * saturate_offset);
  color.rgb = hsv2rgb(hsv);
  color.rgb += opposite_noise * light_offset;
  color.a = clamp(color.a, 0.0, 1.0);

  // Preserve the source's subtle deterministic display noise and premultiply
  // the result before Flutter composites it over the MIUIX surface.
  color += (10.0 / 255.0) * gradient_noise(frag_coord) - (5.0 / 255.0);
  frag_color = vec4(color.rgb * color.a, color.a);
}
