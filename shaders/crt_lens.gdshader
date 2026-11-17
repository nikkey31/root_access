shader_type canvas_item;
render_mode unshaded;

// Жёсткий ретро-CRT шейдер (стиль мониторов и Toughbook конца 90-х / 2000-х):
// - без современных скруглений углов;
// - пикселизация (filter_nearest + привязка к сетке ретро-разрешения);
// - 16-битное квантование цвета с Bayer-дизерингом;
// - горизонтальные сканлайны, лёгкая RGB-маска люминофора и аналоговое зерно;
// - выпуклая линза кинескопа, синхронизированная с программным курсором.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.35) = 0.06;
uniform float zoom : hint_range(0.85, 1.0) = 0.98;
uniform float corner_radius : hint_range(0.0, 0.12) = 0.01;
uniform float vignette_strength : hint_range(0.0, 0.6) = 0.18;
uniform float aberration : hint_range(0.0, 0.008) = 0.0007;
uniform float aspect = 1.7777778;

uniform vec2 pixel_resolution = vec2(800.0, 450.0);
uniform float scanline_strength : hint_range(0.0, 0.45) = 0.15;
uniform float grille_strength : hint_range(0.0, 0.25) = 0.06;
uniform float color_levels : hint_range(8.0, 64.0) = 32.0;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.022;

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

	// Бочкообразное искажение кинескопа (синхронно с crt_screen_to_ui).
	vec2 lens_p = p * (1.0 - curvature * r2);
	vec2 src_uv = 0.5 + (lens_p / vec2(aspect, 1.0)) * 0.5;
	src_uv = (src_uv - 0.5) / zoom + 0.5;

	// Жёсткая рамка экрана без скруглённых "современных" углов.
	vec2 q = abs(p) - vec2(aspect - corner_radius, 1.0 - corner_radius);
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float mask = step(sd, 0.0);

	// Привязка к ретро-пиксельной сетке.
	vec2 pix_coord = floor(src_uv * pixel_resolution);
	vec2 snapped_uv = (pix_coord + 0.5) / pixel_resolution;

	// Хроматическое расхождение лучей ЭЛТ.
	vec2 dir = normalize(p + vec2(0.00001));
	float ca = aberration * (0.35 + r2);
	vec3 color;
	color.r = texture(screen_texture, snapped_uv + dir * ca).r;
	color.g = texture(screen_texture, snapped_uv).g;
	color.b = texture(screen_texture, snapped_uv - dir * ca).b;

	// 16-битный дизеринг и квантование палитры (High Color 90-х).
	float dither = (bayer4(pix_coord) - 0.5) / color_levels;
	color = clamp(floor((color + dither) * color_levels + 0.5) / color_levels, 0.0, 1.0);

	// Чёткие горизонтальные сканлайны.
	float scan = sin(src_uv.y * pixel_resolution.y * 3.14159265);
	color *= 1.0 - scanline_strength * (0.5 - 0.5 * scan);

	// Субпиксельная вертикальная маска (aperture grille).
	float triad = mod(floor(FRAGCOORD.x), 3.0);
	vec3 grille = vec3(
		1.0 - grille_strength * step(0.5, abs(triad - 0.0)),
		1.0 - grille_strength * step(0.5, abs(triad - 1.0)),
		1.0 - grille_strength * step(0.5, abs(triad - 2.0))
	);
	color *= grille;

	// Лёгкое живое зерно аналогового сигнала.
	float grain = (hash12(pix_coord + fract(TIME * 17.3) * 100.0) - 0.5) * noise_strength;
	color = clamp(color + vec3(grain), 0.0, 1.0);

	// Виньетирование по краям кинескопа.
	vec2 centered = uv - 0.5;
	float edge = smoothstep(0.32, 0.98, length(centered) * 1.414);
	color *= 1.0 - vignette_strength * edge;

	float inside = step(0.0, src_uv.x) * step(src_uv.x, 1.0)
		* step(0.0, src_uv.y) * step(src_uv.y, 1.0);
	COLOR = vec4(color * mask * inside, 1.0);
}
