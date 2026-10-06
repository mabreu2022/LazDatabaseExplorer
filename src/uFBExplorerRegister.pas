unit uFBExplorerRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  // Lazarus IDE Interfaces ("OTA" do Lazarus)
  MenuIntf, IDEWindowIntf, LazIDEIntf,
  // Form principal
  uFBExplorerMainForm;

procedure Register;

implementation

procedure CreateFBExplorerWindow(Sender: TObject; aFormName: string;
  var AForm: TCustomForm; DoDisableAutoSizing: boolean);
begin
  IDEWindowCreators.CreateForm(AForm, TFBExplorerMainForm, DoDisableAutoSizing,
    LazarusIDE.OwningComponent);
  AForm.Name := aFormName;
  FBExplorerMainForm := AForm as TFBExplorerMainForm;
end;

procedure ShowFBExplorerMenuClicked(Sender: TObject);
begin
  IDEWindowCreators.ShowForm('FBExplorerMainForm', True);
end;

procedure Register;
begin
  // Adiciona comando ao menu "Ferramentas" (Tools) da IDE do Lazarus
  RegisterIDEMenuCommand(
    itmSecondaryTools,
    'itmFBDatabaseExplorer',
    'Firebird Database Explorer',
    nil,
    @ShowFBExplorerMenuClicked
  );

  // Registra janela como Janela da IDE (acoplável com AnchorDocking)
  IDEWindowCreators.Add(
    'FBExplorerMainForm',
    @CreateFBExplorerWindow,
    nil,
    '20%', '15%', '+950', '+620'
  );
end;

end.
