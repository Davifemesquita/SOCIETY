class_name CloudsAdapter
extends Node
## Adaptador das nuvens volumétricas (seção 13: SunshineClouds2, Fase 9): a única peça que conhece
## o addon, carregado pelo caminho e usado só por set/get. Liga e desliga pelo nível gráfico
## (set_quality) e recebe a cobertura do clima. Sem o addon, o céu fica sem nuvens volumétricas.

const DRIVER_SCRIPT := "res://addons/SunshineClouds2/SunshineCloudsDriver.gd"
## Cópia própria do recurso de exemplo do addon (o dele aponta para uma máscara na raiz do projeto
## dele): no lugar da máscara, o ruído de escala extragrande que o addon também traz.
const BASE_RESOURCE := "res://world/sky/clouds.tres"

var _driver: Node
var _resource: Resource
var _sun: DirectionalLight3D
var _environment: Environment
var _enabled: bool = false
var _coverage: float = 0.5


func setup(sun: DirectionalLight3D, environment: Environment) -> void:
	_sun = sun
	_environment = environment


## O addon existe e a placa de vídeo é de verdade. No Vulkan por software (llvmpipe, a VM sem GPU) o
## efeito escurece a tela inteira fora das nuvens: lá elas ficam desligadas.
func available() -> bool:
	return ResourceLoader.exists(DRIVER_SCRIPT) and ResourceLoader.exists(BASE_RESOURCE) and not software_renderer()


static func software_renderer() -> bool:
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	return adapter.contains("llvmpipe") or adapter.contains("lavapipe") or adapter.contains("swiftshader")


func is_enabled() -> bool:
	return _enabled


## Nível gráfico: nuvens só nos que as pedem.
func set_quality(preset: GraphicsPresetDef) -> void:
	set_enabled(preset.clouds)


func set_enabled(on: bool) -> void:
	on = on and available()
	if on == _enabled:
		return
	_enabled = on
	if on:
		_create()
	elif _driver != null:
		_driver.set(&"clouds_resource", null)
		_driver.queue_free()
		_driver = null


## Fração do céu coberta (0 a 1), vinda do clima.
func set_coverage(value: float) -> void:
	_coverage = clampf(value, 0.0, 1.0)
	if _resource != null:
		_resource.set(&"clouds_coverage", _coverage)


func coverage() -> float:
	return _coverage


func _create() -> void:
	var base := load(BASE_RESOURCE)
	_resource = base.duplicate()
	_resource.set(&"clouds_coverage", _coverage)
	var script := load(DRIVER_SCRIPT) as GDScript
	_driver = script.new()
	_driver.name = "Clouds"
	add_child(_driver)
	_driver.set(&"ambience_sample_environment", _environment)
	if _sun != null:
		var lights: Array[DirectionalLight3D] = [_sun]
		_driver.set(&"tracked_directional_lights", lights)
	_driver.set(&"clouds_resource", _resource)
	_driver.set(&"update_continuously", true)
