program FBExplorerApp;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // LCL widgetset
  Forms,
  uFBTypes,
  uFBConnectionManager,
  uFBMetaData,
  uFBConnectionDialog,
  uFBCreateTableForm,
  uFBExplorerMainForm;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TFBExplorerMainForm, FBExplorerMainForm);
  Application.Run;
end.
