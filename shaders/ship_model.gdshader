// Navio de modelo (Kenney Pirate Kit): a textura de cores do pacote, com as velas (texel claro e sem
// saturação) tingidas na cor do tipo de navio ou da companhia rival.
shader_type spatial;

uniform sampler2D colormap : source_color, filter_nearest;
uniform vec4 sail_tint : source_color = vec4(1.0);

void fragment() {
	vec3 color = texture(colormap, UV).rgb;
	float bright = min(min(color.r, color.g), color.b);
	float spread = max(max(color.r, color.g), color.b) - bright;
	float sail = smoothstep(0.6, 0.75, bright) * (1.0 - smoothstep(0.08, 0.2, spread));
	ALBEDO = mix(color, color * sail_tint.rgb, sail);
	ROUGHNESS = 0.85;
}
