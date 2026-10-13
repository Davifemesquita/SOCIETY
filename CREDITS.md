# Créditos

Todo asset, addon e ferramenta de terceiros que entra no jogo, com autor, link, licença e
arquivos usados. A tela de créditos do jogo lê este arquivo. Licenças aceitas: CC0, MIT,
OFL e CC BY (com crédito). Proibido: assets extraídos de jogos, licença "não comercial" e
código GPL dentro do jogo.

| Item | Autor | Link | Licença | Arquivos |
|---|---|---|---|---|
| Godot Engine 4.7.2 | Juan Linietsky, Ariel Manzur e colaboradores | https://godotengine.org | MIT | o motor |
| gdUnit4 6.2.2 | Mike Schulze e colaboradores | https://github.com/godot-gdunit-labs/gdUnit4 | MIT | `addons/gdUnit4/` (só desenvolvimento, fora da exportação) |
| Sky3D 2.1.0 | Cory Petkovsek, J. Cuéllar e colaboradores | https://github.com/TokisanGames/Sky3D | MIT | `addons/sky_3d/` (céu, sol, lua e estrelas; usado pelo `world/sky/sky_adapter.gd`) |
| The Milky Way panorama (dentro do Sky3D) | ESO/S. Brunier | https://www.eso.org/public/images/eso0932a/ | CC BY 4.0 | `addons/sky_3d/assets/thirdparty/textures/milkyway/` — usado no original e numa versão modificada (só as estrelas mais brilhantes) |
| Textura da lua (dentro do Sky3D) | GPoSM | https://www.highend3d.com/downloads/3d-textures/c/16k-earth-w-4k-moon-free | MIT | `addons/sky_3d/assets/thirdparty/textures/moon/` |
| Universal Base Characters (Standard) | Quaternius | https://quaternius.itch.io/universal-base-characters | CC0 | `assets/source/quaternius/Superhero_{Male,Female}_FullBody.gltf/.bin`, reduzidos a ~1.600 triângulos em `assets/vat/pedestrian_*.res` |
| Universal Animation Library 1 e 2 (Standard) | Quaternius | https://quaternius.itch.io/universal-animation-library e https://quaternius.itch.io/universal-animation-library-2 | CC0 | animações Walk_Loop, Idle_Loop, Idle_Talking_Loop (1) e Walk_Carry_Loop (2), em `assets/source/quaternius/pedestrian_clips.res` e gravadas nas texturas VAT |
| Boujie Water Shader 1.0.1 | Zach Bernal e colaboradores | https://github.com/Chrisknyfe/boujie_water_shader | MIT | `addons/boujie_water_shader/` (nó Ocean e o material pronto); cópia editada do shader em `shaders/water.gdshader` (poluição da água) |
| Texturas do terreno | Poly Haven | https://polyhaven.com (aerial_grass_rock, aerial_rocks_02, aerial_beach_01, forest_ground_04) | CC0 | 1K, empacotadas em `assets/terrain/*_albedo_height.png` e `*_normal_roughness.png` por `tools/pack_terrain_textures.gd` |
| Nature Kit 2.1 | Kenney | https://kenney.nl/assets/nature-kit | CC0 | `assets/models/nature/` (5 árvores e 2 pedras; as cores do jogo trocam as do pacote) |
