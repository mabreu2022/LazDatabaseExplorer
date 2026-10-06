{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazarusDataBaseExplorer;

{$warn 5023 off : no warning about unused units}
interface

uses
  uFBExplorerRegister, uFBExplorerMainForm, uFBConnectionManager,
  uFBMetaData, uFBConnectionDialog, uFBCreateTableForm, uFBTypes,
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('uFBExplorerRegister', @uFBExplorerRegister.Register);
end;

initialization
  RegisterPackage('LazarusDataBaseExplorer', @Register);
end.
