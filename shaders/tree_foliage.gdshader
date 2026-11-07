// Fase 279: a folhagem das árvores de perto (o nível de detalhe de perto do TreeModel, menos o coqueiro): a mesma do
// foliage.gdshader, com os cachos de folhas e a borda da copa recortada (LEAF_DETAIL, no foliage.gdshaderinc). Fica num shader
// à parte porque o discard tira a profundidade antecipada: as plantações, o capim e as árvores de longe seguem sem ele.
shader_type spatial;
render_mode cull_disabled;

#define LEAF_DETAIL
#include "res://shaders/foliage.gdshaderinc"
