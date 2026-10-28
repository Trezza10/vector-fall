shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(0.35, 0.95, 0.85, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float radius = length(p);
	float ring = exp(-abs(radius - (0.4 + 0.4 * (1.0 - strength))) * 65.0);
	float core = exp(-radius * radius * 12.0) * 0.25;
	float rails = exp(-abs(abs(p.x) - 0.28) * 65.0);
	rails *= (1.0 - smoothstep(0.1, 0.9, abs(p.y))) * 0.3;
	COLOR = vec4(tint.rgb, (ring + core + rails) * strength * tint.a);
}
