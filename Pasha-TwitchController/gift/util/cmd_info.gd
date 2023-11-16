extends Reference
class_name CommandInfo

const SenderData  = preload("res://mods-unpacked/Pasha-TwitchController/gift/util/sender_data.gd")

var sender_data : SenderData
var command : String
var whisper : bool

func _init(sndr_dt, cmd, whspr):
	sender_data = sndr_dt
	command = cmd
	whisper = whspr

