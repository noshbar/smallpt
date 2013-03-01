UNIT common;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

INTERFACE

USES vector, windows;

CONST
  Tile_Width = 64;
  Tile_Height = 64;

CONST
  MSG_NEWLINE = WM_APP + 0;

TYPE
  TVectorLine = ARRAY[0..Tile_Width - 1] OF TVector;
  TVectorLinePtr = ^TVectorLine;

TYPE
  PTileLine = ^TTileLine;
  TTileLine = RECORD
    x, y : INTEGER;
    width : INTEGER;
    line : TVectorLine;
  END;

IMPLEMENTATION

END.
