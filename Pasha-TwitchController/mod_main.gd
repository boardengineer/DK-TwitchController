extends Node

const MOD_DIR = "Pasha-TwitchController/"
var OAuthTokenFetcher = preload("res://mods-unpacked/Pasha-TwitchController/oauth_token_fetcher.gd")
var GiftNode = preload("res://mods-unpacked/Pasha-TwitchController/gift/gift_node.gd")

var gift_node
var auth_handler

var is_twitch_connected = false
var is_auth_complete = false

func _init(_modLoader = ModLoader):
	var ext_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR + "extensions/"
	
	ModLoaderMod.install_script_extension(ext_dir + "stages/title/TitleStage.gd")

func _ready():
	auth_handler = OAuthTokenFetcher.new()
	auth_handler.set_name("AuthHandler")
	var _unused = auth_handler.connect("auth_success", self, "auth_success")
	$"/root".call_deferred("add_child", auth_handler)
	
	gift_node = GiftNode.new()
	gift_node.set_name("GiftNode")
	
	gift_node.connect_to_twitch()
	gift_node.connect("twitch_connected", self, "twitch_connected")
	gift_node.connect("login_attempt", self, "login_attempt_callback")
#	gift_node.connect("chat_message", self, "chat_message")
	
	$"/root".call_deferred("add_child", gift_node)

func auth_success():
	is_auth_complete = true
	maybe_connect_to_channel()

func twitch_connected():
	is_twitch_connected = true
	print_debug("twitch connected ")
	maybe_connect_to_channel()
	
#	gift_node.authenticate_oauth(twitch_username, twitch_token)
#	if $"/root".has_node("AutobattlerOptions"):
#		var options_node = $"/root/AutobattlerOptions"
#		print_debug("setting to true, should work?")
#		options_node.enable_autobattler = true

func maybe_connect_to_channel() -> void:
	if is_twitch_connected and is_auth_complete:
		print_debug("this is where we can join the channel")
		gift_node.authenticate_oauth("twitchslaysspire", auth_handler.access_token) 
#		gift_node.join_channel("twitchslaysspire")

func login_attempt_callback(success : bool) -> void:
	print_debug("was success? ", success)
	if success:
		gift_node.join_channel("twitchslaysspire")
		gift_node.chat("Test messages are going to be sent on this channel, don't panic", "twitchslaysspire")
