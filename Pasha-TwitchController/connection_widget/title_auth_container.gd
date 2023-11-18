extends VBoxContainer

onready var twitch_button = $ConnectButton

onready var username_save_button = $UsernameContainer/SaveButton
onready var username_text_edit = $UsernameContainer/HBoxContainer/UsernameText
onready var username_warning = $UsernameContainer/HBoxContainer/UsernameWarning

onready var channel_name_save_button = $ChannelNameContainer/SaveButton
onready var channel_name_text_edit = $ChannelNameContainer/HBoxContainer/ChannelNameText
onready var channel_name_warning = $ChannelNameContainer/HBoxContainer/ChannelNameWarning

var auth_handler
var gift_node
var is_twitch_connected = false
var twitch_oauth_complete = false

func _ready():
	if not $"/root".has_node("AuthHandler") or not $"/root".has_node("GiftNode"):
		return
	
	gift_node = $"/root/GiftNode"
	auth_handler = $"/root/AuthHandler"
	
	if auth_handler.access_token != "":
		make_connect_button_green()
		
	if auth_handler.username != "":
		username_text_edit.text = auth_handler.username
		_on_save_username_pressed()
	
	if auth_handler.channel != "":
		channel_name_text_edit.text = auth_handler.channel
		_on_save_channel_name_pressed()
	
	auth_handler.connect("auth_in_progress", self, "make_connect_button_yellow")
	auth_handler.connect("auth_failure", self, "make_connect_button_red")
	auth_handler.connect("auth_success", self, "make_connect_button_green")
	
	gift_node.connect_to_twitch()
	gift_node.connect("twitch_connected", self, "twitch_connected")
	gift_node.connect("login_attempt", self, "login_attempt_callback")
#	gift_node.connect("chat_message", self, "chat_message")

func start_twitch_auth():
	twitch_button.release_focus()
	$"/root/AuthHandler".get_auth_code()

func maybe_oauth_twitch():
	if auth_handler.username != "" and auth_handler.access_token != "" and not twitch_oauth_complete:
		gift_node.authenticate_oauth(auth_handler.username, auth_handler.access_token) 

func make_connect_button_red():
	change_button_color(twitch_button, Color(.5,0,0))
	
func make_connect_button_yellow():
	change_button_color(twitch_button, Color(.5,.5,0))
	
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

func _on_username_text_changed():
	change_button_color(username_save_button, Color(1,1,0))

func _on_save_username_pressed():
	if username_text_edit.text == "":
		return
	
	auth_handler.username = username_text_edit.text
	auth_handler.save_config_file()
	
	username_warning.hide()
	
	change_button_color(username_save_button, Color(0,.5,0))
	username_save_button.text = "Connected"
	maybe_oauth_twitch()

func change_button_color(button, color) -> void:
	var stylebox_flat = button.get_stylebox("normal").duplicate()
	stylebox_flat.bg_color = color
	button.add_stylebox_override("normal", stylebox_flat)
	
	var stylebox_flat_hover = button.get_stylebox("hover").duplicate()
	stylebox_flat_hover.bg_color = color
	button.add_stylebox_override("hover", stylebox_flat_hover)

func _on_username_text_focus_entered():
	if auth_handler.username == "":
		username_text_edit.text = ""
	username_warning.hide()

func _on_username_text_focus_exited():
	if username_text_edit.text == "":
		username_text_edit.text = "username"
		username_warning.show()

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
		gift_node.join_channel(channel)
		gift_node.chat("Test messages are going to be sent on this channel, don't panic", channel)

func login_attempt_callback(success : bool) -> void:
	if success:
		twitch_oauth_complete = true
		channel_name_save_button.disabled = false
		maybe_connect_to_channel()
