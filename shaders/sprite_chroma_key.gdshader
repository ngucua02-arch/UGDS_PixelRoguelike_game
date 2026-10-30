shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float tolerance : hint_range(0.0, 1.0) = 0.16;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (distance(texel.rgb, key_color) < tolerance) {
		discard;
	}
	COLOR *= texel;
}
