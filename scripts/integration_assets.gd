extends RefCounted
class_name IntegrationAssets

## Recorded import metadata for runtime integration (see references/integration-checklist.md).

const TRACK := {
	"path": "res://assets/kenney_racing-kit/Models/GLTF format/",
	"type": "kenney_modular",
	"layout": "KenneyTrackLayout",
	"tile_size": 10.0,
	"road_surface_y": 0.01,
}

const CARS := {
	"res://assets/cars/f1_mercedes_w13_concept.glb": {
		"role": "player",
		"forward_fix_degrees": Vector3(0, 90, 0),
		"bounds": Vector3(30.888, 17.232, 26.624),
		"target_length": 1.8,
	},
	"res://assets/cars/red_bull_racing.glb": {
		"role": "ai_opponent",
		"forward_fix_degrees": Vector3(0, 90, 0),
		"bounds": Vector3(255.011, 64.106, 94.556),
	},
	"res://assets/cars/ferrari_f1_2019.glb": {
		"role": "unused",
		"forward_fix_degrees": Vector3(0, 90, 0),
	},
	"res://assets/cars/f1_2021_mclaren_mcl35m.glb": {
		"role": "unused",
		"forward_fix_degrees": Vector3(0, 90, 0),
	},
}
