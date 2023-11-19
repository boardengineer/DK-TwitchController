extends "res://stages/loadout/LoadoutStage.gd"

onready var left_container = $CanvasLayer/HBoxContainer/MarginContainer2

# Called when the node enters the scene tree for the first time.
func _ready():
	var container = VBoxContainer.new()
	
	var dome_vote_button = DomeButton.duplicate()
	dome_vote_button.text = "Start Twitch Vote for Dome Type"
	disconnect_all(dome_vote_button)
	dome_vote_button.connect("pressed", self, "_on_dome_vote_pressed")
	container.add_child(dome_vote_button)
	
#	var creating_button = DomeButton.duplicate()
#	container.add_child(creating_button)
#
#	creating_button = DomeButton.duplicate()
#	container.add_child(creating_button)
#
#	creating_button = DomeButton.duplicate()
#	container.add_child(creating_button)
#
#	creating_button = DomeButton.duplicate()
#	container.add_child(creating_button)
	
	left_container.add_child(container)
	print_debug("loadout stage extensions onready")
	pass # Replace with function body.

func disconnect_all(signalling_node) -> void:
	var signals = signalling_node.get_signal_list();
	for cur_signal in signals:
		var conns = signalling_node.get_signal_connection_list(cur_signal.name);
		for cur_conn in conns:
			signalling_node.disconnect(cur_conn.signal, cur_conn.target, cur_conn.method)

func _on_dome_vote_pressed():
	for option in Data.loadoutDomes:
		print_debug(option)
		print_debug(tr("upgrades." + option + ".title"))
	
	print_debug("pressed here")
