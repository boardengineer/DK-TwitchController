extends Node

const MOD_DIR = "Pasha-TwitchController/"
var OAuthTokenFetcher = load("res://mods-unpacked/Pasha-TwitchController/oauth_token_fetcher.gd")

func _init(_modLoader = ModLoader):
	var ext_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR + "extensions/"
	
	ModLoaderMod.install_script_extension(ext_dir + "stages/title/TitleStage.gd")

func _ready():
	var auth_handler = OAuthTokenFetcher.new()
	auth_handler.set_name("AuthHandler")
	$"/root".call_deferred("add_child", auth_handler)
