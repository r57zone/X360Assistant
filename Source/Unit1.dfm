object Main: TMain
  Left = 192
  Top = 125
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'X360Assistant'
  ClientHeight = 118
  ClientWidth = 293
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GamepadTimer: TTimer
    Interval = 10
    OnTimer = GamepadTimerTimer
    Left = 40
    Top = 7
  end
  object PopupMenu1: TPopupMenu
    Left = 72
    Top = 8
    object ScrModeBtn: TMenuItem
      Caption = #1056#1077#1078#1080#1084' '#1089#1082#1088#1080#1085#1096#1086#1090#1086#1074
      object ScrGameBarMode: TMenuItem
        Caption = 'Game Bar'
        Checked = True
        OnClick = ScrGameBarModeClick
      end
      object ScrSteamMode: TMenuItem
        Caption = 'Steam (F12)'
        OnClick = ScrSteamModeClick
      end
      object ScrGameBarSteamMode: TMenuItem
        Caption = 'Game Bar + Steam'
        OnClick = ScrGameBarSteamModeClick
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object CloseBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = CloseBtnClick
    end
  end
  object XPManifest1: TXPManifest
    Left = 8
    Top = 8
  end
end
