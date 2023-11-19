extends VBoxContainer

var ChatController = preload("res://mods-unpacked/Pasha-TwitchController/chat_controller.gd")

onready var twitch_button = $ConnectButton


onready var channel_name_save_button = $ChannelNameContainer/SaveButton
onready var channel_name_text_edit = $ChannelNameContainer/HBoxContainer/ChannelNameText
onready var channel_name_warning = $ChannelNameContainer/HBoxContainer/ChannelNameWarning

var auth_handler
var chat_controller
var is_twitch_connected = false
var twitch_oauth_complete = false

func _ready():
	if not $"/root".has_node("AuthHandler") or not $"/root".has_node("ChatController"):
		return
	
	chat_controller = $"/root/ChatController"
	auth_handler = $"/root/AuthHandler"
	
	if auth_handler.access_token != "":
		make_connect_button_green()
	
	if auth_handler.channel != "":
		channel_name_text_edit.text = auth_handler.channel
		_on_save_channel_name_pressed()
	
	auth_handler.connect("auth_in_progress", self, "make_connect_button_yellow")
	auth_handler.connect("auth_failure", self, "make_connect_button_red")
	auth_handler.connect("auth_success", self, "make_connect_button_green")
	
	chat_controller.connect("twitch_connected", self, "twitch_connected")
	chat_controller.connect("login_attempt", self, "login_attempt_callback")
	chat_controller.connect("twitch_disconnected", self, "twitch_disconnected")
	chat_controller.connect_to_twitch()

func start_twitch_auth():
	twitch_button.release_focus()
	$"/root/AuthHandler".get_auth_code()

func maybe_oauth_twitch():
	if auth_handler.access_token != "" and is_twitch_connected and not twitch_oauth_complete:
		chat_controller.authenticate_oauth(auth_handler.access_token) 

func make_connect_button_red():
	change_button_color(twitch_button, Color(.5,0,0))
	
func make_connect_button_yellow():
	change_button_color(twitch_button, Color(.5,.5,0))

func auth_success():
	make_connect_button_green()
	maybe_oauth_twitch()

func make_connect_button_green():
	change_button_color(twitch_button, Color(0,.5,0))

func _on_channel_name_text_changed():
	change_button_color(channel_name_save_button, Color(1,1,0))

func _on_save_channel_name_pressed():
	if channel_name_text_edit.text == "":
		return
	
	auth_handler.channel = channel_name_text_edit.text
	auth_handler.save_config_file()
	
	channel_name_warning.hide()
	
	change_button_color(channel_name_save_button, Color(0,.5,0))
	channel_name_save_button.text = "Joined"
	
	maybe_connect_to_channel()

func change_button_color(button, color) -> void:
	var stylebox_flat = button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = color
	button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = color
	button.add_stylebox_override("hover", stylebox_flat_hover)

func _on_channel_text_focus_entered():
	channel_name_warning.hide()

func _on_channel_text_focus_exited():
	channel_name_warning.show()

func twitch_connected():
	is_twitch_connected = true
	maybe_oauth_twitch()

func maybe_connect_to_channel() -> void:
	var has_valid_channel = (auth_handler.channel != "")
	if has_valid_channel:
		var channel = auth_handler.channel
		chat_controller.join_channel(channel)

func login_attempt_callback(success : bool) -> void:
	if success:
		twitch_oauth_complete = true
		channel_name_save_button.disabled = false
		maybe_connect_to_channel()

func twitch_disconnected():
	chat_controller.connect_to_twitch()

func _on_reset_twitch():
	auth_handler.restart()
	
	change_button_color(twitch_button, Color(.6,.6,.6))
	
	# reset chat controller
	$"/root".remove_child(chat_controller)

	# Add a new chat controller
	chat_controller = ChatController.new()
	chat_controller.set_name("ChatController")
	$"/root".call_deferred("add_child", chat_controller)
	chat_controller.connect("twitch_connected", self, "twitch_connected")
	chat_controller.connect("login_attempt", self, "login_attempt_callback")
	chat_controller.connect_to_twitch()
	
	channel_name_text_edit.text = "Channel Name"
	channel_name_warning.show()
	channel_name_save_button.disabled = true
