unit MOSQUITTO;

interface

uses
  Windows;

const
  LIBMOSQUITTO_MAJOR = 2;
  LIBMOSQUITTO_MINOR = 0;
  LIBMOSQUITTO_REVISION = 14;
  LIBMOSQUITTO_VERSION_NUMBER = (LIBMOSQUITTO_MAJOR * 1000000 + LIBMOSQUITTO_MINOR * 1000 + LIBMOSQUITTO_REVISION);

  MOSQ_LOG_NONE = $00;
  MOSQ_LOG_INFO = $01;
  MOSQ_LOG_NOTICE = $02;
  MOSQ_LOG_WARNING = $04;
  MOSQ_LOG_ERR = $08;
  MOSQ_LOG_DEBUG = $10;
  MOSQ_LOG_SUBSCRIBE = $20;
  MOSQ_LOG_UNSUBSCRIBE = $40;
  MOSQ_LOG_WEBSOCKETS = $80;
  MOSQ_LOG_INTERNAL: Uint32 = $80000000;
  MOSQ_LOG_ALL: Uint32 = $FFFFFFFF;

  MOSQ_ERR_CONN_PENDING = -1;
  MOSQ_ERR_SUCCESS = 0;
  MOSQ_ERR_NOMEM = 1;
  MOSQ_ERR_PROTOCOL = 2;
  MOSQ_ERR_INVAL = 3;
  MOSQ_ERR_NO_CONN = 4;
  MOSQ_ERR_CONN_REFUSED = 5;
  MOSQ_ERR_NOT_FOUND = 6;
  MOSQ_ERR_CONN_LOST = 7;
  MOSQ_ERR_TLS = 8;
  MOSQ_ERR_PAYLOAD_SIZE = 9;
  MOSQ_ERR_NOT_SUPPORTED = 10;
  MOSQ_ERR_AUTH = 11;
  MOSQ_ERR_ACL_DENIED = 12;
  MOSQ_ERR_UNKNOWN = 13;
  MOSQ_ERR_ERRNO = 14;
  MOSQ_ERR_EAI = 15;
  MOSQ_ERR_PROXY = 16;
  MOSQ_ERR_PLUGIN_DEFER = 17;
  MOSQ_ERR_MALFORMED_UTF8 = 18;
  MOSQ_ERR_KEEPALIVE = 19;
  MOSQ_ERR_LOOKUP = 20;
  MOSQ_ERR_MALFORMED_PACKET = 21;
  MOSQ_ERR_DUPLICATE_PROPERTY = 22;
  MOSQ_ERR_TLS_HANDSHAKE = 23;
  MOSQ_ERR_QOS_NOT_SUPPORTED = 24;
  MOSQ_ERR_OVERSIZE_PACKET = 25;
  MOSQ_ERR_OCSP = 26;
  MOSQ_ERR_TIMEOUT = 27;
  MOSQ_ERR_RETAIN_NOT_SUPPORTED = 28;
  MOSQ_ERR_TOPIC_ALIAS_INVALID = 29;
  MOSQ_ERR_ADMINISTRATIVE_ACTION = 30;
  MOSQ_ERR_ALREADY_EXISTS = 31;

type
  mosq_err_t = Longint;

const
  MOSQ_OPT_PROTOCOL_VERSION = 1;
  MOSQ_OPT_SSL_CTX = 2;
  MOSQ_OPT_SSL_CTX_WITH_DEFAULTS = 3;
  MOSQ_OPT_RECEIVE_MAXIMUM = 4;
  MOSQ_OPT_SEND_MAXIMUM = 5;
  MOSQ_OPT_TLS_KEYFORM = 6;
  MOSQ_OPT_TLS_ENGINE = 7;
  MOSQ_OPT_TLS_ENGINE_KPASS_SHA1 = 8;
  MOSQ_OPT_TLS_OCSP_REQUIRED = 9;
  MOSQ_OPT_TLS_ALPN = 10;
  MOSQ_OPT_TCP_NODELAY = 11;
  MOSQ_OPT_BIND_ADDRESS = 12;
  MOSQ_OPT_TLS_USE_OS_CERTS = 13;

type
  T_mosq_opt = Longint;

const
  MOSQ_MQTT_ID_MAX_LENGTH = 23;

const
  MQTT_PROTOCOL_V31 = 3;
  MQTT_PROTOCOL_V311 = 4;
  MQTT_PROTOCOL_V5 = 5;

type
  T_mosquitto_message = record
    mid: Integer;
    topic: PAnsiChar;
    payload: Pointer;
    payloadlen: Integer;
    qos: Integer;
    retain: Uint8;
  end;

  P_mosquitto_message = ^T_mosquitto_message;
  PP_mosquitto_message = ^P_mosquitto_message;

  Tmosquitto = record
  end;

  Pmosquitto = ^Tmosquitto;

  PPAnsiChar = ^PAnsiChar;
  PPPAnsiChar = ^PPAnsiChar;

  T_pw_callback = function(buf: PAnsiChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer; cdecl;
  T_on_connect = procedure(mosq: Pmosquitto; obj: Pointer; rc: Integer); cdecl;
  T_on_disconnect = procedure(mosq: Pmosquitto; obj: Pointer; rc: Integer); cdecl;
  T_on_publish = procedure(mosq: Pmosquitto; obj: Pointer; mid: Integer); cdecl;
  T_on_message = procedure(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message); cdecl;
  T_on_subscribe = procedure(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger); cdecl;
  T_on_unsubscribe = procedure(mosq: Pmosquitto; obj: Pointer; mid: Integer); cdecl;
  T_on_log = procedure(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar); cdecl;

function mosquitto_lib_version(major: PInteger; minor: PInteger; revision: PInteger): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_lib_init: Integer; cdecl; external 'mosquitto.dll';
function mosquitto_lib_cleanup: Integer; cdecl; external 'mosquitto.dll';

function mosquitto_new(id: PAnsiChar; clean_session: Byte; obj: Pointer): Pmosquitto; cdecl; external 'mosquitto.dll';
procedure mosquitto_destroy(mosq: Pmosquitto); cdecl; external 'mosquitto.dll';
function mosquitto_reinitialise(mosq: Pmosquitto; id: PAnsiChar; clean_session: Uint8; obj: Pointer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_will_set(mosq: Pmosquitto; topic: PAnsiChar; payloadlen: Integer; payload: Pointer; qos: Integer; retain: Byte): Integer; cdecl;
  external 'mosquitto.dll';
function mosquitto_will_clear(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_username_pw_set(mosq: Pmosquitto; username: PAnsiChar; password: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_connect(mosq: Pmosquitto; host: PAnsiChar; port: Integer; keepalive: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_connect_bind(mosq: Pmosquitto; host: PAnsiChar; port: Integer; keepalive: Integer; bind_address: PAnsiChar): Integer; cdecl;
  external 'mosquitto.dll';
function mosquitto_connect_async(mosq: Pmosquitto; host: PAnsiChar; port: Integer; keepalive: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_connect_bind_async(mosq: Pmosquitto; host: PAnsiChar; port: Integer; keepalive: Integer; bind_address: PAnsiChar): Integer; cdecl;
  external 'mosquitto.dll';
function mosquitto_connect_srv(mosq: Pmosquitto; host: PAnsiChar; keepalive: Integer; bind_address: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_reconnect(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_reconnect_async(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_disconnect(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_publish(mosq: Pmosquitto; mid: PInteger; topic: PAnsiChar; payloadlen: Integer; payload: Pointer; qos: Integer; retain: Byte): Integer;
  cdecl; external 'mosquitto.dll';
function mosquitto_subscribe(mosq: Pmosquitto; mid: PInteger; sub: PAnsiChar; qos: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_unsubscribe(mosq: Pmosquitto; mid: PInteger; sub: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_message_copy(dst: P_mosquitto_message; src: P_mosquitto_message): Integer; cdecl; external 'mosquitto.dll';
procedure mosquitto_message_free(msg: PP_mosquitto_message); cdecl; external 'mosquitto.dll';
procedure mosquitto_message_clear(msg: P_mosquitto_message); cdecl; external 'mosquitto.dll';
function mosquitto_loop(mosq: Pmosquitto; timeout: Integer; max_packets: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_forever(mosq: Pmosquitto; timeout: Integer; max_packets: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_start(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_stop(mosq: Pmosquitto; force: Byte): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_socket(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_read(mosq: Pmosquitto; max_packets: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_write(mosq: Pmosquitto; max_packets: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_loop_misc(mosq: Pmosquitto): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_want_write(mosq: Pmosquitto): Uint8; cdecl; external 'mosquitto.dll';
function mosquitto_threaded_set(mosq: Pmosquitto; threaded: Uint8): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_opts_set(mosq: Pmosquitto; option: T_mosq_opt; value: Pointer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_tls_set(mosq: Pmosquitto; cafile: PAnsiChar; capath: PAnsiChar; certfile: PAnsiChar; keyfile: PAnsiChar; pw_callback: T_pw_callback)
  : Integer; cdecl; external 'mosquitto.dll';
function mosquitto_tls_insecure_set(mosq: Pmosquitto; value: Uint8): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_tls_opts_set(mosq: Pmosquitto; cert_reqs: Integer; tls_version: PAnsiChar; ciphers: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_tls_psk_set(mosq: Pmosquitto; psk: PAnsiChar; identity: PAnsiChar; ciphers: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';

procedure mosquitto_connect_callback_set(mosq: Pmosquitto; on_connect: T_on_connect); cdecl; external 'mosquitto.dll';
procedure mosquitto_disconnect_callback_set(mosq: Pmosquitto; on_disconnect: T_on_disconnect); cdecl; external 'mosquitto.dll';
procedure mosquitto_publish_callback_set(mosq: Pmosquitto; on_publish: T_on_publish); cdecl; external 'mosquitto.dll';
procedure mosquitto_message_callback_set(mosq: Pmosquitto; on_message: T_on_message); cdecl; external 'mosquitto.dll';
procedure mosquitto_subscribe_callback_set(mosq: Pmosquitto; on_subscribe: T_on_subscribe); cdecl; external 'mosquitto.dll';
procedure mosquitto_unsubscribe_callback_set(mosq: Pmosquitto; on_unsubscribe: T_on_unsubscribe); cdecl; external 'mosquitto.dll';

procedure mosquitto_log_callback_set(mosq: Pmosquitto; on_log: T_on_log); cdecl; external 'mosquitto.dll';
function mosquitto_reconnect_delay_set(mosq: Pmosquitto; reconnect_delay: Longword; reconnect_delay_max: Longword; reconnect_exponential_backoff: Uint8)
  : Integer; cdecl; external 'mosquitto.dll';
function mosquitto_max_inflight_messages_set(mosq: Pmosquitto; max_inflight_messages: Longword): Integer; cdecl; external 'mosquitto.dll';
procedure mosquitto_message_retry_set(mosq: Pmosquitto; message_retry: Longword); cdecl; external 'mosquitto.dll';
procedure mosquitto_user_data_set(mosq: Pmosquitto; obj: Pointer); cdecl; external 'mosquitto.dll';
function mosquitto_socks5_set(mosq: Pmosquitto; host: PAnsiChar; port: Integer; username: PAnsiChar; password: PAnsiChar): Integer; cdecl;
  external 'mosquitto.dll';
function mosquitto_strerror(mosq_errno: Integer): PAnsiChar; cdecl; external 'mosquitto.dll';
function mosquitto_connack_string(connack_code: Integer): PAnsiChar; cdecl; external 'mosquitto.dll';
function mosquitto_sub_topic_tokenise(subtopic: PAnsiChar; topics: PPPAnsiChar; count: PInteger): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_sub_topic_tokens_free(topics: PPPAnsiChar; count: Integer): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_topic_matches_sub(sub: PAnsiChar; topic: PAnsiChar; result: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_pub_topic_check(topic: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';
function mosquitto_sub_topic_check(topic: PAnsiChar): Integer; cdecl; external 'mosquitto.dll';

implementation

end.
