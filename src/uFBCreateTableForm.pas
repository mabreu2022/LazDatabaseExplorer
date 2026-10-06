unit uFBCreateTableForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Grids, Clipbrd,
  uFBTypes, uFBConnectionManager;

type
  { TFBCreateTableForm }
  TFBCreateTableForm = class(TForm)
    PanelTop: TPanel;
    LabelTableName: TLabel;
    EditTableName: TEdit;
    ChkFB3Identity: TCheckBox;
    BtnTemplateAudit: TButton;

    PageControlMain: TPageControl;
    TabSheetColumns: TTabSheet;
    PanelGridTools: TPanel;
    BtnAddCol: TButton;
    BtnDelCol: TButton;
    BtnMoveUp: TButton;
    BtnMoveDown: TButton;
    GridColumns: TStringGrid;

    TabSheetPreview: TTabSheet;
    MemoSQLPreview: TMemo;

    PanelBottom: TPanel;
    BtnExecute: TButton;
    BtnCopySQL: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure BtnAddColClick(Sender: TObject);
    procedure BtnDelColClick(Sender: TObject);
    procedure BtnMoveUpClick(Sender: TObject);
    procedure BtnMoveDownClick(Sender: TObject);
    procedure BtnTemplateAuditClick(Sender: TObject);
    procedure EditTableNameChange(Sender: TObject);
    procedure ChkFB3IdentityChange(Sender: TObject);
    procedure GridColumnsEditingDone(Sender: TObject);
    procedure BtnExecuteClick(Sender: TObject);
    procedure BtnCopySQLClick(Sender: TObject);
  private
    procedure SetupGridHeaders;
    procedure AddColumnRow(const AName, AType, ASize, AScale, ANotNull, APK, AAutoInc, ADefVal: string);
    function GenerateSQL: string;
    procedure UpdatePreview;
  public
    class function Execute(const DefaultTableName: string = 'NOVA_TABELA'): Boolean;
  end;

implementation

{$R *.lfm}

const
  COL_NAME    = 0;
  COL_TYPE    = 1;
  COL_SIZE    = 2;
  COL_SCALE   = 3;
  COL_NOTNULL = 4;
  COL_PK      = 5;
  COL_AUTOINC = 6;
  COL_DEFVAL  = 7;

{ TFBCreateTableForm }

procedure TFBCreateTableForm.FormCreate(Sender: TObject);
begin
  SetupGridHeaders;
  // Coluna inicial ID
  AddColumnRow('ID', 'BIGINT', '', '', 'SIM', 'SIM', 'SIM', '');
  AddColumnRow('DESCRICAO', 'VARCHAR', '150', '', 'SIM', 'NAO', 'NAO', '');
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
    // Limpa a única linha
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

procedure TFBCreateTableForm.BtnTemplateAuditClick(Sender: TObject);
begin
  AddColumnRow('DATA_CADASTRO', 'TIMESTAMP', '', '', 'SIM', 'NAO', 'NAO', 'CURRENT_TIMESTAMP');
  AddColumnRow('DATA_ATUALIZACAO', 'TIMESTAMP', '', '', 'NAO', 'NAO', 'NAO', '');
  AddColumnRow('ATIVO', 'CHAR', '1', '', 'SIM', 'NAO', 'NAO', '''S''');
  UpdatePreview;
end;

procedure TFBCreateTableForm.EditTableNameChange(Sender: TObject);
begin
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

function TFBCreateTableForm.GenerateSQL: string;
var
  TblName: string;
  R: Integer;
  ColDef: TColumnDef;
  Cols: array of TColumnDef;
  Count: Integer;
  PKList: string;
  ColSQL: string;
  GenSQL: string;
begin
  TblName := UpperCase(Trim(EditTableName.Text));
  if TblName = '' then
    TblName := 'NOVA_TABELA';

  SetLength(Cols, GridColumns.RowCount - 1);
  Count := 0;
  PKList := '';

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

    Cols[Count] := ColDef;
    Inc(Count);
  end;

  SetLength(Cols, Count);

  Result := 'CREATE TABLE ' + TblName + ' (' + LineEnding;

  GenSQL := '';
  for R := 0 to Count - 1 do
  begin
    ColSQL := '  ' + TFBMetaTypeHelper.BuildColumnSQL(Cols[R], ChkFB3Identity.Checked);

    if Cols[R].PrimaryKey then
    begin
      if PKList <> '' then PKList := PKList + ', ';
      PKList := PKList + Cols[R].Name;
    end;

    // Se FB 2.5 e AutoIncrement, cria generator + trigger no script
    if Cols[R].AutoIncrement and (not ChkFB3Identity.Checked) then
    begin
      GenSQL := GenSQL + LineEnding +
        Format('CREATE SEQUENCE GEN_%s_%s;' + LineEnding, [TblName, Cols[R].Name]) +
        Format('SET TERM ^ ;' + LineEnding +
               'CREATE TRIGGER TR_%s_BI FOR %s' + LineEnding +
               'ACTIVE BEFORE INSERT POSITION 0 AS' + LineEnding +
               'BEGIN' + LineEnding +
               '  IF (NEW.%s IS NULL) THEN' + LineEnding +
               '    NEW.%s = GEN_ID(GEN_%s_%s, 1);' + LineEnding +
               'END ^' + LineEnding +
               'SET TERM ; ^' + LineEnding,
               [TblName, TblName, Cols[R].Name, Cols[R].Name, TblName, Cols[R].Name]);
    end;

    if (R < Count - 1) or (PKList <> '') then
      Result := Result + ColSQL + ',' + LineEnding
    else
      Result := Result + ColSQL + LineEnding;
  end;

  if PKList <> '' then
  begin
    Result := Result + Format('  CONSTRAINT PK_%s PRIMARY KEY (%s)' + LineEnding, [TblName, PKList]);
  end;

  Result := Result + ');';

  if GenSQL <> '' then
    Result := Result + LineEnding + GenSQL;
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
      // Se tiver ';' no final da criação da tabela, retira se for single statement
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
