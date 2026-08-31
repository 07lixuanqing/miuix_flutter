#version 320 es

// Flutter image-filter port of miuix-blur/internal/Shaders.kt. The first vec2
// and sampler are populated by ImageFilter.shader; layer uniforms are supplied
// by MiuixLayerBackdrop in the same order as the original Compose pipeline.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_size;
uniform float u_layer_count;
uniform vec4 u_layer_colors[8];
uniform float u_modes[8];
uniform float u_brightness;
uniform float u_contrast;
uniform float u_saturation;
uniform sampler2D u_texture_input;

out vec4 frag_color;

float color_burn(float base, float blend) {
  return blend == 0.0 ? blend : max(1.0 - (1.0 - base) / blend, 0.0);
}

vec3 color_burn(vec3 base, vec3 blend) {
  return vec3(
    color_burn(base.r, blend.r),
    color_burn(base.g, blend.g),
    color_burn(base.b, blend.b)
  );
}

float color_dodge(float base, float blend) {
  return blend == 1.0 ? blend : min(base / (1.0 - blend), 1.0);
}

vec3 color_dodge(vec3 base, vec3 blend) {
  return vec3(
    color_dodge(base.r, blend.r),
    color_dodge(base.g, blend.g),
    color_dodge(base.b, blend.b)
  );
}

float linear_light(float base, float blend) {
  return blend < 0.5
      ? max(base + 2.0 * blend - 1.0, 0.0)
      : min(base + 2.0 * (blend - 0.5), 1.0);
}

vec3 linear_light(vec3 base, vec3 blend) {
  return vec3(
    linear_light(base.r, blend.r),
    linear_light(base.g, blend.g),
    linear_light(base.b, blend.b)
  );
}

float greyscale(vec3 color) {
  return 0.3 * color.r + 0.59 * color.g + 0.11 * color.b;
}

vec3 rgb2xyz(vec3 c) {
  c.r = c.r > 0.04045 ? pow((c.r + 0.055) / 1.055, 2.4) : c.r / 12.92;
  c.g = c.g > 0.04045 ? pow((c.g + 0.055) / 1.055, 2.4) : c.g / 12.92;
  c.b = c.b > 0.04045 ? pow((c.b + 0.055) / 1.055, 2.4) : c.b / 12.92;
  c *= 100.0;
  return vec3(
    c.r * 0.4124 + c.g * 0.3576 + c.b * 0.1805,
    c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722,
    c.r * 0.0193 + c.g * 0.1192 + c.b * 0.9505
  );
}

vec3 xyz2lab(vec3 c) {
  c /= vec3(95.047, 100.0, 108.883);
  c.x = c.x > 0.008856 ? pow(c.x, 1.0 / 3.0) : 7.787 * c.x + 16.0 / 116.0;
  c.y = c.y > 0.008856 ? pow(c.y, 1.0 / 3.0) : 7.787 * c.y + 16.0 / 116.0;
  c.z = c.z > 0.008856 ? pow(c.z, 1.0 / 3.0) : 7.787 * c.z + 16.0 / 116.0;
  return vec3(116.0 * c.y - 16.0, 500.0 * (c.x - c.y), 200.0 * (c.y - c.z));
}

vec3 rgb2lab(vec3 c) {
  return xyz2lab(rgb2xyz(c));
}

vec3 lab2xyz(vec3 lab) {
  float y = (lab.x + 16.0) / 116.0;
  float x = lab.y / 500.0 + y;
  float z = y - lab.z / 200.0;
  y = pow(y, 3.0) > 0.008856 ? pow(y, 3.0) : (y - 16.0 / 116.0) / 7.787;
  x = pow(x, 3.0) > 0.008856 ? pow(x, 3.0) : (x - 16.0 / 116.0) / 7.787;
  z = pow(z, 3.0) > 0.008856 ? pow(z, 3.0) : (z - 16.0 / 116.0) / 7.787;
  return vec3(x * 95.047, y * 100.0, z * 108.883);
}

vec3 xyz2rgb(vec3 xyz) {
  xyz /= 100.0;
  float r = xyz.x * 3.2406 + xyz.y * -1.5372 + xyz.z * -0.4986;
  float g = xyz.x * -0.9689 + xyz.y * 1.8758 + xyz.z * 0.0415;
  float b = xyz.x * 0.0557 + xyz.y * -0.2040 + xyz.z * 1.0570;
  r = r > 0.0031308 ? 1.055 * pow(r, 1.0 / 2.4) - 0.055 : 12.92 * r;
  g = g > 0.0031308 ? 1.055 * pow(g, 1.0 / 2.4) - 0.055 : 12.92 * g;
  b = b > 0.0031308 ? 1.055 * pow(b, 1.0 / 2.4) - 0.055 : 12.92 * b;
  return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec3 lab2rgb(vec3 lab) {
  return xyz2rgb(lab2xyz(lab));
}

vec3 lab_lighten(vec3 color, float amount) {
  vec3 lab = rgb2lab(color);
  lab.r = (100.0 - amount) / 55.0 * lab.r + (100.0 * amount - 4500.0) / 55.0;
  return lab2rgb(lab);
}

vec3 lab_darken(vec3 color, float amount) {
  vec3 lab = rgb2lab(color);
  lab.r = amount / 45.0 * lab.r;
  return lab2rgb(lab);
}

vec3 lab_color(vec3 color, float m, float n) {
  vec3 lab = rgb2lab(color);
  lab.r = (n - m) * lab.r + m * 100.0;
  return lab2rgb(lab);
}

vec3 lab_normalized(vec3 lab) {
  return vec3(lab.r / 100.0, (lab.g + 128.0) / 255.0, (lab.b + 128.0) / 255.0);
}

vec3 lab_denormalized(vec3 lab) {
  return vec3(lab.r * 100.0, lab.g * 255.0 - 128.0, lab.b * 255.0 - 128.0);
}

vec3 linear_light_lab(vec3 source, vec3 destination) {
  vec3 source_lab = lab_normalized(rgb2lab(source));
  vec3 destination_lab = lab_normalized(rgb2lab(destination));
  return lab2rgb(lab_denormalized(linear_light(destination_lab, source_lab)));
}

vec3 rgb2hsl(vec3 c) {
  float minimum = min(c.r, min(c.g, c.b));
  float maximum = max(c.r, max(c.g, c.b));
  float lightness = (maximum + minimum) * 0.5;
  float saturation = 0.0;
  float hue = 0.0;
  if (maximum > minimum) {
    float delta = maximum - minimum;
    saturation = lightness < 0.5
        ? delta / (maximum + minimum)
        : delta / (2.0 - maximum - minimum);
    if (maximum == c.r) hue = (c.g - c.b) / delta;
    else if (maximum == c.g) hue = 2.0 + (c.b - c.r) / delta;
    else hue = 4.0 + (c.r - c.g) / delta;
    hue = mod(hue / 6.0, 1.0);
  }
  return vec3(hue, saturation, lightness);
}

vec3 hsl2rgb(vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  return c.z + c.y * (rgb - 0.5) * (1.0 - abs(2.0 * c.z - 1.0));
}

float soft_light_channel(float base, float blend) {
  if (blend <= 0.5) return base - (1.0 - 2.0 * blend) * base * (1.0 - base);
  float d = base <= 0.25
      ? ((16.0 * base - 12.0) * base + 4.0) * base
      : sqrt(base);
  return base + (2.0 * blend - 1.0) * (d - base);
}

vec3 standard_blend(int mode, vec3 base, vec3 blend) {
  if (mode == 14) return 1.0 - (1.0 - base) * (1.0 - blend);
  if (mode == 24) return base * blend;
  if (mode == 15) return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base));
  if (mode == 20) return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, blend));
  if (mode == 21) return vec3(
    soft_light_channel(base.r, blend.r),
    soft_light_channel(base.g, blend.g),
    soft_light_channel(base.b, blend.b)
  );
  if (mode == 18) return color_dodge(base, blend);
  if (mode == 19) return color_burn(base, blend);
  if (mode == 28) {
    vec3 hsl = rgb2hsl(base);
    hsl.z = rgb2hsl(blend).z;
    return hsl2rgb(hsl);
  }
  return blend;
}

vec4 apply_mode(vec4 background, vec4 source, int mode) {
  float bg_alpha = max(background.a, 0.0001);
  float source_alpha = source.a;
  vec3 base = background.rgb / bg_alpha;
  vec3 blend = source_alpha > 0.0 ? source.rgb / source_alpha : vec3(0.0);
  vec3 result = base;

  if (mode <= 31) {
    vec3 blended = standard_blend(mode, base, blend);
    result = mix(base, blended, source_alpha);
  } else if (mode == 100) {
    result = mix(base, linear_light(base, blend), source_alpha);
  } else if (mode == 101) {
    result = mix(base, linear_light(base, blend), source_alpha * greyscale(base));
  } else if (mode == 102) {
    result = mix(base, abs(base - blend), source_alpha);
  } else if (mode == 103) {
    float amount = 0.4 * greyscale(base) * 100.0 + 45.0;
    result = mix(base, lab_lighten(base, amount), source_alpha);
  } else if (mode == 105) {
    float amount = 45.0 - 0.15 * greyscale(base) * 100.0;
    result = mix(base, lab_darken(base, amount), source_alpha);
  } else if (mode == 106) {
    result = mix(base, lab_color(base, blend.r, blend.g), source_alpha);
  } else if (mode == 107) {
    result = mix(base, linear_light_lab(blend, base), source_alpha);
  } else if (mode == 118) {
    result = mix(base, color_dodge(base, blend), source_alpha);
  } else if (mode == 119) {
    result = mix(base, color_burn(base, blend), source_alpha);
  } else if (mode == 120) {
    result = max(vec3(0.0), 1.0 - ((1.0 - base) * bg_alpha + (1.0 - blend) * source_alpha));
  } else if (mode == 121) {
    result = min(base * bg_alpha + blend * source_alpha, vec3(1.0));
  }

  float out_alpha = source_alpha + bg_alpha * (1.0 - source_alpha);
  return vec4(result * out_alpha, out_alpha);
}

vec4 apply_color_controls(vec4 color) {
  float alpha = max(color.a, 0.0001);
  vec3 source = color.rgb / alpha;
  float inverse_saturation = 1.0 - u_saturation;
  vec3 luma = vec3(0.213, 0.715, 0.072) * inverse_saturation;
  float offset = 0.5 - u_contrast * 0.5 + u_brightness;
  vec3 adjusted = vec3(
    (luma.r + u_saturation) * source.r +
        luma.g * source.g + luma.b * source.b,
    luma.r * source.r + (luma.g + u_saturation) * source.g +
        luma.b * source.b,
    luma.r * source.r + luma.g * source.g +
        (luma.b + u_saturation) * source.b
  );
  adjusted = clamp(adjusted * u_contrast + offset, 0.0, 1.0);
  return vec4(adjusted * color.a, color.a);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  vec4 current = apply_color_controls(texture(u_texture_input, uv));
  int count = int(u_layer_count + 0.5);
  for (int i = 0; i < 8; i++) {
    if (i >= count) break;
    current = apply_mode(current, u_layer_colors[i], int(u_modes[i] + 0.5));
  }
  frag_color = current;
}
