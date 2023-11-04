unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ShellAPI, Menus, XPMan;

const
  // Constants for gamepad buttons
  XINPUT_DPAD_UP          = $0001;
  XINPUT_DPAD_DOWN        = $0002;
  XINPUT_DPAD_LEFT        = $0004;
  XINPUT_DPAD_RIGHT       = $0008;
  XINPUT_GUIDE            = $0400;
  XINPUT_START            = $0010;
  XINPUT_BACK             = $0020;
  XINPUT_LEFT_THUMB       = $0040;
  XINPUT_RIGHT_THUMB      = $0080;
  XINPUT_LEFT_SHOULDER    = $0100;
  XINPUT_RIGHT_SHOULDER   = $0200;
  XINPUT_A                = $1000;
  XINPUT_B                = $2000;
  XINPUT_X                = $4000;
  XINPUT_Y                = $8000;

  //Flags for battery status level
  BATTERY_TYPE_DISCONNECTED       = $00;

  //User index definitions
  XUSER_MAX_COUNT                 = 4;
  XUSER_INDEX_ANY                 = $000000FF;

  //Other
  ERROR_DEVICE_NOT_CONNECTED = 1167;
  ERROR_SUCCESS = 0;

  //Types and headers taken from XInput.pas
  //https://casterprojects.googlecode.com/svn/Delphi/XE2/Projects/DX/DirectXHeaders/Compact/XInput.pas

  type
  //Structures used by XInput APIs
    PXInputGamepad = ^TXInputGamepad;
    _XINPUT_GAMEPAD = record
    wButtons: Word;
    bLeftTrigger: Byte;
    bRightTrigger: Byte;
    sThumbLX: Smallint;
    sThumbLY: Smallint;
    sThumbRX: Smallint;
    sThumbRY: Smallint;
  end;
  XINPUT_GAMEPAD = _XINPUT_GAMEPAD;
  TXInputGamepad = XINPUT_GAMEPAD;

  PXInputState = ^TXInputState;
  _XINPUT_STATE = record
    dwPacketNumber: DWORD;
    Gamepad: TXInputGamepad;
  end;
  XINPUT_STATE = _XINPUT_STATE;
  TXInputState = XINPUT_STATE;

  PXInputBatteryInformation = ^TXInputBatteryInformation;
  _XINPUT_BATTERY_INFORMATION = record
    BatteryType: Byte;
    BatteryLevel: Byte;
  end;
  XINPUT_BATTERY_INFORMATION = _XINPUT_BATTERY_INFORMATION;
  TXInputBatteryInformation = _XINPUT_BATTERY_INFORMATION;

  _XInputGetState = function(dwUserIndex: DWORD; pState: PXInputState): DWORD; stdcall;
  //_XInputSetState = function(dwUserIndex: DWORD; pVibration: PXInputVibration): DWORD; stdcall;

type
  TMain = class(TForm)
    GamepadTimer: TTimer;
    PopupMenu1: TPopupMenu;
    AboutBtn: TMenuItem;
    N1: TMenuItem;
    CloseBtn: TMenuItem;
    XPManifest1: TXPManifest;
    ScrModeBtn: TMenuItem;
    ScrGameBarMode: TMenuItem;
    ScrSteamMode: TMenuItem;
    ScrGameBarSteamMode: TMenuItem;
    N2: TMenuItem;
    procedure GamepadTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CloseBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure ScrGameBarModeClick(Sender: TObject);
    procedure ScrSteamModeClick(Sender: TObject);
    procedure ScrGameBarSteamModeClick(Sender: TObject);
  private
    procedure DefaultHandler(var Message); override;
    { Private declarations }
  public
    { Public declarations }
  protected
    procedure IconMouse(var Msg: TMessage); message WM_USER + 1;
  end;

type
  TKeyButton = record
	  PressedOnce: boolean;
	  UnpressedOnce: boolean;
    KeyCode: integer;
  end;

const
  VK_GAMEBAR = 509;
  VK_GAMEBAR_SCREENSHOT = 510;
  VK_STEAM_SCREENSHOT = 511;
  VK_MULTI_SCREENSHOT = 512;
  VK_VOLUME_DOWN = 174;
  VK_VOLUME_UP = 175;

  XboxBtnReleasedTimeOut = 30;

var
  Main: TMain;
  State: TXInputState;
  XInputGetState: _XInputGetState;
  KeyButtons: array[1..4] of TKeyButton;

  XboxBtnOnlyCheckCount: integer = 0;
	XboxBtnReleasedCount: integer = 0;
	XboxBtnOnlyPressed: boolean = false;

  LastGamepadIndex: integer = 0;

  WM_TASKBARCREATED: Cardinal;
  RunOnce: boolean;

  ID_ABOUT_TITLE, ID_LAST_UPDATE: string;

implementation

{$R *.dfm}

procedure Tray(ActInd: integer); // 1 - добавить, 2 - заменить, 3 -  удалить
var
  NIM: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(nim);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
    hIcon:=SendMessage(Application.Handle, WM_GETICON, ICON_SMALL2, 0);
    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case ActInd of
    1: Shell_NotifyIcon(NIM_ADD, @NIM);
    2: Shell_NotifyIcon(NIM_MODIFY, @NIM);
    3: Shell_NotifyIcon(NIM_DELETE, @NIM);
  end;
end;

procedure MyKeyPress(KeyCode: Integer; ButtonPressed: Boolean; var ButtonState: TKeyButton);
begin
  if ButtonPressed then begin
    ButtonState.UnpressedOnce:=true;
    if not ButtonState.PressedOnce then begin

      if KeyCode < 500 then
        keybd_event(KeyCode, $45, KEYEVENTF_EXTENDEDKEY or 0, 0)

      else if KeyCode = VK_GAMEBAR then begin
        keybd_event(VK_LWIN, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
        keybd_event(ord('G'), $45, KEYEVENTF_EXTENDEDKEY or 0, 0);

      end else if (KeyCode = VK_GAMEBAR_SCREENSHOT) or (KeyCode = VK_MULTI_SCREENSHOT) then begin
        keybd_event(VK_LWIN, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
        keybd_event(VK_MENU, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
        keybd_event(VK_SNAPSHOT, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);

      end else if KeyCode = VK_STEAM_SCREENSHOT then
					keybd_event(VK_F12, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);

      ButtonState.PressedOnce:=true;
    end;
  end else if not ButtonPressed and ButtonState.UnpressedOnce then begin

    if KeyCode < 500 then
      keybd_event(KeyCode, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0)

    else if KeyCode = VK_GAMEBAR then begin
      keybd_event(ord('G'), $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
      keybd_event(VK_LWIN, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);

    end else if (KeyCode = VK_GAMEBAR_SCREENSHOT) or (KeyCode = VK_MULTI_SCREENSHOT) then begin
      keybd_event(VK_SNAPSHOT, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
      keybd_event(VK_MENU, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
      keybd_event(VK_LWIN, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
      if KeyCode = VK_MULTI_SCREENSHOT then begin keybd_event(VK_F12, $45, KEYEVENTF_EXTENDEDKEY or 0, 0); keybd_event(VK_F12, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0); end; // Steam

    end else if KeyCode = VK_STEAM_SCREENSHOT then
      keybd_event(VK_F12, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);

    ButtonState.UnpressedOnce:=false;
		ButtonState.PressedOnce:=false;
  end;
end;

procedure TMain.GamepadTimerTimer(Sender: TObject);
var
  i: integer; FoundXboxGamepad: boolean;
begin
  if XInputGetState(LastGamepadIndex, @State) <> ERROR_SUCCESS then begin

    FoundXboxGamepad:=false;
    for i:=0 to XUSER_MAX_COUNT - 1 do begin
      if XInputGetState(i, @State) = ERROR_SUCCESS then begin
        LastGamepadIndex:=i;
        GamepadTimer.Interval:=10;
        FoundXboxGamepad:=true;
        Break;
      end;
    end;

    if FoundXboxGamepad = false then begin
      State.Gamepad.wButtons:=0;
      GamepadTimer.Interval:=5000;
    end;
  end else
    GamepadTimer.Interval:=10;

  //Caption:=IntToStr(GamepadTimer.Interval);

  MyKeyPress(KeyButtons[1].KeyCode, (State.Gamepad.wButtons and XINPUT_GUIDE <> 0) and
                                    ((State.Gamepad.wButtons and XINPUT_X <> 0) or (State.Gamepad.wButtons and XINPUT_DPAD_LEFT <> 0)), KeyButtons[1]);

  MyKeyPress(KeyButtons[2].KeyCode, (State.Gamepad.wButtons and XINPUT_GUIDE <> 0) and
                                    ((State.Gamepad.wButtons and XINPUT_B <> 0) or
                                    (State.Gamepad.wButtons and XINPUT_DPAD_RIGHT <> 0)), KeyButtons[2]);

  MyKeyPress(KeyButtons[3].KeyCode, (State.Gamepad.wButtons and XINPUT_GUIDE <> 0) and
                                    ((State.Gamepad.wButtons and XINPUT_A <> 0) or
                                    (State.Gamepad.wButtons and XINPUT_DPAD_UP <> 0) or
                                    (State.Gamepad.wButtons and XINPUT_LEFT_SHOULDER <> 0) or
                                    (State.Gamepad.wButtons and XINPUT_RIGHT_SHOULDER <> 0)), KeyButtons[3]);

  if (XboxBtnReleasedCount = 0) and (State.Gamepad.wButtons = XINPUT_GUIDE) then begin XboxBtnOnlyCheckCount:=20; XboxBtnOnlyPressed:=true; end;
		if XboxBtnOnlyCheckCount > 0 then begin
			if (XboxBtnOnlyCheckCount = 1) and (XboxBtnOnlyPressed) then
				XboxBtnReleasedCount:=XboxBtnReleasedTimeOut; // Timeout to release the Xbox button and don't execute commands
			Dec(XboxBtnOnlyCheckCount);
			if (State.Gamepad.wButtons <> XINPUT_GUIDE) and (State.Gamepad.wButtons <> 0) then begin XboxBtnOnlyPressed:=false; XboxBtnOnlyCheckCount:=0; end;
		end;
		if (State.Gamepad.wButtons and XINPUT_GUIDE <> 0) and (State.Gamepad.wButtons <> XINPUT_GUIDE) then XboxBtnReleasedCount:=XboxBtnReleasedTimeOut; // printf("PS + any button\n"); }
		if XboxBtnReleasedCount > 0 then Dec(XboxBtnReleasedCount);

  MyKeyPress(KeyButtons[4].KeyCode, (XboxBtnOnlyCheckCount = 1) and (XboxBtnOnlyPressed), KeyButtons[4]);
end;

function GetLocaleInformation(Flag: Integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19)<=0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  hDll: THandle;
  i: Integer;
begin
  Application.Title:=Caption;
  WM_TASKBARCREATED:=RegisterWindowMessage('TaskbarCreated');
  Tray(1);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);

  KeyButtons[1].KeyCode:=VK_VOLUME_DOWN;
  KeyButtons[2].KeyCode:=VK_VOLUME_UP;
  KeyButtons[3].KeyCode:=VK_GAMEBAR_SCREENSHOT;
  KeyButtons[4].KeyCode:=VK_GAMEBAR;

  hDll := LoadLibrary('xinput1_3.dll'); // x360ce support
  if hDll = 0 then
    hDll := LoadLibrary('xinput1_4.dll');
  
  if hDll <> 0 then
  begin
    XInputGetState := _XInputGetState(GetProcAddress(hDll, PAnsiChar(100))); // "XInputGetState"); // Ordinal 100 is the same as XInputGetState but supports the Guide button. Taken here https://github.com/speps/XInputDotNet/blob/master/XInputInterface/GamePad.cpp
    //XInputSetState := _XInputSetState(GetProcAddress(hDll, 'XInputSetState'));

    if not Assigned(XInputGetState) then // or not Assigned(XInputSetState) then
      hDll := 0;
  end;

  if GetLocaleInformation(LOCALE_SENGLANGUAGE) = 'Russian' then begin
    ID_ABOUT_TITLE:='О программе...';
    ID_LAST_UPDATE:='Последнее обновление:';
  end else begin
    ScrModeBtn.Caption:='Screenshot mode';
    ID_ABOUT_TITLE:='About...';
    AboutBtn.Caption:=ID_ABOUT_TITLE;
    ID_LAST_UPDATE:='Last update:';
    CloseBtn.Caption:='Exit';
  end;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Tray(3);
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    //WM_LBUTTONDBLCLK: ...
    WM_LBUTTONDOWN: begin
      PostMessage(Handle, WM_LBUTTONDOWN, MK_LBUTTON, 0);
      PostMessage(Handle, WM_LBUTTONUP, MK_LBUTTON, 0);
    end;
    WM_RBUTTONDOWN:
    begin
      SetForegroundWindow(Handle);
      PopupMenu1.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
    end;
  end;
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(1);
  inherited;
end;

procedure TMain.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Main.Caption + ' 1.0' + #13#10 +
  ID_LAST_UPDATE + ' 04.11.2023' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), MB_ICONINFORMATION);
end;

procedure TMain.ScrGameBarModeClick(Sender: TObject);
begin
  KeyButtons[3].KeyCode:=VK_GAMEBAR_SCREENSHOT;
  ScrGameBarMode.Checked:=true;
  ScrSteamMode.Checked:=false;
  ScrGameBarSteamMode.Checked:=false;
end;

procedure TMain.ScrSteamModeClick(Sender: TObject);
begin
  KeyButtons[3].KeyCode:=VK_STEAM_SCREENSHOT;
  ScrSteamMode.Checked:=true;
  ScrGameBarMode.Checked:=false;
  ScrGameBarSteamMode.Checked:=false;
end;

procedure TMain.ScrGameBarSteamModeClick(Sender: TObject);
begin
  KeyButtons[3].KeyCode:=VK_MULTI_SCREENSHOT;
  ScrGameBarSteamMode.Checked:=true;
  ScrSteamMode.Checked:=false;
  ScrGameBarMode.Checked:=false;
end;

end.
