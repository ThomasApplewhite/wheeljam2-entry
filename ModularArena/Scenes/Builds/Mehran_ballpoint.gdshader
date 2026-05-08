shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 paper_color : source_color = vec4(0.965, 0.945, 0.902, 1.0);
uniform vec4 paper_shadow_color : source_color = vec4(0.839, 0.811, 0.756, 1.0);
uniform vec4 ink_color : source_color = vec4(0.071, 0.137, 0.349, 1.0);
uniform vec4 ink_shadow_color : source_color = vec4(0.024, 0.051, 0.152, 1.0);
uniform vec4 sheen_color : source_color = vec4(0.376, 0.525, 0.792, 1.0);

uniform float tone : hint_range(0.0, 1.0) = 0.32;
uniform float pressure : hint_range(0.0, 1.0) = 0.82;
uniform float pattern_scale : hint_range(0.1, 64.0, 0.1) = 6.6;
uniform float world_space_blend : hint_range(0.0, 1.0) = 0.12;
uniform float world_space_scale : hint_range(0.01, 4.0, 0.01) = 0.45;
uniform float hatch_density : hint_range(1.0, 64.0, 0.1) = 10.5;
uniform float micro_hatch_density : hint_range(1.0, 128.0, 0.1) = 28.0;
uniform float hatch_thickness : hint_range(0.01, 0.45, 0.001) = 0.16;
uniform float stroke_angle : hint_range(-3.14159, 3.14159, 0.001) = 0.48;
uniform float crosshatch_separation : hint_range(0.05, 3.14159, 0.001) = 1.02;
uniform float waviness : hint_range(0.0, 1.0) = 0.38;
uniform float jitter : hint_range(0.0, 1.0) = 0.24;
uniform float scribble_strength : hint_range(0.0, 1.0) = 0.68;
uniform float crosshatch_strength : hint_range(0.0, 1.0) = 0.78;
uniform float ink_breakup : hint_range(0.0, 1.0) = 0.35;
uniform float paper_fiber_scale : hint_range(0.1, 32.0, 0.1) = 7.2;
uniform float paper_tooth_strength : hint_range(0.0, 1.0) = 0.65;
uniform float domain_warp_strength : hint_range(0.0, 1.0) = 0.42;
uniform float edge_pooling : hint_range(0.0, 1.0) = 0.62;
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.55;
uniform float lighting_ink_response : hint_range(0.0, 1.0) = 0.80;
uniform float lighting_contrast : hint_range(0.5, 4.0, 0.01) = 1.5;
uniform vec3 sketch_light_direction = vec3(-0.42, 0.88, 0.18);

uniform sampler2D tone_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pressure_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float tone_texture_strength : hint_range(0.0, 1.0) = 0.0;
uniform float pressure_texture_strength : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_position;
varying vec3 world_normal;

float saturate(float x) {
	return clamp(x, 0.0, 1.0);
}

mat2 rotate2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, s), vec2(-s, c));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 78.233);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 6; octave++) {
		value += amplitude * noise2(p);
		p = rotate2d(0.85) * p * 2.03 + vec2(7.1, 3.7);
		amplitude *= 0.5;
	}

	return value;
}

vec2 warp_uv(vec2 uv) {
	vec2 flow = vec2(
		fbm(uv * 0.75 + vec2(1.7, 9.2)),
		fbm(uv * 0.75 + vec2(8.3, 2.8))
	);
	return uv + (flow - 0.5) * domain_warp_strength * 2.2;
}

vec2 triplanar_uv(vec3 position_ws, vec3 normal_ws) {
	vec3 blend = abs(normalize(normal_ws));
	blend = pow(blend, vec3(3.0));
	blend /= max(dot(blend, vec3(1.0)), 0.0001);
	vec2 uv_x = position_ws.zy;
	vec2 uv_y = position_ws.xz;
	vec2 uv_z = position_ws.xy;
	return uv_x * blend.x + uv_y * blend.y + uv_z * blend.z;
}

float paper_tooth(vec2 uv) {
	vec2 macro_uv = rotate2d(0.21) * uv * paper_fiber_scale;
	vec2 micro_uv = rotate2d(1.07) * uv * paper_fiber_scale * 2.35 + vec2(4.0, 7.2);
	float macro = fbm(macro_uv * vec2(0.9, 1.7));
	float micro = fbm(micro_uv * vec2(0.65, 2.9));
	float fibers = 1.0 - abs(
		sin((rotate2d(0.62) * uv).x * paper_fiber_scale * 13.0 + fbm(uv * paper_fiber_scale * 0.75) * 2.6)
	);
	fibers = pow(saturate(fibers), 6.0);
	return saturate(macro * 0.55 + micro * 0.35 + fibers * 0.30);
}

vec2 hatch_band(
	vec2 uv,
	float angle,
	float density,
	float width,
	float local_waviness,
	float local_jitter,
	float breakup,
	float seed
) {
	vec2 p = rotate2d(angle) * uv;
	float band = p.y * density;
	float band_id = floor(band);
	float drift = (fbm(vec2(p.x * 0.24, band_id * 0.05) + seed * 13.1) - 0.5) * (0.10 + local_waviness * 0.45);
	float wobble = (fbm(vec2(p.x * 0.65, band_id * 0.09) + seed * 3.7) - 0.5) * local_waviness * 0.28;
	float jitter_offset = (hash21(vec2(band_id, floor(p.x * 0.7)) + seed * 19.3) - 0.5) * local_jitter * 0.16;
	float coord = band + drift + wobble + jitter_offset;
	float dist = abs(fract(coord) - 0.5);
	float aa = fwidth(coord) * 0.85 + 0.0001;
	float core = 1.0 - smoothstep(width, width + aa, dist);
	float body = 1.0 - smoothstep(width * 1.9, width * 1.9 + aa, dist);
	float run = fbm(vec2(p.x * 1.15, band_id * 0.23) + vec2(seed * 9.7, seed * 5.4));
	float gaps = smoothstep(breakup, 1.0, run);
	float grain = 0.85 + 0.15 * fbm(p * 0.9 + seed * 4.2);
	core *= gaps * grain;
	body *= gaps;
	return vec2(core, max(body - core, 0.0));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 world_uv = triplanar_uv(world_position * world_space_scale, world_normal);
	vec2 pattern_uv = mix(UV, world_uv, world_space_blend) * pattern_scale;
	vec2 warped_uv = warp_uv(pattern_uv);

	float sampled_tone = dot(texture(tone_texture, UV).rgb, vec3(0.299, 0.587, 0.114));
	float sampled_pressure = dot(texture(pressure_texture, UV).rgb, vec3(0.299, 0.587, 0.114));

	float final_pressure = saturate(mix(pressure, sampled_pressure, pressure_texture_strength));
	vec3 draw_light = normalize(sketch_light_direction);
	float lambert = saturate(dot(normalize(world_normal), draw_light));
	float lighting_tone = pow(1.0 - lambert, lighting_contrast);
	float final_tone = saturate(mix(tone + lighting_tone * lighting_ink_response, sampled_tone, tone_texture_strength));

	float tooth = paper_tooth(warped_uv);
	float paper_macro = fbm(pattern_uv * 0.32 + vec2(12.4, 2.3));
	float paper_micro = fbm(warped_uv * 1.8 + vec2(6.8, 14.2));
	float grain_noise = fbm(warped_uv * 2.6 + vec2(23.1, 5.2));

	float base_width = mix(hatch_thickness * 0.75, hatch_thickness * 1.35, final_pressure);
	float density_scale = mix(0.88, 1.25, final_pressure);

	vec2 layer_a = hatch_band(
		warped_uv,
		stroke_angle,
		hatch_density * density_scale,
		base_width,
		waviness,
		jitter,
		0.18 + ink_breakup * 0.35,
		1.3
	);
	vec2 layer_b = hatch_band(
		warped_uv * vec2(1.0, 1.04),
		stroke_angle + crosshatch_separation,
		hatch_density * 1.45 * density_scale,
		base_width * 0.88,
		waviness * 0.85,
		jitter * 1.1,
		0.22 + ink_breakup * 0.40,
		2.7
	);
	vec2 layer_c = hatch_band(
		warped_uv * vec2(1.12, 0.94),
		stroke_angle - crosshatch_separation * 0.68,
		hatch_density * 2.10 * density_scale,
		base_width * 0.72,
		waviness * 1.20,
		jitter * 1.25,
		0.28 + ink_breakup * 0.45,
		5.1
	);
	vec2 layer_d = hatch_band(
		warped_uv * 1.6,
		stroke_angle + PI * 0.5,
		micro_hatch_density * density_scale,
		base_width * 0.45,
		waviness * 0.55,
		jitter * 0.75,
		0.34 + ink_breakup * 0.50,
		8.9
	);

	float layer_c_fade = 1.0 - smoothstep(
		0.9,
		2.8,
		fwidth(warped_uv.x * hatch_density * 2.2) + fwidth(warped_uv.y * hatch_density * 2.2)
	);
	float micro_fade = 1.0 - smoothstep(
		0.8,
		2.4,
		fwidth(warped_uv.x * micro_hatch_density) + fwidth(warped_uv.y * micro_hatch_density)
	);

	float a = smoothstep(0.08, 0.42, final_tone);
	float b = smoothstep(0.24, 0.66, final_tone) * crosshatch_strength;
	float c = smoothstep(0.45, 0.88, final_tone) * scribble_strength * layer_c_fade;
	float d = smoothstep(0.60, 1.00, final_tone) * 0.70 * micro_fade;

	float stroke_core = layer_a.x * a + layer_b.x * b + layer_c.x * c + layer_d.x * d;
	float stroke_ridge = layer_a.y * a + layer_b.y * b + layer_c.y * c + layer_d.y * d;

	float wash = smoothstep(0.52, 1.0, final_tone) * (0.12 + 0.24 * final_pressure);
	float tooth_gate = mix(1.0, smoothstep(0.24, 0.92, tooth + grain_noise * 0.20), paper_tooth_strength);
	float breakup_gate = mix(1.0, smoothstep(0.22, 0.95, grain_noise), ink_breakup * 0.55);
	float pooled = saturate(stroke_ridge * edge_pooling * (0.55 + 0.45 * final_pressure));
	float coverage = saturate((stroke_core + wash) * tooth_gate * breakup_gate + pooled * 0.30);

	float paper_mix = saturate(0.30 + paper_macro * 0.45 + tooth * 0.35 + paper_micro * 0.15);
	vec3 paper_rgb = mix(paper_shadow_color.rgb, paper_color.rgb, paper_mix);
	paper_rgb *= mix(0.94, 1.06, paper_micro);

	float dye_noise = fbm(warped_uv * 1.25 + vec2(31.7, 9.3));
	vec3 ink_rgb = mix(ink_shadow_color.rgb, ink_color.rgb, saturate(0.35 + dye_noise * 0.90));
	ink_rgb *= mix(0.92, 1.08, grain_noise);
	ink_rgb = mix(ink_rgb, ink_shadow_color.rgb, pooled * 0.45);

	float fresnel = pow(1.0 - saturate(dot(normalize(NORMAL), normalize(VIEW))), 5.0);
	float sheen = fresnel * sheen_strength * coverage * (0.35 + 0.65 * fbm(warped_uv * 0.9 + vec2(44.0, 11.7)));

	ALBEDO = mix(paper_rgb, ink_rgb, coverage);
	ROUGHNESS = mix(0.92 - paper_micro * 0.08, 0.48 - pooled * 0.18, coverage);
	SPECULAR = mix(0.32, 0.72, coverage);
	METALLIC = pooled * 0.03;
	CLEARCOAT = saturate(coverage * (0.08 + 0.32 * sheen_strength) + pooled * 0.18);
	AO = mix(0.98 - tooth * 0.08, 0.88 - pooled * 0.14, coverage);
	EMISSION = sheen_color.rgb * (sheen * (0.4 + 0.6 * final_pressure) + pooled * 0.04);
}
