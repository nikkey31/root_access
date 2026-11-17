shader_type canvas_item;
render_mode unshaded;

// Аутентичный ретро-CRT шейдер (монитор / Toughbook 2000-х):
// - минимальная выпуклая линза без обрезки углов панели задач;
// - 100% читаемый текст без муара (сканлайны по реальным строкам FRAGCOORD.y);
// - лёгкий 16-битный Bayer-дизеринг и тонкая RGB-маска;
// - периодические короткие аналоговые помехи (горизонтальный сдвиг полосы + микро-снег).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.35) = 0.025;
uniform float zoom : hint_range(0.85, 1.0) = 0.975;
uniform float corner_radius : hint_range(0.0, 0.12) = 0.01;
uniform float vignette_strength : hint_range(0.0, 0.6) = 0.14;
uniform float aberration : hint_range(0.0, 0.008) = 0.00045;
uniform float aspect = 1.7777778;

uniform float scanline_strength : hint_range(0.0, 0.35) = 0.09;
uniform float grille_strength : hint_range(0.0, 0.25) = 0.035;
uniform float color_levels : hint_range(16.0, 128.0) = 48.0;
uniform float noise_strength : hint_range(0.0, 0.08) = 0.014;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;

float bayer4(vec2 p) {
	ivec2 ip = ivec2(mod(p, 4.0));
	int index = ip.y * 4 + ip.x;
	if (index == 0) return 0.0 / 16.0;
	if (index == 1) return 8.0 / 16.0;
	if (index == 2) return 2.0 / 16.0;
	if (index == 3) return 10.0 / 16.0;
	if (index == 4) return 12.0 / 16.0;
	if (index == 5) return 4.0 / 16.0;
	if (index == 6) return 14.0 / 16.0;
	if (index == 7) return 6.0 / 16.0;
	if (index == 8) return 3.0 / 16.0;
	if (index == 9) return 11.0 / 16.0;
	if (index == 10) return 1.0 / 16.0;
	if (index == 11) return 9.0 / 16.0;
	if (index == 12) return 15.0 / 16.0;
	if (index == 13) return 7.0 / 16.0;
	if (index == 14) return 13.0 / 16.0;
	return 5.0 / 16.0;
}

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	vec2 p = (uv - 0.5) * 2.0;
	p.x *= aspect;
	float r2 = dot(p, p) / (aspect * aspect + 1.0);

	// Аккуратное бочкообразное искажение (синхронно с crt_screen_to_ui).
	vec2 lens_p = p * (1.0 - curvature * r2);
	vec2 src_uv = 0.5 + (lens_p / vec2(aspect, 1.0)) * 0.5;
	src_uv = (src_uv - 0.5) / zoom + 0.5;

	// Жёсткий край экрана без современных скруглений.
	vec2 q = abs(p) - vec2(aspect - corner_radius, 1.0 - corner_radius);
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float mask = step(sd, 0.0);

	// Небольшие редкие аналоговые помехи раз в ~8-11 секунд (длительность ~0.16 сек).
	float cycle = floor(TIME / 9.0);
	float phase = fract(TIME / 9.0);
	float auto_burst = step(0.965, phase) * step(0.35, hash11(cycle * 13.7));
	float active_glitch = max(glitch_intensity, auto_burst * 0.55);

	vec2 sample_uv = src_uv;
	float band_noise = 0.0;
	if (active_glitch > 0.01) {
		float slice_t = floor(TIME * 24.0);
		float band_y = hash11(slice_t * 3.17);
		float band_h = 0.018 + 0.03 * hash11(slice_t * 7.31);
		float in_band = step(abs(src_uv.y - band_y), band_h);
		float shift = (hash11(slice_t * 11.9 + floor(src_uv.y * 180.0)) - 0.5) * 0.016 * active_glitch;
		sample_uv.x += shift * in_band;
		band_noise = in_band * active_glitch * 0.14;
	}

	// Лёгкая хроматическая аберрация ЭЛТ.
	vec2 dir = normalize(p + vec2(0.00001));
	float ca = (aberration + active_glitch * 0.0022) * (0.3 + r2);
	vec3 color;
	color.r = texture(screen_texture, sample_uv + dir * ca).r;
	color.g = texture(screen_texture, sample_uv).g;
	color.b = texture(screen_texture, sample_uv - dir * ca).b;

	// Деликатное 16-битное квантование цвета с Bayer-дизерингом (сохраняет чёткость текста).
	float dither = (bayer4(floor(FRAGCOORD.xy)) - 0.5) / color_levels;
	color = clamp(floor((color + dither) * color_levels + 0.5) / color_levels, 0.0, 1.0);

	// Чистые горизонтальные сканлайны без муара (строго по реальным строкам пикселей).
	float scan = mod(floor(FRAGCOORD.y), 2.0);
	color *= 1.0 - scanline_strength * scan;

	// Едва заметная вертикальная RGB-маска люминофора.
	float triad = mod(floor(FRAGCOORD.x), 3.0);
	vec3 grille = vec3(
		1.0 - grille_strength * step(0.5, abs(triad - 0.0)),
		1.0 - grille_strength * step(0.5, abs(triad - 1.0)),
		1.0 - grille_strength * step(0.5, abs(triad - 2.0))
	);
	color *= grille;

	// Лёгкое живое зерно + снег на полосе помехи.
	float grain = (hash12(floor(FRAGCOORD.xy) + fract(TIME * 23.0) * 100.0) - 0.5) * (noise_strength + band_noise);
	color = clamp(color + vec3(grain), 0.0, 1.0);

	// Мягкое виньетирование по углам кинескопа.
	vec2 centered = uv - 0.5;
	float edge = smoothstep(0.38, 1.0, length(centered) * 1.414);
	color *= 1.0 - vignette_strength * edge;

	float inside = step(0.0, sample_uv.x) * step(sample_uv.x, 1.0)
		* step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
	COLOR = vec4(color * mask * inside, 1.0);
}
