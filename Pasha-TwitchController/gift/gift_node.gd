extends Node
class_name Gift

signal twitch_connected
signal twitch_disconnected
signal twitch_unavailable

# The client tried to login. Returns true if successful, else false.
signal login_attempt(success)
# User sent a message in chat.
signal chat_message(user, channel, tags, message)
# User sent a whisper message.

signal pong

# Time to wait in msec after each sent chat message. Values below ~310 might lead to a disconnect after 100 messages.
export(int) var chat_timeout_ms = 320

var websocket := WebSocketClient.new()
var user_regex := RegEx.new()
var twitch_restarting
# Twitch disconnects connected clients if too many chat messages are being sent. (At about 100 messages/30s)
var chat_queue = []
var last_msg = OS.get_ticks_msec()
# Mapping of channels to their channel info, like available badges.
var channels : Dictionary = {}

var connected = false

func _init():
	websocket.verify_ssl = true
	var _unused = user_regex.compile("(?<=!)[\\w]*(?=@)")

func _ready() -> void:
	var _unused = websocket.connect("data_received", self, "data_received")
	_unused = websocket.connect("connection_established", self, "connection_established")
	_unused = websocket.connect("connection_closed", self, "connection_closed")
	_unused = websocket.connect("server_close_request", self, "sever_close_request")
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

# Login using a oauth token.
# You will have to either get a oauth token yourself or use
# https://twitchapps.com/tokengen/
# to generate a token with custom scopes.
func authenticate_oauth(token : String) -> void:
	websocket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	send("PASS " + ("" if token.begins_with("oauth:") else "oauth:") + token, true)
	send("NICK karmakarmakarmakarmakarmachameleon")
	request_caps()

func request_caps(caps : String = "twitch.tv/commands twitch.tv/tags twitch.tv/membership") -> void:
	send("CAP REQ :" + caps)

# Sends a String to Twitch.
func send(text : String, token : bool = false) -> void:
	var _unused = websocket.get_peer(1).put_packet(text.to_utf8())
	if(OS.is_debug_build()):
		if(!token):
			print("< " + text.strip_edges(false))
		else:
			print("< PASS oauth:******************************")

# Sends a chat message to a channel. Defaults to the only connected channel.
func chat(message : String, channel : String = ""):
	var keys : Array = channels.keys()
	if(channel != ""):
		chat_queue.append("PRIVMSG " + ("" if channel.begins_with("#") else "#") + channel + " :" + message + "\r\n")
	elif(keys.size() == 1):
		chat_queue.append("PRIVMSG #" + channels.keys()[0] + " :" + message + "\r\n")
	else:
		print_debug("No channel specified.")

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
#		if(OS.is_debug_build()):
#			print("> " + message)
		handle_message(message, tags)

func handle_message(message : String, tags : Dictionary) -> void:
	if(message == ":tmi.twitch.tv NOTICE * :Login authentication failed"):
		print_debug("Authentication failed.")
		emit_signal("login_attempt", false)
		return
	if(message == "PING :tmi.twitch.tv"):
		send("PONG :tmi.twitch.tv")
		emit_signal("pong")
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
	channels[lower_channel] = {}

func leave_channel(channel : String) -> void:
	var lower_channel : String = channel.to_lower()
	send("PART #" + lower_channel)
	var _unused = channels.erase(lower_channel)

func connection_established(_protocol : String) -> void:
	print_debug("Connected to Twitch.")
	emit_signal("twitch_connected")

func connection_closed(was_clean_close : bool) -> void:
	if(twitch_restarting):
		connect_to_twitch()
		yield(self, "twitch_connected")
		for channel in channels.keys():
			join_channel(channel)
		twitch_restarting = false
	else:
		print_debug("Disconnected from Twitch.")
		emit_signal("twitch_disconnected")

func connection_error() -> void:
	emit_signal("twitch_unavailable")

func server_close_request(_code : int, _reason : String) -> void:
	pass
