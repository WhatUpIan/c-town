class_name Interactable
extends Area2D

@export var stable_id: String = ""
@export var prompt: String = "Interact"
@export var blocks_los: bool = false

func get_stable_id() -> String:
	return stable_id

func get_prompt() -> String:
	return prompt

func available_action() -> String:
	return "interact"
