program IoTBsAs;

uses
  System.StartUpCopy,
  FMX.Forms,
  HeaderFooterTemplate in 'HeaderFooterTemplate.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
