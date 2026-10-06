unit uFBConstraintForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Grids, CheckLst, Clipbrd,
  uFBTypes, uFBConnectionManager, uFBMetaData;

type
  { TFBConstraintForm }
  TFBConstraintForm = class(TForm)
    PanelTop: TPanel;
    LabelTitle: TLabel;
    LabelTable: TLabel;
    ComboTables: TComboBox;
    BtnRefresh: TButton;

    PageControlMain: TPageControl;

    { Aba 1: Chaves Estrangeiras (FK) }
    TabSheetFK: TTabSheet;
    PanelFKExisting: TPanel;
    LabelExistingFKs: TLabel;
    GridExistingFKs: TStringGrid;
    PanelExistingFKTools: TPanel;
    BtnNewFK: TButton;
    BtnDropSelectedFK: TButton;

    GroupBoxFKEditor: TGroupBox;
    LabelFKName: TLabel;
    EditFKName: TEdit;
    BtnSuggestFKName: TButton;
    LabelRefTable: TLabel;
    ComboRefTable: TComboBox;

    GroupBoxMapping: TGroupBox;
    LabelLocalField: TLabel;
    ComboLocalField: TComboBox;
    LabelArrow: TLabel;
    LabelRefField: TLabel;
    ComboRefField: TComboBox;

    GroupBoxRules: TGroupBox;
    LabelOnUpdate: TLabel;
    ComboOnUpdate: TComboBox;
    LabelOnDelete: TLabel;
    ComboOnDelete: TComboBox;

    GroupBoxFKDDL: TGroupBox;
    MemoFKDDL: TMemo;
    PanelFKActions: TPanel;
    BtnExecuteFK: TButton;
    BtnCopyFKDDL: TButton;

    { Aba 2: Chave Primária (PK) }
    TabSheetPK: TTabSheet;
    GroupBoxCurrentPK: TGroupBox;
    LabelCurrentPKStatus: TLabel;
    BtnDropPK: TButton;

    GroupBoxNewPK: TGroupBox;
    LabelPKName: TLabel;
    EditPKName: TEdit;
    BtnSuggestPKName: TButton;
    LabelPKFieldsHint: TLabel;
    CheckListPKFields: TCheckListBox;
    LabelPKNote: TLabel;

    GroupBoxPKDDL: TGroupBox;
    MemoPKDDL: TMemo;
    PanelPKActions: TPanel;
    BtnExecutePK: TButton;
    BtnCopyPKDDL: TButton;

    { Rodapé }
    PanelBottom: TPanel;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure ComboTablesChange(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);

    { Eventos FK }
    procedure BtnNewFKClick(Sender: TObject);
    procedure BtnDropSelectedFKClick(Sender: TObject);
    procedure BtnSuggestFKNameClick(Sender: TObject);
    procedure ComboRefTableChange(Sender: TObject);
    procedure ComboLocalFieldChange(Sender: TObject);
    procedure ComboRefFieldChange(Sender: TObject);
    procedure ComboOnUpdateChange(Sender: TObject);
    procedure ComboOnDeleteChange(Sender: TObject);
    procedure EditFKNameChange(Sender: TObject);
    procedure GridExistingFKsSelection(Sender: TObject; aCol, aRow: Integer);
    procedure BtnExecuteFKClick(Sender: TObject);
    procedure BtnCopyFKDDLClick(Sender: TObject);

    { Eventos PK }
    procedure BtnDropPKClick(Sender: TObject);
    procedure BtnSuggestPKNameClick(Sender: TObject);
    procedure CheckListPKFieldsClickCheck(Sender: TObject);
    procedure EditPKNameChange(Sender: TObject);
    procedure BtnExecutePKClick(Sender: TObject);
    procedure BtnCopyPKDDLClick(Sender: TObject);
  private
    FCurrentPKConstraintName: string;
    procedure SetupFKGridHeaders;
    procedure LoadTablesList;
    procedure LoadTableData(const ATableName: string);
    procedure LoadExistingFKs(const ATableName: string);
    procedure LoadCurrentPK(const ATableName: string);
    procedure PopulateRefFields(const ARefTableName: string);
    procedure SuggestFKName;
    procedure SuggestPKName;
    procedure UpdateFKDDL;
    procedure UpdatePKDDL;
    function BuildFKDefinition: TForeignKeyDef;
    function GetSelectedPKFields: string;
  public
    class function Execute(const InitialTableName: string = ''): Boolean;
  end;

implementation

{$R *.lfm}

const
  FK_GRID_NAME    = 0;
  FK_GRID_LOCAL   = 1;
  FK_GRID_REFTBL  = 2;
  FK_GRID_REFCOL  = 3;
  FK_GRID_ONUPD   = 4;
  FK_GRID_ONDEL   = 5;

{ TFBConstraintForm }

procedure TFBConstraintForm.FormCreate(Sender: TObject);
begin
  SetupFKGridHeaders;

  ComboOnUpdate.Items.Clear;
  ComboOnUpdate.Items.Add('NO ACTION');
  ComboOnUpdate.Items.Add('CASCADE');
  ComboOnUpdate.Items.Add('SET NULL');
  ComboOnUpdate.Items.Add('SET DEFAULT');
  ComboOnUpdate.Items.Add('RESTRICT');
  ComboOnUpdate.ItemIndex := 0;

  ComboOnDelete.Items.Clear;
  ComboOnDelete.Items.Add('NO ACTION');
  ComboOnDelete.Items.Add('CASCADE');
  ComboOnDelete.Items.Add('SET NULL');
  ComboOnDelete.Items.Add('SET DEFAULT');
  ComboOnDelete.Items.Add('RESTRICT');
  ComboOnDelete.ItemIndex := 0;

  LoadTablesList;
end;

procedure TFBConstraintForm.SetupFKGridHeaders;
begin
  GridExistingFKs.ColCount := 6;
  GridExistingFKs.RowCount := 1;

  GridExistingFKs.Cells[FK_GRID_NAME, 0]   := 'Nome da FK';
  GridExistingFKs.Cells[FK_GRID_LOCAL, 0]  := 'Campo Local';
  GridExistingFKs.Cells[FK_GRID_REFTBL, 0] := 'Tabela Referenciada';
  GridExistingFKs.Cells[FK_GRID_REFCOL, 0] := 'Campo Referenciado';
  GridExistingFKs.Cells[FK_GRID_ONUPD, 0]  := 'ON UPDATE';
  GridExistingFKs.Cells[FK_GRID_ONDEL, 0]  := 'ON DELETE';

  GridExistingFKs.ColWidths[FK_GRID_NAME]   := 160;
  GridExistingFKs.ColWidths[FK_GRID_LOCAL]  := 120;
  GridExistingFKs.ColWidths[FK_GRID_REFTBL] := 140;
  GridExistingFKs.ColWidths[FK_GRID_REFCOL] := 120;
  GridExistingFKs.ColWidths[FK_GRID_ONUPD]  := 90;
  GridExistingFKs.ColWidths[FK_GRID_ONDEL]  := 90;
end;

procedure TFBConstraintForm.LoadTablesList;
var
  CurTbl: string;
begin
  if not FBConnManager.IsConnected then Exit;

  CurTbl := ComboTables.Text;
  ComboTables.Items.BeginUpdate;
  ComboRefTable.Items.BeginUpdate;
  try
    ComboTables.Items.Clear;
    ComboRefTable.Items.Clear;
    TFBMetaDataExtractor.GetTables(ComboTables.Items, False);
    ComboRefTable.Items.Assign(ComboTables.Items);
  finally
    ComboTables.Items.EndUpdate;
    ComboRefTable.Items.EndUpdate;
  end;

  if (CurTbl <> '') and (ComboTables.Items.IndexOf(CurTbl) >= 0) then
    ComboTables.Text := CurTbl
  else if ComboTables.Items.Count > 0 then
    ComboTables.ItemIndex := 0;

  if ComboTables.Text <> '' then
    LoadTableData(ComboTables.Text);
end;

procedure TFBConstraintForm.LoadTableData(const ATableName: string);
var
  Tbl: string;
  Flds: TFBMetaFieldList;
  I: Integer;
begin
  Tbl := UpperCase(Trim(ATableName));
  if Tbl = '' then Exit;

  // Carrega campos locais da tabela
  ComboLocalField.Items.BeginUpdate;
  CheckListPKFields.Items.BeginUpdate;
  try
    ComboLocalField.Items.Clear;
    CheckListPKFields.Items.Clear;
    Flds := TFBMetaDataExtractor.GetTableFields(Tbl);
    for I := 0 to High(Flds) do
    begin
      ComboLocalField.Items.Add(Flds[I].FieldName);
      CheckListPKFields.Items.Add(Flds[I].FieldName);
    end;
  finally
    ComboLocalField.Items.EndUpdate;
    CheckListPKFields.Items.EndUpdate;
  end;

  if ComboLocalField.Items.Count > 0 then
    ComboLocalField.ItemIndex := 0;

  LoadExistingFKs(Tbl);
  LoadCurrentPK(Tbl);
  SuggestFKName;
  SuggestPKName;
  UpdateFKDDL;
  UpdatePKDDL;
end;

procedure TFBConstraintForm.LoadExistingFKs(const ATableName: string);
var
  FKList: TFBForeignKeyInfoList;
  I: Integer;
begin
  GridExistingFKs.RowCount := 1;
  FKList := TFBMetaDataExtractor.GetTableForeignKeys(ATableName);

  for I := 0 to High(FKList) do
  begin
    GridExistingFKs.RowCount := GridExistingFKs.RowCount + 1;
    GridExistingFKs.Cells[FK_GRID_NAME, I + 1]   := FKList[I].ConstraintName;
    GridExistingFKs.Cells[FK_GRID_LOCAL, I + 1]  := FKList[I].LocalField;
    GridExistingFKs.Cells[FK_GRID_REFTBL, I + 1] := FKList[I].RefTable;
    GridExistingFKs.Cells[FK_GRID_REFCOL, I + 1] := FKList[I].RefField;
    GridExistingFKs.Cells[FK_GRID_ONUPD, I + 1]  := FKList[I].UpdateRule;
    GridExistingFKs.Cells[FK_GRID_ONDEL, I + 1]  := FKList[I].DeleteRule;
  end;
end;

procedure TFBConstraintForm.LoadCurrentPK(const ATableName: string);
var
  PKList: TStringList;
  I, FldIdx: Integer;
  PKStr: string;
begin
  FCurrentPKConstraintName := '';
  PKList := TStringList.Create;
  try
    TFBMetaDataExtractor.GetPrimaryKeys(ATableName, PKList);
    if PKList.Count > 0 then
    begin
      PKStr := '';
      for I := 0 to PKList.Count - 1 do
      begin
        if I > 0 then PKStr := PKStr + ', ';
        PKStr := PKStr + PKList[I];

        // Marca no checklist
        FldIdx := CheckListPKFields.Items.IndexOf(PKList[I]);
        if FldIdx >= 0 then
          CheckListPKFields.Checked[FldIdx] := True;
      end;
      FCurrentPKConstraintName := 'PK_' + UpperCase(Trim(ATableName));
      LabelCurrentPKStatus.Caption := Format('Chave Primária Atual: %s (%s)', [FCurrentPKConstraintName, PKStr]);
      LabelCurrentPKStatus.Font.Color := clNavy;
      BtnDropPK.Enabled := True;
    end
    else
    begin
      LabelCurrentPKStatus.Caption := 'Nenhuma Chave Primária (PRIMARY KEY) definida nesta tabela.';
      LabelCurrentPKStatus.Font.Color := clGray;
      BtnDropPK.Enabled := False;
    end;
  finally
    PKList.Free;
  end;
end;

procedure TFBConstraintForm.PopulateRefFields(const ARefTableName: string);
var
  PKList: TStringList;
  Tbl: string;
begin
  Tbl := UpperCase(Trim(ARefTableName));
  if Tbl = '' then Exit;

  ComboRefField.Items.BeginUpdate;
  try
    ComboRefField.Items.Clear;
    TFBMetaDataExtractor.GetTableFieldNames(Tbl, ComboRefField.Items);
  finally
    ComboRefField.Items.EndUpdate;
  end;

  PKList := TStringList.Create;
  try
    TFBMetaDataExtractor.GetPrimaryKeys(Tbl, PKList);
    if PKList.Count > 0 then
      ComboRefField.Text := PKList[0]
    else if ComboRefField.Items.Count > 0 then
      ComboRefField.ItemIndex := 0
    else
      ComboRefField.Text := 'ID';
  finally
    PKList.Free;
  end;
end;

procedure TFBConstraintForm.SuggestFKName;
var
  Tbl, LocalCol, RefTbl, Proposed: string;
begin
  Tbl := UpperCase(Trim(ComboTables.Text));
  LocalCol := UpperCase(Trim(ComboLocalField.Text));
  RefTbl := UpperCase(Trim(ComboRefTable.Text));

  if RefTbl <> '' then
    Proposed := Format('FK_%s_%s', [Tbl, RefTbl])
  else if LocalCol <> '' then
    Proposed := Format('FK_%s_%s', [Tbl, LocalCol])
  else
    Proposed := Format('FK_%s_1', [Tbl]);

  if Length(Proposed) > 31 then
    Proposed := Copy(Proposed, 1, 31);

  EditFKName.Text := Proposed;
end;

procedure TFBConstraintForm.SuggestPKName;
var
  Tbl, Proposed: string;
begin
  Tbl := UpperCase(Trim(ComboTables.Text));
  Proposed := 'PK_' + Tbl;
  if Length(Proposed) > 31 then
    Proposed := Copy(Proposed, 1, 31);
  EditPKName.Text := Proposed;
end;

function TFBConstraintForm.BuildFKDefinition: TForeignKeyDef;
begin
  Result.ConstraintName := UpperCase(Trim(EditFKName.Text));
  Result.ColumnName     := UpperCase(Trim(ComboLocalField.Text));
  Result.RefTable       := UpperCase(Trim(ComboRefTable.Text));
  Result.RefColumn      := UpperCase(Trim(ComboRefField.Text));
  Result.OnUpdate       := UpperCase(Trim(ComboOnUpdate.Text));
  Result.OnDelete       := UpperCase(Trim(ComboOnDelete.Text));
end;

procedure TFBConstraintForm.UpdateFKDDL;
var
  FK: TForeignKeyDef;
begin
  FK := BuildFKDefinition;
  if (FK.ColumnName <> '') and (FK.RefTable <> '') then
  begin
    if FK.RefColumn = '' then FK.RefColumn := 'ID';
    MemoFKDDL.Text := TFBMetaDataExtractor.AddForeignKeySQL(ComboTables.Text, FK);
  end
  else
    MemoFKDDL.Text := '-- Selecione o campo local e a tabela de destino para gerar o DDL.';
end;

function TFBConstraintForm.GetSelectedPKFields: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to CheckListPKFields.Items.Count - 1 do
  begin
    if CheckListPKFields.Checked[I] then
    begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + CheckListPKFields.Items[I];
    end;
  end;
end;

procedure TFBConstraintForm.UpdatePKDDL;
var
  Flds: string;
begin
  Flds := GetSelectedPKFields;
  if Flds <> '' then
    MemoPKDDL.Text := TFBMetaDataExtractor.AddPrimaryKeySQL(ComboTables.Text, EditPKName.Text, Flds)
  else
    MemoPKDDL.Text := '-- Marque um ou mais campos acima para compor a Chave Primária.';
end;

procedure TFBConstraintForm.ComboTablesChange(Sender: TObject);
begin
  LoadTableData(ComboTables.Text);
end;

procedure TFBConstraintForm.BtnRefreshClick(Sender: TObject);
begin
  LoadTablesList;
end;

procedure TFBConstraintForm.BtnNewFKClick(Sender: TObject);
begin
  EditFKName.Text := '';
  if ComboLocalField.Items.Count > 0 then
    ComboLocalField.ItemIndex := 0;
  if ComboRefTable.Items.Count > 0 then
    ComboRefTable.ItemIndex := 0;
  ComboRefTableChange(nil);
  SuggestFKName;
  UpdateFKDDL;
end;

procedure TFBConstraintForm.BtnDropSelectedFKClick(Sender: TObject);
var
  R: Integer;
  FKName, Sql: string;
  Rows: Integer;
begin
  R := GridExistingFKs.Row;
  if (R < 1) or (R >= GridExistingFKs.RowCount) then
  begin
    ShowMessage('Selecione uma Chave Estrangeira na grade para excluir.');
    Exit;
  end;

  FKName := Trim(GridExistingFKs.Cells[FK_GRID_NAME, R]);
  if FKName = '' then Exit;

  if MessageDlg('Confirmação de Exclusão',
     Format('Deseja realmente excluir a restrição "%s" da tabela "%s"?', [FKName, ComboTables.Text]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Sql := TFBMetaDataExtractor.DropConstraintSQL(ComboTables.Text, FKName);
  try
    FBConnManager.ExecuteDirect(Sql, Rows);
    ShowMessage(Format('Chave Estrangeira "%s" removida com sucesso!', [FKName]));
    LoadExistingFKs(ComboTables.Text);
  except
    on E: Exception do
      ShowMessage('Erro ao remover Chave Estrangeira: ' + LineEnding + E.Message);
  end;
end;

procedure TFBConstraintForm.BtnSuggestFKNameClick(Sender: TObject);
begin
  SuggestFKName;
  UpdateFKDDL;
end;

procedure TFBConstraintForm.ComboRefTableChange(Sender: TObject);
begin
  PopulateRefFields(ComboRefTable.Text);
  SuggestFKName;
  UpdateFKDDL;
end;

procedure TFBConstraintForm.ComboLocalFieldChange(Sender: TObject);
var
  ColName, GuessedTbl: string;
  I: Integer;
begin
  ColName := UpperCase(Trim(ComboLocalField.Text));
  if ColName <> '' then
  begin
    GuessedTbl := '';
    if EndsText('_ID', ColName) then
      GuessedTbl := Copy(ColName, 1, Length(ColName) - 3)
    else if StartsText('ID_', ColName) then
      GuessedTbl := Copy(ColName, 4, Length(ColName))
    else if StartsText('COD_', ColName) then
      GuessedTbl := Copy(ColName, 5, Length(ColName));

    if GuessedTbl <> '' then
    begin
      for I := 0 to ComboRefTable.Items.Count - 1 do
      begin
        if SameText(ComboRefTable.Items[I], GuessedTbl) or
           SameText(ComboRefTable.Items[I], GuessedTbl + 'S') or
           SameText(ComboRefTable.Items[I], GuessedTbl + 'ES') then
        begin
          ComboRefTable.ItemIndex := I;
          PopulateRefFields(ComboRefTable.Text);
          Break;
        end;
      end;
    end;
  end;

  SuggestFKName;
  UpdateFKDDL;
end;

procedure TFBConstraintForm.ComboRefFieldChange(Sender: TObject);
begin
  UpdateFKDDL;
end;

procedure TFBConstraintForm.ComboOnUpdateChange(Sender: TObject);
begin
  UpdateFKDDL;
end;

procedure TFBConstraintForm.ComboOnDeleteChange(Sender: TObject);
begin
  UpdateFKDDL;
end;

procedure TFBConstraintForm.EditFKNameChange(Sender: TObject);
begin
  UpdateFKDDL;
end;

procedure TFBConstraintForm.GridExistingFKsSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aRow > 0) and (aRow < GridExistingFKs.RowCount) then
  begin
    EditFKName.Text := GridExistingFKs.Cells[FK_GRID_NAME, aRow];
    ComboLocalField.Text := GridExistingFKs.Cells[FK_GRID_LOCAL, aRow];
    ComboRefTable.Text := GridExistingFKs.Cells[FK_GRID_REFTBL, aRow];
    PopulateRefFields(ComboRefTable.Text);
    ComboRefField.Text := GridExistingFKs.Cells[FK_GRID_REFCOL, aRow];
    ComboOnUpdate.Text := GridExistingFKs.Cells[FK_GRID_ONUPD, aRow];
    ComboOnDelete.Text := GridExistingFKs.Cells[FK_GRID_ONDEL, aRow];
    UpdateFKDDL;
  end;
end;

procedure TFBConstraintForm.BtnExecuteFKClick(Sender: TObject);
var
  Sql: string;
  Rows: Integer;
begin
  Sql := Trim(MemoFKDDL.Text);
  if (Sql = '') or StartsText('--', Sql) then
  begin
    ShowMessage('Defina os parâmetros da Chave Estrangeira antes de executar.');
    Exit;
  end;

  if MessageDlg('Executar DDL',
     'Deseja criar a Chave Estrangeira no banco de dados agora?' + LineEnding + LineEnding + Sql,
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      FBConnManager.ExecuteDirect(Sql, Rows);
      ShowMessage('Chave Estrangeira criada com sucesso no Firebird!');
      LoadExistingFKs(ComboTables.Text);
    except
      on E: Exception do
        ShowMessage('Erro ao criar Chave Estrangeira: ' + LineEnding + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBConstraintForm.BtnCopyFKDDLClick(Sender: TObject);
begin
  Clipboard.AsText := MemoFKDDL.Text;
  ShowMessage('DDL copiado para a área de transferência!');
end;

procedure TFBConstraintForm.BtnDropPKClick(Sender: TObject);
var
  Sql: string;
  Rows: Integer;
begin
  if FCurrentPKConstraintName = '' then
  begin
    ShowMessage('Nenhuma chave primária para remover.');
    Exit;
  end;

  if MessageDlg('Confirmação',
     Format('Deseja realmente remover a chave primária "%s" da tabela "%s"?' + LineEnding +
            'Atenção: Outras tabelas que referenciam essa chave como Foreign Key podem impedir a exclusão.',
            [FCurrentPKConstraintName, ComboTables.Text]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Sql := TFBMetaDataExtractor.DropConstraintSQL(ComboTables.Text, FCurrentPKConstraintName);
  try
    FBConnManager.ExecuteDirect(Sql, Rows);
    ShowMessage('Chave Primária removida com sucesso!');
    LoadCurrentPK(ComboTables.Text);
  except
    on E: Exception do
      ShowMessage('Erro ao remover Chave Primária: ' + LineEnding + E.Message);
  end;
end;

procedure TFBConstraintForm.BtnSuggestPKNameClick(Sender: TObject);
begin
  SuggestPKName;
  UpdatePKDDL;
end;

procedure TFBConstraintForm.CheckListPKFieldsClickCheck(Sender: TObject);
begin
  UpdatePKDDL;
end;

procedure TFBConstraintForm.EditPKNameChange(Sender: TObject);
begin
  UpdatePKDDL;
end;

procedure TFBConstraintForm.BtnExecutePKClick(Sender: TObject);
var
  Sql: string;
  Rows: Integer;
begin
  Sql := Trim(MemoPKDDL.Text);
  if (Sql = '') or StartsText('--', Sql) then
  begin
    ShowMessage('Selecione ao menos um campo para compor a Chave Primária.');
    Exit;
  end;

  if MessageDlg('Executar DDL',
     'Deseja criar a Chave Primária no banco de dados agora?' + LineEnding + LineEnding + Sql,
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      FBConnManager.ExecuteDirect(Sql, Rows);
      ShowMessage('Chave Primária criada com sucesso no Firebird!');
      LoadCurrentPK(ComboTables.Text);
    except
      on E: Exception do
        ShowMessage('Erro ao criar Chave Primária: ' + LineEnding + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBConstraintForm.BtnCopyPKDDLClick(Sender: TObject);
begin
  Clipboard.AsText := MemoPKDDL.Text;
  ShowMessage('DDL copiado para a área de transferência!');
end;

class function TFBConstraintForm.Execute(const InitialTableName: string): Boolean;
var
  Frm: TFBConstraintForm;
begin
  Frm := TFBConstraintForm.Create(nil);
  try
    if InitialTableName <> '' then
    begin
      Frm.ComboTables.Text := UpperCase(Trim(InitialTableName));
      Frm.LoadTableData(Frm.ComboTables.Text);
    end;
    Result := (Frm.ShowModal = mrOk);
  finally
    Frm.Free;
  end;
end;

end.
