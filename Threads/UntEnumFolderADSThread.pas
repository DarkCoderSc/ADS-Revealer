(*******************************************************************************

    Author:
        ->  Jean-Pierre LESUEUR (@DarkCoderSc)
        https://github.com/DarkCoderSc
        https://gist.github.com/DarkCoderSc
        https://www.phrozen.io/

*******************************************************************************)

unit UntEnumFolderADSThread;

interface

uses System.Classes, VirtualTrees, UntDataStreamObject;

type
  TEnumFolderADS = class(TThread)
  private
    FTargetFolder : String;

    {@M}
    function EnumerateFiles() : TStringList;
    procedure AppendItem(AFile : String; ADataStreams : TEnumDataStream);
  protected
    {@M}
    procedure Execute(); override;
  public
    {@C}
    constructor Create(ATargetFolder : String); overload;
  end;

implementation

uses WinAPI.Windows, System.SysUtils, UntMain;

{-------------------------------------------------------------------------------
  Append items to main form List View
-------------------------------------------------------------------------------}
procedure TEnumFolderADS.AppendItem(AFile : String; ADataStreams : TEnumDataStream);
var AParent : PVirtualNode;
    AData   : PTreeData;
    I       : Integer;
    AStream : TDataStream;
    AChild  : PVirtualNode;
begin
  if NOT Assigned(ADataStreams) then
    Exit();
  ///

  {
    Create Parent Node
  }
  Synchronize(procedure begin
    AParent := FrmMain.VST.AddChild(nil);
    AData := FrmMain.VST.GetNodeData(AParent);
  end);

  if NOT Assigned(AData) then
    Exit();

  AData^.Name := AFile;

  {
    Create Childs
  }
  for I := 0 to ADataStreams.Items.Count -1 do begin
    AStream := ADataStreams.Items.Items[I];
    if NOT Assigned(AStream) then
      continue;
    ///

    Synchronize(procedure begin
      AChild := FrmMain.VST.AddChild(AParent);
      AData := FrmMain.VST.GetNodeData(AChild);
    end);

    AData^.Name       := AStream.StreamName;
    AData^.StreamSize := AStream.StreamSize;
    AData^.StreamPath := AStream.StreamPath;
  end;
end;

{-------------------------------------------------------------------------------
  Enumerate Files inside target folder
-------------------------------------------------------------------------------}
function TEnumFolderADS.EnumerateFiles() : TStringList;
var ASearchRec : TSearchRec;
    ANeedClose : Boolean;
begin
  result := TStringList.Create();

  FTargetFolder := IncludeTrailingPathDelimiter(FTargetFolder);

  ANeedClose := False;
  try
    if (FindFirst(Format('%s*.*', [FTargetFolder]), (faAnyFile - faDirectory), ASearchRec) = 0) then begin
      ANeedClose := True;
      repeat
        result.Add(Format('%s%s', [FTargetFolder, ASearchRec.Name]));
      until (FindNext(ASearchRec) <> 0) and (NOT Terminated);
    end;
  finally
    if ANeedClose then
      FindClose(ASearchRec);
  end;
end;

{-------------------------------------------------------------------------------
  ___execute
-------------------------------------------------------------------------------}
procedure TEnumFolderADS.Execute();
var AFiles       : TStringList;
    I            : Integer;
    ADataStreams : TEnumDataStream;
begin
  try
    Synchronize(procedure begin
      FrmMain.VST.Clear();
      FrmMain.VST.BeginUpdate();
    end);
    try
      if NOT DirectoryExists(FTargetFolder) then
        Exit();
      ///

      AFiles := self.EnumerateFiles();
      try
        for I := 0 to AFiles.Count -1 do begin
          if Terminated then
            break;
          ///

          ADataStreams := TEnumDataStream.Create(AFiles.Strings[i], True);
          try
            if (ADataStreams.Items.Count > 0) then
              self.AppendItem(AFiles.Strings[i], ADataStreams);
          finally
            FreeAndNil(ADataStreams);
          end;
        end;
      finally
        if Assigned(AFiles) then
          FreeAndNil(AFiles);
      end;
    finally
      Synchronize(procedure begin
        FrmMain.VST.EndUpdate();

        FrmMain.VST.FullExpand();

        FrmMain.RefreshStatusBar();
      end);
    end;
  finally
    ExitThread(0);
  end;
end;

{-------------------------------------------------------------------------------
  ___constructor
-------------------------------------------------------------------------------}
constructor TEnumFolderADS.Create(ATargetFolder : String);
begin
  inherited Create(True);
  ///

  self.FreeOnTerminate := True;
  self.Priority := tpNormal;

  self.FTargetFolder := ATargetFolder;

  self.Resume();
end;

end.
