object frmMain: TfrmMain
  Left = 2631
  Height = 202
  Top = 296
  Width = 351
  Caption = 'smallpt'
  ClientHeight = 202
  ClientWidth = 351
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  OnClose = FormClose
  OnCreate = FormCreate
  LCLVersion = '1.0.6.0'
  object cmdRender: TButton
    Left = 77
    Height = 25
    Top = 112
    Width = 75
    Caption = '&Render'
    OnClick = cmdRenderClick
    TabOrder = 0
  end
  object imgRender: TImage
    Left = 160
    Height = 188
    Top = 4
    Width = 184
  end
  object lblTime: TLabel
    Left = 17
    Height = 14
    Top = 144
    Width = 61
    Caption = 'Time Taken:'
    ParentColor = False
  end
  object cmdSave: TButton
    Left = 77
    Height = 25
    Top = 168
    Width = 75
    Caption = '&Save Image'
    OnClick = cmdSaveClick
    TabOrder = 1
  end
  object strThreadCount: TEdit
    Left = 104
    Height = 21
    Top = 80
    Width = 48
    TabOrder = 2
    Text = '4'
  end
  object strSampleCount: TEdit
    Left = 104
    Height = 21
    Top = 56
    Width = 48
    TabOrder = 3
    Text = '10'
  end
  object strWidth: TEdit
    Left = 104
    Height = 21
    Top = 8
    Width = 48
    TabOrder = 4
    Text = '320'
  end
  object strHeight: TEdit
    Left = 104
    Height = 21
    Top = 32
    Width = 48
    TabOrder = 5
    Text = '240'
  end
  object Label1: TLabel
    Left = 8
    Height = 14
    Top = 11
    Width = 32
    Caption = 'Width:'
    ParentColor = False
  end
  object Label2: TLabel
    Left = 8
    Height = 14
    Top = 32
    Width = 35
    Caption = 'Height:'
    ParentColor = False
  end
  object Label3: TLabel
    Left = 8
    Height = 14
    Top = 56
    Width = 70
    Caption = 'Sample Count:'
    ParentColor = False
  end
  object Label4: TLabel
    Left = 8
    Height = 14
    Top = 82
    Width = 69
    Caption = 'Thread Count:'
    ParentColor = False
  end
  object sd: TSaveDialog
    Filter = 'Bitmap files (*.BMP)|*.bmp'
    left = 13
    top = 111
  end
end
