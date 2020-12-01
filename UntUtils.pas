(*******************************************************************************

    Author:
        ->  Jean-Pierre LESUEUR (@DarkCoderSc)
        https://github.com/DarkCoderSc
        https://gist.github.com/DarkCoderSc
        https://www.phrozen.io/

*******************************************************************************)

unit UntUtils;

interface

uses Windows, ShlObj, Math, SysUtils, ShellAPI, VCL.Controls;

type TFormatMode = (fmBits, fmByte);

function BrowseForFolder(const ADialogTitle : String; const AInitialFolder : String = ''; ACanCreateFolder: Boolean = False) : String;
function FormatSize(const ADataCount : Int64; AFormat : TFormatMode = fmByte) : string;

implementation


{-------------------------------------------------------------------------------
  Format bytes to human readable mode
-------------------------------------------------------------------------------}
function FormatSize(const ADataCount : Int64; AFormat : TFormatMode = fmByte) : string;
const AByteDescription : Array[0..8] of string = ('Bytes', 'KiB', 'MB', 'GiB', 'TB', 'PB', 'EB', 'ZB', 'YB');
      ABitsDescription : Array[0..8] of string = ('Bits', 'KBits', 'MBits', 'GBits', 'TBits', 'PBits', 'EBits', 'ZBits', 'YBits');

var ACount : Integer;
begin
  ACount := 0;

  while ADataCount > Power(1024, ACount +1) do begin
    Inc(ACount);
  end;

  result := FormatFloat('###0.00', ADataCount / Power(1024, ACount)) + ' ';

  case AFormat of
    fmByte : begin
      result := result + AByteDescription[ACount];
    end;

    fmBits : begin
      result := result + ABitsDescription[ACount];
    end;
  end;
end;

{-------------------------------------------------------------------------------
  Show native Windows Dialog to select an existing folder.
-------------------------------------------------------------------------------}

function BrowseForFolderCallBack(hwnd : HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) then begin
    SendMessage(hwnd, BFFM_SETSELECTION, 1, lpData);
  end;

  ///
  result := 0;
end;

function BrowseForFolder(const ADialogTitle : String; const AInitialFolder : String = ''; ACanCreateFolder: Boolean = False) : String;
var ABrowseInfo : TBrowseInfo;
    AFolder  : array[0..MAX_PATH-1] of Char;
    pItem  : PItemIDList;
begin
  ZeroMemory(@ABrowseInfo, SizeOf(TBrowseInfo));
  ///

  ABrowseInfo.pszDisplayName := @AFolder[0];
  ABrowseInfo.lpszTitle := PChar(ADialogTitle);
  ABrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;


  if NOT ACanCreateFolder then
    ABrowseInfo.ulFlags := ABrowseInfo.ulFlags or BIF_NONEWFOLDERBUTTON;

  ABrowseInfo.hwndOwner := 0;

  if AInitialFolder <> '' then begin
    ABrowseInfo.lpfn   := BrowseForFolderCallBack;
    ABrowseInfo.lParam := NativeUInt(@AInitialFolder[1]);
  end;

  pItem := SHBrowseForFolder(ABrowseInfo);
  if Assigned(pItem) then begin
    if SHGetPathFromIDList(pItem, AFolder) then
      result := AFolder
    else
      result := '';

    GlobalFreePtr(pItem);
  end else
    result := '';
end;


end.
