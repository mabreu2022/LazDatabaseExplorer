unit uFBIndexManagerForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, uFBMetaData, uFBConnectionManager;

type
  { TFBIndexManagerForm }
  TFBIndexManagerForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelCenter: TPanel;
    LabelTitle: TLabel;
    LabelTable: TLabel;
    GridIndices: TStringGrid;
    PanelActions: TPanel;
    BtnRecalcStats: TButton;
    BtnDropIndex: TButton;
    BtnRefresh: TButton;
    GroupBoxNewIndex: TGroupBox;
    LabelNewIndexName: TLabel;
    EditNewIndexName: TEdit;
    LabelFields: TLabel;
    EditFields: TEdit;
    CheckUnique: TCheckBox;
    CheckDescending: TCheckBox;
    BtnCreateIndex: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure BtnRecalcStatsClick(Sender: TObject);
    procedure BtnDropIndexClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnCreateIndexClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    FTableName: string;
    procedure LoadIndices;
    procedure SetupGridHeaders;
    function GetSelectedIndexName: string;
  public
    class procedure Execute(const ATableName: string);
  end;

implementation

{$R *.lfm}

{ TFBIndexManagerForm }

class procedure TFBIndexManagerForm.Execute(const ATableName: string);
var
  Form: TFBIndexManagerForm;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a um banco de dados antes de gerenciar índices.');
    Exit;
  end;

  Form := TFBIndexManagerForm.Create(nil);
  try
    Form.FTableName := UpperCase(Trim(ATableName));
    Form.LabelTable.Caption := 'Tabela: ' + Form.FTableName;
    Form.SetupGridHeaders;
    Form.LoadIndices;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TFBIndexManagerForm.FormCreate(Sender: TObject);
begin
  Caption := 'Gerenciador de Índices da Tabela (Padrão IBExpert)';
end;

procedure TFBIndexManagerForm.SetupGridHeaders;
begin
  GridIndices.ColCount := 6;
  GridIndices.RowCount := 1;
  GridIndices.Cells[0, 0] := 'Nome do Índice';
  GridIndices.Cells[1, 0] := 'Campos';
  GridIndices.Cells[2, 0] := 'Único?';
  GridIndices.Cells[3, 0] := 'Ordem';
  GridIndices.Cells[4, 0] := 'Ativo?';
  GridIndices.Cells[5, 0] := 'Seletividade';

  GridIndices.ColWidths[0] := 180;
  GridIndices.ColWidths[1] := 180;
  GridIndices.ColWidths[2] := 60;
  GridIndices.ColWidths[3] := 70;
  GridIndices.ColWidths[4] := 60;
  GridIndices.ColWidths[5] := 100;
end;

procedure TFBIndexManagerForm.LoadIndices;
var
  Idxs: TFBIndexInfoList;
  I, R: Integer;
begin
  Idxs := TFBMetaDataExtractor.GetTableIndices(FTableName);
  GridIndices.RowCount := Length(Idxs) + 1;

  for I := 0 to High(Idxs) do
  begin
    R := I + 1;
    GridIndices.Cells[0, R] := Idxs[I].IndexName;
    GridIndices.Cells[1, R] := Idxs[I].Fields;

    if Idxs[I].IsUnique then
      GridIndices.Cells[2, R] := 'SIM'
    else
      GridIndices.Cells[2, R] := 'NÃO';

    if Idxs[I].IsDescending then
      GridIndices.Cells[3, R] := 'DESC'
    else
      GridIndices.Cells[3, R] := 'ASC';

    if Idxs[I].IsActive then
      GridIndices.Cells[4, R] := 'SIM'
    else
      GridIndices.Cells[4, R] := 'NÃO';

    GridIndices.Cells[5, R] := FormatFloat('0.000000', Idxs[I].Selectivity);
  end;
end;

function TFBIndexManagerForm.GetSelectedIndexName: string;
begin
  Result := '';
  if GridIndices.Row > 0 then
    Result := Trim(GridIndices.Cells[0, GridIndices.Row]);
end;

procedure TFBIndexManagerForm.BtnRecalcStatsClick(Sender: TObject);
var
  IdxName: string;
begin
  IdxName := GetSelectedIndexName;
  if IdxName = '' then
  begin
    ShowMessage('Selecione um índice na lista para recalcular a seletividade.');
    Exit;
  end;

  try
    TFBMetaDataExtractor.RecalculateIndexStatistics(IdxName);
    LoadIndices;
    ShowMessage(Format('Estatística de seletividade do índice "%s" recalculada com sucesso!' + LineEnding +
                       'Comando executado: SET STATISTICS INDEX %s;', [IdxName, IdxName]));
  except
    on E: Exception do
      ShowMessage('Erro ao recalcular estatística: ' + LineEnding + E.Message);
  end;
end;

procedure TFBIndexManagerForm.BtnDropIndexClick(Sender: TObject);
var
  IdxName: string;
begin
  IdxName := GetSelectedIndexName;
  if IdxName = '' then
  begin
    ShowMessage('Selecione um índice na lista para excluir.');
    Exit;
  end;

  if MessageDlg('Confirmação',
     Format('Deseja realmente EXCLUIR o índice "%s"?' + LineEnding +
            'Comando: DROP INDEX %s;', [IdxName, IdxName]),
     mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    TFBMetaDataExtractor.DropIndex(IdxName);
    LoadIndices;
    ShowMessage(Format('Índice "%s" excluído com sucesso!', [IdxName]));
  except
    on E: Exception do
      ShowMessage('Erro ao excluir índice: ' + LineEnding + E.Message);
  end;
end;

procedure TFBIndexManagerForm.BtnRefreshClick(Sender: TObject);
begin
  LoadIndices;
end;

procedure TFBIndexManagerForm.BtnCreateIndexClick(Sender: TObject);
var
  IdxName, Flds: string;
begin
  IdxName := UpperCase(Trim(EditNewIndexName.Text));
  Flds := UpperCase(Trim(EditFields.Text));

  if IdxName = '' then
  begin
    ShowMessage('Informe o nome do novo índice (ex: IDX_' + FTableName + '_NOME).');
    Exit;
  end;

  if Flds = '' then
  begin
    ShowMessage('Informe ao menos um campo para compor o índice.');
    Exit;
  end;

  try
    TFBMetaDataExtractor.CreateIndex(IdxName, FTableName, Flds, CheckUnique.Checked, CheckDescending.Checked);
    ShowMessage(Format('Índice "%s" criado com sucesso na tabela %s!', [IdxName, FTableName]));
    EditNewIndexName.Text := '';
    EditFields.Text := '';
    LoadIndices;
  except
    on E: Exception do
      ShowMessage('Erro ao criar índice: ' + LineEnding + E.Message);
  end;
end;

procedure TFBIndexManagerForm.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
