shader_type canvas_item;
render_mode unshaded;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;
uniform vec2 hit_direction = vec2(0.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = smoothstep(0.30, 1.0, max(abs(p.x), abs(p.y)));
	float directional = 1.0;
	if (length(hit_direction) > 0.1) {
		directional = 0.35 + 0.65 * max(0.0, dot(normalize(p + vec2(0.0001)), hit_direction));
	}
	float opacity = edge * (strength * 0.58 * directional + low_health * 0.13);
	COLOR = vec4(1.0, 0.07, 0.04, clamp(opacity, 0.0, 0.65));
}
