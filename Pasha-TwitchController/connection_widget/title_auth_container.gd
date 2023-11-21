extends VBoxContainer

var ChatController = preload("res://mods-unpacked/Pasha-TwitchController/chat_controller.gd")

onready var twitch_button = $HBoxContainer2/AuthenticateButton
onready var authenticated_label = $HBoxContainer2/AuthenticatedLabel
onready var instruction_label = $InstructionLabel

onready var join_channel_button = $HBoxContainer/JoinChannelButton
onready var channel_text_edit = $HBoxContainer/ChannelTextEdit
onready var channel_joined_label = $HBoxContainer/ChannelJoinedLabel

var auth_handler
var chat_controller
var twitch_oauth_complete = false

func _ready():
	if not $"/root".has_node("AuthHandler") or not $"/root".has_node("ChatController"):
		return
	
	chat_controller = $"/root/ChatController"
	auth_handler = $"/root/AuthHandler"
	
	if auth_handler.access_token != "":
		twitch_button.disabled = true
		join_channel_button.disabled = false
		authenticated_label.show()
	
	if auth_handler.channel != "":
		join_channel_button.disabled = false
		channel_text_edit.text = auth_handler.channel
		_on_save_channel_name_pressed()
	
	auth_handler.connect("auth_failure", self, "make_connect_button_red")
	auth_handler.connect("auth_success", self, "auth_success")
	
	chat_controller.connect("twitch_connected", self, "twitch_connected")
	chat_controller.connect("login_attempt", self, "login_attempt_callback")
	chat_controller.connect("twitch_disconnected", self, "twitch_disconnected")
	
	if not chat_controller.connected:
		chat_controller.connect_to_twitch()
	
	update_instruction_label()

func start_twitch_auth():
	twitch_button.release_focus()
	$"/root/AuthHandler".get_auth_code()

func maybe_oauth_twitch():
	if auth_handler.access_token != "" and chat_controller.connected and not twitch_oauth_complete:
		chat_controller.authenticate_oauth(auth_handler.access_token) 

func auth_success():
	authenticated_label.show()
	twitch_button.disabled = true
	maybe_oauth_twitch()
	update_instruction_label()

func _on_save_channel_name_pressed():
	if channel_text_edit.text == "":
		return
	
	auth_handler.channel = channel_text_edit.text
	auth_handler.save_config_file()
	
	update_instruction_label()
	maybe_connect_to_channel()

func change_button_color(button, color) -> void:
	var stylebox_flat = button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = color
	button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = color
	button.add_stylebox_override("hover", stylebox_flat_hover)

func _on_channel_text_focus_entered():
	if auth_handler.channel == "":
		channel_text_edit.text = ""

func _on_channel_text_focus_exited():
	if channel_text_edit.text == "":
		channel_text_edit.text = "Channel Name"

func twitch_connected():
	update_instruction_label()
	maybe_oauth_twitch()

func maybe_connect_to_channel() -> void:
	var has_valid_channel = (auth_handler.channel != "")
	if has_valid_channel:
		channel_joined_label.show()
		var channel = auth_handler.channel
		chat_controller.join_channel(channel)
		chat_controller.chat("[BOT] Dome Keeper Bot Joined", channel)

func login_attempt_callback(success : bool) -> void:
	if success:
		twitch_oauth_complete = true
		join_channel_button.disabled = false
		maybe_connect_to_channel()

func twitch_disconnected():
	chat_controller.connect_to_twitch()

func _on_reset_twitch():
	auth_handler.restart()
	authenticated_label.hide()
	channel_joined_label.hide()
	
	twitch_button.disabled = false
	twitch_oauth_complete = false
	
	# reset chat controller
	$"/root".remove_child(chat_controller)

	# Add a new chat controller
	chat_controller = ChatController.new()
	chat_controller.set_name("ChatController")
	chat_controller.connected = false
	$"/root".call_deferred("add_child", chat_controller)
	
	chat_controller.connect("twitch_connected", self, "twitch_connected")
	chat_controller.connect("login_attempt", self, "login_attempt_callback")
	chat_controller.connect("twitch_disconnected", self, "twitch_disconnected")
	chat_controller.connect_to_twitch()
	
	channel_text_edit.text = "Channel Name"
	join_channel_button.disabled = true
	update_instruction_label()

func update_instruction_label() -> void:
	instruction_label.text = get_instruction_string()

func get_instruction_string() -> String:
	if auth_handler.access_token == "":
		return "Please Authenticate Twitch"
	elif not chat_controller.connected:
		return "Connecting to twitch..."
	elif auth_handler.channel == "":
		return "Please Select a Channel to Join"
	else:
		return "Twitch Chat Connected, You're Good to Go"
