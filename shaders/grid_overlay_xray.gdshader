// Camadas de depuração (F1 ocupação, F2 rede de estradas): desenhadas por cima dos
// prédios, para a ocupação aparecer mesmo embaixo das caixas.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, shadows_disabled;

#include "res://shaders/grid_overlay.gdshaderinc"
