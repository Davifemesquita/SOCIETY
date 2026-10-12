// Corpo comum da grade de construção e das camadas de depuração (F1, F2).
uniform float cell_size = 2.0;
uniform vec2 grid_cells = vec2(250.0, 250.0);
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.22);
uniform bool show_lines = true;
uniform bool show_cells = false;
uniform sampler2D cell_data : source_color, filter_nearest;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = world_position.xz / cell_size;
	vec4 color = vec4(0.0);
	if (show_cells) {
		color = texture(cell_data, cell / grid_cells);
	}
	if (show_lines) {
		vec2 width = fwidth(cell);
		vec2 distance_to_line = abs(fract(cell - 0.5) - 0.5) / max(width, vec2(0.0001));
		float line = 1.0 - min(min(distance_to_line.x, distance_to_line.y), 1.0);
		float alpha = line_color.a * line;
		color.rgb = mix(color.rgb, line_color.rgb, alpha);
		color.a = max(color.a, alpha);
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
