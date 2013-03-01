UNIT main;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

INTERFACE

USES
{$IFNDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, Windows,
{$ENDIF}
  SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Engine, common;

TYPE

  { TfrmMain }

  TfrmMain = CLASS(TForm)
    cmdSave : TButton;
    cmdRender : TButton;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label4 : TLabel;
    sd : TSaveDialog;
    strWidth : TEdit;
    strHeight : TEdit;
    strThreadCount : TEdit;
    strSampleCount : TEdit;
    imgRender : TImage;
    lblTime : TLabel;
    PROCEDURE cmdRenderClick(Sender : TObject);
    PROCEDURE cmdSaveClick(Sender : TObject);
    PROCEDURE FormClose(Sender: TObject; VAR CloseAction: TCloseAction);
    PROCEDURE FormCreate(Sender : TObject);
  PRIVATE
    { Private declarations }
    engine : TEngine;
  PUBLIC
    { Public declarations }
    startTime : LONGINT;

    PROCEDURE MSGNewLine(VAR Message : TMessage); MESSAGE MSG_NEWLINE;
  END;

VAR
  frmMain : TfrmMain;

IMPLEMENTATION

{$R *.dfm}

USES
  utils;

FUNCTION SecToTime(Sec : INTEGER) : STRING;
VAR
  H, M, S : STRING;
  ZH, ZM, ZS : INTEGER;
BEGIN
  ZH := Sec DIV 3600;
  ZM := Sec DIV 60 - ZH * 60;
  ZS := Sec - (ZH * 3600 + ZM * 60);
  H := IntToStr(ZH);
  IF (H = '0') THEN
    H := '00';
  M := IntToStr(ZM);
  IF (M = '0') THEN
    M := '00';
  S := IntToStr(ZS);
  IF (S = '0') THEN
    S := '00';
  Result := H + ':' + M + ':' + S;
END;

PROCEDURE TfrmMain.MSGNewLine(VAR Message : TMessage);
VAR
  LNewLine : PTileLine;
  i : INTEGER;
BEGIN
  LNewLine := Pointer(Message.LParam);

  FOR i := 0 TO LNewLine^.width - 1 DO
    imgRender.Canvas.Pixels[LNewLine^.x + i, LNewLine^.y] := (Utils_toInt(LNewLine^.line[i].x)) + (Utils_toInt(LNewLine^.line[i].y) SHL 8) + (Utils_toInt(LNewLine^.line[i].z) SHL 16);
  lblTime.Caption := 'Time Taken: ' + SecToTime((GetTickCount - startTime) DIV 1000);

  Message.Result := 0;
  INHERITED;
END;

PROCEDURE TfrmMain.cmdRenderClick(Sender : TObject);
BEGIN
  startTime := GetTickCount;
  imgRender.Width := strtoint(strWidth.Text);
  imgRender.Height := strtoint(strHeight.Text);
  imgRender.Canvas.Brush.Color := clBlack;
  imgRender.Canvas.FillRect(0,0, imgRender.Width, imgRender.Height);
  ClientWidth := imgRender.Left + 5 + imgRender.Width;
  ClientHeight := imgRender.Top + 5 + imgRender.Height;
  engine.Free;
  engine := TEngine.Create;
  engine.Render(self.Handle, imgRender.Width, imgRender.Height, strtoint(strSampleCount.Text), strtoint(strThreadCount.Text));
END;

PROCEDURE TfrmMain.cmdSaveClick(Sender : TObject);
BEGIN
  IF (sd.Execute) THEN
    imgRender.Picture.SaveToFile(sd.FileName);
END;

PROCEDURE TfrmMain.FormClose(Sender: TObject; VAR CloseAction: TCloseAction);
BEGIN
  engine.Free;
END;

PROCEDURE TfrmMain.FormCreate(Sender : TObject);
BEGIN
  DoubleBuffered := TRUE;
  Left           := 10;
  Top            := 10;
END;

END.
