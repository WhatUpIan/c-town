class_name RngState
extends RefCounted

var seed: int = 12345
var draw_counter: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func configure(p_seed: int, p_draw: int = 0) -> void:
	seed = p_seed
	draw_counter = p_draw
	_rng.seed = seed
	# Fast-forward draws for determinism after load
	for _i in draw_counter:
		_rng.randf()

func draw_float() -> float:
	draw_counter += 1
	return _rng.randf()

func draw_bool(success_chance: float = 0.7) -> bool:
	return draw_float() < success_chance

func clone() -> RngState:
	var c := RngState.new()
	c.configure(seed, draw_counter)
	return c
