(*******************************************************************************

    Author:
        ->  Jean-Pierre LESUEUR (@DarkCoderSc)
        https://github.com/DarkCoderSc
        https://gist.github.com/DarkCoderSc
        https://www.phrozen.io/

*******************************************************************************)

unit UntMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.ComCtrls, UntEnumFolderADSThread,
  UntDataStreamObject, System.ImageList, Vcl.ImgList;

type
  TTreeData = record
    Name       : String;
    StreamSize : Int64;
    StreamPath : String;
  end;
  PTreeData = ^TTreeData;

  TFrmMain = class(TForm)
    VST: TVirtualStringTree;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Quit1: TMenuItem;
    OpenFolder1: TMenuItem;
    N1: TMenuItem;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    CopyfiletocurrentADS1: TMenuItem;
    BackupcurrentADS1: TMenuItem;
    N2: TMenuItem;
    DeleteCurrentADSItem1: TMenuItem;
    About1: TMenuItem;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    procedure Quit1Click(Sender: TObject);
    procedure VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure VSTGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure OpenFolder1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure About1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure CopyfiletocurrentADS1Click(Sender: TObject);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure BackupcurrentADS1Click(Sender: TObject);
    procedure DeleteCurrentADSItem1Click(Sender: TObject);
  private
    FEnumFolderADS : TEnumFolderADS;
    FLastPath      : String;

    {@M}
    procedure TerminateThread();
    function CountNodes(ALevel : Integer) : Int64;
    procedure RefreshList();
    function GetParentNode(ANode : PVirtualNode) : PVirtualNode;
    function GetADSEnumerator(ANode : PVirtualNode) : TEnumDataStream;
  public
    {@M}
    procedure RefreshStatusBar();
  end;

var
  FrmMain: TFrmMain;

implementation

uses UntUtils, ShellAPI;

{$R *.dfm}

function TFrmMain.GetParentNode(ANode : PVirtualNode) : PVirtualNode;
begin
  result := nil;
  ///

  if NOT Assigned(ANode) then
    Exit();

  if VST.GetNodeLevel(ANode) = 1 then
    result := ANode.Parent
  else
    result := ANode; // We are already the parent node.
end;

function TFrmMain.GetADSEnumerator(ANode : PVirtualNode) : TEnumDataStream;
var AData : PTreeData;
begin
  result := nil;
  ///

  ANode := self.GetParentNode(ANode);
  if NOT Assigned(ANode) then
    Exit();

  AData := VST.GetNodeData(ANode);

  result := TEnumDataStream.Create(AData^.Name, True);
end;

procedure TFrmMain.RefreshList();
begin
  if NOT DirectoryExists(FLastPath) then
    Exit();
  ///

  self.TerminateThread();

  FEnumFolderADS := TEnumFolderADS.Create(FLastPath);
end;

procedure TFrmMain.RefreshStatusBar();
begin
  self.StatusBar1.Panels.Items[0].Text := Format('File Count: %d', [CountNodes(0)]);
  self.StatusBar1.Panels.Items[1].Text := Format('ADS Files Count: %d', [CountNodes(1)]);
end;

procedure TFrmMain.About1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://www.phrozen.io', nil, nil, SW_SHOW);
end;

procedure TFrmMain.BackupcurrentADS1Click(Sender: TObject);
var AData        : PTreeData;
    ADestPath    : String;
    i            : Integer;
    ADataStreams : TEnumDataStream;
    AStatus      : TADSBackupStatus;
begin
  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  ADestPath := BrowseForFolder('Backup ADS file(s) to target folder.');

  ADataStreams := self.GetADSEnumerator(VST.FocusedNode);
  if NOT Assigned(ADataStreams) then
    Exit();
  try
    AStatus := ADataStreams.BackupAllFromADS(ADestPath);
  finally
    FreeAndNil(ADataStreams);
  end;

  case AStatus of
    absPartial : Application.MessageBox('File(s) partially "backuped" from target ADS.', 'Backup from ADS', MB_ICONINFORMATION);
    absTotal   : Application.MessageBox('File(s) successfully "backuped" from target ADS.', 'Backup from ADS', MB_ICONINFORMATION);
    absError   : Application.MessageBox('Could not backup file(s) from target ADS.', 'Backup from ADS', MB_ICONERROR);
  end;
end;

procedure TFrmMain.CopyfiletocurrentADS1Click(Sender: TObject);
var AData        : PTreeData;
    ARet         : Boolean;
    ADataStreams : TEnumDataStream;
begin
  if NOT self.OpenDialog1.Execute() then
    Exit();

  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  ADataStreams := self.GetADSEnumerator(VST.FocusedNode);
  if NOT Assigned(ADataStreams) then
    Exit();
  try
    ARet := ADataStreams.CopyFileToADS(self.OpenDialog1.FileName);
  finally
    FreeAndNil(ADataStreams);
  end;

  if ARet then
    Application.MessageBox('File successfully copied to target ADS.', 'Copy to ADS', MB_ICONINFORMATION)
  else
    Application.MessageBox('Could not copy file to target ADS.', 'Copy to ADS', MB_ICONERROR);

  ///
  self.RefreshList();
end;

function TFrmMain.CountNodes(ALevel : Integer) : Int64;
var ANode : PVirtualNode;

  procedure Check();
  begin
    if (VST.GetNodeLevel(ANode) = ALevel) then
      Inc(result);
  end;

begin
  result := 0;
  ///

  ANode := VST.GetFirst(True);
  if (ANode = nil) then
    Exit();

  Check();

  while True do begin
    ANode := VST.GetNext(ANode);
    if (ANode = nil) then
      break;

    Check();
  end;
end;

procedure TFrmMain.DeleteCurrentADSItem1Click(Sender: TObject);
var AData        : PTreeData;
    ARet         : Boolean;
    i            : Integer;
    ADataStreams : TEnumDataStream;
begin
  if (VST.GetNodeLevel(VST.FocusedNode) = 0) then
    Exit();

  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  ADataStreams := self.GetADSEnumerator(VST.FocusedNode);
  if NOT Assigned(ADataStreams) then
    Exit();
  try
    ARet := ADataStreams.DeleteFromADS(AData^.Name);
  finally
    FreeAndNil(ADataStreams);
  end;

  if ARet then
    Application.MessageBox('File successfully deleted from target ADS.', 'Delete from ADS', MB_ICONINFORMATION)
  else
    Application.MessageBox('Could not delete file from target ADS.', 'Delete from ADS', MB_ICONERROR);

  self.RefreshList();
end;

procedure TFrmMain.TerminateThread();
var AExitCode : Cardinal;
begin
  if Assigned(FEnumFolderADS) then begin
    GetExitCodeThread(FEnumFolderADS.handle, AExitCode);
    if (AExitCode = STILL_ACTIVE) then begin
      FEnumFolderADS.Terminate();
      FEnumFolderADS.WaitFor();
    end;
  end;

  ///
  FEnumFolderADS := nil;
end;

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  self.TerminateThread();
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FEnumFolderADS := nil;
  FLastPath      := '';
end;

procedure TFrmMain.OpenFolder1Click(Sender: TObject);
begin
  FLastPath := BrowseForFolder('Search for Alternate Data Stream in Folder:');

  self.RefreshList();
end;

procedure TFrmMain.PopupMenu1Popup(Sender: TObject);
var ANode : PVirtualNode;
begin
  ANode := VST.FocusedNode;

  self.CopyfiletocurrentADS1.Enabled := Assigned(ANode);
  self.BackupcurrentADS1.Enabled     := Assigned(ANode);
  self.DeleteCurrentADSItem1.Enabled := Assigned(ANode);

  if self.DeleteCurrentADSItem1.Enabled then
    self.DeleteCurrentADSItem1.Enabled := (VST.GetNodeLevel(ANode) = 1);
end;

procedure TFrmMain.Quit1Click(Sender: TObject);
begin
  self.Close();
end;

procedure TFrmMain.VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex);
begin
  self.VST.Refresh();
end;

procedure TFrmMain.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  ///
end;

procedure TFrmMain.VSTGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TTreeData);
end;

procedure TFrmMain.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var AData  : PTreeData;
    ALevel : Integer;
begin
  AData := VST.GetNodeData(Node);
  if NOT Assigned(AData) then
    Exit();
  ///

  CellText := '';

  ALevel := VST.GetNodeLevel(Node);

  case Column of
    0 : begin
      CellText := AData^.Name;
    end;

    1 : begin
      if (ALevel = 1) then
        CellText := FormatSize(AData^.StreamSize);
    end;

    2 : begin
      if (ALevel = 1) then
        CellText := AData^.StreamPath;
    end;
  end;
end;

end.
