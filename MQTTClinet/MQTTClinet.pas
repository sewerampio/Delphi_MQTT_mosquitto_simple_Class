Unit MQTTClinet;

Interface

Uses
  System.Generics.Collections,
  MOSQUITTO;

Type
  TConnectionState = (tcsUnknown = 0, tcsConnecting = 1, tcsConnected = 2, tcsDisconnected = 3, tcsReady = 4);

Type
  IMQTTClinet = Interface;

  MQTTCallback_On_tls_set = Function(Sender: IMQTTClinet; buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer Of Object;

  MQTTCallback_On_connect = Procedure(Sender: IMQTTClinet; obj: Pointer; rc: Integer) Of Object;

  MQTTCallback_On_disconnect = Procedure(Sender: IMQTTClinet; obj: Pointer; rc: Integer) Of Object;

  MQTTCallback_On_publish = Procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer) Of Object;

  MQTTCallback_On_message = Procedure(Sender: IMQTTClinet; obj: Pointer; mosquitto_message: P_mosquitto_message) Of Object;

  MQTTCallback_On_subscribe = Procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger) Of Object;

  MQTTCallback_On_unsubscribe = Procedure(Sender: IMQTTClinet; obj: Pointer; mid: Integer) Of Object;

  MQTTCallback_On_log = Procedure(Sender: IMQTTClinet; obj: Pointer; level: Integer; Str: PAnsiChar) Of Object;

  IMQTTClinet = Interface(IInterface)
    // private
    Function libVersion: String;
    Function GetFInitialized: Boolean;
    Function GetFUser: String;
    Procedure SetFUser(Const Value: String);
    Function GetFPassword: String;
    Procedure SetFPassword(Const Value: String);
    Function GetFHost: String;
    Procedure SetFHost(Const Value: String);
    Function GetFPort: UInt32;
    Procedure SetFPort(Const Value: UInt32);
    Function GetFKeepAlive: Integer;
    Procedure SetKeepAlive(Const Value: Integer);
    Function GetFClientID: String;
    Procedure setFClientID(Const Value: String);
    Function GetFCleanSession: Boolean;
    Procedure SetFCleanSession(Const Value: Boolean);
    Procedure SetFOnConnect(Const Value: MQTTCallback_On_connect);
    Procedure SetFOnDisconnect(Const Value: MQTTCallback_On_disconnect);
    Procedure SetFOnLog(Const Value: MQTTCallback_On_log);
    Procedure SetFOnMessage(Const Value: MQTTCallback_On_message);
    Procedure SetFOnPublish(Const Value: MQTTCallback_On_publish);
    Procedure SetFOnSubscribe(Const Value: MQTTCallback_On_subscribe);
    Procedure SetFOnTlsSet(Const Value: MQTTCallback_On_tls_set);
    Procedure SetFOnUnsubscribe(Const Value: MQTTCallback_On_unsubscribe);

    // only to callback core

    Function feedback_main_callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer;
    Procedure feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    Procedure feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    Procedure feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    Procedure feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
    Procedure feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger);
    Procedure feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    Procedure feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; Str: PAnsiChar);

    // public
    Function GetState: TConnectionState;
    Procedure Disconnect;
    Function Connect: Boolean;
    Function isConnected: Boolean;
    Function Publish(Const topic: String; Const payload: String; Const QoS: Integer; Const retain: Boolean): Boolean;
    Function Subscribe(Const topic: String; Const QoS: Integer; Const retain: Boolean): Boolean;
    Function Unsubscribe(Const topic: String): Boolean;
    Property Initialized: Boolean Read GetFInitialized;
    Property User: String Read GetFUser Write SetFUser;
    Property Password: String Read GetFPassword Write SetFPassword;
    Property Host: String Read GetFHost Write SetFHost;
    Property Port: UInt32 Read GetFPort Write SetFPort;
    Property KeepAlive: Integer Read GetFKeepAlive Write SetKeepAlive;
    Property ClientID: String Read GetFClientID Write setFClientID;
    Property CleanSession: Boolean Read GetFCleanSession Write SetFCleanSession;
    Property OnTlsSet: MQTTCallback_On_tls_set Write SetFOnTlsSet;
    Property OnConnect: MQTTCallback_On_connect Write SetFOnConnect;
    Property OnDisconnect: MQTTCallback_On_disconnect Write SetFOnDisconnect;
    Property OnPublish: MQTTCallback_On_publish Write SetFOnPublish;
    Property OnMessage: MQTTCallback_On_message Write SetFOnMessage;
    Property OnSubscribe: MQTTCallback_On_subscribe Write SetFOnSubscribe;
    Property OnUnsubscribe: MQTTCallback_On_unsubscribe Write SetFOnUnsubscribe;
    Property OnLog: MQTTCallback_On_log Write SetFOnLog;
  End;

Procedure Convert_Topic_To_String(Const utf8str: PAnsiChar; Var Str: String);

Function ConvertStringToUTF8(Const Str: String; Var utf8str: AnsiString): Integer;

Function MQTTClientCreate: IMQTTClinet;

Var
  ClientList: TDictionary<Integer, Integer>;

Implementation

Uses
  System.SysUtils,
  System.Threading,
  CodeSiteLogging;

Type
  T_user_obj = Record
    Data: Integer;
  End;

  P_user_obg = ^T_user_obj;

Type
  TMQTTClient = Class(TInterfacedObject, IMQTTClinet)
  Private
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
    f_port: UInt32;

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

    Function ConvertStringToUTF8(Const Str: String; Var utf8str: AnsiString): Integer;
    Procedure ConvertUTF8ToString(Const utf8str: PAnsiChar; Var Str: String);

    Procedure Convert_Topic_To_String(Const utf8str: PAnsiChar; Var Str: String);
    Procedure Convert_Payload_To_String(Const utf8str: PAnsiChar; sz: Integer; Var Str: String);

    Function libInit: Boolean;
    Function GetFInitialized: Boolean;

    Function SessionStart: Boolean;

    Function GetFHost: String;
    Procedure SetFHost(Const Value: String);

    Function GetFPort: UInt32;
    Procedure SetFPort(Const Value: UInt32);

    Function GetFClientID: String;
    Procedure setFClientID(Const Value: String);

    Function GetFUser: String;
    Procedure SetFUser(Const Value: String);

    Function GetFPassword: String;
    Procedure SetFPassword(Const Value: String);

    Function GetFCleanSession: Boolean;
    Procedure SetFCleanSession(Const Value: Boolean);

    Function GetFKeepAlive: Integer;
    Procedure SetKeepAlive(Const Value: Integer);

    Procedure SetFOnConnect(Const Value: MQTTCallback_On_connect);
    Procedure SetFOnDisconnect(Const Value: MQTTCallback_On_disconnect);
    Procedure SetFOnLog(Const Value: MQTTCallback_On_log);
    Procedure SetFOnMessage(Const Value: MQTTCallback_On_message);
    Procedure SetFOnPublish(Const Value: MQTTCallback_On_publish);
    Procedure SetFOnSubscribe(Const Value: MQTTCallback_On_subscribe);
    Procedure SetFOnTlsSet(Const Value: MQTTCallback_On_tls_set);
    Procedure SetFOnUnsubscribe(Const Value: MQTTCallback_On_unsubscribe);

  Protected
  Public
    Constructor Create; Overload;
    Destructor Destroy; Override;

    Function feedback_main_callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer;
    Procedure feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    Procedure feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
    Procedure feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    Procedure feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
    Procedure feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger);
    Procedure feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
    Procedure feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; Str: PAnsiChar);

    Procedure Disconnect;
    Function Connect: Boolean;
    Function isConnected: Boolean;

    Function GetState: TConnectionState;

    Function libVersion: String;

    Property Initialized: Boolean Read GetFInitialized;

    Property Host: String Read GetFHost Write SetFHost;
    Property Port: UInt32 Read GetFPort Write SetFPort;
    Property ClientID: String Read GetFClientID Write setFClientID;
    Property KeepAlive: Integer Read GetFKeepAlive Write SetKeepAlive;

    Property CleanSession: Boolean Read GetFCleanSession Write SetFCleanSession;

    Property User: String Read GetFUser Write SetFUser;
    Property Password: String Read GetFPassword Write SetFPassword;

    Function Publish(Const topic: String; Const payload: String; Const QoS: Integer; Const retain: Boolean): Boolean;
    Function Subscribe(Const topic: String; Const QoS: Integer; Const retain: Boolean): Boolean;
    Function Unsubscribe(Const topic: String): Boolean;

    Property OnTlsSet: MQTTCallback_On_tls_set Write SetFOnTlsSet;
    Property OnConnect: MQTTCallback_On_connect Write SetFOnConnect;
    Property OnDisconnect: MQTTCallback_On_disconnect Write SetFOnDisconnect;
    Property OnPublish: MQTTCallback_On_publish Write SetFOnPublish;
    Property OnMessage: MQTTCallback_On_message Write SetFOnMessage;
    Property OnSubscribe: MQTTCallback_On_subscribe Write SetFOnSubscribe;
    Property OnUnsubscribe: MQTTCallback_On_unsubscribe Write SetFOnUnsubscribe;
    Property OnLog: MQTTCallback_On_log Write SetFOnLog;

  Published
  End;

Function GetClinet(mosq: Pmosquitto): IMQTTClinet;
Var
  PointerValue: Integer;
  LocalClientValue: IMQTTClinet;
Begin
  Result := nil;
  If mosq = nil Then
    Exit;
  If Not ClientList.TryGetValue(Integer(mosq), PointerValue) Then
    Exit;

  LocalClientValue := TMQTTClient(Pointer(PointerValue));
  ;
  Result := LocalClientValue;
End;

Function Callback_tls_set(buf: PChar; size: Integer; rwflag: Integer; userdata: Pointer): Integer; Cdecl;
Begin
  CodeSite.SendNote('Callback_tls_set');
End;

Procedure Callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_connect(mosq, obj, rc);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_connect parrent nil');
End;

Procedure Callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_disconnect(mosq, obj, rc);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_disconnect parrent nil');
End;

Procedure Callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_publish(mosq, obj, mid);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_publish parrent nil');
End;

Procedure Callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_message(mosq, obj, mosquitto_message);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_message parrent nil');
End;

Procedure Callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer; qos_count: Integer; granted_qos: PInteger); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_subscribe(mosq, obj, mid, qos_count, granted_qos);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_subscribe parrent nil');
End;

Procedure Callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_unsubscribe(mosq, obj, mid);
    Except
    End;
  End
  Else
  Begin
    CodeSite.SendNote('Callback_on_unsubscribe parrent nil');
  End;
End;

Procedure Callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar); Cdecl;
Var
  LocalClientValue: IMQTTClinet;
Begin
  LocalClientValue := GetClinet(mosq);
  If LocalClientValue <> nil Then
  Begin
    Try
      LocalClientValue.feedback_main_callback_on_log(mosq, obj, level, str);
    Except
    End;
  End
  Else
    CodeSite.SendNote('Callback_on_log parrent nil');
End;

{ TMQTTClient }

Function TMQTTClient.Connect: Boolean;
Var
  res: Integer;
  errdesc: String;
Begin
  Result := False;
  If Not Self.SessionStart Then
    Abort;

  If f_connected = True Then
    Abort;

  Self.FConnectionState := tcsConnecting;

  Self.Disconnect;

  mosquitto_will_clear(Self.f_mosq);

  res := mosquitto_username_pw_set(Self.f_mosq, PAnsiChar(f_user_name), PAnsiChar(f_user_password));

  If res <> MOSQ_ERR_SUCCESS Then
  Begin
    Case res Of
      MOSQ_ERR_INVAL:
        errdesc := 'The input parameters is invalid';
      MOSQ_ERR_NOMEM:
        errdesc := 'An out of memory condition occurred';
    Else
      errdesc := 'Unknown error';
    End;
    CodeSite.SendNote('Autoryzacja - Ustawiania danych User name Password: ' + errdesc);

    Raise Exception.CreateFmt(errdesc + ' Err No: %d', [res]);

    Abort;
  End;

  CodeSite.SendNote('mosquitto_threaded_set result = ' + IntToStr(mosquitto_threaded_set(Self.f_mosq, 1)));

  res := mosquitto_connect(Self.f_mosq, PAnsiChar(f_hostname), f_port, f_keepalive);

  If res <> MOSQ_ERR_SUCCESS Then
  Begin
    Case res Of

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
          'Connection is not avaible';
    Else
      errdesc := 'Unknown error';
    End;

    CodeSite.SendNote('Nawi¹zywanie po³¹czenia - Connection establishing error: ' + errdesc);
    Raise Exception.CreateFmt(errdesc + ' Err No: %d', [res]);

    Abort;
  End;

  Self.f_connected := True;

  CodeSite.SendNote('Global: ' + IntToStr(Integer(Self.f_mosq)));

  f_loop_task := TTask.Run(
    Procedure()
    Begin
      CodeSite.SendNote('IntTask: ' + IntToStr(Integer(Self.f_mosq)));

      res := mosquitto_loop_forever(Self.f_mosq, -1, 1);

      If res <> MOSQ_ERR_SUCCESS Then
      Begin
        Case res Of

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
        Else
          errdesc := 'Unknown error';
        End;
        CodeSite.SendNote('Authorization - Error starting library loop: ' + errdesc);

        Raise Exception.CreateFmt(errdesc + ' Err No: %d', [res]);

        Abort;
      End;
    End);
End;

Function TMQTTClient.ConvertStringToUTF8(Const str: String; Var utf8str: AnsiString): Integer;
Var
  L, SL: Integer;
Begin
  SL := Length(str);
  L := SL * SizeOf(Char);
  L := L + 1;

  SetLength(utf8str, L);
  UnicodeToUtf8(PAnsiChar(utf8str), L, PWideChar(str), SL);
  ConvertStringToUTF8 := System.SysUtils.StrLen(PAnsiChar(utf8str));
End;

Procedure TMQTTClient.ConvertUTF8ToString(Const utf8str: PAnsiChar; Var str: String);
Var
  L: Integer;
  Temp: UnicodeString;
Begin
  L := System.SysUtils.StrLen(utf8str);

  str := '';
  If L = 0 Then
    Exit;
  SetLength(Temp, L);

  L := System.Utf8ToUnicode(PWideChar(Temp), L + 1, utf8str, L);
  If L > 0 Then
    SetLength(Temp, L - 1)
  Else
    Temp := '';
  str := Temp;
End;

Procedure TMQTTClient.Convert_Payload_To_String(Const utf8str: PAnsiChar; sz: Integer; Var str: String);
Var
  L: Integer;
  Temp: UnicodeString;
Begin
  str := '';
  If sz = 0 Then
    Exit;
  SetLength(Temp, sz);

  L := System.Utf8ToUnicode(PWideChar(Temp), sz + 1, utf8str, sz);
  If L > 0 Then
    SetLength(Temp, L - 1)
  Else
    Temp := '';
  str := Temp;
End;

Procedure TMQTTClient.Convert_Topic_To_String(Const utf8str: PAnsiChar; Var str: String);
Begin
  ConvertUTF8ToString(utf8str, str);
End;

Constructor TMQTTClient.Create;
Begin
  Inherited;
  CodeSite.SendNote('TMQTTClient.Create - Start');

  Self.FOnTlsSet := nil;
  Self.FOnConnect := nil;
  Self.FOnDisconnect := nil;
  Self.FOnPublish := nil;
  Self.FOnMessage := nil;
  Self.FOnSubscribe := nil;
  Self.FOnUnsubscribe := nil;
  Self.FOnLog := nil;

  Self.FConnectionState := tcsUnknown;

  Self.FInitialized := False;
  Self.FSesionStarted := False;
  Self.f_connected := False;

  Self.FLibVersion := 'ND';

  Self.f_mosq := nil;
  Self.f_user_id := '';
  Self.f_clean_session := 1;

  Self.User := '';
  Self.Password := '';

  Self.Host := '127.0.0.1';
  Self.Port := 1883;

  Self.f_keepalive := 10;

  Self.FInitialized := Self.libInit;

  CodeSite.SendNote('TMQTTClient.Create - Done');
End;

Destructor TMQTTClient.Destroy;
Begin
  CodeSite.SendNote('TMQTTClient.Destroy - Start');

  Self.Disconnect;

  If Self.FSesionStarted = True Then
  Begin
    ClientList.Remove(Integer(Self.f_mosq));
    mosquitto_destroy(Self.f_mosq);
    f_mosq := Nil;
  End;

  CodeSite.SendNote('TMQTTClient.Destroy - Done');
  Inherited;
End;

Procedure TMQTTClient.Disconnect;
Var
  res: Integer;
Begin
  Try
    If Self.f_mosq <> Nil Then
    Begin
      If Self.f_connected = True Then
      Begin

        res := mosquitto_disconnect(Self.f_mosq);
        If res <> MOSQ_ERR_SUCCESS Then
          CodeSite.SendNote('mosquitto_disconnect = ' + IntToStr(res));

        res := mosquitto_loop_write(Self.f_mosq, 1);
        If res <> MOSQ_ERR_SUCCESS Then
          CodeSite.SendNote('mosquitto_loop_write = ' + IntToStr(res));
      End;
    End;
  Finally

  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_connect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
Begin
  If Assigned(Self.FOnConnect) Then
  Try
    Self.FOnConnect(Self, obj, rc);
  Except
  End;
  If rc = MOSQ_ERR_SUCCESS Then
    Self.FConnectionState := tcsConnected;
End;

Procedure TMQTTClient.feedback_main_callback_on_disconnect(mosq: Pmosquitto; obj: Pointer; rc: Integer);
Begin
  Self.FConnectionState := tcsDisconnected;
  If Assigned(Self.FOnDisconnect) Then
  Try
    Self.FOnDisconnect(Self, obj, rc);
  Except
  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_log(mosq: Pmosquitto; obj: Pointer; level: Integer; str: PAnsiChar);
Begin
  If Assigned(Self.FOnLog) Then
  Try
    Self.FOnLog(Self, obj, level, str);
  Except
  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_message(mosq: Pmosquitto; obj: Pointer; mosquitto_message: P_mosquitto_message);
Var
  dst: P_mosquitto_message;
  HEXVal: String;
  StringVal: String;
  val_no: Integer;
  TopisLoc: String;
Begin
  If Assigned(Self.FOnMessage) Then
  Try
    Self.FOnMessage(Self, obj, mosquitto_message);
  Except
  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_publish(mosq: Pmosquitto; obj: Pointer; mid: Integer);
Begin

  If Assigned(Self.FOnPublish) Then
  Try
    Self.FOnPublish(Self, obj, mid);
  Except
  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_subscribe(mosq: Pmosquitto; obj: Pointer; mid, qos_count: Integer; granted_qos: PInteger);
Begin

  If Assigned(Self.FOnSubscribe) Then
  Try
    Self.FOnSubscribe(Self, obj, mid, qos_count, granted_qos);
  Except
  End;
End;

Procedure TMQTTClient.feedback_main_callback_on_unsubscribe(mosq: Pmosquitto; obj: Pointer; mid: Integer);
Begin

  If Assigned(Self.FOnUnsubscribe) Then
  Try
    Self.FOnUnsubscribe(Self, obj, mid);
  Except
  End;
End;

Function TMQTTClient.feedback_main_callback_tls_set(buf: PChar; size, rwflag: Integer; userdata: Pointer): Integer;
Begin

  If Assigned(Self.FOnTlsSet) Then
  Try
    Result := Self.FOnTlsSet(Self, buf, size, rwflag, userdata)
  Except
  End;
End;

Function TMQTTClient.GetFCleanSession: Boolean;
Begin
  If Self.f_clean_session > 0 Then
    Result := True
  Else
    Result := False;
End;

Function TMQTTClient.GetFClientID: String;
Begin
  ConvertUTF8ToString(PAnsiChar(Self.f_user_id), Result);
End;

Function TMQTTClient.GetFHost: String;
Begin
  ConvertUTF8ToString(PAnsiChar(Self.f_hostname), Result);
End;

Function TMQTTClient.GetFInitialized: Boolean;
Begin
  If Not Self.FInitialized Then
    Self.libInit;

  Result := Self.FInitialized;
End;

Function TMQTTClient.GetFKeepAlive: Integer;
Begin
  Result := Self.f_keepalive
End;

Function TMQTTClient.GetFPassword: String;
Begin
  ConvertUTF8ToString(PAnsiChar(Self.f_user_password), Result);
End;

Function TMQTTClient.GetFPort: UInt32;
Begin
  Result := Self.f_port;
End;

Function TMQTTClient.GetFUser: String;
Begin
  ConvertUTF8ToString(PAnsiChar(Self.f_user_name), Result);
End;

Function TMQTTClient.GetState: TConnectionState;
Begin
  Result := Self.FConnectionState;
End;

Function TMQTTClient.isConnected: Boolean;
Begin
  If (Self.f_connected) And (Self.FConnectionState = tcsConnected) Then
    Result := True
  Else
    Result := False;
End;

Function TMQTTClient.libInit: Boolean;
Var
  res: Integer;
  major: Integer;
  minor: Integer;
  revision: Integer;
Begin
  Result := True;
  res := mosquitto_lib_init;

  If res <> MOSQ_ERR_SUCCESS Then
  Begin
    Result := False;
  End;

  mosquitto_lib_version(@major, @minor, @revision);

  Self.FLibVersion := IntToStr(major) + '.' + IntToStr(minor) + '.' + IntToStr(revision);
End;

Function TMQTTClient.libVersion: String;
Begin
  If Not Self.FInitialized Then
    Self.libInit;

  Result := Self.FLibVersion;
End;

Function TMQTTClient.Publish(Const topic: String; Const payload: String; Const QoS: Integer; Const retain: Boolean): Boolean;
Var
  res: Integer;
  errdesc: String;
Begin
  Result := False;

  If f_connected = False Then
    Abort;

  Inc(f_pub_id);

  // ------------------------------------
  f_pub_qos := QoS;
  // ------------------------------------
  If retain Then
    f_pub_retain := 1
  Else
    f_pub_retain := 0;
  // ------------------------------------
  If topic = '' Then
    f_pub_topic := ''
  Else
  Begin
    ConvertStringToUTF8(topic, f_pub_topic);
  End;
  // ------------------------------------
  If payload = '' Then
    f_pub_payload := ''
  Else
  Begin
    f_pub_payload_len := ConvertStringToUTF8(payload, f_pub_payload);
  End;
  // ------------------------------------

  res := mosquitto_publish(f_mosq, @f_pub_id, PAnsiChar(f_pub_topic), f_pub_payload_len, Pointer(f_pub_payload), f_pub_qos, f_pub_retain);
  If res <> MOSQ_ERR_SUCCESS Then
  Begin
    Case res Of
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
    Else
      errdesc := 'Unknown error';
    End;

    Abort;
  End;

  Result := True;
End;

Function TMQTTClient.SessionStart: Boolean;
Begin
  Result := False;
  Self.f_connected := False;

  If Self.FSesionStarted = True Then
  Begin
    ClientList.Remove(Integer(Self.f_mosq));
    mosquitto_destroy(Self.f_mosq);
    f_mosq := Nil;
  End;

  If Self.f_user_id = '' Then
    f_mosq := mosquitto_new(nil, Self.f_clean_session, @Self.f_user_obj)
  Else
    f_mosq := mosquitto_new(PAnsiChar(Self.f_user_id), Self.f_clean_session, @Self.f_user_obj);

  If f_mosq = Nil Then
  Begin
    Abort;
  End;

  mosquitto_connect_callback_set(f_mosq, Callback_on_connect);
  mosquitto_disconnect_callback_set(f_mosq, Callback_on_disconnect);
  mosquitto_publish_callback_set(f_mosq, Callback_on_publish);
  mosquitto_message_callback_set(f_mosq, Callback_on_message);
  mosquitto_subscribe_callback_set(f_mosq, Callback_on_subscribe);
  mosquitto_unsubscribe_callback_set(f_mosq, Callback_on_unsubscribe);
  mosquitto_log_callback_set(f_mosq, Callback_on_log);

  ClientList.Add(Integer(Self.f_mosq), Integer(Self));

  Self.FSesionStarted := True;
  Result := True;
End;

Procedure TMQTTClient.SetFCleanSession(Const Value: Boolean);
Begin
  If Value Then
    f_clean_session := 1
  Else
    f_clean_session := 0;
End;

Procedure TMQTTClient.setFClientID(Const Value: String);
Begin
  If Trim(Value) = '' Then
    f_user_id := ''
  Else
    ConvertStringToUTF8(Value, f_user_id);
End;

Procedure TMQTTClient.SetFHost(Const Value: String);
Begin
  ConvertStringToUTF8(Value, Self.f_hostname);
End;

Procedure TMQTTClient.SetFOnConnect(Const Value: MQTTCallback_On_connect);
Begin
  Self.FOnConnect := Value;
End;

Procedure TMQTTClient.SetFOnDisconnect(Const Value: MQTTCallback_On_disconnect);
Begin
  Self.FOnDisconnect := Value;
End;

Procedure TMQTTClient.SetFOnLog(Const Value: MQTTCallback_On_log);
Begin
  Self.FOnLog := Value;
End;

Procedure TMQTTClient.SetFOnMessage(Const Value: MQTTCallback_On_message);
Begin
  Self.FOnMessage := Value;
End;

Procedure TMQTTClient.SetFOnPublish(Const Value: MQTTCallback_On_publish);
Begin
  Self.FOnPublish := Value;
End;

Procedure TMQTTClient.SetFOnSubscribe(Const Value: MQTTCallback_On_subscribe);
Begin
  Self.FOnSubscribe := Value;
End;

Procedure TMQTTClient.SetFOnTlsSet(Const Value: MQTTCallback_On_tls_set);
Begin
  Self.FOnTlsSet := Value;
End;

Procedure TMQTTClient.SetFOnUnsubscribe(Const Value: MQTTCallback_On_unsubscribe);
Begin
  Self.FOnUnsubscribe := Value;
End;

Procedure TMQTTClient.SetFPassword(Const Value: String);
Begin
  ConvertStringToUTF8(Value, f_user_password);
End;

Procedure TMQTTClient.SetFPort(Const Value: UInt32);
Begin
  Self.f_port := Value;
End;

Procedure TMQTTClient.SetFUser(Const Value: String);
Begin
  ConvertStringToUTF8(Value, f_user_name);
End;

Procedure TMQTTClient.SetKeepAlive(Const Value: Integer);
Begin
  Self.f_keepalive := Value;
End;

Function TMQTTClient.Subscribe(Const topic: String; Const QoS: Integer; Const retain: Boolean): Boolean;
Var
  res: Integer;
  result_exec: String;
Begin

  Self.ConvertStringToUTF8(topic, Self.f_sub_topic);
  Self.f_sub_qos := QoS;

  res := mosquitto_subscribe(Self.f_mosq, @(Self.f_sub_id), PAnsiChar(Self.f_sub_topic), Self.f_sub_qos);
  Case res Of
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
  End;

  CodeSite.SendNote('mosquitto_subscribe result = ' + IntToStr(res) + ' ' + result_exec);
End;

Function TMQTTClient.Unsubscribe(Const topic: String): Boolean;
Var
  res: Integer;
  result_exec: String;
Begin
  If Trim(topic) = '' Then
    Exit;

  Self.ConvertStringToUTF8(topic, Self.f_sub_topic);

  res := mosquitto_unsubscribe(Self.f_mosq, @(Self.f_sub_id), PAnsiChar(Self.f_sub_topic));
  Case res Of
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
  End;

  CodeSite.SendNote('mosquitto_unsubscribe result = ' + IntToStr(res) + ' ' + result_exec);
End;

Function MQTTClientCreate: IMQTTClinet;
Begin
  Result := TMQTTClient.Create;
End;

Procedure Convert_Topic_To_String(Const utf8str: PAnsiChar; Var str: String);
Var
  L: Integer;
  Temp: UnicodeString;
Begin
  L := System.SysUtils.StrLen(utf8str);

  str := '';
  If L = 0 Then
    Exit;
  SetLength(Temp, L);

  L := System.Utf8ToUnicode(PWideChar(Temp), L + 1, utf8str, L);
  If L > 0 Then
    SetLength(Temp, L - 1)
  Else
    Temp := '';
  str := Temp;
End;

Function ConvertStringToUTF8(Const str: String; Var utf8str: AnsiString): Integer;
Var
  L, SL: Integer;
Begin
  SL := Length(str);
  L := SL * SizeOf(Char);
  L := L + 1;

  SetLength(utf8str, L);
  UnicodeToUtf8(PAnsiChar(utf8str), L, PWideChar(str), SL);
  Result := System.SysUtils.StrLen(PAnsiChar(utf8str));
End;

Initialization
  CodeSite.SendNote('Initialization start');
  ClientList := TDictionary<Integer, Integer>.Create;
  CodeSite.SendNote('Initialization Done');

Finalization
  CodeSite.SendNote('finalization start');
  FreeAndNil(ClientList);
  CodeSite.SendNote('finalization Done');

End.

