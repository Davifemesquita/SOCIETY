// Fase 290: os estratos da rocha, divididos pelo terrain.gdshader e pelo sea_rock.gdshader. Camadas quase horizontais de
// strata_m de altura, onduladas pelo ruído ao longo da costa (não fatias retas), cada uma com a borda de cima mais clara (o
// ressalto que pega luz) e a de baixo na sombra; e sulcos descendo pela encosta (o ruído esticado ao longo da inclinação). Tudo
// em fator de cor (1 = nada), pela altura e pelo lugar no mundo: a rocha do terreno e as pedras soltas batem nas mesmas camadas.

uniform float strata_m = 1.15;
uniform float strata_warp_m = 0.5;
uniform float strata_light = 0.32;
uniform float strata_shade = 0.38;
uniform float gully_strength = 0.18;

float strata_hash(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p)));
	uint h = q.x * 1597334677u ^ q.y * 3812015801u;
	h ^= h >> 16u;
	h *= 2654435769u;
	return float(h >> 8u) / 16777216.0;
}

float strata_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(strata_hash(i), strata_hash(i + vec2(1.0, 0.0)), f.x),
			mix(strata_hash(i + vec2(0.0, 1.0)), strata_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// O fator de cor dos estratos no ponto do mundo com a normal dada (só na face inclinada: steep de 0 na plana a 1 na de pé).
float strata_factor(vec3 at, vec3 normal_w) {
	float steep = 1.0 - smoothstep(0.55, 0.9, normal_w.y);
	if (steep <= 0.0) {
		return 1.0;
	}
	float warp = (strata_noise(at.xz * 0.07) - 0.5) * 2.0 * strata_warp_m
			+ (strata_noise(at.xz * 0.31) - 0.5) * strata_warp_m * 0.5;
	float layer = fract((at.y + warp) / strata_m);
	// em cima da camada (layer perto de 1) a borda clara; logo embaixo (perto de 0) a sombra
	float lip = smoothstep(0.78, 0.97, layer) * (1.0 - smoothstep(0.97, 1.0, layer));
	float under = 1.0 - smoothstep(0.0, 0.22, layer);
	// os sulcos: o ruído esticado ao longo da descida (a direção da normal no plano), estreito de través
	vec2 down = normalize(normal_w.xz + vec2(1e-4, 0.0));
	vec2 across = vec2(-down.y, down.x);
	float along_m = dot(at.xz, down) - at.y;
	float gully = smoothstep(0.62, 0.8, strata_noise(vec2(dot(at.xz, across) * 0.9, along_m * 0.12)));
	float factor = 1.0 + lip * strata_light - under * strata_shade - gully * gully_strength;
	return mix(1.0, factor, steep);
}

// Fase 346: as bancadas de longe. Os estratos de strata_m somem a mais de ~150 m (menores que um pixel); por cima deles, camadas
// largas de strata_broad_m, com a borda clara e a sombra mais fortes, entram de strata_broad_from_m a strata_broad_to_m da câmera
// (a distância vem de quem chama: função de include não lê a câmera).
uniform float strata_broad_m = 4.2;
uniform float strata_broad_light = 0.3;
uniform float strata_broad_shade = 0.42;
uniform float strata_broad_from_m = 70.0;
uniform float strata_broad_to_m = 220.0;

float strata_broad(vec3 at, vec3 normal_w, float distance_m) {
	float steep = 1.0 - smoothstep(0.55, 0.9, normal_w.y);
	float far = smoothstep(strata_broad_from_m, strata_broad_to_m, distance_m);
	if (steep * far <= 0.0) {
		return 1.0;
	}
	float warp = (strata_noise(at.xz * 0.025) - 0.5) * 2.0 * strata_broad_m * 0.6;
	float layer = fract((at.y + warp) / strata_broad_m);
	float lip = smoothstep(0.8, 0.96, layer) * (1.0 - smoothstep(0.96, 1.0, layer));
	float under = 1.0 - smoothstep(0.0, 0.3, layer);
	return mix(1.0, 1.0 + lip * strata_broad_light - under * strata_broad_shade, steep * far);
}

// Fase 291: o musgo e o capim nas saliências da rocha. Nas partes quase planas (pela normal: moss_flat) e no ressalto de cima de
// cada camada (o mesmo dos estratos), em manchas de moss_patch_m, mais no lado da sombra (o norte fixo moss_shade_dir: com o sol
// do dia o musgo andaria) e menos nas faces de pé. Devolve quanto pintar de musgo (0 a 1).
uniform vec2 moss_flat = vec2(0.35, 0.7);
uniform float moss_patch_m = 2.2;
uniform float moss_amount_max = 0.85;
uniform vec2 moss_shade_dir = vec2(0.0, -1.0);
uniform vec3 moss_color : source_color = vec3(0.3, 0.42, 0.14);

float moss_amount(vec3 at, vec3 normal_w) {
	float flat_part = smoothstep(moss_flat.x, moss_flat.y, normal_w.y);
	float warp = (strata_noise(at.xz * 0.07) - 0.5) * 2.0 * strata_warp_m;
	float layer = fract((at.y + warp) / strata_m);
	float ledge = smoothstep(0.86, 0.97, layer) * (1.0 - smoothstep(0.97, 1.0, layer)) * (1.0 - flat_part);
	float shade = 0.6 + 0.4 * clamp(dot(normalize(normal_w.xz + vec2(1e-4, 0.0)), moss_shade_dir), 0.0, 1.0);
	float patches = smoothstep(0.42, 0.7, strata_noise(at.xz / moss_patch_m + vec2(at.y * 0.4, 13.0)));
	return clamp((flat_part + ledge * 0.8) * patches * shade, 0.0, 1.0) * moss_amount_max;
}

// Fase 310: os blocos da face. Nas faces de pé, a rocha se parte em blocos grandes (um Voronoi 3D no mundo, de block_m e mais
// baixos que largos: não depende da normal, que muda a cada faceta da pedra e riscava o desenho), cada um com o seu tom e o seu
// plano (a normal do bloco, torta pelo sorteio dele, pega mais ou menos da luz fixa block_light_dir, como uma faceta), e as juntas
// escuras entre eles. Fator de cor (1 = nada).
uniform float block_m = 2.6;
uniform float block_joint_m = 0.14;
uniform float block_joint_dark = 0.5;
uniform float block_tone = 0.14;
uniform float block_light = 0.35;
uniform vec3 block_light_dir = vec3(0.45, 0.75, 0.48);

float block_hash(vec3 cell, vec2 salt) {
	return strata_hash(cell.xz + vec2(cell.y * 57.0, cell.y * 113.0) + salt);
}

float block_factor(vec3 at, vec3 normal_w) {
	float steep = 1.0 - smoothstep(0.45, 0.8, normal_w.y);
	if (steep <= 0.0) {
		return 1.0;
	}
	vec3 q = vec3(at.x, at.y * 1.45, at.z) / block_m;
	vec3 base = floor(q - 0.5);
	float first = 8.0;
	float second = 8.0;
	vec3 id = base;
	for (int z = 0; z <= 1; z++) {
		for (int y = 0; y <= 1; y++) {
			for (int x = 0; x <= 1; x++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				vec3 point = cell + 0.15 + 0.7 * vec3(block_hash(cell, vec2(3.0, 7.0)), block_hash(cell, vec2(29.0, 11.0)),
						block_hash(cell, vec2(47.0, 83.0)));
				float d = length(q - point);
				if (d < first) {
					second = first;
					first = d;
					id = cell;
				} else if (d < second) {
					second = d;
				}
			}
		}
	}
	float joint = 1.0 - smoothstep(0.0, block_joint_m / block_m, second - first);
	float tone = 1.0 + (block_hash(id, vec2(41.0, 5.0)) - 0.5) * 2.0 * block_tone;
	vec3 tilt = vec3(block_hash(id, vec2(13.0, 57.0)), block_hash(id, vec2(71.0, 23.0)), block_hash(id, vec2(5.0, 91.0))) * 2.0 - 1.0;
	vec3 light_dir = normalize(block_light_dir);
	float light = (dot(normalize(normal_w + tilt * 0.55), light_dir) - dot(normal_w, light_dir)) * block_light;
	float factor = tone * (1.0 + light) * (1.0 - joint * block_joint_dark);
	return mix(1.0, factor, steep);
}
