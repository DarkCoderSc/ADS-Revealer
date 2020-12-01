program ADSRevealer;

uses
  Vcl.Forms,
  UntMain in 'Units\UntMain.pas' {FrmMain},
  UntDataStreamObject in 'Objects\UntDataStreamObject.pas',
  UntUtils in 'UntUtils.pas',
  UntEnumFolderADSThread in 'Threads\UntEnumFolderADSThread.pas';

{$R *.res}

begin
  IsMultiThread := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
