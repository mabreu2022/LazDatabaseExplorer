unit uFBCellViewerForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Clipbrd, db;

type
  { TFBCellViewerForm }
  TFBCellViewerForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    LabelFieldName: TLabel;
    LabelFieldType: TLabel;
    LabelLength: TLabel;
    MemoContent: TMemo;
    BtnSaveToField: TButton;
    BtnCopy: TButton;
    BtnSaveToFile: TButton;
    BtnClose: TButton;
    SaveDialogFile: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure BtnSaveToFieldClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnSaveToFileClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure MemoContentChange(Sender: TObject);
  private
    FField: TField;
    procedure UpdateStats;
  public
    class procedure Execute(AField: TField);
  end;

implementation

{$R *.lfm}

{ TFBCellViewerForm }

class procedure TFBCellViewerForm.Execute(AField: TField);
var
  Form: TFBCellViewerForm;
begin
  if AField = nil then Exit;

  Form := TFBCellViewerForm.Create(nil);
  try
    Form.FField := AField;
    Form.LabelFieldName.Caption := 'Campo: ' + AField.FieldName;
    Form.LabelFieldType.Caption := 'Tipo: ' + FieldTypeNames[AField.DataType];
    Form.MemoContent.Text := AField.AsString;
    Form.BtnSaveToField.Enabled := (AField.DataSet <> nil) and (AField.DataSet.CanModify);
    Form.MemoContent.ReadOnly := not Form.BtnSaveToField.Enabled;
    Form.UpdateStats;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TFBCellViewerForm.FormCreate(Sender: TObject);
begin
  Caption := 'Visualizador e Editor de Campo / Conteúdo';
end;

procedure TFBCellViewerForm.UpdateStats;
begin
  LabelLength.Caption := Format('Tamanho: %d caracteres | %d linhas',
    [Length(MemoContent.Text), MemoContent.Lines.Count]);
end;

procedure TFBCellViewerForm.MemoContentChange(Sender: TObject);
begin
  UpdateStats;
end;

procedure TFBCellViewerForm.BtnSaveToFieldClick(Sender: TObject);
begin
  if (FField = nil) or (FField.DataSet = nil) or not FField.DataSet.CanModify then Exit;

  try
    if not (FField.DataSet.State in [dsEdit, dsInsert]) then
      FField.DataSet.Edit;

    FField.AsString := MemoContent.Text;
    ShowMessage('Conteúdo do campo atualizado com sucesso no DataSet!');
    Close;
  except
    on E: Exception do
      ShowMessage('Erro ao atualizar campo: ' + LineEnding + E.Message);
  end;
end;

procedure TFBCellViewerForm.BtnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := MemoContent.Text;
  ShowMessage('Conteúdo copiado para a Área de Transferência!');
end;

procedure TFBCellViewerForm.BtnSaveToFileClick(Sender: TObject);
var
  List: TStringList;
begin
  SaveDialogFile.DefaultExt := '.txt';
  SaveDialogFile.Filter := 'Arquivo de Texto (*.txt)|*.txt|Todos os arquivos (*.*)|*.*';
  if FField <> nil then
    SaveDialogFile.FileName := LowerCase(FField.FieldName) + '_conteudo.txt'
  else
    SaveDialogFile.FileName := 'conteudo.txt';

  if SaveDialogFile.Execute then
  begin
    List := TStringList.Create;
    try
      List.Text := MemoContent.Text;
      List.SaveToFile(SaveDialogFile.FileName);
      ShowMessage('Conteúdo salvo com sucesso!');
    finally
      List.Free;
    end;
  end;
end;

procedure TFBCellViewerForm.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
