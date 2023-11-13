extends "res://stages/title/TitleStage.gd"

var twitch_button

onready var button_container = $Canvas
onready var main_menu = $Canvas/MainMenu/Panel/MainMenuButtons/ContinueButton

func _ready():
	if not $"/root".has_node("AuthHandler"):
		return
	
	var auth_handler = $"/root/AuthHandler"
	auth_handler.connect("auth_in_progress", self, "make_button_yellow")
	auth_handler.connect("auth_failure", self, "make_button_red")
	auth_handler.connect("auth_success", self, "make_button_green")
	
	twitch_button = load("res://mods-unpacked/Pasha-TwitchController/TwitchAuthButton.tscn").instance()
	twitch_button.connect("pressed", self, "start_twitch_auth")
	
	if auth_handler.jwt and auth_handler.jwt != "":
		make_button_green()
	
	button_container.add_child(twitch_button)
	button_container.move_child(twitch_button, 1)

func start_twitch_auth():
	if not $"/root".has_node("AuthHandler"):
		return
	
	twitch_button.release_focus()
	main_menu.grab_focus()
	
	$"/root/AuthHandler".get_auth_code()

func make_button_red():
	var stylebox_flat = twitch_button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = Color(1,0,0)
	twitch_button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = twitch_button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = Color(1,0,0)
	twitch_button.add_stylebox_override("hover", stylebox_flat_hover)
	
func make_button_yellow():
	var stylebox_flat = twitch_button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = Color(1,1,0)
	twitch_button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = twitch_button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = Color(1,1,0)
	twitch_button.add_stylebox_override("hover", stylebox_flat_hover)
	
func make_button_green():
	var stylebox_flat = twitch_button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = Color(0,1,0)
	twitch_button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = twitch_button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = Color(0,1,0)
	twitch_button.add_stylebox_override("hover", stylebox_flat_hover)
