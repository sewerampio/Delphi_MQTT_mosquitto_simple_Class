unit MainFormTest;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  System.Threading,
  MQTTClinet,
  MOSQUITTO;
//

type
  T_mqtt_msg_id = (ON_CONNECT_ID, ON_DISCONNECT_ID, ON_PUBLISH_ID, ON_MESSAGE_ID, ON_SUBSCRIBE_ID, ON_UNSUBSCRIBE_ID, ON_LOG_ID);

type
  T_win_message = record
    description: string;
    id: T_mqtt_msg_id;
    rc: Integer; // Код с причиной вызова
    mosquitto_message: P_mosquitto_message;
  end;

type
  P_win_message = ^T_win_message;

type
  T_user_obj = record
    Data: Integer;
  end;

  P_user_obg = ^T_user_obj;

const
  WM_MQTT_MESSAGES = WM_USER + 1;

type
  TMainFormText = class(
    TForm)
    edtUserID: TEdit;
    chkCleanSession: TCheckBox;
    edtHostName: TEdit;
    edtUserName: TEdit;
    edtUserPassword: TEdit;
    chkSubscribeRetain: TCheckBox;
    btnSubscribeNew: TButton;
    lbluser_name: TLabel;
    Label1: TLabel;
    edtPort: TEdit;
    Label2: TLabel;
    btnConnectToBroker: TButton;
    Label3: TLabel;
    edtKeepAlive: TEdit;
    lblUserName: TLabel;
    lblPassword: TLabel;
    lblConnectSection: TLabel;
    lblSubscribeSection: TLabel;
    edtsubscribeTopic: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    cbbQos: TComboBox;
    lbl1: TLabel;
    lblSebscribeMessageText: TLabel;
    btnDisconnect: TButton;
    btnUsubscribe: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSubscribeNewClick(Sender: TObject);
    procedure edtPortChange(Sender: TObject);
    procedure btnConnectToBrokerClick(Sender: TObject);
    procedure edtKeepAliveChange(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnUsubscribeClick(Sender: TObject);
    private
      { Private declarations }
      f_mosq: Pmosquitto;
      f_clean_session: Byte;

      f_user_obj: T_user_obj;
      f_user_id: AnsiString;

      f_will_payload: AnsiString;
      f_will_payload_len: Integer;
      f_will_topic: AnsiString;

      f_user_name: AnsiString;
      f_user_password: AnsiString;

      f_session_started: boolean;

      f_retain: Byte;

      f_hostname: AnsiString;
      f_port: Integer;
      f_keepalive: Integer;

      f_connected: boolean;
      f_connect_result: Integer;
      f_disconnect_result: Integer;

      f_pub_id: Integer;
      f_pub_topic: AnsiString;
      f_pub_payload_len: Integer;
      f_pub_payload: AnsiString;
      f_pub_qos: Integer;
      f_pub_retain: Byte;

      f_sub_id: Integer;
      f_sub_topic: AnsiString;
      f_sub_qos: Integer;

      task: ITask;

      MainMQTTClient: IMQTTClinet;

      procedure Publish(topic: string; payload: string; QoS: Integer; retain: boolean);

      function ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;
      procedure Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);

      procedure feedback_main_callback_on_message(Sender: IMQTTClinet; obj: Pointer; mosquitto_message: P_mosquitto_message);

    public
      { Public declarations }
  end;

var
  MainFormText: TMainFormText;

implementation

uses
  CodeSiteLogging;

{$R *.dfm}

procedure TMainFormText.btnConnectToBrokerClick(Sender: TObject);
var
  IntValue: Integer;
begin
  self.MainMQTTClient.Host := edtHostName.Text;

  if not(TryStrToInt(edtPort.Text, IntValue) AND (IntValue > 0) AND (IntValue <= 65535)) then
  begin
    exit;
  end;

  self.MainMQTTClient.Port := IntValue;

  if not(TryStrToInt(edtPort.Text, IntValue) AND (IntValue >= 5) AND (IntValue <= 2147483647)) then
  begin
    exit;
  end;

  self.MainMQTTClient.KeepAlive := IntValue;

  self.MainMQTTClient.User := trim(edtUserName.Text);
  self.MainMQTTClient.Password := trim(edtUserPassword.Text);

  self.MainMQTTClient.ClientID := trim(edtUserID.Text);
  self.MainMQTTClient.CleanSession := chkCleanSession.Checked;
  self.MainMQTTClient.Connect;
end;

procedure TMainFormText.btnDisconnectClick(Sender: TObject);
begin
  self.MainMQTTClient.Disconnect;
end;

procedure TMainFormText.btnSubscribeNewClick(Sender: TObject);
begin
  if trim(edtsubscribeTopic.Text) <> '' then
    self.MainMQTTClient.Subscribe(trim(edtsubscribeTopic.Text), cbbQos.ItemIndex, chkSubscribeRetain.Checked);
end;

procedure TMainFormText.btnUsubscribeClick(Sender: TObject);
begin
  if trim(edtsubscribeTopic.Text) <> '' then
    self.MainMQTTClient.Unsubscribe(trim(edtsubscribeTopic.Text));
end;

function TMainFormText.ConvertStringToUTF8(const str: string; var utf8str: AnsiString): Integer;
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

procedure TMainFormText.Convert_Topic_To_String(const utf8str: PAnsiChar; var str: string);
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

procedure TMainFormText.edtKeepAliveChange(Sender: TObject);
var
  IntValue: Integer;
begin
  if (TryStrToInt(edtKeepAlive.Text, IntValue) AND (IntValue >= 5) AND (IntValue <= 2147483647)) then
  begin
    edtKeepAlive.Color := clWindow
  end
  else
  begin
    edtKeepAlive.Color := clRed;
  end;

end;

procedure TMainFormText.edtPortChange(Sender: TObject);
var
  IntValue: Integer;
begin
  if (TryStrToInt(edtPort.Text, IntValue) AND (IntValue > 0) AND (IntValue <= 65535)) then
  begin
    edtPort.Color := clWindow
  end
  else
  begin
    edtPort.Color := clRed;
  end;

end;

procedure TMainFormText.feedback_main_callback_on_message(Sender: IMQTTClinet; obj: Pointer; mosquitto_message: P_mosquitto_message);
var
  dst: P_mosquitto_message;

  HEXVal: String;
  StringVal: String;
  val_no: Integer;
  TopisLoc: String;
begin

  dst := AllocMem(SizeOf(T_mosquitto_message));
  mosquitto_message_copy(dst, mosquitto_message);

  if Assigned(mosquitto_message) then
  begin
    HEXVal := '';

    // TopisLoc := String(mosquitto_message^.topic^);

    self.Convert_Topic_To_String(mosquitto_message^.topic, TopisLoc);

    if mosquitto_message^.payloadlen > 0 then
      for val_no := 0 to mosquitto_message^.payloadlen - 1 do
        HEXVal := HEXVal + ' ' + IntToHEX(TBytes(mosquitto_message^.payload)[val_no], 2);

    StringVal := '';
    if mosquitto_message^.payloadlen > 0 then
      for val_no := 0 to mosquitto_message^.payloadlen - 1 do
        StringVal := StringVal + Char(TBytes(mosquitto_message^.payload)[val_no]);

    CodeSite.SendNote(Sender.Host + ' -->> ON_MESSAGE_ID ' + TopisLoc + ' Payload (Len: ' + IntToStr(mosquitto_message^.payloadlen) + ') Str: "' + StringVal +
      '" HEX[' + HEXVal + ']');
    lblSebscribeMessageText.Caption := Sender.Host + ' -->> ON_MESSAGE_ID ' + TopisLoc + ' Payload (Len: ' + IntToStr(mosquitto_message^.payloadlen) +
      ') Str: "' + StringVal + '" HEX[' + HEXVal + ']';

  end
  else
  begin
    CodeSite.SendNote(Sender.Host + ' -->> EMPTY VALUE');
  end;

end;

procedure TMainFormText.FormCreate(Sender: TObject);
begin
  self.MainMQTTClient := MQTTClientCreate;
  self.MainMQTTClient.OnMessage := self.feedback_main_callback_on_message;
end;

procedure TMainFormText.Publish(topic, payload: string; QoS: Integer; retain: boolean);
var
  res: Integer;
  errdesc: string;
begin
  if f_connected = False then
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

end;

end.
