extends Node

const MOD_DIR = "Pasha-TwitchController/"
var OAuthTokenFetcher = preload("res://mods-unpacked/Pasha-TwitchController/oauth_token_fetcher.gd")
var ChatController = preload("res://mods-unpacked/Pasha-TwitchController/chat_controller.gd")

var chat_controller
var auth_handler

var is_twitch_connected = false
var is_auth_complete = false

func _init(_modLoader = ModLoader):
	var ext_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR + "extensions/"
	
	ModLoaderMod.install_script_extension(ext_dir + "stages/title/TitleStage.gd")
	
	ModLoaderMod.install_script_extension(ext_dir + "stages/loadout/LoadoutOption.gd")
	ModLoaderMod.install_script_extension(ext_dir + "stages/loadout/LoadoutStage.gd")

func _ready():
	auth_handler = OAuthTokenFetcher.new()
	auth_handler.set_name("AuthHandler")
	$"/root".call_deferred("add_child", auth_handler)
	
	chat_controller = ChatController.new()
	chat_controller.set_name("ChatController")
	$"/root".call_deferred("add_child", chat_controller)
