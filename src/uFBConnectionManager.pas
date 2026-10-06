unit uFBConnectionManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles,
  // Database components
  db, sqldb, ibconnection, ibase60dyn,
  // Local types
  uFBTypes;

type
  TFBConnectionEvent = procedure(Sender: TObject; Connected: Boolean; const Msg: string) of object;

  { TFBConnectionManager }
  TFBConnectionManager = class
  private
    FConnection: TIBConnection;
    FTransaction: TSQLTransaction;
    FConfig: TFBConnectionConfig;
    FOnConnectionChange: TFBConnectionEvent;
    FConfigFile: string;
    procedure SetupConnectionParams(const AConfig: TFBConnectionConfig);
  public
    constructor Create;
    destructor Destroy; override;

    function Connect(const AConfig: TFBConnectionConfig): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;

    function CreateNewDatabase(const AConfig: TFBConnectionConfig; PageSize: Integer = 8192): Boolean;
    function ExecuteDirect(const ASql: string; out RowsAffected: Integer): Boolean;
    procedure ExecuteQuery(const ASql: string; TargetQuery: TSQLQuery);
    procedure Commit;
    procedure Rollback;

    procedure SaveProfile(const AConfig: TFBConnectionConfig);
    function LoadProfile(const ProfileName: string; out AConfig: TFBConnectionConfig): Boolean;
    procedure GetProfileNames(List: TStrings);
    procedure DeleteProfile(const ProfileName: string);
    procedure SaveLastConnection(const AConfig: TFBConnectionConfig);
    function LoadLastConnection(out AConfig: TFBConnectionConfig): Boolean;

    property Connection: TIBConnection read FConnection;
    property Transaction: TSQLTransaction read FTransaction;
    property CurrentConfig: TFBConnectionConfig read FConfig;
    property OnConnectionChange: TFBConnectionEvent read FOnConnectionChange write FOnConnectionChange;
    property ConfigFile: string read FConfigFile write FConfigFile;
  end;

var
  FBConnManager: TFBConnectionManager;

implementation

{ TFBConnectionManager }

function GetDefaultProfilePath: string;
var
  BaseDir: string;
begin
  BaseDir := GetEnvironmentVariable('APPDATA');
  if BaseDir = '' then
    BaseDir := GetEnvironmentVariable('USERPROFILE');
  if BaseDir = '' then
    BaseDir := GetAppConfigDir(False);

  Result := IncludeTrailingPathDelimiter(BaseDir) + 'LazarusFirebirdExplorer' + PathDelim + 'fb_profiles.ini';
end;

constructor TFBConnectionManager.Create;
begin
  inherited Create;
  FConnection := TIBConnection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);

  FConnection.Transaction := FTransaction;
  FTransaction.Database := FConnection;

  // Defaults
  FConfig := TFBMetaTypeHelper.DefaultConfig;
  FConfigFile := GetDefaultProfilePath;
end;

destructor TFBConnectionManager.Destroy;
begin
  Disconnect;
  FreeAndNil(FTransaction);
  FreeAndNil(FConnection);
  inherited Destroy;
end;

procedure TFBConnectionManager.SetupConnectionParams(const AConfig: TFBConnectionConfig);
var
  LibPath: string;
begin
  Disconnect;

  FConnection.HostName := Trim(AConfig.Host);
  if AConfig.Port > 0 then
    FConnection.Port := AConfig.Port
  else
    FConnection.Port := 3050;

  FConnection.DatabaseName := Trim(AConfig.DatabasePath);
  FConnection.UserName := Trim(AConfig.User);
  FConnection.Password := Trim(AConfig.Password);
  FConnection.CharSet := Trim(AConfig.Charset);

  // Client Library (fbclient.dll)
  LibPath := Trim(AConfig.ClientLibrary);
  if (LibPath = '') and FileExists('C:\Program Files\Firebird\Firebird_5_0\fbclient.dll') then
    LibPath := 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';

  if (LibPath <> '') and FileExists(LibPath) then
  begin
    InitialiseIBase60(LibPath);
    FConnection.FieldNameQuoteChars := DoubleQuotes;
  end;

  FConnection.Params.Clear;
  if Trim(AConfig.Charset) <> '' then
    FConnection.Params.Add('lc_ctype=' + Trim(AConfig.Charset));
  if AConfig.Port > 0 then
    FConnection.Params.Add('Port=' + IntToStr(AConfig.Port));
  if AConfig.SqlDialect > 0 then
    FConnection.Params.Add('sql_dialect=' + IntToStr(AConfig.SqlDialect));
end;

function TFBConnectionManager.Connect(const AConfig: TFBConnectionConfig): Boolean;
begin
  Result := False;
  try
    SetupConnectionParams(AConfig);
    FConnection.Connected := True;
    FConfig := AConfig;
    SaveLastConnection(AConfig);
    Result := FConnection.Connected;
    if Assigned(FOnConnectionChange) then
      FOnConnectionChange(Self, True, 'Conectado com sucesso ao Firebird!');
  except
    on E: Exception do
    begin
      Disconnect;
      if Assigned(FOnConnectionChange) then
        FOnConnectionChange(Self, False, 'Falha ao conectar: ' + E.Message);
      raise;
    end;
  end;
end;

procedure TFBConnectionManager.Disconnect;
begin
  if FConnection.Connected then
  begin
    try
      if FTransaction.Active then
        FTransaction.Rollback;
      FConnection.Connected := False;
      if Assigned(FOnConnectionChange) then
        FOnConnectionChange(Self, False, 'Desconectado.');
    except
      // Ignorar erros ao desconectar forçado
    end;
  end;
end;

function TFBConnectionManager.IsConnected: Boolean;
begin
  Result := (FConnection <> nil) and FConnection.Connected;
end;

function TFBConnectionManager.CreateNewDatabase(const AConfig: TFBConnectionConfig; PageSize: Integer): Boolean;
begin
  Result := False;
  SetupConnectionParams(AConfig);
  try
    FConnection.Params.Add('PAGE_SIZE=' + IntToStr(PageSize));
    FConnection.CreateDB;
    FConnection.Connected := True;
    FConfig := AConfig;
    Result := True;
    if Assigned(FOnConnectionChange) then
      FOnConnectionChange(Self, True, 'Novo banco criado e conectado com sucesso!');
  except
    on E: Exception do
    begin
      Disconnect;
      if Assigned(FOnConnectionChange) then
        FOnConnectionChange(Self, False, 'Erro ao criar banco: ' + E.Message);
      raise;
    end;
  end;
end;

function TFBConnectionManager.ExecuteDirect(const ASql: string; out RowsAffected: Integer): Boolean;
var
  Qry: TSQLQuery;
begin
  Result := False;
  RowsAffected := 0;
  if not IsConnected then
    raise Exception.Create('Não conectado a um banco Firebird.');

  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FConnection;
    Qry.Transaction := FTransaction;
    if not FTransaction.Active then
      FTransaction.StartTransaction;

    Qry.SQL.Text := ASql;
    Qry.ExecSQL;
    RowsAffected := Qry.RowsAffected;
    FTransaction.CommitRetaining;
    Result := True;
  finally
    Qry.Free;
  end;
end;

procedure TFBConnectionManager.ExecuteQuery(const ASql: string; TargetQuery: TSQLQuery);
begin
  if not IsConnected then
    raise Exception.Create('Não conectado a um banco Firebird.');

  TargetQuery.Close;
  TargetQuery.DataBase := FConnection;
  TargetQuery.Transaction := FTransaction;
  if not FTransaction.Active then
    FTransaction.StartTransaction;

  TargetQuery.SQL.Text := ASql;
  TargetQuery.Open;
end;

procedure TFBConnectionManager.Commit;
begin
  if (FTransaction <> nil) and FTransaction.Active then
    FTransaction.CommitRetaining;
end;

procedure TFBConnectionManager.Rollback;
begin
  if (FTransaction <> nil) and FTransaction.Active then
    FTransaction.RollbackRetaining;
end;

procedure TFBConnectionManager.SaveProfile(const AConfig: TFBConnectionConfig);
var
  Ini: TIniFile;
  Sec: string;
begin
  ForceDirectories(ExtractFileDir(FConfigFile));
  Ini := TIniFile.Create(FConfigFile);
  try
    Sec := Trim(AConfig.ProfileName);
    if Sec = '' then
      Sec := 'Default';
    Ini.WriteString(Sec, 'Host', AConfig.Host);
    Ini.WriteInteger(Sec, 'Port', AConfig.Port);
    Ini.WriteString(Sec, 'DatabasePath', AConfig.DatabasePath);
    Ini.WriteString(Sec, 'User', AConfig.User);
    Ini.WriteString(Sec, 'Password', AConfig.Password);
    Ini.WriteString(Sec, 'Charset', AConfig.Charset);
    Ini.WriteString(Sec, 'ClientLibrary', AConfig.ClientLibrary);
    Ini.WriteInteger(Sec, 'SqlDialect', AConfig.SqlDialect);
  finally
    Ini.Free;
  end;
  SaveLastConnection(AConfig);
end;

procedure TFBConnectionManager.SaveLastConnection(const AConfig: TFBConnectionConfig);
var
  Ini: TIniFile;
begin
  ForceDirectories(ExtractFileDir(FConfigFile));
  Ini := TIniFile.Create(FConfigFile);
  try
    Ini.WriteString('LastConnection', 'ProfileName', AConfig.ProfileName);
    Ini.WriteString('LastConnection', 'Host', AConfig.Host);
    Ini.WriteInteger('LastConnection', 'Port', AConfig.Port);
    Ini.WriteString('LastConnection', 'DatabasePath', AConfig.DatabasePath);
    Ini.WriteString('LastConnection', 'User', AConfig.User);
    Ini.WriteString('LastConnection', 'Password', AConfig.Password);
    Ini.WriteString('LastConnection', 'Charset', AConfig.Charset);
    Ini.WriteString('LastConnection', 'ClientLibrary', AConfig.ClientLibrary);
    Ini.WriteInteger('LastConnection', 'SqlDialect', AConfig.SqlDialect);
  finally
    Ini.Free;
  end;
end;

function TFBConnectionManager.LoadLastConnection(out AConfig: TFBConnectionConfig): Boolean;
var
  Ini: TIniFile;
begin
  Result := False;
  AConfig := TFBMetaTypeHelper.DefaultConfig;
  if not FileExists(FConfigFile) then Exit;

  Ini := TIniFile.Create(FConfigFile);
  try
    if not Ini.SectionExists('LastConnection') then Exit;

    AConfig.ProfileName := Ini.ReadString('LastConnection', 'ProfileName', 'Novo Perfil');
    AConfig.Host := Ini.ReadString('LastConnection', 'Host', 'localhost');
    AConfig.Port := Ini.ReadInteger('LastConnection', 'Port', 3050);
    AConfig.DatabasePath := Ini.ReadString('LastConnection', 'DatabasePath', '');
    AConfig.User := Ini.ReadString('LastConnection', 'User', 'SYSDBA');
    AConfig.Password := Ini.ReadString('LastConnection', 'Password', 'masterkey');
    AConfig.Charset := Ini.ReadString('LastConnection', 'Charset', 'UTF8');
    AConfig.ClientLibrary := Ini.ReadString('LastConnection', 'ClientLibrary', '');
    AConfig.SqlDialect := Ini.ReadInteger('LastConnection', 'SqlDialect', 3);
    Result := True;
  finally
    Ini.Free;
  end;
end;

function TFBConnectionManager.LoadProfile(const ProfileName: string; out AConfig: TFBConnectionConfig): Boolean;
var
  Ini: TIniFile;
  Sec: string;
begin
  Result := False;
  AConfig := TFBMetaTypeHelper.DefaultConfig;
  if not FileExists(FConfigFile) then Exit;

  Ini := TIniFile.Create(FConfigFile);
  try
    Sec := Trim(ProfileName);
    if not Ini.SectionExists(Sec) then Exit;

    AConfig.ProfileName := Sec;
    AConfig.Host := Ini.ReadString(Sec, 'Host', 'localhost');
    AConfig.Port := Ini.ReadInteger(Sec, 'Port', 3050);
    AConfig.DatabasePath := Ini.ReadString(Sec, 'DatabasePath', '');
    AConfig.User := Ini.ReadString(Sec, 'User', 'SYSDBA');
    AConfig.Password := Ini.ReadString(Sec, 'Password', 'masterkey');
    AConfig.Charset := Ini.ReadString(Sec, 'Charset', 'UTF8');
    AConfig.ClientLibrary := Ini.ReadString(Sec, 'ClientLibrary', '');
    AConfig.SqlDialect := Ini.ReadInteger(Sec, 'SqlDialect', 3);
    Result := True;
  finally
    Ini.Free;
  end;
end;

procedure TFBConnectionManager.GetProfileNames(List: TStrings);
var
  Ini: TIniFile;
  I: Integer;
begin
  List.Clear;
  if FileExists(FConfigFile) then
  begin
    Ini := TIniFile.Create(FConfigFile);
    try
      Ini.ReadSections(List);
      I := List.IndexOf('LastConnection');
      if I >= 0 then
        List.Delete(I);
    finally
      Ini.Free;
    end;
  end;
end;

procedure TFBConnectionManager.DeleteProfile(const ProfileName: string);
var
  Ini: TIniFile;
begin
  if FileExists(FConfigFile) then
  begin
    Ini := TIniFile.Create(FConfigFile);
    try
      Ini.EraseSection(ProfileName);
    finally
      Ini.Free;
    end;
  end;
end;

initialization
  FBConnManager := TFBConnectionManager.Create;

finalization
  FreeAndNil(FBConnManager);

end.
