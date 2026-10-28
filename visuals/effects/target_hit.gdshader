shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 status_tint : source_color = vec4(1.0);
uniform float status_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, status_tint.rgb, status_strength);
	COLOR.rgb = mix(COLOR.rgb, vec3(0.9, 1.0, 0.97), flash);
}
