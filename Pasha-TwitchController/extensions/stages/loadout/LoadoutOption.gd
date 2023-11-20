extends "res://stages/loadout/LoadoutOption.gd"

onready var content_container = $MarginContainer/VBoxContainer

var LoadoutOptionTwitchDisplay = load("res://mods-unpacked/Pasha-TwitchController/LoadoutOptionTwitchDisplay.tscn")

var twitch_display

func _ready():
	twitch_display = LoadoutOptionTwitchDisplay.instance()
	content_container.add_child(twitch_display)
	content_container.move_child(twitch_display, 0)
