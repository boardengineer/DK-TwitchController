extends Node

signal twitch_connected
signal twitch_disconnected
signal twitch_unavailable

signal login_attempt(success)
signal chat_message(user, channel, tags, message)

# Time to wait in msec after each sent chat message. Values below ~310 might lead to a disconnect after 100 messages.
export(int) var chat_timeout_ms = 320

var websocket := WebSocketClient.new()
var user_regex := RegEx.new()
var twitch_restarting

var chat_queue = []
var last_msg = OS.get_ticks_msec()

var connected = false

func _init():
	websocket.verify_ssl = true
	var _unused = user_regex.compile("(?<=!)[\\w]*(?=@)")

func _ready() -> void:
	var _unused = websocket.connect("data_received", self, "data_received")
	_unused = websocket.connect("connection_established", self, "connection_established")
	_unused = websocket.connect("connection_closed", self, "connection_closed")
	_unused = websocket.connect("connection_error", self, "connection_error")

func connect_to_twitch() -> void:
	if(websocket.connect_to_url("wss://irc-ws.chat.twitch.tv:443") != OK):
		emit_signal("twitch_unavailable")

func _process(_delta : float) -> void:
	if(websocket.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED):
		websocket.poll()
		if (!chat_queue.empty() && (last_msg + chat_timeout_ms) <= OS.get_ticks_msec()):
			send(chat_queue.pop_front())
			last_msg = OS.get_ticks_msec()

func authenticate_oauth(token : String) -> void:
	websocket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	send("PASS " + ("" if token.begins_with("oauth:") else "oauth:") + token, true)
	send("NICK karmakarmakarmakarmakarmachameleon")

# Sends a String to Twitch.
func send(text : String, token : bool = false) -> void:
	var _unused = websocket.get_peer(1).put_packet(text.to_utf8())

# Sends a chat message to a channel. Defaults to the only connected channel.
func chat(message : String, channel : String = ""):
	if(channel != ""):
		chat_queue.append("PRIVMSG " + ("" if channel.begins_with("#") else "#") + channel + " :" + message + "\r\n")

func data_received() -> void:
	var messages : PoolStringArray = websocket.get_peer(1).get_packet().get_string_from_utf8().strip_edges(false).split("\r\n")
	var tags = {}
	for message in messages:
		if(message.begins_with("@")):
			var msg : PoolStringArray = message.split(" ", false, 1)
			message = msg[1]
			for tag in msg[0].split(";"):
				var pair = tag.split("=")
				tags[pair[0]] = pair[1]
		handle_message(message, tags)

func handle_message(message : String, tags : Dictionary) -> void:
	if(message == ":tmi.twitch.tv NOTICE * :Login authentication failed"):
		emit_signal("login_attempt", false)
		return
	var msg : PoolStringArray = message.split(" ", true, 3)
	match msg[1]:
		"001":
			print_debug("Authentication successful.")
			emit_signal("login_attempt", true)
		"PRIVMSG":
			emit_signal("chat_message", user_regex.search(msg[0]).get_string(), msg[2], tags, msg[3].right(1))
			print_debug("message ? ", message)
		"RECONNECT":
			twitch_restarting = true
		_:
			emit_signal("unhandled_message", message, tags)

func join_channel(channel : String) -> void:
	var lower_channel : String = channel.to_lower()
	send("JOIN #" + lower_channel)

func leave_channel(channel : String) -> void:
	var lower_channel : String = channel.to_lower()
	send("PART #" + lower_channel)

func connection_established(_protocol : String) -> void:
	emit_signal("twitch_connected")

func connection_closed(was_clean_close : bool) -> void:
	if(twitch_restarting):
		connect_to_twitch()
		yield(self, "twitch_connected")
		twitch_restarting = false
	else:
		emit_signal("twitch_disconnected")

func connection_error() -> void:
	emit_signal("twitch_unavailable")
