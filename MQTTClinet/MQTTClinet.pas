unit MQTTClinet;

interface

uses
  System.Generics.Collections,
  MOSQUITTO;

type

  TConnectionState = (tcsUnknown = 0, tcsConnecting = 1, tcsConnected = 2, tcsDisconnected = 3, tcsReady = 4);

type
  IMQTTClinet = Interface;

  MQTTCallback_On_tls_set = function(Sender: IMQTTClinet; buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer of object;
  MQTTCallback_On_connect = procedure(Sender: IMQTTClinet; obj: Pointer; rc: Integer) of object;
  MQTTCallback_On_disconnect = procedure(Sender: IMQTTClinet; obj: Pointer; rc: Integer) of object;
  MQTTCallback_On_publish = procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer) of object;
  MQTTCallback_On_message = procedure(Sender: IMQTTClinet; obj: Pointer; mosquitto_message: P_mosquitto_message) of object;
  MQTTCallback_On_subscribe = procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger) of object;
  MQTTCallback_On_unsubscribe = procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer) of object;
  MQTTCallback_On_log = procedure(Sender: IMQTTClinet; obj: Pointer; level: Integer; str: PAnsiChar) of object;

  IMQTTClinet = Interface(
    IInterface)
    // private
    function libVersion: String;

    function GetFInitialized: Boolean;

    function GetFUser: String;
    procedure SetFUser(const Value: String);

    function GetFPassword: String;
    procedure SetFPassword(const Value: String);

    function GetFHost: String;
    procedure SetFHost(const Value: String);

    function GetFPort: Uint32;
    procedure SetFPort(const Value: Uint32);

    function GetFKeepAlive: Integer;
    procedure SetKeepAlive(const Value: Integer);

    function GetFClientID: String;
    procedure setFClientID(const Value: String);

    function GetFCleanSession: Boolean;
    procedure SetFCleanSession(const Value: Boolean);

    procedure SetFOnConnect(const Value: MQTTCallback_On_connect);
    procedure SetFOnDisconnect(const Value: MQTTCallback_On_disconnect);
    procedure SetFOnLog(const Value: MQTTCallback_On_log);
    procedure SetFOnMessage(const Value: MQTTCallback_On_message);
    procedure SetFOnPublish(const Value: MQTTCallback_On_publish);
    procedure SetFOnSubscribe(const Value: MQTTCallback_On_subscribe);
    procedure SetFOnTlsSet(const Value: MQTTCallback_On_tls_set);
    procedure SetFOnUnsubscribe(const Value: MQTTCallback_On_unsubscribe);

    // only to callback core

    function feedback_main_callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer;
    procedure feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    procedure feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    procedure feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    procedure feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
    procedure feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger);
    procedure feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    procedure feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar);

    // public
    function GetState: TConnectionState;
    procedure Disconnect;
    function Connect: Boolean;
    function isConnected: Boolean;

    function Publish(const topic: string; const payload: string; const QoS: Integer; const retain: Boolean): Boolean;
    function Subscribe(const topic: string; const QoS: Integer; const retain: Boolean): Boolean;
    function Unsubscribe(const topic: string): Boolean;

    property Initialized: Boolean read GetFInitialized;

    property User: String read GetFUser write SetFUser;
    property Password: String read GetFPassword write SetFPassword;
    property Host: String read GetFHost write SetFHost;
    property Port: Uint32 read GetFPort write SetFPort;
    property KeepAlive: Integer read GetFKeepAlive write SetKeepAlive;

    property ClientID: String read GetFClientID write setFClientID;
    property CleanSession: Boolean read GetFCleanSession write SetFCleanSession;

    property OnTlsSet: MQTTCallback_On_tls_set write SetFOnTlsSet;
    property OnConnect: MQTTCallback_On_connect write SetFOnConnect;
    property OnDisconnect: MQTTCallback_On_disconnect write SetFOnDisconnect;
    property OnPublish: MQTTCallback_On_publish write SetFOnPublish;
    property OnMessage: MQTTCallback_On_message write SetFOnMessage;
    property OnSubscribe: MQTTCallback_On_subscribe write SetFOnSubscribe;
    property OnUnsubscribe: MQTTCallback_On_unsubscribe write SetFOnUnsubscribe;
    property OnLog: MQTTCallback_On_log write SetFOnLog;

  End;

procedure Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);
function ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;

function MQTTClientCreate: IMQTTClinet;

Var
  ClientList: TDictionary<Integer, Integer>;

implementation

uses
  System.SysUtils,
  System.Threading,
  CodeSiteLogging;

type

  T_user_obj = record
    Data: Integer;
  end;

  P_user_obg = ^T_user_obj;

type

  TMQTTClient = class(
    TInterfacedObject,
    IMQTTClinet)
    private
      FLibVersion: String;

      FInitialized: Boolean;
      FSesionStarted: Boolean;

      f_loop_task: ITask;

      f_connected: Boolean;

      f_mosq: Pmosquitto;

      f_user_obj: T_user_obj;
      f_user_id: AnsiString;

      f_clean_session: Byte;

      f_user_name: AnsiString;
      f_user_password: AnsiString;

      f_hostname: AnsiString;
      f_port: Uint32;

      f_keepalive: Integer;

      f_pub_id: Integer;
      f_pub_topic: AnsiString;
      f_pub_payload_len: Integer;
      f_pub_payload: AnsiString;
      f_pub_qos: Integer;
      f_pub_retain: Byte;

      f_sub_id: Integer;
      f_sub_topic: AnsiString;
      f_sub_qos: Integer;

      FConnectionState: TConnectionState;

      // CallbackList:
      FOnTlsSet: MQTTCallback_On_tls_set;
      FOnConnect: MQTTCallback_On_connect;
      FOnDisconnect: MQTTCallback_On_disconnect;
      FOnPublish: MQTTCallback_On_publish;
      FOnMessage: MQTTCallback_On_message;
      FOnSubscribe: MQTTCallback_On_subscribe;
      FOnUnsubscribe: MQTTCallback_On_unsubscribe;
      FOnLog: MQTTCallback_On_log;

      function ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;
      procedure ConvertUTF8ToString(const utf8str: PAnsiChar; var str: string);

      procedure Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);
      procedure Convert_Payload_To_String(const utf8str: PAnsiChar; sz: Integer; var str: string);

      function libInit: Boolean;
      function GetFInitialized: Boolean;

      function SessionStart: Boolean;

      function GetFHost: String;
      procedure SetFHost(const Value: String);

      function GetFPort: Uint32;
      procedure SetFPort(const Value: Uint32);

      function GetFClientID: String;
      procedure setFClientID(const Value: String);

      function GetFUser: String;
      procedure SetFUser(const Value: String);

      function GetFPassword: String;
      procedure SetFPassword(const Value: String);

      function GetFCleanSession: Boolean;
      procedure SetFCleanSession(const Value: Boolean);

      function GetFKeepAlive: Integer;
      procedure SetKeepAlive(const Value: Integer);

      procedure SetFOnConnect(const Value: MQTTCallback_On_connect);
      procedure SetFOnDisconnect(const Value: MQTTCallback_On_disconnect);
      procedure SetFOnLog(const Value: MQTTCallback_On_log);
      procedure SetFOnMessage(const Value: MQTTCallback_On_message);
      procedure SetFOnPublish(const Value: MQTTCallback_On_publish);
      procedure SetFOnSubscribe(const Value: MQTTCallback_On_subscribe);
      procedure SetFOnTlsSet(const Value: MQTTCallback_On_tls_set);
      procedure SetFOnUnsubscribe(const Value: MQTTCallback_On_unsubscribe);

    protected

    public
      constructor Create; overload;
      destructor Destroy; override;

      function feedback_main_callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer;
      procedure feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
      procedure feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
      procedure feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
      procedure feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
      procedure feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger);
      procedure feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
      procedure feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar);

      procedure Disconnect;
      function Connect: Boolean;
      function isConnected: Boolean;

      function GetState: TConnectionState;

      function libVersion: String;

      property Initialized: Boolean read GetFInitialized;

      property Host: String read GetFHost write SetFHost;
      property Port: Uint32 read GetFPort write SetFPort;
      property ClientID: String read GetFClientID write setFClientID;
      property KeepAlive: Integer read GetFKeepAlive write SetKeepAlive;

      property CleanSession: Boolean read GetFCleanSession write SetFCleanSession;

      property User: String read GetFUser write SetFUser;
      property Password: String read GetFPassword write SetFPassword;

      function Publish(const topic: string; const payload: string; const QoS: Integer; const retain: Boolean): Boolean;
      function Subscribe(const topic: string; const QoS: Integer; const retain: Boolean): Boolean;
      function Unsubscribe(const topic: string): Boolean;

      property OnTlsSet: MQTTCallback_On_tls_set write SetFOnTlsSet;
      property OnConnect: MQTTCallback_On_connect write SetFOnConnect;
      property OnDisconnect: MQTTCallback_On_disconnect write SetFOnDisconnect;
      property OnPublish: MQTTCallback_On_publish write SetFOnPublish;
      property OnMessage: MQTTCallback_On_message write SetFOnMessage;
      property OnSubscribe: MQTTCallback_On_subscribe write SetFOnSubscribe;
      property OnUnsubscribe: MQTTCallback_On_unsubscribe write SetFOnUnsubscribe;
      property OnLog: MQTTCallback_On_log write SetFOnLog;

    published

  end;

function GetClinet(mosq: Pmosquitto): IMQTTClinet;
var
  PointerValue: Integer;
  LocalClientValue: IMQTTClinet;
begin
  result := nil;
  if mosq = nil then
    exit;
  if not ClientList.TryGetValue(Integer(mosq), PointerValue) then
    exit;

  LocalClientValue := TMQTTClient(Pointer(PointerValue));;
  result := LocalClientValue;
end;

function Callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer; cdecl;
begin
  CodeSite.SendNote('Callback_tls_set');

end;

procedure Callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_connect(mosq, obj, rc);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_connect parrent nil');
end;

procedure Callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_disconnect(mosq, obj, rc);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_disconnect parrent nil');

end;

procedure Callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_publish(mosq, obj, mid);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_publish parrent nil');
end;

procedure Callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_message(mosq, obj, mosquitto_message);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_message parrent nil');

end;

procedure Callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_subscribe(mosq, obj, mid, qos_count, granted_qos);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_subscribe parrent nil');

end;

procedure Callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_unsubscribe(mosq, obj, mid);
    except
    end;
  end
  else
  begin
    CodeSite.SendNote('Callback_on_unsubscribe parrent nil');
  end;

end;

procedure Callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar); cdecl;
var
  LocalClientValue: IMQTTClinet;
begin
  LocalClientValue := GetClinet(mosq);
  if LocalClientValue <> nil then
  begin
    try
      LocalClientValue.feedback_main_callback_on_log(mosq, obj, level, str);
    except
    end;
  end
  else
    CodeSite.SendNote('Callback_on_log parrent nil');

end;

{ TMQTTClient }

function TMQTTClient.Connect: Boolean;
var
  res: Integer;
  errdesc: string;

begin
  result := false;
  if not self.SessionStart then
    Abort;

  if f_connected = True then
    Abort;

  self.FConnectionState := tcsConnecting;

  try

    self.Disconnect;

    mosquitto_will_clear(self.f_mosq);

    res := mosquitto_username_pw_set(self.f_mosq, PAnsiChar(f_user_name), PAnsiChar(f_user_password));

    if res <> MOSQ_ERR_SUCCESS then
    begin
      case res of
        MOSQ_ERR_INVAL:
          errdesc := 'The input parameters is invalid';
        MOSQ_ERR_NOMEM:
          errdesc := 'An out of memory condition occurred';
      else
        errdesc := 'Unknown error';
      end;
      CodeSite.SendNote('Autoryzacja - B³¹d po³¹czenia User name Password: ' + errdesc);
      Abort;
    end;

    CodeSite.SendNote('mosquitto_threaded_set result = ' + IntToStr(mosquitto_threaded_set(self.f_mosq, 1)));

    res := mosquitto_connect(self.f_mosq, PAnsiChar(f_hostname), f_port, f_keepalive);

    if res <> MOSQ_ERR_SUCCESS then
    begin
      case res of

        MOSQ_ERR_INVAL:
          errdesc := ' the input parameters were invalid.';
        MOSQ_ERR_NOMEM:
          errdesc := ' an out of memory condition occurred.';
        MOSQ_ERR_NO_CONN:
          errdesc := ' the client isn’t connected to a broker.';
        MOSQ_ERR_CONN_LOST:
          errdesc := ' the connection to the broker was lost.';
        MOSQ_ERR_PROTOCOL:
          errdesc := ' there is a protocol error communicating with the broker.';
        MOSQ_ERR_ERRNO:
          errdesc :=
            ' a system call returned an error.  The variable errno contains the error code, even on Windows.  Use strerror_r() where available or FormatMessage() on Windows.';
      else
        errdesc := 'Unknown error';
      end;
      CodeSite.SendNote('Authorization - Connection establishing error: ' + errdesc);
      Abort;
    end;

    self.f_connected := True;

    CodeSite.SendNote('Global: ' + IntToStr(Integer(self.f_mosq)));

    f_loop_task := TTask.Run(
      procedure()
      begin
        CodeSite.SendNote('IntTask: ' + IntToStr(Integer(self.f_mosq)));

        res := mosquitto_loop_forever(self.f_mosq, -1, 1);;

        if res <> MOSQ_ERR_SUCCESS then
        begin
          case res of

            MOSQ_ERR_NOT_SUPPORTED:
              errdesc := 'Thread support is not available';
            MOSQ_ERR_INVAL:
              errdesc := 'the input parameters were invalid.';
            MOSQ_ERR_NOMEM:
              errdesc := 'an out of memory condition occurred.';
            MOSQ_ERR_NO_CONN:
              errdesc := 'the client isn’t connected to a broker.';
            MOSQ_ERR_CONN_LOST:
              errdesc := 'the connection to the broker was lost.';
            MOSQ_ERR_PROTOCOL:
              errdesc := 'there is a protocol error communicating with the broker.';
            MOSQ_ERR_ERRNO:
              errdesc :=
                'a system call returned an error.  The variable errno contains the error code, even on Windows.  Use strerror_r() where available or FormatMessage() on Windows.';
          else
            errdesc := 'Unknown error';
          end;
          CodeSite.SendNote('Authorization - Error starting library loop: ' + errdesc);

          Abort;
        end;

      end);

  finally

  end;

end;

function TMQTTClient.ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;
var
  L, SL: Integer;
begin
  SL := Length(str);
  L := SL * SizeOf(Char);
  L := L + 1;

  SetLength(utf8str, L);
  UnicodeToUtf8(PAnsiChar(utf8str), L, PWideChar(str), SL);
  ConvertStringToUTF8 := System.SysUtils.StrLen(PAnsiChar(utf8str));
end;

procedure TMQTTClient.ConvertUTF8ToString(const utf8str: PAnsiChar; var str: string);
var
  L: Integer;
  Temp: UnicodeString;
begin
  L := System.SysUtils.StrLen(utf8str);

  str := '';
  if L = 0 then
    exit;
  SetLength(Temp, L);

  L := System.Utf8ToUnicode(PWideChar(Temp), L + 1, utf8str, L);
  if L > 0 then
    SetLength(Temp, L - 1)
  else
    Temp := '';
  str := Temp;
end;

procedure TMQTTClient.Convert_Payload_To_String(const utf8str: PAnsiChar; sz: Integer; var str: string);
var
  L: Integer;
  Temp: UnicodeString;
begin
  str := '';
  if sz = 0 then
    exit;
  SetLength(Temp, sz);

  L := System.Utf8ToUnicode(PWideChar(Temp), sz + 1, utf8str, sz);
  if L > 0 then
    SetLength(Temp, L - 1)
  else
    Temp := '';
  str := Temp;

end;

procedure TMQTTClient.Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);
begin
  ConvertUTF8ToString(utf8str, str);
end;

constructor TMQTTClient.Create;
begin
  inherited;
  CodeSite.SendNote('TMQTTClient.Create - Start');

  self.FOnTlsSet := nil;
  self.FOnConnect := nil;
  self.FOnDisconnect := nil;
  self.FOnPublish := nil;
  self.FOnMessage := nil;
  self.FOnSubscribe := nil;
  self.FOnUnsubscribe := nil;
  self.FOnLog := nil;

  self.FConnectionState := tcsUnknown;

  self.FInitialized := false;
  self.FSesionStarted := false;
  self.f_connected := false;

  self.FLibVersion := 'ND';

  self.f_mosq := nil;
  self.f_user_id := '';
  self.f_clean_session := 1;

  self.User := '';
  self.Password := '';

  self.Host := '127.0.0.1';
  self.Port := 1883;

  self.f_keepalive := 10;

  self.FInitialized := self.libInit;

  CodeSite.SendNote('TMQTTClient.Create - Done');
end;

destructor TMQTTClient.Destroy;
begin
  CodeSite.SendNote('TMQTTClient.Destroy - Start');

  self.Disconnect;

  if self.FSesionStarted = True then
  begin
    ClientList.Remove(Integer(self.f_mosq));
    mosquitto_destroy(self.f_mosq);
    f_mosq := Nil;
  end;

  CodeSite.SendNote('TMQTTClient.Destroy - Done');
  inherited;
end;

procedure TMQTTClient.Disconnect;
var
  res: Integer;
begin
  try
    if self.f_mosq <> Nil then
    begin
      if self.f_connected = True then
      begin

        res := mosquitto_disconnect(self.f_mosq);
        if res <> MOSQ_ERR_SUCCESS then
          CodeSite.SendNote('mosquitto_disconnect = ' + IntToStr(res));

        res := mosquitto_loop_write(self.f_mosq, 1);
        if res <> MOSQ_ERR_SUCCESS then
          CodeSite.SendNote('mosquitto_loop_write = ' + IntToStr(res));
      end;
    end;
  finally

  end;

end;

procedure TMQTTClient.feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
begin
  if Assigned(self.FOnConnect) then
    try
      self.FOnConnect(self, obj, rc);
    except

    end;
  self.FConnectionState := tcsConnected;
end;

procedure TMQTTClient.feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
begin
  self.FConnectionState := tcsDisconnected;

  if Assigned(self.FOnDisconnect) then
    try
      self.FOnDisconnect(self, obj, rc);
    except

    end;

end;

procedure TMQTTClient.feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar);
begin

  if Assigned(self.FOnLog) then
    try
      self.FOnLog(self, obj, level, str);
    except

    end;

end;

procedure TMQTTClient.feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
var
  dst: P_mosquitto_message;

  HEXVal: String;
  StringVal: String;
  val_no: Integer;
  TopisLoc: String;
begin
  if Assigned(self.FOnMessage) then
    try
      self.FOnMessage(self, obj, mosquitto_message);
    except

    end;
end;

procedure TMQTTClient.feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
begin

  if Assigned(self.FOnPublish) then
    try
      self.FOnPublish(self, obj, mid);
    except

    end;

end;

procedure TMQTTClient.feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid, qos_count: Integer; granted_qos: PInteger);
begin

  if Assigned(self.FOnSubscribe) then
    try
      self.FOnSubscribe(self, obj, mid, qos_count, granted_qos);
    except

    end;

end;

procedure TMQTTClient.feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
begin

  if Assigned(self.FOnUnsubscribe) then
    try
      self.FOnUnsubscribe(self, obj, mid);
    except

    end;
end;

function TMQTTClient.feedback_main_callback_tls_set(buf: PChar; size, rwflag: Integer; userdata: Pointer): Integer;
begin

  if Assigned(self.FOnTlsSet) then
    try
      result := self.FOnTlsSet(self, buf, size, rwflag, userdata)
    except

    end;
end;

function TMQTTClient.GetFCleanSession: Boolean;
begin
  if self.f_clean_session > 0 then
    result := True
  else
    result := false;
end;

function TMQTTClient.GetFClientID: String;
begin
  ConvertUTF8ToString(PAnsiChar(self.f_user_id), result);
end;

function TMQTTClient.GetFHost: String;
begin
  ConvertUTF8ToString(PAnsiChar(self.f_hostname), result);
end;

function TMQTTClient.GetFInitialized: Boolean;
begin
  if not self.FInitialized then
    self.libInit;

  result := self.FInitialized;
end;

function TMQTTClient.GetFKeepAlive: Integer;
begin
  result := self.f_keepalive
end;

function TMQTTClient.GetFPassword: String;
begin
  ConvertUTF8ToString(PAnsiChar(self.f_user_password), result);
end;

function TMQTTClient.GetFPort: Uint32;
begin
  result := self.f_port;
end;

function TMQTTClient.GetFUser: String;
begin
  ConvertUTF8ToString(PAnsiChar(self.f_user_name), result);
end;

function TMQTTClient.GetState: TConnectionState;
begin
  result := self.FConnectionState;
end;

function TMQTTClient.isConnected: Boolean;
begin
  result := self.f_connected;
end;

function TMQTTClient.libInit: Boolean;
var
  res: Integer;
  major: Integer;
  minor: Integer;
  revision: Integer;
begin
  result := True;
  res := mosquitto_lib_init;

  if res <> MOSQ_ERR_SUCCESS then
  begin
    result := false;
  end;

  mosquitto_lib_version(@major, @minor, @revision);

  self.FLibVersion := IntToStr(major) + '.' + IntToStr(minor) + '.' + IntToStr(revision);

end;

function TMQTTClient.libVersion: String;
begin
  if not self.FInitialized then
    self.libInit;

  result := self.FLibVersion;
end;

function TMQTTClient.Publish(const topic: string; const payload: string; const QoS: Integer; const retain: Boolean): Boolean;
var
  res: Integer;
  errdesc: string;
begin
  result := false;

  if f_connected = false then
    Abort;

  inc(f_pub_id);

  // ------------------------------------
  f_pub_qos := QoS;
  // ------------------------------------
  if retain then
    f_pub_retain := 1
  else
    f_pub_retain := 0;
  // ------------------------------------
  if topic = '' then
    f_pub_topic := ''
  else
  begin
    ConvertStringToUTF8(topic, f_pub_topic);
  end;
  // ------------------------------------
  if payload = '' then
    f_pub_payload := ''
  else
  begin
    f_pub_payload_len := ConvertStringToUTF8(payload, f_pub_payload);
  end;
  // ------------------------------------

  res := mosquitto_publish(f_mosq, @f_pub_id, PAnsiChar(f_pub_topic), f_pub_payload_len, Pointer(f_pub_payload), f_pub_qos, f_pub_retain);
  if res <> MOSQ_ERR_SUCCESS then
  begin
    case res of
      MOSQ_ERR_INVAL:
        errdesc := 'The input parameters is invalid';
      MOSQ_ERR_NOMEM:
        errdesc := 'An out of memory condition occurred';
      MOSQ_ERR_NO_CONN:
        errdesc := 'The client isn''t connected to a broker';
      MOSQ_ERR_PROTOCOL:
        errdesc := 'There is a protocol error communicating with the broker';
      MOSQ_ERR_PAYLOAD_SIZE:
        errdesc := 'The payloadlen is too large';
      MOSQ_ERR_MALFORMED_UTF8:
        errdesc := 'the topic is not valid UTF-8';
      MOSQ_ERR_QOS_NOT_SUPPORTED:
        errdesc := 'the QoS is greater than that supported by the broker.';
      MOSQ_ERR_OVERSIZE_PACKET:
        errdesc := 'the resulting packet would be larger than supported by the broker.';
    else
      errdesc := 'Unknown error';
    end;

    Abort;
  end;

  result := True;
end;

function TMQTTClient.SessionStart: Boolean;
begin
  result := false;
  self.f_connected := false;

  if self.FSesionStarted = True then
  begin
    ClientList.Remove(Integer(self.f_mosq));
    mosquitto_destroy(self.f_mosq);
    f_mosq := Nil;
  end;

  if self.f_user_id = '' then
    f_mosq := mosquitto_new(nil, self.f_clean_session, @self.f_user_obj)
  else
    f_mosq := mosquitto_new(PAnsiChar(self.f_user_id), self.f_clean_session, @self.f_user_obj);

  if f_mosq = Nil then
  begin
    Abort;
  end;

  mosquitto_connect_callback_set(f_mosq, Callback_on_connect);
  mosquitto_disconnect_callback_set(f_mosq, Callback_on_disconnect);
  mosquitto_publish_callback_set(f_mosq, Callback_on_publish);
  mosquitto_message_callback_set(f_mosq, Callback_on_message);
  mosquitto_subscribe_callback_set(f_mosq, Callback_on_subscribe);
  mosquitto_unsubscribe_callback_set(f_mosq, Callback_on_unsubscribe);
  mosquitto_log_callback_set(f_mosq, Callback_on_log);

  ClientList.Add(Integer(self.f_mosq), Integer(self));

  self.FSesionStarted := True;
  result := True;
end;

procedure TMQTTClient.SetFCleanSession(const Value: Boolean);
begin
  if Value then
    f_clean_session := 1
  else
    f_clean_session := 0;
end;

procedure TMQTTClient.setFClientID(const Value: String);
begin
  if Trim(Value) = '' then
    f_user_id := ''
  else
    ConvertStringToUTF8(Value, f_user_id);
end;

procedure TMQTTClient.SetFHost(const Value: String);
begin
  ConvertStringToUTF8(Value, self.f_hostname);
end;

procedure TMQTTClient.SetFOnConnect(const Value: MQTTCallback_On_connect);
begin
  self.FOnConnect := Value;
end;

procedure TMQTTClient.SetFOnDisconnect(const Value: MQTTCallback_On_disconnect);
begin
  self.FOnDisconnect := Value;
end;

procedure TMQTTClient.SetFOnLog(const Value: MQTTCallback_On_log);
begin
  self.FOnLog := Value;
end;

procedure TMQTTClient.SetFOnMessage(const Value: MQTTCallback_On_message);
begin
  self.FOnMessage := Value;
end;

procedure TMQTTClient.SetFOnPublish(const Value: MQTTCallback_On_publish);
begin
  self.FOnPublish := Value;
end;

procedure TMQTTClient.SetFOnSubscribe(const Value: MQTTCallback_On_subscribe);
begin
  self.FOnSubscribe := Value;
end;

procedure TMQTTClient.SetFOnTlsSet(const Value: MQTTCallback_On_tls_set);
begin
  self.FOnTlsSet := Value;
end;

procedure TMQTTClient.SetFOnUnsubscribe(const Value: MQTTCallback_On_unsubscribe);
begin
  self.FOnUnsubscribe := Value;
end;

procedure TMQTTClient.SetFPassword(const Value: String);
begin
  ConvertStringToUTF8(Value, f_user_password);
end;

procedure TMQTTClient.SetFPort(const Value: Uint32);
begin
  self.f_port := Value;
end;

procedure TMQTTClient.SetFUser(const Value: String);
begin
  ConvertStringToUTF8(Value, f_user_name);
end;

procedure TMQTTClient.SetKeepAlive(const Value: Integer);
begin
  self.f_keepalive := Value;
end;

function TMQTTClient.Subscribe(const topic: string; const QoS: Integer; const retain: Boolean): Boolean;
var
  res: Integer;
  result_exec: String;
begin

  self.ConvertStringToUTF8(topic, self.f_sub_topic);
  self.f_sub_qos := QoS;

  res := mosquitto_subscribe(self.f_mosq, @(self.f_sub_id), PAnsiChar(self.f_sub_topic), self.f_sub_qos);
  case res of
    MOSQ_ERR_SUCCESS:
      result_exec := 'success.';
    MOSQ_ERR_INVAL:
      result_exec := 'the input parameters were invalid.';
    MOSQ_ERR_NOMEM:
      result_exec := 'out of memory condition occurred.';
    MOSQ_ERR_NO_CONN:
      result_exec := 'the client isn’t connected to a broker.';
    MOSQ_ERR_MALFORMED_UTF8:
      result_exec := 'the topic is not valid UTF-8';
    MOSQ_ERR_OVERSIZE_PACKET:
      result_exec := 'the resulting packet would be larger than supported by the broker.';

  end;

  CodeSite.SendNote('mosquitto_subscribe result = ' + IntToStr(res) + ' ' + result_exec);

end;

function TMQTTClient.Unsubscribe(const topic: string): Boolean;
var
  res: Integer;
  result_exec: String;
begin
  if Trim(topic) = '' then
    exit;

  self.ConvertStringToUTF8(topic, self.f_sub_topic);

  res := mosquitto_unsubscribe(self.f_mosq, @(self.f_sub_id), PAnsiChar(self.f_sub_topic));
  case res of
    MOSQ_ERR_SUCCESS:
      result_exec := 'success.';
    MOSQ_ERR_INVAL:
      result_exec := 'the input parameters were invalid.';
    MOSQ_ERR_NOMEM:
      result_exec := 'out of memory condition occurred.';
    MOSQ_ERR_NO_CONN:
      result_exec := 'the client isn’t connected to a broker.';
    MOSQ_ERR_MALFORMED_UTF8:
      result_exec := 'the topic is not valid UTF-8';
    MOSQ_ERR_OVERSIZE_PACKET:
      result_exec := 'the resulting packet would be larger than supported by the broker.';

  end;

  CodeSite.SendNote('mosquitto_unsubscribe result = ' + IntToStr(res) + ' ' + result_exec);

end;

function MQTTClientCreate: IMQTTClinet;
begin
  result := TMQTTClient.Create;
end;

procedure Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);
var
  L: Integer;
  Temp: UnicodeString;
begin
  L := System.SysUtils.StrLen(utf8str);

  str := '';
  if L = 0 then
    exit;
  SetLength(Temp, L);

  L := System.Utf8ToUnicode(PWideChar(Temp), L + 1, utf8str, L);
  if L > 0 then
    SetLength(Temp, L - 1)
  else
    Temp := '';
  str := Temp;

end;

function ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;
var
  L, SL: Integer;
begin
  SL := Length(str);
  L := SL * SizeOf(Char);
  L := L + 1;

  SetLength(utf8str, L);
  UnicodeToUtf8(PAnsiChar(utf8str), L, PWideChar(str), SL);
  result := System.SysUtils.StrLen(PAnsiChar(utf8str));

end;

initialization

CodeSite.SendNote('Initialization start');
ClientList := TDictionary<Integer, Integer>.Create;
CodeSite.SendNote('Initialization Done');

finalization

CodeSite.SendNote('finalization start');
FreeAndNil(ClientList);
CodeSite.SendNote('finalization Done');

end.
