extends "res://stages/title/TitleStage.gd"

onready var button_container = $Canvas
onready var main_menu = $Canvas/MainMenu/Panel/MainMenuButtons/ContinueButton

onready var twitch_options_scene = load("res://mods-unpacked/Pasha-TwitchController/extensions/systems/options/TwitchCategory.tscn")
onready var auth_connect = load("res://mods-unpacked/Pasha-TwitchController/connection_widget/TitleAuthContainer.tscn")

func _ready():
	var invisible_connector = auth_connect.instance()
	invisible_connector.hide()
	button_container.add_child(invisible_connector)

func _on_OptionsButton_pressed()->void :
	Audio.sound("gui_title_options")
	var i = preload("res://systems/options/OptionsInputProcessor.gd").new()
	i.blockAllKeys = true
	var options_panel = preload("res://systems/options/OptionsPanel.tscn").instance()
	var twitch_button = Button.new()
	twitch_button.text = "Twitch"
	twitch_button.set_name("TwitchCategoryButton")
	twitch_button.connect("pressed", options_panel, "_on_CategoryButton_pressed", ["Twitch"])
	options_panel.categories.push_back("Twitch")
	options_panel.find_node("CategoriesList").add_child(twitch_button)
	twitch_button.owner = options_panel
	var twitch_category = auth_connect.instance()
	twitch_category.set_name("TwitchCategory")
	options_panel.find_node("MarginContainer").add_child(twitch_category)
	twitch_category.owner = options_panel
	i.popup = options_panel
	i.stickReceiver = i.popup
	$Canvas.add_child(i.popup)
	i.popup.setFromOptions()
	i.integrate(self)
	i.connect("onStop", self, "optionsClosed", [i.popup])
	i.popup.connect("close", i, "desintegrate")
	find_node("Overlay").showOverlay()
