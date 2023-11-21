extends "res://stages/loadout/LoadoutStage.gd"

const VOTE_TIME = 15.0

onready var choice_popup = $CanvasLayer/ChoicePopup

onready var popup_container = $CanvasLayer/ChoicePopup/PanelContainer/MarginContainer/VBoxContainer
onready var choices_container = $CanvasLayer/ChoicePopup/PanelContainer/MarginContainer/VBoxContainer/ChoicesContainer

var vote_timer
var start_twitch_button
var chat_controller
var auth_handler

var key_to_choice := {}
var votestring_to_key := {}
var username_to_vote := {}

func _ready():
	chat_controller = $"/root/ChatController"
	auth_handler = $"/root/AuthHandler"
	
	chat_controller.connect("chat_message", self, "chat_message")
	
	start_twitch_button = Button.new()
	Style.init(start_twitch_button)
	start_twitch_button.text = "Start Twitch Vote"
	start_twitch_button.connect("pressed", self, "start_twitch_vote")
	popup_container.add_child(start_twitch_button)
	popup_container.move_child(start_twitch_button, 1)
	
	vote_timer = Timer.new()
	vote_timer.one_shot = true
	vote_timer.connect("timeout", self, "vote_timeout")
	add_child(vote_timer)

func _process(delta):
	if not vote_timer.is_stopped():
		start_twitch_button.text = "%.2f" %vote_timer.time_left
		
		var tally = tally_votes()
		for choice in choices_container.get_children():
			var count = tally[choice.id]
			choice.twitch_display.find_node("TallyLabel").text = "Votes Counter: %s" % str(count)

func chat_message(user, channel, tags, message) -> void:
	if votestring_to_key.has(message):
		username_to_vote[user] = message

func vote_timeout() -> void:
	for choice in choices_container.get_children():
		choice.twitch_display.hide()
	
	var tally = tally_votes()
	
	var max_votes = 0
	var top_keys = []
	
	for key in tally:
		var count = tally[key]
		if count > max_votes:
			top_keys.clear()
			max_votes = count
		
		if max_votes == count:
			top_keys.push_back(key)
	
	var best_result = top_keys[randi() % top_keys.size()]
	choice_popup.emit_signal("choice_made", choice_popup.type, best_result)
	start_twitch_button.text = "Start Twitch Vote"
	chat_controller.chat("[BOT] Winning result: %s" % tr("upgrades." + best_result + ".title"), auth_handler.channel)

func tally_votes() -> Dictionary:
	var result = {}
	for key in key_to_choice:
		result[key] = 0
	
	for voted_user in username_to_vote:
		result[votestring_to_key[username_to_vote[voted_user]]] += 1
	
	return result

func start_twitch_vote() -> void:
	key_to_choice = {}
	votestring_to_key = {}
	username_to_vote = {}
	
	var chat_message = str("[BOT] ", tr("loadout." + choice_popup.type + "options.title"), " Vote: ")
	
	var vote_index = 1
	for choice in choices_container.get_children():
		var vote_key = str(vote_index)
		var vote_result = tr("upgrades." + choice.id + ".title")
		
		chat_message = str(chat_message, " [%s | %s] " % [vote_key, vote_result])
		vote_index += 1
		
		choice.twitch_display.find_node("KeyLabel").text = "Enter \"%s\" in chat" % vote_key
		choice.twitch_display.show()
		
		key_to_choice[choice.id] = choice
		votestring_to_key[vote_key] = choice.id
	
	chat_controller.chat(chat_message, auth_handler.channel)
	vote_timer.start(VOTE_TIME)
