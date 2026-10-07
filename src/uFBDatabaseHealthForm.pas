unit uFBDatabaseHealthForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uFBMetaData, uFBConnectionManager;

type
  { TFBDatabaseHealthForm }
  TFBDatabaseHealthForm = class(TForm)
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelCenter: TPanel;
    LabelTitle: TLabel;
    LabelDbInfo: TLabel;
    GroupBoxMetrics: TGroupBox;
    LabelPageSize: TLabel;
    LabelPageBuffers: TLabel;
    LabelSweepInterval: TLabel;
    LabelOIT: TLabel;
    LabelOAT: TLabel;
    LabelOST: TLabel;
    LabelNextTx: TLabel;
    LabelGap: TLabel;
    PanelStatus: TPanel;
    LabelHealthStatus: TLabel;
    BtnSweep: TButton;
    BtnRefresh: TButton;
    BtnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnSweepClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    procedure LoadHealthMetrics;
  public
    class procedure Execute;
  end;

implementation

{$R *.lfm}

{ TFBDatabaseHealthForm }

class procedure TFBDatabaseHealthForm.Execute;
var
  Form: TFBDatabaseHealthForm;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a um banco de dados para analisar o diagnóstico.');
    Exit;
  end;

  Form := TFBDatabaseHealthForm.Create(nil);
  try
    Form.LoadHealthMetrics;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TFBDatabaseHealthForm.FormCreate(Sender: TObject);
begin
  Caption := 'Diagnóstico de Saúde & Transações do Firebird';
end;

procedure TFBDatabaseHealthForm.LoadHealthMetrics;
var
  H: TFBDatabaseHealthInfo;
begin
  LabelDbInfo.Caption := Format('Banco: %s (%s)', [
    ExtractFileName(FBConnManager.CurrentConfig.DatabasePath),
    FBConnManager.CurrentConfig.Host
  ]);

  try
    H := TFBMetaDataExtractor.GetDatabaseHealthInfo;

    LabelPageSize.Caption      := Format('Tamanho de Página: %d bytes', [H.PageSize]);
    LabelPageBuffers.Caption   := Format('Buffers de Página (Cache): %d', [H.PageBuffers]);
    LabelSweepInterval.Caption := Format('Intervalo de Sweep Automático: %d transações', [H.SweepInterval]);

    LabelNextTx.Caption := Format('Próxima Transação (Next): %d', [H.NextTransaction]);
    LabelOAT.Caption    := Format('Mais Antiga Ativa (OAT): %d', [H.OAT]);
    LabelOIT.Caption    := Format('Mais Antiga de Interesse (OIT): %d', [H.OIT]);
    LabelOST.Caption    := Format('Mais Antiga Snapshot (OST): %d', [H.OST]);
    LabelGap.Caption    := Format('Diferencial Ativo (Next - OAT): %d transações', [H.Difference]);

    if H.Difference < 20000 then
    begin
      PanelStatus.Color := TColor($00DCFCE7); // Fundo verde claro
      LabelHealthStatus.Font.Color := TColor($00166534); // Texto verde escuro
      LabelHealthStatus.Caption := '🟢 SAUDÁVEL: O banco de dados está operando em excelente estado.' + LineEnding +
                                   'Não há retenção excessiva de transações nem acúmulo de versões de registros.';
    end
    else if H.Difference < 100000 then
    begin
      PanelStatus.Color := TColor($00FEF9C3); // Fundo amarelo
      LabelHealthStatus.Font.Color := TColor($00854D0E); // Texto âmbar
      LabelHealthStatus.Caption := '🟡 ATENÇÃO: Existem transações abertas retendo versões antigas.' + LineEnding +
                                   'Verifique se aplicações clientes esqueceram transações ativas sem Commit.';
    end
    else
    begin
      PanelStatus.Color := TColor($00FEE2E2); // Fundo vermelho claro
      LabelHealthStatus.Font.Color := TColor($00991B1B); // Texto vermelho escuro
      LabelHealthStatus.Caption := '🔴 CRÍTICO: Acúmulo severo de versões de registros (lixo)!' + LineEnding +
                                   'Recomenda-se fechar conexões travadas e executar Sweep imediatamente.';
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao obter métricas de saúde: ' + LineEnding + E.Message);
  end;
end;

procedure TFBDatabaseHealthForm.BtnRefreshClick(Sender: TObject);
begin
  LoadHealthMetrics;
end;

procedure TFBDatabaseHealthForm.BtnSweepClick(Sender: TObject);
begin
  if MessageDlg('Executar Sweep',
     'Deseja disparar a limpeza de versões mortas (Sweep) no banco de dados agora?' + LineEnding +
     'Esta operação força o recolhimento de versões pendentes de registros.',
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    try
      TFBMetaDataExtractor.ExecuteSweep;
      LoadHealthMetrics;
      ShowMessage('Ciclo de limpeza de transações concluído com sucesso!');
    except
      on E: Exception do
        ShowMessage('Erro ao executar Sweep: ' + LineEnding + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBDatabaseHealthForm.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
