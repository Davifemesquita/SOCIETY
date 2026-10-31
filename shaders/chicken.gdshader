// Galinha (Fase 135): a cor dos vértices, e a plumagem (UV.x = 1) tingida pela cor da galinha, que o ChickenView põe em
// INSTANCE_CUSTOM.rgb (sRGB). A crista, o bico e as pernas (UV.x = 0) ficam na cor deles.
shader_type spatial;

varying vec3 tint;

void vertex() {
	tint = mix(vec3(1.0), INSTANCE_CUSTOM.rgb, UV.x);
}

void fragment() {
	vec3 color = COLOR.rgb * tint;
	// a cor vem em sRGB, como no vertex_color_is_srgb do StandardMaterial3D
	ALBEDO = mix(pow((color + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), color * (1.0 / 12.92), lessThan(color, vec3(0.04045)));
	ROUGHNESS = 0.85;
}
