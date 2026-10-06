unit uFBAlterFieldForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Clipbrd,
  uFBTypes, uFBConnectionManager, uFBMetaData;

type
  TAlterFieldMode = (afmAdd, afmAlterType, afmRename, afmDrop);

  { TFBAlterFieldForm }
  TFBAlterFieldForm = class(TForm)
    PanelTop: TPanel;
    LabelTable: TLabel;
    RadioGroupOperation: TRadioGroup;

    PageControlOps: TPageControl;

    { Aba 1: Adicionar Campo }
    TabSheetAdd: TTabSheet;
    LabelAddName: TLabel;
    EditAddName: TEdit;
    LabelAddType: TLabel;
    ComboAddType: TComboBox;
    LabelAddSize: TLabel;
    EditAddSize: TEdit;
    LabelAddScale: TLabel;
    EditAddScale: TEdit;
    ChkAddNotNull: TCheckBox;
    LabelAddDefault: TLabel;
    EditAddDefault: TEdit;

    { Aba 2: Alterar Tipo / Tamanho }
    TabSheetAlterType: TTabSheet;
    LabelAlterField: TLabel;
    ComboAlterField: TComboBox;
    LabelAlterNewType: TLabel;
    ComboAlterNewType: TComboBox;
    LabelAlterNewSize: TLabel;
    EditAlterNewSize: TEdit;
    LabelAlterNewScale: TLabel;
    EditAlterNewScale: TEdit;

    { Aba 3: Renomear Campo }
    TabSheetRename: TTabSheet;
    LabelRenameField: TLabel;
    ComboRenameField: TComboBox;
    LabelRenameNewName: TLabel;
    EditRenameNewName: TEdit;

    { Aba 4: Excluir Campo }
    TabSheetDrop: TTabSheet;
    LabelDropField: TLabel;
    ComboDropField: TComboBox;
    LabelDropWarning: TLabel;

    GroupBoxDDL: TGroupBox;
    MemoDDL: TMemo;

    PanelBottom: TPanel;
    BtnExecute: TButton;
    BtnCopySQL: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure RadioGroupOperationClick(Sender: TObject);
    procedure FieldParamChange(Sender: TObject);
    procedure BtnExecuteClick(Sender: TObject);
    procedure BtnCopySQLClick(Sender: TObject);
  private
    FTableName: string;
    procedure PopulateFieldsList(const ASelectedField: string);
    function GenerateDDL: string;
    procedure UpdateDDL;
  public
    class function Execute(const ATableName: string; InitialMode: TAlterFieldMode = afmAdd; const InitialFieldName: string = ''): Boolean;
  end;

implementation

{$R *.lfm}

{ TFBAlterFieldForm }

procedure TFBAlterFieldForm.FormCreate(Sender: TObject);
const
  FB_TYPES: array[0..11] of string = (
    'VARCHAR', 'INTEGER', 'BIGINT', 'SMALLINT', 'NUMERIC', 'DECIMAL',
    'TIMESTAMP', 'DATE', 'TIME', 'CHAR', 'BLOB SUB_TYPE TEXT', 'BOOLEAN'
  );
var
  I: Integer;
begin
  ComboAddType.Items.Clear;
  ComboAlterNewType.Items.Clear;
  for I := Low(FB_TYPES) to High(FB_TYPES) do
  begin
    ComboAddType.Items.Add(FB_TYPES[I]);
    ComboAlterNewType.Items.Add(FB_TYPES[I]);
  end;
  ComboAddType.ItemIndex := 0;      // VARCHAR
  ComboAlterNewType.ItemIndex := 0; // VARCHAR
end;

procedure TFBAlterFieldForm.PopulateFieldsList(const ASelectedField: string);
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    TFBMetaDataExtractor.GetTableFieldNames(FTableName, List);

    ComboAlterField.Items.Assign(List);
    ComboRenameField.Items.Assign(List);
    ComboDropField.Items.Assign(List);

    if ASelectedField <> '' then
    begin
      ComboAlterField.Text := ASelectedField;
      ComboRenameField.Text := ASelectedField;
      ComboDropField.Text := ASelectedField;
    end
    else
    begin
      if ComboAlterField.Items.Count > 0 then ComboAlterField.ItemIndex := 0;
      if ComboRenameField.Items.Count > 0 then ComboRenameField.ItemIndex := 0;
      if ComboDropField.Items.Count > 0 then ComboDropField.ItemIndex := 0;
    end;
  finally
    List.Free;
  end;
end;

procedure TFBAlterFieldForm.RadioGroupOperationClick(Sender: TObject);
begin
  PageControlOps.TabIndex := RadioGroupOperation.ItemIndex;
  UpdateDDL;
end;

procedure TFBAlterFieldForm.FieldParamChange(Sender: TObject);
begin
  UpdateDDL;
end;

function TFBAlterFieldForm.GenerateDDL: string;
var
  Tbl, FldName, FldType, Sz, Sc, DefVal: string;
  ColDef: TColumnDef;
begin
  Tbl := UpperCase(Trim(FTableName));
  Result := '';

  case RadioGroupOperation.ItemIndex of
    0: // Adicionar Campo
    begin
      FldName := UpperCase(Trim(EditAddName.Text));
      if FldName = '' then FldName := 'NOVO_CAMPO';
      FldType := UpperCase(Trim(ComboAddType.Text));
      Sz := Trim(EditAddSize.Text);
      Sc := Trim(EditAddScale.Text);
      DefVal := Trim(EditAddDefault.Text);

      ColDef.Name := FldName;
      ColDef.DataType := FldType;
      ColDef.Size := StrToIntDef(Sz, 0);
      ColDef.Scale := StrToIntDef(Sc, 0);
      ColDef.NotNull := ChkAddNotNull.Checked;
      ColDef.PrimaryKey := False;
      ColDef.AutoIncrement := False;
      ColDef.DefaultValue := DefVal;

      Result := Format('ALTER TABLE %s ADD %s;', [Tbl, TFBMetaTypeHelper.BuildColumnSQL(ColDef, True)]);
    end;

    1: // Alterar Tipo / Tamanho
    begin
      FldName := UpperCase(Trim(ComboAlterField.Text));
      FldType := UpperCase(Trim(ComboAlterNewType.Text));
      Sz := Trim(EditAlterNewSize.Text);
      Sc := Trim(EditAlterNewScale.Text);

      if FldName = '' then FldName := 'CAMPO';
      if (FldType = 'VARCHAR') or (FldType = 'CHAR') then
      begin
        if StrToIntDef(Sz, 0) > 0 then
          FldType := Format('%s(%s)', [FldType, Sz]);
      end
      else if (FldType = 'NUMERIC') or (FldType = 'DECIMAL') then
      begin
        if StrToIntDef(Sz, 0) > 0 then
        begin
          if StrToIntDef(Sc, 0) > 0 then
            FldType := Format('%s(%s,%s)', [FldType, Sz, Sc])
          else
            FldType := Format('%s(%s)', [FldType, Sz]);
        end;
      end;

      Result := Format('ALTER TABLE %s ALTER %s TYPE %s;', [Tbl, FldName, FldType]);
    end;

    2: // Renomear Campo
    begin
      FldName := UpperCase(Trim(ComboRenameField.Text));
      DefVal := UpperCase(Trim(EditRenameNewName.Text));
      if FldName = '' then FldName := 'CAMPO_ANTIGO';
      if DefVal = '' then DefVal := 'NOVO_NOME_CAMPO';

      Result := Format('ALTER TABLE %s ALTER %s TO %s;', [Tbl, FldName, DefVal]);
    end;

    3: // Excluir Campo
    begin
      FldName := UpperCase(Trim(ComboDropField.Text));
      if FldName = '' then FldName := 'CAMPO';
      Result := Format('ALTER TABLE %s DROP %s;', [Tbl, FldName]);
    end;
  end;
end;

procedure TFBAlterFieldForm.UpdateDDL;
begin
  MemoDDL.Text := GenerateDDL;
end;

procedure TFBAlterFieldForm.BtnExecuteClick(Sender: TObject);
var
  Sql: string;
  Rows: Integer;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Não há conexão ativa com o banco Firebird.');
    Exit;
  end;

  Sql := Trim(MemoDDL.Text);
  if Sql = '' then Exit;

  if MessageDlg('Executar Alteração na Tabela',
     'Deseja executar o seguinte comando DDL agora no banco de dados?' + LineEnding + LineEnding + Sql,
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      if EndsText(';', Sql) then
        Sql := Copy(Sql, 1, Length(Sql) - 1);

      FBConnManager.ExecuteDirect(Sql, Rows);
      ShowMessage('Estrutura da tabela alterada com sucesso no Firebird!');
      ModalResult := mrOk;
    except
      on E: Exception do
        ShowMessage('Erro ao alterar estrutura da tabela: ' + LineEnding + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBAlterFieldForm.BtnCopySQLClick(Sender: TObject);
begin
  Clipboard.AsText := MemoDDL.Text;
  ShowMessage('Comando DDL copiado para a área de transferência!');
end;

class function TFBAlterFieldForm.Execute(const ATableName: string; InitialMode: TAlterFieldMode; const InitialFieldName: string): Boolean;
var
  Frm: TFBAlterFieldForm;
begin
  Frm := TFBAlterFieldForm.Create(nil);
  try
    Frm.FTableName := UpperCase(Trim(ATableName));
    Frm.LabelTable.Caption := 'Tabela: ' + Frm.FTableName;
    Frm.PopulateFieldsList(InitialFieldName);
    Frm.RadioGroupOperation.ItemIndex := Ord(InitialMode);
    Frm.RadioGroupOperationClick(Frm.RadioGroupOperation);

    Result := (Frm.ShowModal = mrOk);
  finally
    Frm.Free;
  end;
end;

end.
