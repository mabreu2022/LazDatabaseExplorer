unit uFBCreateTableForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Grids, Clipbrd,
  uFBTypes, uFBConnectionManager, uFBMetaData, uFBConstraintForm;

type
  { TFBCreateTableForm }
  TFBCreateTableForm = class(TForm)
    PanelTop: TPanel;
    LabelTableName: TLabel;
    EditTableName: TEdit;
    ChkFB3Identity: TCheckBox;
    BtnTemplateAudit: TButton;

    PageControlMain: TPageControl;

    { Aba 1: Colunas }
    TabSheetColumns: TTabSheet;
    PanelGridTools: TPanel;
    BtnAddCol: TButton;
    BtnDelCol: TButton;
    BtnMoveUp: TButton;
    BtnMoveDown: TButton;
    BtnCreateFKForCol: TButton;
    GridColumns: TStringGrid;

    { Aba 2: Chaves Estrangeiras (FK) }
    TabSheetFK: TTabSheet;
    GroupBoxFKEdit: TGroupBox;
    LabelFKName: TLabel;
    EditFKName: TEdit;
    BtnFKSuggestName: TButton;
    LabelFKRefTable: TLabel;
    ComboFKRefTable: TComboBox;
    LabelFKLocalCol: TLabel;
    ComboFKLocalCol: TComboBox;
    LabelArrow: TLabel;
    LabelFKRefCol: TLabel;
    ComboFKRefCol: TComboBox;
    LabelFKOnUpdate: TLabel;
    ComboFKOnUpdate: TComboBox;
    LabelFKOnDelete: TLabel;
    ComboFKOnDelete: TComboBox;
    BtnFKAddOrUpdate: TButton;
    BtnFKClear: TButton;
    PanelFKTools: TPanel;
    BtnFKDelete: TButton;
    BtnOpenConstraintManager: TButton;
    LabelFKHint: TLabel;
    GridFKs: TStringGrid;

    { Aba 3: Script Preview }
    TabSheetPreview: TTabSheet;
    MemoSQLPreview: TMemo;

    { Rodapé }
    PanelBottom: TPanel;
    BtnExecute: TButton;
    BtnCopySQL: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure PageControlMainChange(Sender: TObject);
    procedure BtnAddColClick(Sender: TObject);
    procedure BtnDelColClick(Sender: TObject);
    procedure BtnMoveUpClick(Sender: TObject);
    procedure BtnMoveDownClick(Sender: TObject);
    procedure BtnCreateFKForColClick(Sender: TObject);
    procedure BtnTemplateAuditClick(Sender: TObject);
    procedure EditTableNameChange(Sender: TObject);
    procedure ChkFB3IdentityChange(Sender: TObject);
    procedure GridColumnsEditingDone(Sender: TObject);
    procedure BtnFKSuggestNameClick(Sender: TObject);
    procedure ComboFKLocalColChange(Sender: TObject);
    procedure ComboFKRefTableChange(Sender: TObject);
    procedure BtnFKAddOrUpdateClick(Sender: TObject);
    procedure BtnFKDeleteClick(Sender: TObject);
    procedure BtnFKClearClick(Sender: TObject);
    procedure BtnOpenConstraintManagerClick(Sender: TObject);
    procedure GridFKsClick(Sender: TObject);
    procedure GridFKsSelection(Sender: TObject; aCol, aRow: Integer);
    procedure BtnExecuteClick(Sender: TObject);
    procedure BtnCopySQLClick(Sender: TObject);
  private
    procedure SetupGridHeaders;
    procedure SetupFKGridHeaders;
    procedure AddColumnRow(const AName, AType, ASize, AScale, ANotNull, APK, AAutoInc, ADefVal: string);
    procedure PopulateLocalColumnsCombo;
    procedure PopulateRefTablesCombo;
    procedure PopulateRefColumnsCombo(const ATableName: string);
    procedure SuggestFKName;
    procedure ClearFKFields;
    procedure LoadFKFromGrid(RowIdx: Integer);
    function GenerateSQL: string;
    procedure UpdatePreview;
  public
    class function Execute(const DefaultTableName: string = 'NOVA_TABELA'): Boolean;
  end;

implementation

{$R *.lfm}

const
  { Colunas da grade de campos }
  COL_NAME    = 0;
  COL_TYPE    = 1;
  COL_SIZE    = 2;
  COL_SCALE   = 3;
  COL_NOTNULL = 4;
  COL_PK      = 5;
  COL_AUTOINC = 6;
  COL_DEFVAL  = 7;

  { Colunas da grade de Foreign Keys }
  FK_COL_NAME     = 0;
  FK_COL_LOCAL    = 1;
  FK_COL_REFTBL   = 2;
  FK_COL_REFCOL   = 3;
  FK_COL_ONUPDATE = 4;
  FK_COL_ONDELETE = 5;

{ TFBCreateTableForm }

procedure TFBCreateTableForm.FormCreate(Sender: TObject);
begin
  SetupGridHeaders;
  SetupFKGridHeaders;

  // Opções de ON UPDATE e ON DELETE para Firebird
  ComboFKOnUpdate.Items.Clear;
  ComboFKOnUpdate.Items.Add('NO ACTION');
  ComboFKOnUpdate.Items.Add('CASCADE');
  ComboFKOnUpdate.Items.Add('SET NULL');
  ComboFKOnUpdate.Items.Add('SET DEFAULT');
  ComboFKOnUpdate.Items.Add('RESTRICT');
  ComboFKOnUpdate.ItemIndex := 0;

  ComboFKOnDelete.Items.Clear;
  ComboFKOnDelete.Items.Add('NO ACTION');
  ComboFKOnDelete.Items.Add('CASCADE');
  ComboFKOnDelete.Items.Add('SET NULL');
  ComboFKOnDelete.Items.Add('SET DEFAULT');
  ComboFKOnDelete.Items.Add('RESTRICT');
  ComboFKOnDelete.ItemIndex := 0;

  // Colunas iniciais ID e DESCRICAO
  AddColumnRow('ID', 'BIGINT', '', '', 'SIM', 'SIM', 'SIM', '');
  AddColumnRow('DESCRICAO', 'VARCHAR', '150', '', 'SIM', 'NAO', 'NAO', '');

  PopulateLocalColumnsCombo;
  PopulateRefTablesCombo;

  UpdatePreview;
end;

procedure TFBCreateTableForm.SetupGridHeaders;
begin
  GridColumns.ColCount := 8;
  GridColumns.RowCount := 1;

  GridColumns.Cells[COL_NAME, 0]    := 'Nome do Campo';
  GridColumns.Cells[COL_TYPE, 0]    := 'Tipo de Dado';
  GridColumns.Cells[COL_SIZE, 0]    := 'Tamanho';
  GridColumns.Cells[COL_SCALE, 0]   := 'Decimais';
  GridColumns.Cells[COL_NOTNULL, 0] := 'Não Nulo?';
  GridColumns.Cells[COL_PK, 0]      := 'Chave Primária?';
  GridColumns.Cells[COL_AUTOINC, 0] := 'Auto Inc / Identity?';
  GridColumns.Cells[COL_DEFVAL, 0]  := 'Valor Padrão';

  GridColumns.ColWidths[COL_NAME]    := 140;
  GridColumns.ColWidths[COL_TYPE]    := 110;
  GridColumns.ColWidths[COL_SIZE]    := 65;
  GridColumns.ColWidths[COL_SCALE]   := 65;
  GridColumns.ColWidths[COL_NOTNULL] := 75;
  GridColumns.ColWidths[COL_PK]      := 100;
  GridColumns.ColWidths[COL_AUTOINC] := 115;
  GridColumns.ColWidths[COL_DEFVAL]  := 95;
end;

procedure TFBCreateTableForm.SetupFKGridHeaders;
begin
  GridFKs.ColCount := 6;
  GridFKs.RowCount := 1;

  GridFKs.Cells[FK_COL_NAME, 0]     := 'Nome da FK';
  GridFKs.Cells[FK_COL_LOCAL, 0]    := 'Campo Local';
  GridFKs.Cells[FK_COL_REFTBL, 0]   := 'Tabela Destino';
  GridFKs.Cells[FK_COL_REFCOL, 0]   := 'Campo Destino';
  GridFKs.Cells[FK_COL_ONUPDATE, 0] := 'ON UPDATE';
  GridFKs.Cells[FK_COL_ONDELETE, 0] := 'ON DELETE';

  GridFKs.ColWidths[FK_COL_NAME]     := 175;
  GridFKs.ColWidths[FK_COL_LOCAL]    := 125;
  GridFKs.ColWidths[FK_COL_REFTBL]   := 145;
  GridFKs.ColWidths[FK_COL_REFCOL]   := 125;
  GridFKs.ColWidths[FK_COL_ONUPDATE] := 95;
  GridFKs.ColWidths[FK_COL_ONDELETE] := 95;
end;

procedure TFBCreateTableForm.AddColumnRow(const AName, AType, ASize, AScale, ANotNull, APK, AAutoInc, ADefVal: string);
var
  R: Integer;
begin
  R := GridColumns.RowCount;
  GridColumns.RowCount := R + 1;

  GridColumns.Cells[COL_NAME, R]    := UpperCase(Trim(AName));
  GridColumns.Cells[COL_TYPE, R]    := UpperCase(Trim(AType));
  GridColumns.Cells[COL_SIZE, R]    := Trim(ASize);
  GridColumns.Cells[COL_SCALE, R]   := Trim(AScale);
  GridColumns.Cells[COL_NOTNULL, R] := UpperCase(Trim(ANotNull));
  GridColumns.Cells[COL_PK, R]      := UpperCase(Trim(APK));
  GridColumns.Cells[COL_AUTOINC, R] := UpperCase(Trim(AAutoInc));
  GridColumns.Cells[COL_DEFVAL, R]  := Trim(ADefVal);

  UpdatePreview;
end;

procedure TFBCreateTableForm.BtnAddColClick(Sender: TObject);
begin
  AddColumnRow('CAMPO_' + IntToStr(GridColumns.RowCount), 'VARCHAR', '100', '', 'NAO', 'NAO', 'NAO', '');
end;

procedure TFBCreateTableForm.BtnDelColClick(Sender: TObject);
var
  R, I: Integer;
begin
  R := GridColumns.Row;
  if (R > 0) and (GridColumns.RowCount > 2) then
  begin
    GridColumns.DeleteRow(R);
    UpdatePreview;
  end
  else if GridColumns.RowCount = 2 then
  begin
    for I := 0 to GridColumns.ColCount - 1 do
      GridColumns.Cells[I, 1] := '';
    UpdatePreview;
  end;
end;

procedure TFBCreateTableForm.BtnMoveUpClick(Sender: TObject);
var
  R, C: Integer;
  Tmp: string;
begin
  R := GridColumns.Row;
  if R > 1 then
  begin
    for C := 0 to GridColumns.ColCount - 1 do
    begin
      Tmp := GridColumns.Cells[C, R];
      GridColumns.Cells[C, R] := GridColumns.Cells[C, R - 1];
      GridColumns.Cells[C, R - 1] := Tmp;
    end;
    GridColumns.Row := R - 1;
    UpdatePreview;
  end;
end;

procedure TFBCreateTableForm.BtnMoveDownClick(Sender: TObject);
var
  R, C: Integer;
  Tmp: string;
begin
  R := GridColumns.Row;
  if (R > 0) and (R < GridColumns.RowCount - 1) then
  begin
    for C := 0 to GridColumns.ColCount - 1 do
    begin
      Tmp := GridColumns.Cells[C, R];
      GridColumns.Cells[C, R] := GridColumns.Cells[C, R + 1];
      GridColumns.Cells[C, R + 1] := Tmp;
    end;
    GridColumns.Row := R + 1;
    UpdatePreview;
  end;
end;

procedure TFBCreateTableForm.BtnCreateFKForColClick(Sender: TObject);
var
  R: Integer;
  ColName: string;
begin
  R := GridColumns.Row;
  if (R > 0) and (R < GridColumns.RowCount) then
    ColName := UpperCase(Trim(GridColumns.Cells[COL_NAME, R]))
  else
    ColName := '';

  PageControlMain.ActivePage := TabSheetFK;
  PopulateLocalColumnsCombo;

  if ColName <> '' then
  begin
    ComboFKLocalCol.Text := ColName;
    ComboFKLocalColChange(ComboFKLocalCol);
  end;
end;

procedure TFBCreateTableForm.BtnTemplateAuditClick(Sender: TObject);
begin
  AddColumnRow('DATA_CADASTRO', 'TIMESTAMP', '', '', 'SIM', 'NAO', 'NAO', 'CURRENT_TIMESTAMP');
  AddColumnRow('DATA_ATUALIZACAO', 'TIMESTAMP', '', '', 'NAO', 'NAO', 'NAO', '');
  AddColumnRow('ATIVO', 'CHAR', '1', '', 'SIM', 'NAO', 'NAO', '''S''');
  UpdatePreview;
end;

procedure TFBCreateTableForm.EditTableNameChange(Sender: TObject);
begin
  if (EditFKName.Text = '') or StartsText('FK_', EditFKName.Text) then
    SuggestFKName;
  UpdatePreview;
end;

procedure TFBCreateTableForm.ChkFB3IdentityChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TFBCreateTableForm.GridColumnsEditingDone(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TFBCreateTableForm.PopulateLocalColumnsCombo;
var
  R: Integer;
  ColName, CurSel: string;
begin
  CurSel := ComboFKLocalCol.Text;
  ComboFKLocalCol.Items.BeginUpdate;
  try
    ComboFKLocalCol.Items.Clear;
    for R := 1 to GridColumns.RowCount - 1 do
    begin
      ColName := UpperCase(Trim(GridColumns.Cells[COL_NAME, R]));
      if ColName <> '' then
        ComboFKLocalCol.Items.Add(ColName);
    end;
  finally
    ComboFKLocalCol.Items.EndUpdate;
  end;

  if (CurSel <> '') and (ComboFKLocalCol.Items.IndexOf(CurSel) >= 0) then
    ComboFKLocalCol.Text := CurSel
  else if ComboFKLocalCol.Items.Count > 0 then
    ComboFKLocalCol.ItemIndex := 0;
end;

procedure TFBCreateTableForm.PopulateRefTablesCombo;
var
  CurSel: string;
begin
  if not FBConnManager.IsConnected then Exit;
  CurSel := ComboFKRefTable.Text;
  ComboFKRefTable.Items.BeginUpdate;
  try
    ComboFKRefTable.Items.Clear;
    TFBMetaDataExtractor.GetTables(ComboFKRefTable.Items, False);
  finally
    ComboFKRefTable.Items.EndUpdate;
  end;
  if CurSel <> '' then
    ComboFKRefTable.Text := CurSel;
end;

procedure TFBCreateTableForm.PopulateRefColumnsCombo(const ATableName: string);
var
  PKList: TStringList;
  Tbl: string;
begin
  Tbl := UpperCase(Trim(ATableName));
  if Tbl = '' then Exit;

  ComboFKRefCol.Items.BeginUpdate;
  try
    ComboFKRefCol.Items.Clear;
    if FBConnManager.IsConnected then
      TFBMetaDataExtractor.GetTableFieldNames(Tbl, ComboFKRefCol.Items);
  finally
    ComboFKRefCol.Items.EndUpdate;
  end;

  if FBConnManager.IsConnected then
  begin
    PKList := TStringList.Create;
    try
      TFBMetaDataExtractor.GetPrimaryKeys(Tbl, PKList);
      if PKList.Count > 0 then
        ComboFKRefCol.Text := PKList[0]
      else if ComboFKRefCol.Items.Count > 0 then
        ComboFKRefCol.ItemIndex := 0
      else
        ComboFKRefCol.Text := 'ID';
    finally
      PKList.Free;
    end;
  end
  else
  begin
    if ComboFKRefCol.Text = '' then
      ComboFKRefCol.Text := 'ID';
  end;
end;

procedure TFBCreateTableForm.SuggestFKName;
var
  Tbl, LocalCol, RefTbl, Proposed: string;
begin
  Tbl := UpperCase(Trim(EditTableName.Text));
  if Tbl = '' then Tbl := 'TABELA';
  LocalCol := UpperCase(Trim(ComboFKLocalCol.Text));
  RefTbl := UpperCase(Trim(ComboFKRefTable.Text));

  if RefTbl <> '' then
    Proposed := Format('FK_%s_%s', [Tbl, RefTbl])
  else if LocalCol <> '' then
    Proposed := Format('FK_%s_%s', [Tbl, LocalCol])
  else
    Proposed := Format('FK_%s_1', [Tbl]);

  // Limite Firebird clássico de 31 caracteres para garantir compatibilidade
  if Length(Proposed) > 31 then
    Proposed := Copy(Proposed, 1, 31);

  EditFKName.Text := Proposed;
end;

procedure TFBCreateTableForm.ClearFKFields;
begin
  EditFKName.Text := '';
  if ComboFKLocalCol.Items.Count > 0 then
    ComboFKLocalCol.ItemIndex := 0
  else
    ComboFKLocalCol.Text := '';
  ComboFKRefTable.Text := '';
  ComboFKRefCol.Text := '';
  ComboFKOnUpdate.ItemIndex := 0;
  ComboFKOnDelete.ItemIndex := 0;
end;

procedure TFBCreateTableForm.LoadFKFromGrid(RowIdx: Integer);
begin
  if (RowIdx < 1) or (RowIdx >= GridFKs.RowCount) then Exit;

  EditFKName.Text := GridFKs.Cells[FK_COL_NAME, RowIdx];
  ComboFKLocalCol.Text := GridFKs.Cells[FK_COL_LOCAL, RowIdx];
  ComboFKRefTable.Text := GridFKs.Cells[FK_COL_REFTBL, RowIdx];
  PopulateRefColumnsCombo(ComboFKRefTable.Text);
  ComboFKRefCol.Text := GridFKs.Cells[FK_COL_REFCOL, RowIdx];

  if ComboFKOnUpdate.Items.IndexOf(GridFKs.Cells[FK_COL_ONUPDATE, RowIdx]) >= 0 then
    ComboFKOnUpdate.Text := GridFKs.Cells[FK_COL_ONUPDATE, RowIdx]
  else
    ComboFKOnUpdate.ItemIndex := 0;

  if ComboFKOnDelete.Items.IndexOf(GridFKs.Cells[FK_COL_ONDELETE, RowIdx]) >= 0 then
    ComboFKOnDelete.Text := GridFKs.Cells[FK_COL_ONDELETE, RowIdx]
  else
    ComboFKOnDelete.ItemIndex := 0;
end;

procedure TFBCreateTableForm.GridFKsClick(Sender: TObject);
begin
  if GridFKs.Row > 0 then
    LoadFKFromGrid(GridFKs.Row);
end;

procedure TFBCreateTableForm.GridFKsSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if aRow > 0 then
    LoadFKFromGrid(aRow);
end;

procedure TFBCreateTableForm.PageControlMainChange(Sender: TObject);
begin
  if PageControlMain.ActivePage = TabSheetFK then
  begin
    PopulateLocalColumnsCombo;
    if ComboFKRefTable.Items.Count = 0 then
      PopulateRefTablesCombo;
    if (EditFKName.Text = '') and (ComboFKLocalCol.Text <> '') then
      SuggestFKName;
  end
  else if PageControlMain.ActivePage = TabSheetPreview then
    UpdatePreview;
end;

procedure TFBCreateTableForm.ComboFKLocalColChange(Sender: TObject);
var
  ColName, GuessedTbl: string;
  I: Integer;
begin
  ColName := UpperCase(Trim(ComboFKLocalCol.Text));
  if ColName <> '' then
  begin
    GuessedTbl := '';
    if EndsText('_ID', ColName) then
      GuessedTbl := Copy(ColName, 1, Length(ColName) - 3)
    else if StartsText('ID_', ColName) then
      GuessedTbl := Copy(ColName, 4, Length(ColName))
    else if StartsText('COD_', ColName) then
      GuessedTbl := Copy(ColName, 5, Length(ColName))
    else if EndsText('_COD', ColName) then
      GuessedTbl := Copy(ColName, 1, Length(ColName) - 4);

    if GuessedTbl <> '' then
    begin
      for I := 0 to ComboFKRefTable.Items.Count - 1 do
      begin
        if SameText(ComboFKRefTable.Items[I], GuessedTbl) or
           SameText(ComboFKRefTable.Items[I], GuessedTbl + 'S') or
           SameText(ComboFKRefTable.Items[I], GuessedTbl + 'ES') then
        begin
          ComboFKRefTable.Text := ComboFKRefTable.Items[I];
          PopulateRefColumnsCombo(ComboFKRefTable.Text);
          Break;
        end;
      end;
      if (ComboFKRefTable.Text = '') and (GuessedTbl <> '') then
      begin
        ComboFKRefTable.Text := GuessedTbl;
        if ComboFKRefCol.Text = '' then
          ComboFKRefCol.Text := 'ID';
      end;
    end;
  end;
  SuggestFKName;
end;

procedure TFBCreateTableForm.ComboFKRefTableChange(Sender: TObject);
begin
  PopulateRefColumnsCombo(ComboFKRefTable.Text);
  SuggestFKName;
end;

procedure TFBCreateTableForm.BtnFKSuggestNameClick(Sender: TObject);
begin
  SuggestFKName;
end;

procedure TFBCreateTableForm.BtnFKClearClick(Sender: TObject);
begin
  ClearFKFields;
end;

procedure TFBCreateTableForm.BtnFKAddOrUpdateClick(Sender: TObject);
var
  FKName, LocalCol, RefTbl, RefCol, OnUpd, OnDel: string;
  R, FoundRow: Integer;
begin
  FKName := UpperCase(Trim(EditFKName.Text));
  LocalCol := UpperCase(Trim(ComboFKLocalCol.Text));
  RefTbl := UpperCase(Trim(ComboFKRefTable.Text));
  RefCol := UpperCase(Trim(ComboFKRefCol.Text));
  OnUpd := UpperCase(Trim(ComboFKOnUpdate.Text));
  OnDel := UpperCase(Trim(ComboFKOnDelete.Text));

  if LocalCol = '' then
  begin
    ShowMessage('Selecione ou informe o campo local para a chave estrangeira.');
    ComboFKLocalCol.SetFocus;
    Exit;
  end;

  if RefTbl = '' then
  begin
    ShowMessage('Informe a tabela de destino para a chave estrangeira.');
    ComboFKRefTable.SetFocus;
    Exit;
  end;

  if RefCol = '' then
    RefCol := 'ID';

  if FKName = '' then
    SuggestFKName;
  FKName := UpperCase(Trim(EditFKName.Text));

  if OnUpd = '' then OnUpd := 'NO ACTION';
  if OnDel = '' then OnDel := 'NO ACTION';

  // Verifica se já existe na grade
  FoundRow := -1;
  for R := 1 to GridFKs.RowCount - 1 do
  begin
    if SameText(Trim(GridFKs.Cells[FK_COL_NAME, R]), FKName) or
       SameText(Trim(GridFKs.Cells[FK_COL_LOCAL, R]), LocalCol) then
    begin
      FoundRow := R;
      Break;
    end;
  end;

  if FoundRow > 0 then
  begin
    GridFKs.Cells[FK_COL_NAME, FoundRow]     := FKName;
    GridFKs.Cells[FK_COL_LOCAL, FoundRow]    := LocalCol;
    GridFKs.Cells[FK_COL_REFTBL, FoundRow]   := RefTbl;
    GridFKs.Cells[FK_COL_REFCOL, FoundRow]   := RefCol;
    GridFKs.Cells[FK_COL_ONUPDATE, FoundRow] := OnUpd;
    GridFKs.Cells[FK_COL_ONDELETE, FoundRow] := OnDel;
  end
  else
  begin
    R := GridFKs.RowCount;
    GridFKs.RowCount := R + 1;
    GridFKs.Cells[FK_COL_NAME, R]     := FKName;
    GridFKs.Cells[FK_COL_LOCAL, R]    := LocalCol;
    GridFKs.Cells[FK_COL_REFTBL, R]   := RefTbl;
    GridFKs.Cells[FK_COL_REFCOL, R]   := RefCol;
    GridFKs.Cells[FK_COL_ONUPDATE, R] := OnUpd;
    GridFKs.Cells[FK_COL_ONDELETE, R] := OnDel;
  end;

  UpdatePreview;
  ShowMessage(Format('Chave Estrangeira "%s" salva com sucesso!', [FKName]));
end;

procedure TFBCreateTableForm.BtnFKDeleteClick(Sender: TObject);
var
  R: Integer;
begin
  R := GridFKs.Row;
  if (R > 0) and (GridFKs.RowCount > 1) then
  begin
    GridFKs.DeleteRow(R);
    ClearFKFields;
    UpdatePreview;
  end;
end;

procedure TFBCreateTableForm.BtnOpenConstraintManagerClick(Sender: TObject);
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird para abrir o gerenciador de chaves.');
    Exit;
  end;
  TFBConstraintForm.Execute('');
  PopulateRefTablesCombo;
end;

function TFBCreateTableForm.GenerateSQL: string;
var
  TblName: string;
  R: Integer;
  ColDef: TColumnDef;
  PKList: string;
  ColSQL: string;
  GenSQL: string;
  Lines: TStringList;
  FKDef: TForeignKeyDef;
  I: Integer;
begin
  TblName := UpperCase(Trim(EditTableName.Text));
  if TblName = '' then
    TblName := 'NOVA_TABELA';

  Lines := TStringList.Create;
  try
    PKList := '';
    GenSQL := '';

    for R := 1 to GridColumns.RowCount - 1 do
    begin
      if Trim(GridColumns.Cells[COL_NAME, R]) = '' then Continue;

      ColDef.Name := UpperCase(Trim(GridColumns.Cells[COL_NAME, R]));
      ColDef.DataType := UpperCase(Trim(GridColumns.Cells[COL_TYPE, R]));
      ColDef.Size := StrToIntDef(Trim(GridColumns.Cells[COL_SIZE, R]), 0);
      ColDef.Scale := StrToIntDef(Trim(GridColumns.Cells[COL_SCALE, R]), 0);
      ColDef.NotNull := SameText(Trim(GridColumns.Cells[COL_NOTNULL, R]), 'SIM') or
                        SameText(Trim(GridColumns.Cells[COL_NOTNULL, R]), 'S') or
                        SameText(Trim(GridColumns.Cells[COL_NOTNULL, R]), 'TRUE');
      ColDef.PrimaryKey := SameText(Trim(GridColumns.Cells[COL_PK, R]), 'SIM') or
                           SameText(Trim(GridColumns.Cells[COL_PK, R]), 'S') or
                           SameText(Trim(GridColumns.Cells[COL_PK, R]), 'TRUE');
      ColDef.AutoIncrement := SameText(Trim(GridColumns.Cells[COL_AUTOINC, R]), 'SIM') or
                              SameText(Trim(GridColumns.Cells[COL_AUTOINC, R]), 'S') or
                              SameText(Trim(GridColumns.Cells[COL_AUTOINC, R]), 'TRUE');
      ColDef.DefaultValue := Trim(GridColumns.Cells[COL_DEFVAL, R]);

      ColSQL := '  ' + TFBMetaTypeHelper.BuildColumnSQL(ColDef, ChkFB3Identity.Checked);
      Lines.Add(ColSQL);

      if ColDef.PrimaryKey then
      begin
        if PKList <> '' then PKList := PKList + ', ';
        PKList := PKList + ColDef.Name;
      end;

      // Se FB 2.5 e AutoIncrement, cria generator + trigger no script
      if ColDef.AutoIncrement and (not ChkFB3Identity.Checked) then
      begin
        GenSQL := GenSQL + LineEnding +
          Format('CREATE SEQUENCE GEN_%s_%s;' + LineEnding, [TblName, ColDef.Name]) +
          Format('SET TERM ^ ;' + LineEnding +
                 'CREATE TRIGGER TR_%s_BI FOR %s' + LineEnding +
                 'ACTIVE BEFORE INSERT POSITION 0 AS' + LineEnding +
                 'BEGIN' + LineEnding +
                 '  IF (NEW.%s IS NULL) THEN' + LineEnding +
                 '    NEW.%s = GEN_ID(GEN_%s_%s, 1);' + LineEnding +
                 'END ^' + LineEnding +
                 'SET TERM ; ^' + LineEnding,
                 [TblName, TblName, ColDef.Name, ColDef.Name, TblName, ColDef.Name]);
      end;
    end;

    // Constraint de Chave Primária
    if PKList <> '' then
      Lines.Add(Format('  CONSTRAINT PK_%s PRIMARY KEY (%s)', [TblName, PKList]));

    // Constraints de Chave Estrangeira (FKs)
    for R := 1 to GridFKs.RowCount - 1 do
    begin
      FKDef.ConstraintName := UpperCase(Trim(GridFKs.Cells[FK_COL_NAME, R]));
      FKDef.ColumnName := UpperCase(Trim(GridFKs.Cells[FK_COL_LOCAL, R]));
      FKDef.RefTable := UpperCase(Trim(GridFKs.Cells[FK_COL_REFTBL, R]));
      FKDef.RefColumn := UpperCase(Trim(GridFKs.Cells[FK_COL_REFCOL, R]));
      FKDef.OnUpdate := UpperCase(Trim(GridFKs.Cells[FK_COL_ONUPDATE, R]));
      FKDef.OnDelete := UpperCase(Trim(GridFKs.Cells[FK_COL_ONDELETE, R]));

      if (FKDef.ColumnName <> '') and (FKDef.RefTable <> '') then
      begin
        if FKDef.RefColumn = '' then FKDef.RefColumn := 'ID';
        if FKDef.ConstraintName = '' then
          FKDef.ConstraintName := Format('FK_%s_%s', [TblName, FKDef.ColumnName]);

        Lines.Add('  ' + TFBMetaTypeHelper.BuildForeignKeySQL(FKDef));
      end;
    end;

    Result := 'CREATE TABLE ' + TblName + ' (' + LineEnding;
    for I := 0 to Lines.Count - 1 do
    begin
      if I < Lines.Count - 1 then
        Result := Result + Lines[I] + ',' + LineEnding
      else
        Result := Result + Lines[I] + LineEnding;
    end;
    Result := Result + ');';

    if GenSQL <> '' then
      Result := Result + LineEnding + GenSQL;
  finally
    Lines.Free;
  end;
end;

procedure TFBCreateTableForm.UpdatePreview;
begin
  MemoSQLPreview.Text := GenerateSQL;
end;

procedure TFBCreateTableForm.BtnExecuteClick(Sender: TObject);
var
  Sql: string;
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Não há conexão ativa com o banco Firebird! Conecte-se primeiro.');
    Exit;
  end;

  Sql := Trim(MemoSQLPreview.Text);
  if Sql = '' then
  begin
    ShowMessage('Nenhum comando SQL para executar.');
    Exit;
  end;

  if MessageDlg('Confirmação',
     'Deseja criar a tabela "' + UpperCase(Trim(EditTableName.Text)) + '" no banco de dados?',
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      if EndsText(';', Sql) then
        Sql := Copy(Sql, 1, Length(Sql) - 1);

      FBConnManager.ExecuteDirect(Sql, Rows);
      ShowMessage('Tabela "' + UpperCase(Trim(EditTableName.Text)) + '" criada com sucesso no Firebird!');
      ModalResult := mrOk;
    except
      on E: Exception do
        ShowMessage('Erro ao criar tabela: ' + LineEnding + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBCreateTableForm.BtnCopySQLClick(Sender: TObject);
begin
  Clipboard.AsText := MemoSQLPreview.Text;
  ShowMessage('Script SQL copiado para a área de transferência!');
end;

class function TFBCreateTableForm.Execute(const DefaultTableName: string): Boolean;
var
  Frm: TFBCreateTableForm;
begin
  Frm := TFBCreateTableForm.Create(nil);
  try
    if DefaultTableName <> '' then
      Frm.EditTableName.Text := DefaultTableName;
    Result := (Frm.ShowModal = mrOk);
  finally
    Frm.Free;
  end;
end;

end.
