extends Node

signal auth_in_progress
signal auth_failure
signal auth_success

var port := 31419
var client_id = "pdvlxh7bxab4z9hwj9sfb7qc2o6epp"

var redirect_server := TCP_Server.new()

var netlify_url := "https://spiffy-moonbeam-925327.netlify.app/"

var auth_redirect_url_suffix := ".netlify/functions/auth"
var token_refresh_url_suffix := ".netlify/functions/refresh"
var jwt_url_suffix := ".netlify/functions/jwt"

var twitch_auth_url = "https://id.twitch.tv/oauth2/authorize"

var access_token = ""
var refresh_token = ""
var channel = ""
var expires_in

var jwt
var channel_id

var http_request_jwt
var http_request_token_refresh

# jwts last an hour so we'll refresh them every half hour
const JWT_REFRESH_SECS = 60 * 30
const TOKEN_REFRESH_RETRY_WAIT_SECS = 5 
const TOKEN_REFRESH_TOTAL_RETRIES = 3

var jwt_timer
var refresh_timer
var refresh_retry_attempts = 0

# Will be true if the client id was read from the config file so it cane be written back
var read_write_client = false
var read_write_url = false

const CONFIG_FILENAME = "user://twitch-auth.cfg"
const CONFIG_SECTION = "auth"

func _init():
	read_config_file()

func _ready():
	http_request_jwt = HTTPRequest.new()
	add_child(http_request_jwt)
	http_request_jwt.connect("request_completed", self, "_jwt_request_callback")
	
	http_request_token_refresh = HTTPRequest.new()
	add_child(http_request_token_refresh)
	http_request_token_refresh.connect("request_completed", self, "_token_refresh_request_callback")

	jwt_timer = Timer.new()
	jwt_timer.wait_time = JWT_REFRESH_SECS
	jwt_timer.autostart = true
	jwt_timer.connect("timeout", self, "_request_jwt_token")
	add_child(jwt_timer)
	
	refresh_timer = Timer.new()
	refresh_timer.one_shot = true
	refresh_timer.connect("timeout", self, "request_access_token_refresh")
	add_child(refresh_timer)
	
	# If we've logged on before, we should have a refresh token we can use
	# to get underway
	request_access_token_refresh()

func read_config_file():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILENAME)
	
	if err != OK:
		return
	
	refresh_token = config.get_value(CONFIG_SECTION, "refresh_token", "")
	channel = config.get_value(CONFIG_SECTION, "channel", "")
	
	if config.has_section_key(CONFIG_SECTION, "client_id"):
		client_id = config.get_value(CONFIG_SECTION, "client_id", "")
		read_write_client = true
		
	if config.has_section_key(CONFIG_SECTION, "netlify_url"):
		netlify_url = config.get_value(CONFIG_SECTION, "netlify_url", "")
		read_write_url = true
	
func save_config_file():
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_SECTION, "refresh_token", refresh_token)
	config.set_value(CONFIG_SECTION, "channel", channel)
	
	if read_write_client:
		config.set_value(CONFIG_SECTION, "client_id", client_id)
		
	if read_write_url:
		config.set_value(CONFIG_SECTION, "netlify_url", netlify_url)
	
	config.save(CONFIG_FILENAME)
	
	
func _process(_delta):
	if redirect_server.is_listening() and redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var request = connection.get_string(connection.get_available_bytes())
		
		var page = """
Dome Keeper has Successfully Connected to Twitch, Please close this tab...
		"""
		
		if request:
			refresh_retry_attempts = 0
			access_token = request.split("access_token=")[1].split("&")[0]
			refresh_token = request.split("refresh_token=")[1].split("&")[0]
			save_config_file()
			emit_signal("auth_success")
			
			_request_jwt_token()
			
			connection.put_data("HTTP/1.1 200\r\n".to_ascii())
			connection.put_data(page.to_ascii())
			redirect_server.stop()

func _request_jwt_token():
	if access_token == "":
		return
	
	var url = netlify_url + jwt_url_suffix + "?access_token=" + access_token
		
	var error = http_request_jwt.request(url, [], false, HTTPClient.METHOD_GET)
	if error != OK:
		print_debug("An error occurred in the HTTP request. ", error)

func _jwt_request_callback(_result, _response_code, _headers, body):
	var parse_result = JSON.parse(body.get_string_from_ascii())
	
	if parse_result.error == OK:
		var result_dict = parse_result.result
		jwt = result_dict.token
		channel_id = result_dict.channel_id
	else:
		# jwt request failed, request a new auth token
		
		# invalidate the access token so we don't keep trying
		access_token = ""
		request_access_token_refresh()

func request_access_token_refresh():
	if refresh_token == "":
		return
	
	var url = netlify_url + token_refresh_url_suffix + "?refresh_token=" + refresh_token
		
	var error = http_request_token_refresh.request(url, [], false, HTTPClient.METHOD_GET)
	
	if error != OK:
		print_debug("An error occurred in the token refresh HTTP request.")
	pass

func _token_refresh_request_callback(_result, _response_code, _headers, body):
	var parse_result = JSON.parse(body.get_string_from_ascii())
	
	if parse_result.error == OK:
		refresh_retry_attempts = 0
		var result_dict = parse_result.result
		
		access_token = result_dict.access_token
		refresh_token = result_dict.refresh_token
		
		emit_signal("auth_success")
		save_config_file()
		_request_jwt_token()
	else:
		if refresh_retry_attempts < 3:
			refresh_retry_attempts += 1
			refresh_timer.start(TOKEN_REFRESH_RETRY_WAIT_SECS)
		else:
			# The refresh token doesn't work, invalidate it
			refresh_token = ""
			emit_signal("auth_failure")

func get_auth_code():
	var _redir_error = redirect_server.listen(port)
	
	var encoded_scopes = "user:read:chat chat:edit chat:read".percent_encode()
	print_debug(encoded_scopes)
	var body_parts = [
		"response_type=%s"    % "code",
		"client_id=%s"        % client_id,
		"redirect_uri=%s%s"   % [netlify_url, auth_redirect_url_suffix],
		"scope=%s"            % encoded_scopes,
	]
	
	var url = twitch_auth_url + "?" + PoolStringArray(body_parts).join("&")
	
	emit_signal("auth_in_progress")
	var _shell_result = OS.shell_open(url)

func restart():
	access_token = ""
	refresh_token = ""
	channel = ""
	
	save_config_file()
