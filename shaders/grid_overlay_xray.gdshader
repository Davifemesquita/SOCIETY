// Células destacadas (camadas F1/F2, alcance, terreno pedido): desenhadas por cima dos prédios, para a ocupação
// aparecer mesmo embaixo das caixas. Desde a Fase 33 vai como overlay sem as linhas, que ficam no chão.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, shadows_disabled;

#include "res://shaders/grid_overlay.gdshaderinc"
