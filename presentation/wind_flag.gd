class_name WindFlag
extends Node3D
## Bandeira de mastro (Fase 22): o nó fica no mastro, na beira da bandeira presa nele, e o pano é o
## filho Cloth, deslocado meia largura para +x. O WeatherView gira o nó a cada quadro para o pano
## apontar para onde o vento sopra e tremular com o vento forte. Com o ar parado o pano cai: a beira
## segue presa no mastro e só a ponta desce (cisalhamento, não giro: girado, o pano atravessava o
## mastro), encolhida como pano mole. Só visual.

const GROUP := &"wind_flags"
## Quanto a ponta do pano cai (rad) com o ar parado, quanto da largura sobra mole e a força a partir
## da qual ele fica esticado.
const DROOP_RAD := 1.1
const LIMP_WIDTH := 0.55
const TAUT_WIND := 0.45
## Tremular: amplitude (rad) com o vento cheio e a frequência.
const FLUTTER_RAD := 0.18
const FLUTTER_HZ := 1.6


## Monta a bandeira de tamanho size (largura, altura, espessura) com a beira presa em at (no pai).
static func make(size: Vector3, material: Material, at: Vector3) -> WindFlag:
	var flag := WindFlag.new()
	flag.name = "Flag"
	flag.position = at
	var cloth := MeshInstance3D.new()
	cloth.name = "Cloth"
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	cloth.mesh = box
	cloth.position = Vector3(size.x * 0.5, 0.0, 0.0)
	flag.add_child(cloth)
	flag.add_to_group(GROUP)
	return flag


## Giro em y que leva o +x do nó para a direção do vento (x/z do mundo).
static func yaw_of(direction: Vector2) -> float:
	return atan2(-direction.y, direction.x)


## Quanto o pano cai com a força do vento (0 a 1).
static func droop_of(strength: float) -> float:
	return DROOP_RAD * (1.0 - smoothstep(0.0, TAUT_WIND, strength))


func blow(direction: Vector2, strength: float, time: float) -> void:
	var phase := global_position.x * 0.31 + global_position.z * 0.23
	var flutter := sin(time * FLUTTER_HZ * TAU + phase) * FLUTTER_RAD * strength
	var droop := droop_of(strength)
	var width := lerpf(LIMP_WIDTH, 1.0, smoothstep(0.0, TAUT_WIND, strength))
	var hang := Basis(Vector3(cos(droop), -sin(droop), 0.0) * width, Vector3.UP, Vector3.BACK)
	global_basis = Basis(Vector3.UP, yaw_of(direction) + flutter) * hang
