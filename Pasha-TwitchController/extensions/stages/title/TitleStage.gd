extends "res://stages/title/TitleStage.gd"

onready var button_container = $Canvas
onready var main_menu = $Canvas/MainMenu/Panel/MainMenuButtons/ContinueButton

func _ready():
	var auth_connect = load("res://mods-unpacked/Pasha-TwitchController/connection_widget/TitleAuthContainer.tscn").instance()
	
	button_container.add_child(auth_connect)
