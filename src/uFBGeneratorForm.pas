unit uFBGeneratorForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uFBMetaData, uFBConnectionManager;

type
  { TFBGeneratorForm }
  TFBGeneratorForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelCenter: TPanel;
    LabelTitle: TLabel;
    LabelGenName: TLabel;
    ComboGenerators: TComboBox;
    LabelCurrentVal: TLabel;
    EditCurrentVal: TEdit;
    BtnRefreshVal: TButton;
    LabelNewVal: TLabel;
    EditNewVal: TEdit;
    BtnApplyVal: TButton;
    GroupBoxCreate: TGroupBox;
    LabelNewGenName: TLabel;
    EditNewGenName: TEdit;
    LabelInitialVal: TLabel;
    EditInitialVal: TEdit;
    BtnCreateGen: TButton;
    BtnDropGen: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure ComboGeneratorsChange(Sender: TObject);
    procedure BtnRefreshValClick(Sender: TObject);
    procedure BtnApplyValClick(Sender: TObject);
    procedure BtnCreateGenClick(Sender: TObject);
    procedure BtnDropGenClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    procedure LoadGeneratorsList(const ASelectName: string = '');
    procedure RefreshCurrentValue;
  public
    class procedure Execute(const AInitialGenName: string = '');
  end;

implementation

{$R *.lfm}

{ TFBGeneratorForm }

class procedure TFBGeneratorForm.Execute(const AInitialGenName: string);
var
  Form: TFBGeneratorForm;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a um banco Firebird antes de gerenciar Sequences/Generators.');
    Exit;
  end;

  Form := TFBGeneratorForm.Create(nil);
  try
    Form.LoadGeneratorsList(AInitialGenName);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TFBGeneratorForm.FormCreate(Sender: TObject);
begin
  Caption := 'Gerenciador de Sequences / Generators';
end;

procedure TFBGeneratorForm.LoadGeneratorsList(const ASelectName: string);
var
  List: TStringList;
  Idx: Integer;
begin
  List := TStringList.Create;
  try
    TFBMetaDataExtractor.GetGenerators(List);
    ComboGenerators.Items.Assign(List);
    if ASelectName <> '' then
    begin
      Idx := ComboGenerators.Items.IndexOf(ASelectName);
      if Idx >= 0 then
        ComboGenerators.ItemIndex := Idx
      else
      begin
        ComboGenerators.Items.Add(ASelectName);
        ComboGenerators.ItemIndex := ComboGenerators.Items.Count - 1;
      end;
    end
    else if ComboGenerators.Items.Count > 0 then
      ComboGenerators.ItemIndex := 0;

    RefreshCurrentValue;
  finally
    List.Free;
  end;
end;

procedure TFBGeneratorForm.RefreshCurrentValue;
var
  GenName: string;
  Val: Int64;
begin
  GenName := Trim(ComboGenerators.Text);
  if GenName = '' then
  begin
    EditCurrentVal.Text := '0';
    Exit;
  end;

  try
    Val := TFBMetaDataExtractor.GetGeneratorValue(GenName);
    EditCurrentVal.Text := IntToStr(Val);
    EditNewVal.Text := IntToStr(Val);
  except
    on E: Exception do
      EditCurrentVal.Text := 'Erro: ' + E.Message;
  end;
end;

procedure TFBGeneratorForm.ComboGeneratorsChange(Sender: TObject);
begin
  RefreshCurrentValue;
end;

procedure TFBGeneratorForm.BtnRefreshValClick(Sender: TObject);
begin
  RefreshCurrentValue;
end;

procedure TFBGeneratorForm.BtnApplyValClick(Sender: TObject);
var
  GenName: string;
  NewVal: Int64;
begin
  GenName := Trim(ComboGenerators.Text);
  if GenName = '' then
  begin
    ShowMessage('Selecione ou informe um Generator.');
    Exit;
  end;

  if not TryStrToInt64(Trim(EditNewVal.Text), NewVal) then
  begin
    ShowMessage('Informe um valor numérico inteiro válido.');
    Exit;
  end;

  try
    TFBMetaDataExtractor.SetGeneratorValue(GenName, NewVal);
    FBConnManager.Transaction.CommitRetaining;
    RefreshCurrentValue;
    ShowMessage(Format('Valor da Sequence/Generator "%s" atualizado para %d com sucesso!', [GenName, NewVal]));
  except
    on E: Exception do
      ShowMessage('Erro ao alterar valor: ' + LineEnding + E.Message);
  end;
end;

procedure TFBGeneratorForm.BtnCreateGenClick(Sender: TObject);
var
  NewName: string;
  InitVal: Int64;
begin
  NewName := UpperCase(Trim(EditNewGenName.Text));
  if NewName = '' then
  begin
    ShowMessage('Informe o nome da nova Sequence/Generator.');
    Exit;
  end;

  if not TryStrToInt64(Trim(EditInitialVal.Text), InitVal) then
    InitVal := 0;

  try
    TFBMetaDataExtractor.CreateGenerator(NewName, InitVal);
    FBConnManager.Transaction.CommitRetaining;
    ShowMessage(Format('Sequence "%s" criada com sucesso com valor inicial %d!', [NewName, InitVal]));
    EditNewGenName.Text := '';
    LoadGeneratorsList(NewName);
  except
    on E: Exception do
      ShowMessage('Erro ao criar Sequence: ' + LineEnding + E.Message);
  end;
end;

procedure TFBGeneratorForm.BtnDropGenClick(Sender: TObject);
var
  GenName: string;
begin
  GenName := Trim(ComboGenerators.Text);
  if GenName = '' then Exit;

  if MessageDlg('Confirmação',
     Format('Deseja realmente EXCLUIR a Sequence/Generator "%s"?', [GenName]),
     mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    TFBMetaDataExtractor.DropGenerator(GenName);
    FBConnManager.Transaction.CommitRetaining;
    ShowMessage(Format('Sequence "%s" excluída com sucesso!', [GenName]));
    LoadGeneratorsList;
  except
    on E: Exception do
      ShowMessage('Erro ao excluir Sequence: ' + LineEnding + E.Message);
  end;
end;

procedure TFBGeneratorForm.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
