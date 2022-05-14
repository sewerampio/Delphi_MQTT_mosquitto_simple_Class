program Test;

uses
  Vcl.Forms,
  MainFormTest in 'MainFormTest.pas' {MainFormText},
  MQTTClinet in 'MQTTClinet\MQTTClinet.pas',
  MOSQUITTO in 'MQTTClinet\MOSQUITTO.PAS';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFormText, MainFormText);
  Application.Run;
end.
