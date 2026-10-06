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

    { DDL Generators }
    class function GenerateCreateTableDDL(const ATableName: string): string;
    class function GenerateDropTableSQL(const ATableName: string): string;
    class function GenerateSelectTopSQL(const ATableName: string; Limit: Integer = 100): string;
    class function BuildCreateTableSQL(const ATableName: string; const Cols: array of TColumnDef; Firebird3Plus: Boolean = True): string;
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

end.
