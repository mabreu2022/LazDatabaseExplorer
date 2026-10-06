unit uFBConnectionDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  uFBTypes, uFBConnectionManager;

type
  { TFBConnectionDialog }
  TFBConnectionDialog = class(TForm)
    GroupBoxProfile: TGroupBox;
    LabelProfile: TLabel;
    ComboProfiles: TComboBox;
    BtnSaveProfile: TButton;
    BtnDeleteProfile: TButton;

    GroupBoxParams: TGroupBox;
    LabelName: TLabel;
    EditProfileName: TEdit;
    LabelHost: TLabel;
    EditHost: TEdit;
    LabelPort: TLabel;
    EditPort: TEdit;
    LabelDatabase: TLabel;
    EditDatabase: TEdit;
    BtnBrowseDB: TButton;
    LabelUser: TLabel;
    EditUser: TEdit;
    LabelPassword: TLabel;
    EditPassword: TEdit;
    LabelCharset: TLabel;
    ComboCharset: TComboBox;
    LabelClientLib: TLabel;
    EditClientLib: TEdit;
    BtnBrowseClient: TButton;
    BtnTestConnection: TButton;
    BtnCreateNewDB: TButton;

    BtnConnect: TButton;
    BtnCancel: TButton;

    OpenDialogDB: TOpenDialog;
    OpenDialogLib: TOpenDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnBrowseDBClick(Sender: TObject);
    procedure BtnBrowseClientClick(Sender: TObject);
    procedure BtnTestConnectionClick(Sender: TObject);
    procedure BtnCreateNewDBClick(Sender: TObject);
    procedure BtnSaveProfileClick(Sender: TObject);
    procedure BtnDeleteProfileClick(Sender: TObject);
    procedure ComboProfilesChange(Sender: TObject);
    procedure BtnConnectClick(Sender: TObject);
  private
    function GetConfigFromUI: TFBConnectionConfig;
    procedure SetConfigToUI(const AConfig: TFBConnectionConfig);
    procedure RefreshProfilesList;
  public
    class function Execute(out Config: TFBConnectionConfig): Boolean;
  end;

implementation

{$R *.lfm}

{ TFBConnectionDialog }

procedure TFBConnectionDialog.FormCreate(Sender: TObject);
begin
  //
end;

procedure TFBConnectionDialog.FormShow(Sender: TObject);
var
  LastCfg: TFBConnectionConfig;
begin
  RefreshProfilesList;

  // Carrega última conexão salva ou primeiro perfil
  if FBConnManager.LoadLastConnection(LastCfg) then
  begin
    SetConfigToUI(LastCfg);
    if LastCfg.ProfileName <> '' then
      ComboProfiles.Text := LastCfg.ProfileName;
  end
  else if ComboProfiles.Items.Count > 0 then
  begin
    ComboProfiles.ItemIndex := 0;
    ComboProfilesChange(Self);
  end;

  // Se fbclient estiver vazio, preenche com o caminho padrão do Firebird 5.0
  if (Trim(EditClientLib.Text) = '') and FileExists('C:\Program Files\Firebird\Firebird_5_0\fbclient.dll') then
    EditClientLib.Text := 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';
end;

procedure TFBConnectionDialog.RefreshProfilesList;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    FBConnManager.GetProfileNames(List);
    ComboProfiles.Items.Assign(List);
  finally
    List.Free;
  end;
end;

function TFBConnectionDialog.GetConfigFromUI: TFBConnectionConfig;
var
  P: Integer;
begin
  Result.ProfileName := Trim(EditProfileName.Text);
  if Result.ProfileName = '' then
    Result.ProfileName := 'Firebird';
  Result.Host := Trim(EditHost.Text);
  P := StrToIntDef(Trim(EditPort.Text), 3050);
  Result.Port := P;
  Result.DatabasePath := Trim(EditDatabase.Text);
  Result.User := Trim(EditUser.Text);
  Result.Password := Trim(EditPassword.Text);
  Result.Charset := Trim(ComboCharset.Text);
  Result.ClientLibrary := Trim(EditClientLib.Text);
  Result.SqlDialect := 3;
end;

procedure TFBConnectionDialog.SetConfigToUI(const AConfig: TFBConnectionConfig);
var
  Idx: Integer;
begin
  EditProfileName.Text := AConfig.ProfileName;
  EditHost.Text := AConfig.Host;
  EditPort.Text := IntToStr(AConfig.Port);
  EditDatabase.Text := AConfig.DatabasePath;
  EditUser.Text := AConfig.User;
  EditPassword.Text := AConfig.Password;
  Idx := ComboCharset.Items.IndexOf(AConfig.Charset);
  if Idx >= 0 then
    ComboCharset.ItemIndex := Idx
  else
    ComboCharset.Text := AConfig.Charset;
  EditClientLib.Text := AConfig.ClientLibrary;
end;

procedure TFBConnectionDialog.BtnBrowseDBClick(Sender: TObject);
begin
  if OpenDialogDB.Execute then
    EditDatabase.Text := OpenDialogDB.FileName;
end;

procedure TFBConnectionDialog.BtnBrowseClientClick(Sender: TObject);
begin
  if OpenDialogLib.Execute then
    EditClientLib.Text := OpenDialogLib.FileName;
end;

procedure TFBConnectionDialog.BtnTestConnectionClick(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
begin
  Cfg := GetConfigFromUI;
  if Cfg.DatabasePath = '' then
  begin
    ShowMessage('Por favor, informe o caminho do banco de dados (.fdb).');
    Exit;
  end;

  // Persiste parâmetros informados
  FBConnManager.SaveProfile(Cfg);
  RefreshProfilesList;
  ComboProfiles.Text := Cfg.ProfileName;

  try
    Screen.Cursor := crHourGlass;
    try
      if FBConnManager.Connect(Cfg) then
      begin
        ShowMessage('Conexão estabelecida com sucesso!');
        FBConnManager.Disconnect;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do
    begin
      if Pos('connection shutdown', LowerCase(E.Message)) > 0 then
        ShowMessage('Erro ao conectar: ' + E.Message + LineEnding + LineEnding +
          'DIAGNÓSTICO:' + LineEnding +
          'O erro "-connection shutdown" ocorre quando a versão interna (ODS) do banco .FDB não é compatível com o servidor Firebird atual (ex: banco Firebird 2.5 em servidor Firebird 5.0).' + LineEnding +
          'Dica: Use o botão "Criar Novo Banco (.FDB)" para criar uma base compatível com seu Firebird 5.0 ou restaure seu banco via gbak.')
      else
        ShowMessage('Erro ao conectar: ' + E.Message);
    end;
  end;
end;

procedure TFBConnectionDialog.BtnCreateNewDBClick(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.DefaultExt := '.fdb';
    SaveDlg.Filter := 'Bancos Firebird (*.fdb)|*.fdb';
    SaveDlg.Title := 'Salvar Novo Banco de Dados Firebird';
    if not SaveDlg.Execute then Exit;

    EditDatabase.Text := SaveDlg.FileName;
    Cfg := GetConfigFromUI;

    Screen.Cursor := crHourGlass;
    try
      if FBConnManager.CreateNewDatabase(Cfg) then
      begin
        FBConnManager.SaveProfile(Cfg);
        ShowMessage('Banco de dados criado com sucesso em:' + LineEnding + Cfg.DatabasePath);
        ModalResult := mrOk;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TFBConnectionDialog.BtnSaveProfileClick(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
  Idx: Integer;
begin
  Cfg := GetConfigFromUI;
  FBConnManager.SaveProfile(Cfg);
  RefreshProfilesList;
  Idx := ComboProfiles.Items.IndexOf(Cfg.ProfileName);
  if Idx >= 0 then
    ComboProfiles.ItemIndex := Idx
  else
    ComboProfiles.Text := Cfg.ProfileName;
  ShowMessage('Perfil "' + Cfg.ProfileName + '" salvo com sucesso!');
end;

procedure TFBConnectionDialog.BtnDeleteProfileClick(Sender: TObject);
var
  Sec: string;
begin
  Sec := ComboProfiles.Text;
  if Sec = '' then Exit;

  if MessageDlg('Confirmação', 'Deseja excluir o perfil "' + Sec + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FBConnManager.DeleteProfile(Sec);
    RefreshProfilesList;
    if ComboProfiles.Items.Count > 0 then
    begin
      ComboProfiles.ItemIndex := 0;
      ComboProfilesChange(Self);
    end;
  end;
end;

procedure TFBConnectionDialog.ComboProfilesChange(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
begin
  if ComboProfiles.Text <> '' then
  begin
    if FBConnManager.LoadProfile(ComboProfiles.Text, Cfg) then
      SetConfigToUI(Cfg);
  end;
end;

procedure TFBConnectionDialog.BtnConnectClick(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
begin
  Cfg := GetConfigFromUI;
  if Cfg.DatabasePath = '' then
  begin
    ShowMessage('Informe o caminho do banco de dados antes de conectar.');
    Exit;
  end;

  // Salva perfil e última conexão automaticamente
  FBConnManager.SaveProfile(Cfg);

  try
    Screen.Cursor := crHourGlass;
    try
      if FBConnManager.Connect(Cfg) then
      begin
        ModalResult := mrOk;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do
    begin
      if Pos('connection shutdown', LowerCase(E.Message)) > 0 then
        ShowMessage('Falha ao conectar: ' + E.Message + LineEnding + LineEnding +
          'DIAGNÓSTICO:' + LineEnding +
          'O erro "-connection shutdown" ocorre quando a versão do banco .FDB (ODS) não é compatível com o servidor Firebird atual (ex: banco Firebird 2.5 em servidor Firebird 5.0).' + LineEnding +
          'Dica: Use o botão "Criar Novo Banco (.FDB)" para criar uma base Firebird 5.0 ou converta via gbak.')
      else
        ShowMessage('Falha ao conectar: ' + E.Message);
    end;
  end;
end;

class function TFBConnectionDialog.Execute(out Config: TFBConnectionConfig): Boolean;
var
  Dlg: TFBConnectionDialog;
begin
  Dlg := TFBConnectionDialog.Create(nil);
  try
    Result := (Dlg.ShowModal = mrOk);
    if Result then
      Config := Dlg.GetConfigFromUI;
  finally
    Dlg.Free;
  end;
end;

end.
