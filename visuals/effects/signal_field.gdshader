shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(0.35, 0.9, 0.8, 1.0);
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform int style : hint_range(0, 2) = 0;

void fragment() {
	vec2 point = (UV - 0.5) * 2.0;
	float radius = length(point);
	float angle = atan(point.y, point.x);
	float time = TIME * speed;
	float alpha = 0.0;
	if (style == 0) {
		float edge = 0.58 + 0.025 * sin(angle * 8.0 + time * 2.0);
		alpha = 0.06 * (1.0 - smoothstep(0.0, 0.65, radius));
		alpha += 0.8 * exp(-abs(radius - edge) * 100.0);
		alpha += 0.24 * exp(-abs(radius - 0.42) * 90.0);
		alpha += exp(-radius * radius * 110.0) * 0.7;
	} else if (style == 1) {
		float wave = fract(time * 0.45);
		alpha = exp(-abs(radius - wave * 0.85) * 85.0) * (1.0 - wave);
		alpha += exp(-abs(radius - 0.76) * 100.0) * 0.25;
	} else {
		float sweep = pow(0.5 + 0.5 * cos(angle - time * 1.8), 10.0);
		alpha = exp(-abs(radius - 0.65) * 100.0) * (0.2 + sweep * 0.8);
		alpha += exp(-abs(radius - 0.52) * 90.0) * 0.2;
		alpha += exp(-abs(point.x) * 180.0) * 0.1;
		alpha += exp(-abs(point.y) * 180.0) * 0.1;
	}
	COLOR = vec4(tint.rgb, clamp(alpha * intensity, 0.0, 1.0) * tint.a);
}
