object MainFormText: TMainFormText
  Left = 0
  Top = 0
  Caption = 'MainFormText'
  ClientHeight = 257
  ClientWidth = 852
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbluser_name: TLabel
    Left = 16
    Top = 64
    Width = 42
    Height = 13
    Caption = 'ClientID:'
  end
  object Label1: TLabel
    Left = 32
    Top = 37
    Width = 26
    Height = 13
    Caption = 'Host:'
  end
  object Label2: TLabel
    Left = 360
    Top = 37
    Width = 24
    Height = 13
    Caption = 'Port:'
  end
  object Label3: TLabel
    Left = 434
    Top = 64
    Width = 53
    Height = 13
    Caption = 'Keep alive:'
  end
  object lblUserName: TLabel
    Left = 32
    Top = 91
    Width = 26
    Height = 13
    Caption = 'Host:'
  end
  object lblPassword: TLabel
    Left = 208
    Top = 91
    Width = 50
    Height = 13
    Caption = 'Password:'
  end
  object lblConnectSection: TLabel
    Left = 8
    Top = 8
    Width = 90
    Height = 13
    Caption = 'Connect section'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSubscribeSection: TLabel
    Left = 8
    Top = 146
    Width = 99
    Height = 13
    Caption = 'Subscribe section'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label4: TLabel
    Left = 29
    Top = 165
    Width = 29
    Height = 13
    Caption = 'Topic:'
  end
  object Label5: TLabel
    Left = 666
    Top = 165
    Width = 23
    Height = 13
    Caption = 'Qos:'
  end
  object lbl1: TLabel
    Left = 8
    Top = 220
    Width = 112
    Height = 13
    Caption = 'Subscribe message:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSebscribeMessageText: TLabel
    Left = 136
    Top = 220
    Width = 43
    Height = 13
    Caption = 'No data'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object edtUserID: TEdit
    Left = 64
    Top = 61
    Width = 361
    Height = 21
    TabOrder = 0
    Text = 'PrefixRandomClientID'
  end
  object chkCleanSession: TCheckBox
    Left = 546
    Top = 63
    Width = 97
    Height = 17
    Caption = 'Clear session'
    TabOrder = 1
  end
  object edtHostName: TEdit
    Left = 64
    Top = 34
    Width = 273
    Height = 21
    TabOrder = 2
    Text = 'localhost'
  end
  object edtUserName: TEdit
    Left = 64
    Top = 88
    Width = 121
    Height = 21
    TabOrder = 3
    Text = 'admin'
  end
  object edtUserPassword: TEdit
    Left = 264
    Top = 88
    Width = 121
    Height = 21
    TabOrder = 4
    Text = 'password'
  end
  object chkSubscribeRetain: TCheckBox
    Left = 751
    Top = 164
    Width = 66
    Height = 17
    Caption = 'Retain'
    TabOrder = 5
  end
  object btnSubscribeNew: TButton
    Left = 64
    Top = 189
    Width = 75
    Height = 25
    Caption = 'Subscribe'
    TabOrder = 6
    OnClick = btnSubscribeNewClick
  end
  object edtPort: TEdit
    Left = 390
    Top = 34
    Width = 35
    Height = 21
    TabOrder = 7
    Text = '1883'
    OnChange = edtPortChange
  end
  object btnConnectToBroker: TButton
    Left = 64
    Top = 115
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 8
    OnClick = btnConnectToBrokerClick
  end
  object edtKeepAlive: TEdit
    Left = 493
    Top = 61
    Width = 35
    Height = 21
    TabOrder = 9
    Text = '10'
    OnChange = edtKeepAliveChange
  end
  object edtsubscribeTopic: TEdit
    Left = 64
    Top = 162
    Width = 593
    Height = 21
    TabOrder = 10
    Text = 'test'
  end
  object cbbQos: TComboBox
    Left = 695
    Top = 162
    Width = 42
    Height = 21
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 11
    Text = '0'
    Items.Strings = (
      '0'
      '1'
      '2')
  end
  object btnDisconnect: TButton
    Left = 152
    Top = 115
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    TabOrder = 12
    OnClick = btnDisconnectClick
  end
  object btnUsubscribe: TButton
    Left = 145
    Top = 189
    Width = 75
    Height = 25
    Caption = 'Unsubscribe'
    TabOrder = 13
    OnClick = btnUsubscribeClick
  end
end
