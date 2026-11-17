shader_type canvas_item;
render_mode unshaded;

// Выпуклая линза кинескопа: изображение выгибается наружу, края уходят
// в чёрные скруглённые углы. Картинка берётся из screen texture, поэтому
// программный курсор, нарисованный до этого оверлея, тоже проходит через
// линзу и остаётся визуально под реальной мышью.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float curvature : hint_range(0.0, 0.35) = 0.05;
uniform float zoom : hint_range(0.85, 1.0) = 0.97;
uniform float corner_radius : hint_range(0.02, 0.12) = 0.03;
uniform float vignette_strength : hint_range(0.0, 0.6) = 0.12;
uniform float aberration : hint_range(0.0, 0.004) = 0.0004;
uniform float aspect = 1.7777778;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Переводим координаты в пространство с одинаковым масштабом по осям,
	// чтобы линза была круглой, а не вытянутой по ширине экрана.
	vec2 p = (uv - 0.5) * 2.0;
	p.x *= aspect;
	float r2 = dot(p, p) / (aspect * aspect + 1.0);

	// Обратное бочкообразное искажение: экранный пиксель берёт сэмпл
	// ближе к центру, поэтому картинка визуально выгибается наружу.
	vec2 lens_p = p * (1.0 - curvature * r2);
	vec2 src_uv = 0.5 + (lens_p / vec2(aspect, 1.0)) * 0.5;
	src_uv = (src_uv - 0.5) / zoom + 0.5;

	// Скруглённые углы кинескопа.
	vec2 q = abs(p) - vec2(aspect - corner_radius, 1.0 - corner_radius);
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float mask = 1.0 - smoothstep(-0.0015, 0.0015, sd);

	// Очень лёгкая хроматическая аберрация по краям.
	vec2 dir = normalize(p + vec2(0.00001));
	float ca = aberration * r2;
	vec3 color;
	color.r = texture(screen_texture, src_uv + dir * ca).r;
	color.g = texture(screen_texture, src_uv).g;
	color.b = texture(screen_texture, src_uv - dir * ca).b;

	vec2 centered = uv - 0.5;
	float edge = smoothstep(0.35, 0.95, length(centered) * 1.414);
	color *= 1.0 - vignette_strength * edge;

	float inside = step(0.0, src_uv.x) * step(src_uv.x, 1.0)
		* step(0.0, src_uv.y) * step(src_uv.y, 1.0);
	COLOR = vec4(color * mask * inside, 1.0);
}
