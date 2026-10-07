unit uFBMetaData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb,
  uFBTypes, uFBConnectionManager;

type
  { Metadata record for a table column }
  TFBMetaField = record
    FieldName: string;
    TypeName: string;
    FieldType: Integer;
    FieldSubType: Integer;
    FieldLength: Integer;
    FieldScale: Integer;
    NotNull: Boolean;
    IsPrimaryKey: Boolean;
    DefaultValue: string;
  end;

  TFBMetaFieldList = array of TFBMetaField;

  { Foreign Key info from Firebird system tables }
  TFBForeignKeyInfo = record
    ConstraintName: string;
    TableName: string;
    LocalField: string;
    RefTable: string;
    RefField: string;
    UpdateRule: string;
    DeleteRule: string;
  end;

  TFBForeignKeyInfoList = array of TFBForeignKeyInfo;

  { Index Info from Firebird system tables }
  TFBIndexInfo = record
    IndexName: string;
    TableName: string;
    Fields: string;
    IsUnique: Boolean;
    IsDescending: Boolean;
    Selectivity: Double;
    IsActive: Boolean;
  end;
  TFBIndexInfoList = array of TFBIndexInfo;

  { Database Health & Transaction Info }
  TFBDatabaseHealthInfo = record
    PageSize: Integer;
    PageBuffers: Integer;
    SweepInterval: Integer;
    OIT: Int64;
    OAT: Int64;
    OST: Int64;
    NextTransaction: Int64;
    Difference: Int64;
  end;

  { TFBMetaDataExtractor }
  TFBMetaDataExtractor = class
  public
    class procedure GetTables(List: TStrings; IncludeSystem: Boolean = False);
    class procedure GetViews(List: TStrings);
    class procedure GetProcedures(List: TStrings);
    class procedure GetTriggers(List: TStrings);
    class procedure GetGenerators(List: TStrings);
    class function GetTableFields(const ATableName: string): TFBMetaFieldList;
    class procedure GetPrimaryKeys(const ATableName: string; List: TStrings);
    class procedure GetTableFieldNames(const ATableName: string; List: TStrings);
    class function GetTableForeignKeys(const ATableName: string): TFBForeignKeyInfoList;

    { DDL Generators }
    class function GenerateCreateTableDDL(const ATableName: string): string;
    class function GenerateDropTableSQL(const ATableName: string): string;
    class function GenerateSelectTopSQL(const ATableName: string; Limit: Integer = 100): string;
    class function BuildCreateTableSQL(const ATableName: string; const Cols: array of TColumnDef; Firebird3Plus: Boolean = True): string;
    class function DropConstraintSQL(const ATableName, AConstraintName: string): string;
    class function AddForeignKeySQL(const ATableName: string; const FK: TForeignKeyDef): string;
    class function AddPrimaryKeySQL(const ATableName, APKName, APKFields: string): string;

    { Generator / Sequence Helpers }
    class function GetGeneratorValue(const AGenName: string): Int64;
    class procedure SetGeneratorValue(const AGenName: string; AVal: Int64);
    class procedure CreateGenerator(const AGenName: string; AInitialVal: Int64 = 0);
    class procedure DropGenerator(const AGenName: string);

    { Indices }
    class function GetTableIndices(const ATableName: string): TFBIndexInfoList;
    class procedure RecalculateIndexStatistics(const AIndexName: string);
    class procedure CreateIndex(const AIndexName, ATableName, AFields: string; AUnique, ADescending: Boolean);
    class procedure DropIndex(const AIndexName: string);

    { PSQL Sources }
    class function GetProcedureSource(const AProcName: string): string;
    class function GetTriggerSource(const ATrigName: string): string;

    { Full Database DDL Extraction }
    class function ExtractFullDatabaseDDL: string;

    { Database Health }
    class function GetDatabaseHealthInfo: TFBDatabaseHealthInfo;
    class procedure ExecuteSweep;
  end;

implementation

{ TFBMetaDataExtractor }

class procedure TFBMetaDataExtractor.GetTables(List: TStrings; IncludeSystem: Boolean);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RDB$RELATION_NAME) AS REL_NAME ' +
           'FROM RDB$RELATIONS ' +
           'WHERE (RDB$VIEW_BLR IS NULL) ';

    if not IncludeSystem then
      Sql := Sql + 'AND (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL) ';

    Sql := Sql + 'ORDER BY RDB$RELATION_NAME;';

    FBConnManager.ExecuteQuery(Sql, Qry);
    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('REL_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetViews(List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RDB$RELATION_NAME) AS REL_NAME ' +
           'FROM RDB$RELATIONS ' +
           'WHERE (RDB$VIEW_BLR IS NOT NULL) ' +
           '  AND (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL) ' +
           'ORDER BY RDB$RELATION_NAME;';

    FBConnManager.ExecuteQuery(Sql, Qry);
    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('REL_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetProcedures(List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RDB$PROCEDURE_NAME) AS PROC_NAME ' +
           'FROM RDB$PROCEDURES ' +
           'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL) ' +
           'ORDER BY RDB$PROCEDURE_NAME;';

    FBConnManager.ExecuteQuery(Sql, Qry);
    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('PROC_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetTriggers(List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RDB$TRIGGER_NAME) AS TRIG_NAME ' +
           'FROM RDB$TRIGGERS ' +
           'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL) ' +
           'ORDER BY RDB$TRIGGER_NAME;';

    FBConnManager.ExecuteQuery(Sql, Qry);
    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('TRIG_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetGenerators(List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RDB$GENERATOR_NAME) AS GEN_NAME ' +
           'FROM RDB$GENERATORS ' +
           'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL) ' +
           'ORDER BY RDB$GENERATOR_NAME;';

    FBConnManager.ExecuteQuery(Sql, Qry);
    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('GEN_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetPrimaryKeys(const ATableName: string; List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(ISeg.RDB$FIELD_NAME) AS PK_FIELD ' +
           'FROM RDB$RELATION_CONSTRAINTS RC ' +
           'JOIN RDB$INDEX_SEGMENTS ISeg ON RC.RDB$INDEX_NAME = ISeg.RDB$INDEX_NAME ' +
           'WHERE TRIM(RC.RDB$RELATION_NAME) = :TBL ' +
           '  AND RC.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' ' +
           'ORDER BY ISeg.RDB$FIELD_POSITION;';

    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Qry.SQL.Text := Sql;
    Qry.ParamByName('TBL').AsString := UpperCase(Trim(ATableName));
    Qry.Open;

    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('PK_FIELD').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.GetTableFieldNames(const ATableName: string; List: TStrings);
var
  Qry: TSQLQuery;
  Sql: string;
begin
  List.Clear;
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT TRIM(RF.RDB$FIELD_NAME) AS FLD_NAME ' +
           'FROM RDB$RELATION_FIELDS RF ' +
           'WHERE TRIM(RF.RDB$RELATION_NAME) = :TBL ' +
           'ORDER BY RF.RDB$FIELD_POSITION;';

    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Qry.SQL.Text := Sql;
    Qry.ParamByName('TBL').AsString := UpperCase(Trim(ATableName));
    Qry.Open;

    while not Qry.EOF do
    begin
      List.Add(Trim(Qry.FieldByName('FLD_NAME').AsString));
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TFBMetaDataExtractor.GetTableFields(const ATableName: string): TFBMetaFieldList;
var
  Qry: TSQLQuery;
  Sql: string;
  Idx: Integer;
  PKList: TStringList;
  FldName: string;
begin
  SetLength(Result, 0);
  if not FBConnManager.IsConnected then Exit;

  PKList := TStringList.Create;
  Qry := TSQLQuery.Create(nil);
  try
    GetPrimaryKeys(ATableName, PKList);

    Sql := 'SELECT ' +
           '  TRIM(RF.RDB$FIELD_NAME) AS FLD_NAME, ' +
           '  F.RDB$FIELD_TYPE AS FLD_TYPE, ' +
           '  F.RDB$FIELD_SUB_TYPE AS FLD_SUBTYPE, ' +
           '  F.RDB$FIELD_LENGTH AS FLD_LEN, ' +
           '  F.RDB$FIELD_SCALE AS FLD_SCALE, ' +
           '  RF.RDB$NULL_FLAG AS RF_NULL, ' +
           '  F.RDB$NULL_FLAG AS F_NULL, ' +
           '  RF.RDB$DEFAULT_SOURCE AS FLD_DEF ' +
           'FROM RDB$RELATION_FIELDS RF ' +
           'JOIN RDB$FIELDS F ON RF.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME ' +
           'WHERE TRIM(RF.RDB$RELATION_NAME) = :TBL ' +
           'ORDER BY RF.RDB$FIELD_POSITION;';

    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Qry.SQL.Text := Sql;
    Qry.ParamByName('TBL').AsString := UpperCase(Trim(ATableName));
    Qry.Open;

    Idx := 0;
    while not Qry.EOF do
    begin
      SetLength(Result, Idx + 1);
      FldName := Trim(Qry.FieldByName('FLD_NAME').AsString);
      Result[Idx].FieldName := FldName;
      Result[Idx].FieldType := Qry.FieldByName('FLD_TYPE').AsInteger;
      Result[Idx].FieldSubType := Qry.FieldByName('FLD_SUBTYPE').AsInteger;
      Result[Idx].FieldLength := Qry.FieldByName('FLD_LEN').AsInteger;
      Result[Idx].FieldScale := Qry.FieldByName('FLD_SCALE').AsInteger;
      Result[Idx].TypeName := TFBMetaTypeHelper.FirebirdTypeToString(
        Result[Idx].FieldType,
        Result[Idx].FieldSubType,
        Result[Idx].FieldLength,
        Result[Idx].FieldScale
      );
      Result[Idx].NotNull := (Qry.FieldByName('RF_NULL').AsInteger = 1) or
                             (Qry.FieldByName('F_NULL').AsInteger = 1);
      Result[Idx].IsPrimaryKey := (PKList.IndexOf(FldName) >= 0);
      Result[Idx].DefaultValue := Trim(Qry.FieldByName('FLD_DEF').AsString);

      Inc(Idx);
      Qry.Next;
    end;
  finally
    Qry.Free;
    PKList.Free;
  end;
end;

class function TFBMetaDataExtractor.GenerateCreateTableDDL(const ATableName: string): string;
var
  Flds: TFBMetaFieldList;
  I: Integer;
  PKList: TStringList;
  PKStr: string;
begin
  Flds := GetTableFields(ATableName);
  PKList := TStringList.Create;
  try
    GetPrimaryKeys(ATableName, PKList);

    Result := Format('CREATE TABLE %s (' + LineEnding, [UpperCase(Trim(ATableName))]);
    for I := 0 to High(Flds) do
    begin
      Result := Result + '  ' + Flds[I].FieldName + ' ' + Flds[I].TypeName;
      if Flds[I].DefaultValue <> '' then
        Result := Result + ' ' + Flds[I].DefaultValue;
      if Flds[I].NotNull then
        Result := Result + ' NOT NULL';
      if (I < High(Flds)) or (PKList.Count > 0) then
        Result := Result + ',' + LineEnding
      else
        Result := Result + LineEnding;
    end;

    if PKList.Count > 0 then
    begin
      PKStr := '';
      for I := 0 to PKList.Count - 1 do
      begin
        if I > 0 then PKStr := PKStr + ', ';
        PKStr := PKStr + PKList[I];
      end;
      Result := Result + Format('  CONSTRAINT PK_%s PRIMARY KEY (%s)' + LineEnding,
        [UpperCase(Trim(ATableName)), PKStr]);
    end;

    Result := Result + ');';
  finally
    PKList.Free;
  end;
end;

class function TFBMetaDataExtractor.GenerateDropTableSQL(const ATableName: string): string;
begin
  Result := Format('DROP TABLE %s', [UpperCase(Trim(ATableName))]);
end;

class function TFBMetaDataExtractor.GenerateSelectTopSQL(const ATableName: string; Limit: Integer): string;
begin
  Result := Format('SELECT FIRST %d * FROM %s', [Limit, UpperCase(Trim(ATableName))]);
end;

class function TFBMetaDataExtractor.BuildCreateTableSQL(const ATableName: string; const Cols: array of TColumnDef; Firebird3Plus: Boolean): string;
var
  I: Integer;
  PKNames: string;
  ColDef: string;
begin
  Result := Format('CREATE TABLE %s (' + LineEnding, [UpperCase(Trim(ATableName))]);
  PKNames := '';

  for I := 0 to High(Cols) do
  begin
    ColDef := TFBMetaTypeHelper.BuildColumnSQL(Cols[I], Firebird3Plus);
    Result := Result + '  ' + ColDef;

    if Cols[I].PrimaryKey then
    begin
      if PKNames <> '' then PKNames := PKNames + ', ';
      PKNames := PKNames + Trim(Cols[I].Name);
    end;

    if (I < High(Cols)) or (PKNames <> '') then
      Result := Result + ',' + LineEnding
    else
      Result := Result + LineEnding;
  end;

  if PKNames <> '' then
  begin
    Result := Result + Format('  CONSTRAINT PK_%s PRIMARY KEY (%s)' + LineEnding,
      [UpperCase(Trim(ATableName)), PKNames]);
  end;

  Result := Result + ');';
end;

class function TFBMetaDataExtractor.GetTableForeignKeys(const ATableName: string): TFBForeignKeyInfoList;
var
  Qry: TSQLQuery;
  Sql: string;
  Idx: Integer;
begin
  SetLength(Result, 0);
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Sql := 'SELECT ' +
           '  TRIM(RC.RDB$CONSTRAINT_NAME) AS FK_NAME, ' +
           '  TRIM(RC.RDB$RELATION_NAME) AS TBL_NAME, ' +
           '  TRIM(ISeg.RDB$FIELD_NAME) AS LOCAL_FLD, ' +
           '  TRIM(RefRC.RDB$RELATION_NAME) AS REF_TBL, ' +
           '  TRIM(RefISeg.RDB$FIELD_NAME) AS REF_FLD, ' +
           '  TRIM(RefC.RDB$UPDATE_RULE) AS UPD_RULE, ' +
           '  TRIM(RefC.RDB$DELETE_RULE) AS DEL_RULE ' +
           'FROM RDB$RELATION_CONSTRAINTS RC ' +
           'JOIN RDB$REF_CONSTRAINTS RefC ON RC.RDB$CONSTRAINT_NAME = RefC.RDB$CONSTRAINT_NAME ' +
           'JOIN RDB$RELATION_CONSTRAINTS RefRC ON RefC.RDB$CONST_NAME_UQ = RefRC.RDB$CONSTRAINT_NAME ' +
           'JOIN RDB$INDEX_SEGMENTS ISeg ON RC.RDB$INDEX_NAME = ISeg.RDB$INDEX_NAME ' +
           'JOIN RDB$INDEX_SEGMENTS RefISeg ON RefRC.RDB$INDEX_NAME = RefISeg.RDB$INDEX_NAME ' +
           '  AND ISeg.RDB$FIELD_POSITION = RefISeg.RDB$FIELD_POSITION ' +
           'WHERE RC.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'' ' +
           '  AND TRIM(RC.RDB$RELATION_NAME) = :TBL ' +
           'ORDER BY RC.RDB$CONSTRAINT_NAME, ISeg.RDB$FIELD_POSITION;';

    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Qry.SQL.Text := Sql;
    Qry.ParamByName('TBL').AsString := UpperCase(Trim(ATableName));
    Qry.Open;

    Idx := 0;
    while not Qry.EOF do
    begin
      SetLength(Result, Idx + 1);
      Result[Idx].ConstraintName := Trim(Qry.FieldByName('FK_NAME').AsString);
      Result[Idx].TableName      := Trim(Qry.FieldByName('TBL_NAME').AsString);
      Result[Idx].LocalField     := Trim(Qry.FieldByName('LOCAL_FLD').AsString);
      Result[Idx].RefTable       := Trim(Qry.FieldByName('REF_TBL').AsString);
      Result[Idx].RefField       := Trim(Qry.FieldByName('REF_FLD').AsString);
      Result[Idx].UpdateRule     := Trim(Qry.FieldByName('UPD_RULE').AsString);
      Result[Idx].DeleteRule     := Trim(Qry.FieldByName('DEL_RULE').AsString);
      Inc(Idx);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TFBMetaDataExtractor.DropConstraintSQL(const ATableName, AConstraintName: string): string;
begin
  Result := Format('ALTER TABLE %s DROP CONSTRAINT %s;', [UpperCase(Trim(ATableName)), UpperCase(Trim(AConstraintName))]);
end;

class function TFBMetaDataExtractor.AddForeignKeySQL(const ATableName: string; const FK: TForeignKeyDef): string;
begin
  Result := Format('ALTER TABLE %s ADD %s;',
    [UpperCase(Trim(ATableName)), TFBMetaTypeHelper.BuildForeignKeySQL(FK)]);
end;

class function TFBMetaDataExtractor.AddPrimaryKeySQL(const ATableName, APKName, APKFields: string): string;
var
  CName: string;
begin
  CName := UpperCase(Trim(APKName));
  if CName = '' then
    CName := 'PK_' + UpperCase(Trim(ATableName));
  Result := Format('ALTER TABLE %s ADD CONSTRAINT %s PRIMARY KEY (%s);',
    [UpperCase(Trim(ATableName)), CName, UpperCase(Trim(APKFields))]);
end;

class function TFBMetaDataExtractor.GetGeneratorValue(const AGenName: string): Int64;
var
  Qry: TSQLQuery;
  Sql: string;
begin
  Result := 0;
  if not FBConnManager.IsConnected then Exit;
  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Sql := Format('SELECT GEN_ID(%s, 0) AS CUR_VAL FROM RDB$DATABASE;', [UpperCase(Trim(AGenName))]);
    Qry.SQL.Text := Sql;
    Qry.Open;
    if not Qry.EOF then
      Result := Qry.FieldByName('CUR_VAL').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.SetGeneratorValue(const AGenName: string; AVal: Int64);
var
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.ExecuteDirect(Format('SET GENERATOR %s TO %d;', [UpperCase(Trim(AGenName)), AVal]), Rows);
end;

class procedure TFBMetaDataExtractor.CreateGenerator(const AGenName: string; AInitialVal: Int64);
var
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.ExecuteDirect(Format('CREATE SEQUENCE %s;', [UpperCase(Trim(AGenName))]), Rows);
  if AInitialVal <> 0 then
    SetGeneratorValue(AGenName, AInitialVal);
end;

class procedure TFBMetaDataExtractor.DropGenerator(const AGenName: string);
var
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.ExecuteDirect(Format('DROP SEQUENCE %s;', [UpperCase(Trim(AGenName))]), Rows);
end;

class function TFBMetaDataExtractor.GetTableIndices(const ATableName: string): TFBIndexInfoList;
var
  Qry: TSQLQuery;
  Sql: string;
  Idx: Integer;
  CurIdxName: string;
begin
  SetLength(Result, 0);
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Sql := 'SELECT TRIM(I.RDB$INDEX_NAME) AS IDX_NAME, ' +
           '       TRIM(I.RDB$RELATION_NAME) AS TBL_NAME, ' +
           '       I.RDB$UNIQUE_FLAG AS IS_UNIQUE, ' +
           '       I.RDB$INDEX_INACTIVE AS IS_INACTIVE, ' +
           '       I.RDB$INDEX_TYPE AS IDX_TYPE, ' +
           '       I.RDB$STATISTICS AS STATS, ' +
           '       TRIM(S.RDB$FIELD_NAME) AS FLD_NAME ' +
           'FROM RDB$INDICES I ' +
           'JOIN RDB$INDEX_SEGMENTS S ON I.RDB$INDEX_NAME = S.RDB$INDEX_NAME ' +
           'WHERE UPPER(TRIM(I.RDB$RELATION_NAME)) = :TBL ' +
           'ORDER BY I.RDB$INDEX_NAME, S.RDB$FIELD_POSITION;';
    Qry.SQL.Text := Sql;
    Qry.ParamByName('TBL').AsString := UpperCase(Trim(ATableName));
    Qry.Open;

    Idx := -1;
    CurIdxName := '';
    while not Qry.EOF do
    begin
      if Trim(Qry.FieldByName('IDX_NAME').AsString) <> CurIdxName then
      begin
        CurIdxName := Trim(Qry.FieldByName('IDX_NAME').AsString);
        Inc(Idx);
        SetLength(Result, Idx + 1);
        Result[Idx].IndexName := CurIdxName;
        Result[Idx].TableName := Trim(Qry.FieldByName('TBL_NAME').AsString);
        Result[Idx].IsUnique := (Qry.FieldByName('IS_UNIQUE').AsInteger = 1);
        Result[Idx].IsDescending := (Qry.FieldByName('IDX_TYPE').AsInteger = 1);
        Result[Idx].IsActive := (Qry.FieldByName('IS_INACTIVE').AsInteger = 0);
        Result[Idx].Selectivity := Qry.FieldByName('STATS').AsFloat;
        Result[Idx].Fields := Trim(Qry.FieldByName('FLD_NAME').AsString);
      end
      else
      begin
        Result[Idx].Fields := Result[Idx].Fields + ', ' + Trim(Qry.FieldByName('FLD_NAME').AsString);
      end;
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.RecalculateIndexStatistics(const AIndexName: string);
var
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.ExecuteDirect(Format('SET STATISTICS INDEX %s;', [UpperCase(Trim(AIndexName))]), Rows);
  FBConnManager.Transaction.CommitRetaining;
end;

class procedure TFBMetaDataExtractor.CreateIndex(const AIndexName, ATableName, AFields: string; AUnique, ADescending: Boolean);
var
  Sql: string;
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  Sql := 'CREATE ';
  if AUnique then Sql := Sql + 'UNIQUE ';
  if ADescending then Sql := Sql + 'DESCENDING ';
  Sql := Sql + Format('INDEX %s ON %s (%s);', [UpperCase(Trim(AIndexName)), UpperCase(Trim(ATableName)), UpperCase(Trim(AFields))]);
  FBConnManager.ExecuteDirect(Sql, Rows);
  FBConnManager.Transaction.CommitRetaining;
end;

class procedure TFBMetaDataExtractor.DropIndex(const AIndexName: string);
var
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.ExecuteDirect(Format('DROP INDEX %s;', [UpperCase(Trim(AIndexName))]), Rows);
  FBConnManager.Transaction.CommitRetaining;
end;

class function TFBMetaDataExtractor.GetProcedureSource(const AProcName: string): string;
var
  Qry: TSQLQuery;
  Sql: string;
begin
  Result := '';
  if not FBConnManager.IsConnected then Exit;
  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Sql := 'SELECT RDB$PROCEDURE_SOURCE FROM RDB$PROCEDURES WHERE UPPER(TRIM(RDB$PROCEDURE_NAME)) = :NAME;';
    Qry.SQL.Text := Sql;
    Qry.ParamByName('NAME').AsString := UpperCase(Trim(AProcName));
    Qry.Open;
    if not Qry.EOF then
      Result := Trim(Qry.FieldByName('RDB$PROCEDURE_SOURCE').AsString);
  finally
    Qry.Free;
  end;
end;

class function TFBMetaDataExtractor.GetTriggerSource(const ATrigName: string): string;
var
  Qry: TSQLQuery;
  Sql: string;
begin
  Result := '';
  if not FBConnManager.IsConnected then Exit;
  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Sql := 'SELECT RDB$TRIGGER_SOURCE FROM RDB$TRIGGERS WHERE UPPER(TRIM(RDB$TRIGGER_NAME)) = :NAME;';
    Qry.SQL.Text := Sql;
    Qry.ParamByName('NAME').AsString := UpperCase(Trim(ATrigName));
    Qry.Open;
    if not Qry.EOF then
      Result := Trim(Qry.FieldByName('RDB$TRIGGER_SOURCE').AsString);
  finally
    Qry.Free;
  end;
end;

class function TFBMetaDataExtractor.GetDatabaseHealthInfo: TFBDatabaseHealthInfo;
var
  Qry: TSQLQuery;
  Sql: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FBConnManager.IsConnected then Exit;

  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := FBConnManager.Connection;
    Qry.Transaction := FBConnManager.Transaction;
    Sql := 'SELECT MON$PAGE_SIZE, MON$PAGE_BUFFERS, MON$SWEEP_INTERVAL, ' +
           '       MON$OLDEST_TRANSACTION, MON$OLDEST_ACTIVE, MON$OLDEST_SNAPSHOT, MON$NEXT_TRANSACTION ' +
           'FROM MON$DATABASE;';
    Qry.SQL.Text := Sql;
    Qry.Open;
    if not Qry.EOF then
    begin
      Result.PageSize := Qry.FieldByName('MON$PAGE_SIZE').AsInteger;
      Result.PageBuffers := Qry.FieldByName('MON$PAGE_BUFFERS').AsInteger;
      Result.SweepInterval := Qry.FieldByName('MON$SWEEP_INTERVAL').AsInteger;
      Result.OIT := Qry.FieldByName('MON$OLDEST_TRANSACTION').AsLargeInt;
      Result.OAT := Qry.FieldByName('MON$OLDEST_ACTIVE').AsLargeInt;
      Result.OST := Qry.FieldByName('MON$OLDEST_SNAPSHOT').AsLargeInt;
      Result.NextTransaction := Qry.FieldByName('MON$NEXT_TRANSACTION').AsLargeInt;
      Result.Difference := Result.NextTransaction - Result.OAT;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TFBMetaDataExtractor.ExecuteSweep;
begin
  if not FBConnManager.IsConnected then Exit;
  FBConnManager.Commit;
  FBConnManager.Transaction.StartTransaction;
  FBConnManager.Commit;
end;

class function TFBMetaDataExtractor.ExtractFullDatabaseDDL: string;
var
  SB: TStringList;
  TblList, GenList, ProcList, TrigList: TStringList;
  I: Integer;
  Tbl, Src: string;
  FKs: TFBForeignKeyInfoList;
  J: Integer;
begin
  Result := '';
  if not FBConnManager.IsConnected then Exit;

  SB := TStringList.Create;
  TblList := TStringList.Create;
  GenList := TStringList.Create;
  ProcList := TStringList.Create;
  TrigList := TStringList.Create;
  try
    SB.Add('/* ================================================================ */');
    SB.Add('/* SCRIPT DDL COMPLETO GERADO POR LAZARUS DATABASE EXPLORER         */');
    SB.Add('/* Data/Hora: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '                      */');
    SB.Add('/* Banco: ' + FBConnManager.CurrentConfig.DatabasePath + ' */');
    SB.Add('/* ================================================================ */' + LineEnding);

    // 1. Sequences / Generators
    GetGenerators(GenList);
    if GenList.Count > 0 then
    begin
      SB.Add('/* --- SEQUENCES / GENERATORS --- */');
      for I := 0 to GenList.Count - 1 do
        SB.Add(Format('CREATE SEQUENCE %s;', [GenList[I]]));
      SB.Add('');
    end;

    // 2. Tabelas
    GetTables(TblList, False);
    if TblList.Count > 0 then
    begin
      SB.Add('/* --- TABELAS --- */');
      for I := 0 to TblList.Count - 1 do
      begin
        Tbl := TblList[I];
        SB.Add(GenerateCreateTableDDL(Tbl));
        SB.Add('');
      end;
    end;

    // 3. Foreign Keys (Chaves Estrangeiras)
    SB.Add('/* --- CHAVES ESTRANGEIRAS --- */');
    for I := 0 to TblList.Count - 1 do
    begin
      Tbl := TblList[I];
      FKs := GetTableForeignKeys(Tbl);
      for J := 0 to High(FKs) do
      begin
        SB.Add(Format('ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s);',
          [Tbl, FKs[J].ConstraintName, FKs[J].LocalField, FKs[J].RefTable, FKs[J].RefField]));
      end;
    end;
    SB.Add('');

    // 4. Stored Procedures
    GetProcedures(ProcList);
    if ProcList.Count > 0 then
    begin
      SB.Add('/* --- PROCEDURES (CORPO PSQL) --- */');
      SB.Add('SET TERM ^ ;' + LineEnding);
      for I := 0 to ProcList.Count - 1 do
      begin
        Src := GetProcedureSource(ProcList[I]);
        if Src <> '' then
        begin
          SB.Add('CREATE OR ALTER PROCEDURE ' + ProcList[I]);
          SB.Add(Src + ' ^' + LineEnding);
        end;
      end;
      SB.Add('SET TERM ; ^' + LineEnding);
    end;

    // 5. Triggers
    GetTriggers(TrigList);
    if TrigList.Count > 0 then
    begin
      SB.Add('/* --- TRIGGERS (CORPO PSQL) --- */');
      SB.Add('SET TERM ^ ;' + LineEnding);
      for I := 0 to TrigList.Count - 1 do
      begin
        Src := GetTriggerSource(TrigList[I]);
        if Src <> '' then
        begin
          SB.Add('/* Trigger: ' + TrigList[I] + ' */');
          SB.Add(Src + ' ^' + LineEnding);
        end;
      end;
      SB.Add('SET TERM ; ^' + LineEnding);
    end;

    Result := SB.Text;
  finally
    SB.Free;
    TblList.Free;
    GenList.Free;
    ProcList.Free;
    TrigList.Free;
  end;
end;

end.
