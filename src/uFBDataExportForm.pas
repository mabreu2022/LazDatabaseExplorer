unit uFBDataExportForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Clipbrd, db, fpjson;

type
  TExportFormat = (efCSV, efJSON, efSQL);

  { TFBDataExportForm }
  TFBDataExportForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelCenter: TPanel;
    LabelTitle: TLabel;
    RadioGroupFormat: TRadioGroup;
    GroupBoxOptions: TGroupBox;
    LabelDelimiter: TLabel;
    EditDelimiter: TEdit;
    CheckBoxIncludeHeaders: TCheckBox;
    LabelTargetTable: TLabel;
    EditTargetTable: TEdit;
    LabelPreview: TLabel;
    MemoPreview: TMemo;
    ProgressBarExport: TProgressBar;
    SaveDialogExport: TSaveDialog;
    BtnSaveToFile: TButton;
    BtnCopyToClipboard: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure RadioGroupFormatClick(Sender: TObject);
    procedure EditTargetTableChange(Sender: TObject);
    procedure EditDelimiterChange(Sender: TObject);
    procedure CheckBoxIncludeHeadersChange(Sender: TObject);
    procedure BtnSaveToFileClick(Sender: TObject);
    procedure BtnCopyToClipboardClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    FDataSet: TDataSet;
    FDefaultTableName: string;
    procedure UpdatePreview;
    function GenerateExportString(MaxRows: Integer = 0): string;
    function FormatCSVRow(IsHeader: Boolean): string;
    function EscapeSQLValue(AField: TField): string;
  public
    class procedure Execute(ADataSet: TDataSet; const ATableName: string = '');
  end;

implementation

{$R *.lfm}

{ TFBDataExportForm }

class procedure TFBDataExportForm.Execute(ADataSet: TDataSet; const ATableName: string);
var
  Form: TFBDataExportForm;
begin
  if (ADataSet = nil) or (not ADataSet.Active) or ADataSet.IsEmpty then
  begin
    ShowMessage('Não há dados ativos para exportação.');
    Exit;
  end;

  Form := TFBDataExportForm.Create(nil);
  try
    Form.FDataSet := ADataSet;
    Form.FDefaultTableName := Trim(ATableName);
    if Form.FDefaultTableName = '' then
      Form.FDefaultTableName := 'EXPORTED_TABLE';
    Form.EditTargetTable.Text := Form.FDefaultTableName;
    Form.RadioGroupFormat.ItemIndex := 0; // CSV
    Form.UpdatePreview;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TFBDataExportForm.FormCreate(Sender: TObject);
begin
  Caption := 'Exportador de Dados Profissional';
  RadioGroupFormat.Items.Clear;
  RadioGroupFormat.Items.Add('CSV (Valores Separados por Delimitador)');
  RadioGroupFormat.Items.Add('JSON (JavaScript Object Notation)');
  RadioGroupFormat.Items.Add('Script SQL (Comandos INSERT INTO)');
  RadioGroupFormat.ItemIndex := 0;

  EditDelimiter.Text := ';';
  CheckBoxIncludeHeaders.Checked := True;
end;

procedure TFBDataExportForm.RadioGroupFormatClick(Sender: TObject);
begin
  EditDelimiter.Enabled := (RadioGroupFormat.ItemIndex = 0);
  CheckBoxIncludeHeaders.Enabled := (RadioGroupFormat.ItemIndex = 0);
  EditTargetTable.Enabled := (RadioGroupFormat.ItemIndex = 2);
  UpdatePreview;
end;

procedure TFBDataExportForm.EditTargetTableChange(Sender: TObject);
begin
  if RadioGroupFormat.ItemIndex = 2 then
    UpdatePreview;
end;

procedure TFBDataExportForm.EditDelimiterChange(Sender: TObject);
begin
  if RadioGroupFormat.ItemIndex = 0 then
    UpdatePreview;
end;

procedure TFBDataExportForm.CheckBoxIncludeHeadersChange(Sender: TObject);
begin
  if RadioGroupFormat.ItemIndex = 0 then
    UpdatePreview;
end;

function TFBDataExportForm.FormatCSVRow(IsHeader: Boolean): string;
var
  I: Integer;
  Delim, Val: string;
begin
  Result := '';
  Delim := EditDelimiter.Text;
  if Delim = '' then Delim := ';';

  for I := 0 to FDataSet.FieldCount - 1 do
  begin
    if IsHeader then
      Val := FDataSet.Fields[I].FieldName
    else
    begin
      if FDataSet.Fields[I].IsNull then
        Val := ''
      else
        Val := FDataSet.Fields[I].AsString;
    end;

    // Se contém delimitador, quebra de linha ou aspas, coloca entre aspas
    if (Pos(Delim, Val) > 0) or (Pos('"', Val) > 0) or (Pos(#10, Val) > 0) then
      Val := '"' + StringReplace(Val, '"', '""', [rfReplaceAll]) + '"';

    if I = 0 then
      Result := Val
    else
      Result := Result + Delim + Val;
  end;
end;

function TFBDataExportForm.EscapeSQLValue(AField: TField): string;
var
  S: string;
begin
  if (AField = nil) or AField.IsNull then
    Exit('NULL');

  case AField.DataType of
    ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc:
      Result := AField.AsString;
    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
      begin
        S := StringReplace(AField.AsString, ',', '.', [rfReplaceAll]);
        Result := S;
      end;
    ftBoolean:
      if AField.AsBoolean then
        Result := 'TRUE'
      else
        Result := 'FALSE';
    ftDate:
      Result := QuotedStr(FormatDateTime('yyyy-mm-dd', AField.AsDateTime));
    ftTime:
      Result := QuotedStr(FormatDateTime('hh:nn:ss', AField.AsDateTime));
    ftDateTime, ftTimeStamp:
      Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', AField.AsDateTime));
  else
    Result := QuotedStr(StringReplace(AField.AsString, '''', '''''', [rfReplaceAll]));
  end;
end;

function TFBDataExportForm.GenerateExportString(MaxRows: Integer): string;
var
  BookMark: TBookmark;
  RowCount, I: Integer;
  Lines: TStringList;
  TblName, ColsList, ValsList, Delim: string;
  JArray: TJSONArray;
  JRow: TJSONObject;
begin
  Result := '';
  if (FDataSet = nil) or (not FDataSet.Active) then Exit;

  BookMark := FDataSet.GetBookmark;
  Lines := TStringList.Create;
  FDataSet.DisableControls;
  try
    FDataSet.First;
    RowCount := 0;

    case RadioGroupFormat.ItemIndex of
      0: // CSV
        begin
          if CheckBoxIncludeHeaders.Checked then
            Lines.Add(FormatCSVRow(True));

          while not FDataSet.EOF do
          begin
            Lines.Add(FormatCSVRow(False));
            Inc(RowCount);
            if (MaxRows > 0) and (RowCount >= MaxRows) then Break;
            FDataSet.Next;
          end;
          Result := Lines.Text;
        end;

      1: // JSON
        begin
          JArray := TJSONArray.Create;
          try
            while not FDataSet.EOF do
            begin
              JRow := TJSONObject.Create;
              for I := 0 to FDataSet.FieldCount - 1 do
              begin
                if FDataSet.Fields[I].IsNull then
                  JRow.Add(FDataSet.Fields[I].FieldName, TJSONNull.Create)
                else
                begin
                  case FDataSet.Fields[I].DataType of
                    ftSmallint, ftInteger, ftWord, ftAutoInc:
                      JRow.Add(FDataSet.Fields[I].FieldName, FDataSet.Fields[I].AsInteger);
                    ftLargeint:
                      JRow.Add(FDataSet.Fields[I].FieldName, FDataSet.Fields[I].AsLargeInt);
                    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
                      JRow.Add(FDataSet.Fields[I].FieldName, FDataSet.Fields[I].AsFloat);
                    ftBoolean:
                      JRow.Add(FDataSet.Fields[I].FieldName, FDataSet.Fields[I].AsBoolean);
                  else
                    JRow.Add(FDataSet.Fields[I].FieldName, FDataSet.Fields[I].AsString);
                  end;
                end;
              end;
              JArray.Add(JRow);
              Inc(RowCount);
              if (MaxRows > 0) and (RowCount >= MaxRows) then Break;
              FDataSet.Next;
            end;
            Result := JArray.FormatJSON([], 2);
          finally
            JArray.Free;
          end;
        end;

      2: // SQL INSERT
        begin
          TblName := Trim(EditTargetTable.Text);
          if TblName = '' then TblName := 'MY_TABLE';

          ColsList := '';
          for I := 0 to FDataSet.FieldCount - 1 do
          begin
            if I > 0 then ColsList := ColsList + ', ';
            ColsList := ColsList + FDataSet.Fields[I].FieldName;
          end;

          while not FDataSet.EOF do
          begin
            ValsList := '';
            for I := 0 to FDataSet.FieldCount - 1 do
            begin
              if I > 0 then ValsList := ValsList + ', ';
              ValsList := ValsList + EscapeSQLValue(FDataSet.Fields[I]);
            end;

            Lines.Add(Format('INSERT INTO %s (%s) VALUES (%s);', [TblName, ColsList, ValsList]));
            Inc(RowCount);
            if (MaxRows > 0) and (RowCount >= MaxRows) then Break;
            FDataSet.Next;
          end;
          Result := Lines.Text;
        end;
    end;
  finally
    if FDataSet.BookmarkValid(BookMark) then
      FDataSet.GotoBookmark(BookMark);
    FDataSet.FreeBookmark(BookMark);
    FDataSet.EnableControls;
    Lines.Free;
  end;
end;

procedure TFBDataExportForm.UpdatePreview;
begin
  MemoPreview.Text := GenerateExportString(5);
end;

procedure TFBDataExportForm.BtnSaveToFileClick(Sender: TObject);
var
  Ext, Filter, Content: string;
  OutputList: TStringList;
begin
  case RadioGroupFormat.ItemIndex of
    0:
      begin
        Ext := '.csv';
        Filter := 'Arquivo CSV (*.csv)|*.csv|Todos os arquivos (*.*)|*.*';
      end;
    1:
      begin
        Ext := '.json';
        Filter := 'Arquivo JSON (*.json)|*.json|Todos os arquivos (*.*)|*.*';
      end;
    2:
      begin
        Ext := '.sql';
        Filter := 'Script SQL (*.sql)|*.sql|Todos os arquivos (*.*)|*.*';
      end;
  end;

  SaveDialogExport.DefaultExt := Ext;
  SaveDialogExport.Filter := Filter;
  SaveDialogExport.FileName := LowerCase(Trim(EditTargetTable.Text)) + '_export' + Ext;

  if SaveDialogExport.Execute then
  begin
    Screen.Cursor := crHourGlass;
    ProgressBarExport.Visible := True;
    ProgressBarExport.Style := pbstMarquee;
    OutputList := TStringList.Create;
    try
      Content := GenerateExportString(0);
      OutputList.Text := Content;
      OutputList.SaveToFile(SaveDialogExport.FileName);
      ShowMessage(Format('Exportação concluída com sucesso!' + LineEnding + 'Arquivo: %s',
        [SaveDialogExport.FileName]));
    finally
      OutputList.Free;
      ProgressBarExport.Visible := False;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TFBDataExportForm.BtnCopyToClipboardClick(Sender: TObject);
var
  Content: string;
begin
  Screen.Cursor := crHourGlass;
  try
    Content := GenerateExportString(0);
    Clipboard.AsText := Content;
    ShowMessage('Dados exportados e copiados para a Área de Transferência com sucesso!');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBDataExportForm.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
