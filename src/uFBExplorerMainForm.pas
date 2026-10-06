unit uFBExplorerMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, DBGrids, Grids, Menus, db, sqldb,
  // SynEdit
  SynEdit, SynHighlighterSQL,
  // Local units
  uFBTypes, uFBConnectionManager, uFBMetaData, uFBConnectionDialog, uFBCreateTableForm;

type
  TNodeKind = (nkDatabase, nkTablesGroup, nkTable, nkField, nkViewsGroup, nkView, nkProcsGroup, nkProc, nkTrigsGroup, nkTrig, nkGensGroup, nkGen);

  { TNodeInfo }
  TNodeInfo = class
  public
    Kind: TNodeKind;
    Name: string;
    constructor Create(AKind: TNodeKind; const AName: string);
  end;

  { TFBExplorerMainForm }
  TFBExplorerMainForm = class(TForm)
    PanelTopToolbar: TPanel;
    BtnConnect: TButton;
    BtnDisconnect: TButton;
    BtnRefreshMeta: TButton;
    BtnNewTable: TButton;
    BtnRunSQL: TButton;
    BtnCommit: TButton;
    BtnRollback: TButton;

    PanelClient: TPanel;
    PanelLeft: TPanel;
    SplitterLeft: TSplitter;
    TreeViewMeta: TTreeView;

    PageControlMain: TPageControl;
    TabSheetSQL: TTabSheet;
    PanelEditorContainer: TPanel;
    SplitterEditor: TSplitter;
    PageControlResults: TPageControl;
    TabSheetGrid: TTabSheet;
    DBGridResults: TDBGrid;
    TabSheetLog: TTabSheet;
    MemoLog: TMemo;

    TabSheetStructure: TTabSheet;
    PanelStructTop: TPanel;
    LabelStructTable: TLabel;
    GridStructFields: TStringGrid;
    SplitterStruct: TSplitter;
    MemoDDL: TMemo;

    StatusBar1: TStatusBar;
    DataSource1: TDataSource;
    SQLQuery1: TSQLQuery;

    PopupMenuTree: TPopupMenu;
    MenuItemSelectTop: TMenuItem;
    MenuItemSeparator1: TMenuItem;
    MenuItemNewTable: TMenuItem;
    MenuItemDDL: TMenuItem;
    MenuItemDropTable: TMenuItem;
    MenuItemSeparator2: TMenuItem;
    MenuItemRefresh: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnDisconnectClick(Sender: TObject);
    procedure BtnRefreshMetaClick(Sender: TObject);
    procedure BtnNewTableClick(Sender: TObject);
    procedure BtnRunSQLClick(Sender: TObject);
    procedure BtnCommitClick(Sender: TObject);
    procedure BtnRollbackClick(Sender: TObject);

    procedure TreeViewMetaSelectionChanged(Sender: TObject);
    procedure TreeViewMetaDblClick(Sender: TObject);
    procedure TreeViewMetaDeletion(Sender: TObject; Node: TTreeNode);

    procedure MenuItemSelectTopClick(Sender: TObject);
    procedure MenuItemDDLClick(Sender: TObject);
    procedure MenuItemDropTableClick(Sender: TObject);
  private
    FSynEdit: TSynEdit;
    FSynSQLSyn: TSynSQLSyn;
    procedure InitSynEdit;
    procedure SetupStructGridHeaders;
    procedure OnConnectionChanged(Sender: TObject; Connected: Boolean; const Msg: string);
    procedure RefreshMetaDataTree;
    function GetSelectedTableName: string;
    procedure LoadTableStructure(const ATableName: string);
    procedure LogMsg(const Msg: string);
  public
    procedure OpenSelectedTableData(const ATableName: string; TopCount: Integer = 100);
  end;

var
  FBExplorerMainForm: TFBExplorerMainForm = nil;

procedure ShowFBExplorerForm;

implementation

{$R *.lfm}

{ TNodeInfo }

constructor TNodeInfo.Create(AKind: TNodeKind; const AName: string);
begin
  inherited Create;
  Kind := AKind;
  Name := AName;
end;

procedure ShowFBExplorerForm;
begin
  if FBExplorerMainForm = nil then
    FBExplorerMainForm := TFBExplorerMainForm.Create(Application);
  FBExplorerMainForm.Show;
  FBExplorerMainForm.BringToFront;
end;

{ TFBExplorerMainForm }

procedure TFBExplorerMainForm.FormCreate(Sender: TObject);
begin
  InitSynEdit;
  SetupStructGridHeaders;

  TreeViewMeta.OnDeletion := @TreeViewMetaDeletion;

  FBConnManager.OnConnectionChange := @OnConnectionChanged;
  OnConnectionChanged(Self, FBConnManager.IsConnected, 'Pronto');
end;

procedure TFBExplorerMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

procedure TFBExplorerMainForm.TreeViewMetaDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Node.Data <> nil then
  begin
    TObject(Node.Data).Free;
    Node.Data := nil;
  end;
end;

procedure TFBExplorerMainForm.InitSynEdit;
begin
  FSynEdit := TSynEdit.Create(Self);
  FSynEdit.Parent := PanelEditorContainer;
  FSynEdit.Align := alClient;
  FSynEdit.Font.Name := 'Courier New';
  FSynEdit.Font.Size := 10;
  FSynEdit.Gutter.Visible := True;

  FSynSQLSyn := TSynSQLSyn.Create(Self);
  FSynSQLSyn.SQLDialect := sqlInterbase6;
  FSynEdit.Highlighter := FSynSQLSyn;

  FSynEdit.Text := 'SELECT * FROM RDB$DATABASE' + LineEnding;
end;

procedure TFBExplorerMainForm.SetupStructGridHeaders;
begin
  GridStructFields.ColCount := 6;
  GridStructFields.RowCount := 1;

  GridStructFields.Cells[0, 0] := 'Coluna';
  GridStructFields.Cells[1, 0] := 'Tipo';
  GridStructFields.Cells[2, 0] := 'Tamanho / Escala';
  GridStructFields.Cells[3, 0] := 'Não Nulo?';
  GridStructFields.Cells[4, 0] := 'Chave Primária?';
  GridStructFields.Cells[5, 0] := 'Valor Padrão';

  GridStructFields.ColWidths[0] := 150;
  GridStructFields.ColWidths[1] := 130;
  GridStructFields.ColWidths[2] := 110;
  GridStructFields.ColWidths[3] := 80;
  GridStructFields.ColWidths[4] := 110;
  GridStructFields.ColWidths[5] := 120;
end;

procedure TFBExplorerMainForm.OnConnectionChanged(Sender: TObject; Connected: Boolean; const Msg: string);
begin
  BtnDisconnect.Enabled := Connected;
  BtnRefreshMeta.Enabled := Connected;
  BtnNewTable.Enabled := Connected;
  BtnRunSQL.Enabled := Connected;
  BtnCommit.Enabled := Connected;
  BtnRollback.Enabled := Connected;

  if Connected then
  begin
    StatusBar1.Panels[0].Text := Format('Conectado: %s (%s)',
      [FBConnManager.CurrentConfig.Host, ExtractFileName(FBConnManager.CurrentConfig.DatabasePath)]);
    StatusBar1.Panels[1].Text := Msg;
  end
  else
  begin
    StatusBar1.Panels[0].Text := 'Desconectado';
    StatusBar1.Panels[1].Text := Msg;
    TreeViewMeta.Items.Clear;
    SQLQuery1.Close;
  end;
end;

procedure TFBExplorerMainForm.LogMsg(const Msg: string);
begin
  MemoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
end;

procedure TFBExplorerMainForm.BtnConnectClick(Sender: TObject);
var
  Cfg: TFBConnectionConfig;
begin
  if TFBConnectionDialog.Execute(Cfg) then
  begin
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.BtnDisconnectClick(Sender: TObject);
begin
  FBConnManager.Disconnect;
end;

procedure TFBExplorerMainForm.RefreshMetaDataTree;
var
  RootNode, TablesNode, ViewsNode, ProcsNode, TrigsNode, GensNode, TableNode: TTreeNode;
  List: TStringList;
  I, J: Integer;
  TblName: string;
  Flds: TFBMetaFieldList;
begin
  if not FBConnManager.IsConnected then Exit;

  TreeViewMeta.Items.BeginUpdate;
  List := TStringList.Create;
  try
    TreeViewMeta.Items.Clear;

    RootNode := TreeViewMeta.Items.AddObject(nil, ExtractFileName(FBConnManager.CurrentConfig.DatabasePath),
      TNodeInfo.Create(nkDatabase, ExtractFileName(FBConnManager.CurrentConfig.DatabasePath)));

    // Tabelas
    TablesNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Tabelas',
      TNodeInfo.Create(nkTablesGroup, ''));
    TFBMetaDataExtractor.GetTables(List, False);
    for I := 0 to List.Count - 1 do
    begin
      TblName := Trim(List[I]);
      TableNode := TreeViewMeta.Items.AddChildObject(TablesNode, TblName,
        TNodeInfo.Create(nkTable, TblName));

      // Colunas
      Flds := TFBMetaDataExtractor.GetTableFields(TblName);
      for J := 0 to High(Flds) do
      begin
        if Flds[J].IsPrimaryKey then
          TreeViewMeta.Items.AddChildObject(TableNode, Format('PK: %s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName))
        else
          TreeViewMeta.Items.AddChildObject(TableNode, Format('%s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName));
      end;
    end;

    // Views
    ViewsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Views',
      TNodeInfo.Create(nkViewsGroup, ''));
    TFBMetaDataExtractor.GetViews(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(ViewsNode, List[I],
        TNodeInfo.Create(nkView, List[I]));

    // Procedures
    ProcsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Procedures',
      TNodeInfo.Create(nkProcsGroup, ''));
    TFBMetaDataExtractor.GetProcedures(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(ProcsNode, List[I],
        TNodeInfo.Create(nkProc, List[I]));

    // Triggers
    TrigsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Triggers',
      TNodeInfo.Create(nkTrigsGroup, ''));
    TFBMetaDataExtractor.GetTriggers(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(TrigsNode, List[I],
        TNodeInfo.Create(nkTrig, List[I]));

    // Generators / Sequences
    GensNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Sequences / Generators',
      TNodeInfo.Create(nkGensGroup, ''));
    TFBMetaDataExtractor.GetGenerators(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(GensNode, List[I],
        TNodeInfo.Create(nkGen, List[I]));

    RootNode.Expand(False);
    TablesNode.Expand(False);
  finally
    List.Free;
    TreeViewMeta.Items.EndUpdate;
  end;
end;

procedure TFBExplorerMainForm.BtnRefreshMetaClick(Sender: TObject);
begin
  RefreshMetaDataTree;
end;

procedure TFBExplorerMainForm.BtnNewTableClick(Sender: TObject);
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de criar tabelas.');
    Exit;
  end;

  if TFBCreateTableForm.Execute then
  begin
    RefreshMetaDataTree;
    LogMsg('Nova tabela criada com sucesso.');
  end;
end;

procedure TFBExplorerMainForm.BtnRunSQLClick(Sender: TObject);
var
  Sql, CleanSql: string;
  Rows: Integer;
  StartTime: QWord;
  ElapsedMs: QWord;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Não conectado a um banco de dados.');
    Exit;
  end;

  if FSynEdit.SelText <> '' then
    Sql := Trim(FSynEdit.SelText)
  else
    Sql := Trim(FSynEdit.Text);

  if Sql = '' then Exit;

  // Remove espaços e qualquer ponto-e-vírgula ';' final
  // O Firebird isc_dsql_prepare rejeita ';' no final com erro -Token unknown - ;
  while (Length(Sql) > 0) and (Sql[Length(Sql)] in [';', ' ', #10, #13, #9]) do
    Delete(Sql, Length(Sql), 1);

  if Sql = '' then Exit;

  // Localiza o primeiro comando real ignorando comentários de linha inicial (-- ...)
  CleanSql := UpperCase(Sql);
  while Length(CleanSql) > 0 do
  begin
    while (Length(CleanSql) > 0) and (CleanSql[1] in [' ', #10, #13, #9]) do
      Delete(CleanSql, 1, 1);
    if Pos('--', CleanSql) = 1 then
    begin
      while (Length(CleanSql) > 0) and not (CleanSql[1] in [#10, #13]) do
        Delete(CleanSql, 1, 1);
    end
    else
      Break;
  end;

  StartTime := GetTickCount64;
  Screen.Cursor := crHourGlass;
  try
    try
      if (Pos('SELECT', CleanSql) = 1) or (Pos('WITH', CleanSql) = 1) then
      begin
        // Query de consulta
        FBConnManager.ExecuteQuery(Sql, SQLQuery1);
        ElapsedMs := GetTickCount64 - StartTime;

        PageControlResults.ActivePage := TabSheetGrid;
        LogMsg(Format('Consulta SELECT concluída em %d ms. Registros carregados.', [ElapsedMs]));
        StatusBar1.Panels[1].Text := Format('Linhas: %d | Tempo: %d ms', [SQLQuery1.RecordCount, ElapsedMs]);
      end
      else
      begin
        // DDL ou DML (INSERT, UPDATE, DELETE, CREATE, DROP, ALTER)
        FBConnManager.ExecuteDirect(Sql, Rows);
        ElapsedMs := GetTickCount64 - StartTime;

        PageControlResults.ActivePage := TabSheetLog;
        LogMsg(Format('Comando executado com sucesso em %d ms. Linhas afetadas: %d.', [ElapsedMs, Rows]));
        StatusBar1.Panels[1].Text := Format('Afetadas: %d | Tempo: %d ms', [Rows, ElapsedMs]);

        // Se criou ou excluiu tabela, atualiza metadados automaticamente
        if (Pos('CREATE TABLE', CleanSql) > 0) or
           (Pos('DROP TABLE', CleanSql) > 0) or
           (Pos('ALTER TABLE', CleanSql) > 0) then
        begin
          RefreshMetaDataTree;
        end;
      end;
    except
      on E: Exception do
      begin
        PageControlResults.ActivePage := TabSheetLog;
        LogMsg('ERRO: ' + E.Message);
        StatusBar1.Panels[1].Text := 'Erro na execução.';
        ShowMessage('Erro ao executar SQL: ' + LineEnding + E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFBExplorerMainForm.BtnCommitClick(Sender: TObject);
begin
  FBConnManager.Commit;
  LogMsg('Transação confirmada (Commit realizado).');
  StatusBar1.Panels[1].Text := 'Commit efetuado.';
end;

procedure TFBExplorerMainForm.BtnRollbackClick(Sender: TObject);
begin
  FBConnManager.Rollback;
  LogMsg('Transação desfeita (Rollback realizado).');
  StatusBar1.Panels[1].Text := 'Rollback efetuado.';
end;

function TFBExplorerMainForm.GetSelectedTableName: string;
var
  Node: TTreeNode;
  Info: TNodeInfo;
begin
  Result := '';
  Node := TreeViewMeta.Selected;
  if Node = nil then Exit;

  if Node.Data <> nil then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Kind = nkTable then
      Result := Trim(Info.Name)
    else if (Info.Kind = nkField) and (Node.Parent <> nil) and (Node.Parent.Data <> nil) then
    begin
      if TNodeInfo(Node.Parent.Data).Kind = nkTable then
        Result := Trim(TNodeInfo(Node.Parent.Data).Name);
    end;
  end;
end;

procedure TFBExplorerMainForm.LoadTableStructure(const ATableName: string);
var
  Flds: TFBMetaFieldList;
  I, R: Integer;
begin
  if ATableName = '' then Exit;

  LabelStructTable.Caption := 'Tabela Selecionada: ' + ATableName;
  Flds := TFBMetaDataExtractor.GetTableFields(ATableName);

  GridStructFields.RowCount := Length(Flds) + 1;
  for I := 0 to High(Flds) do
  begin
    R := I + 1;
    GridStructFields.Cells[0, R] := Flds[I].FieldName;
    GridStructFields.Cells[1, R] := Flds[I].TypeName;
    GridStructFields.Cells[2, R] := Format('%d / %d', [Flds[I].FieldLength, Flds[I].FieldScale]);
    if Flds[I].NotNull then
      GridStructFields.Cells[3, R] := 'SIM'
    else
      GridStructFields.Cells[3, R] := 'NÃO';

    if Flds[I].IsPrimaryKey then
      GridStructFields.Cells[4, R] := 'SIM'
    else
      GridStructFields.Cells[4, R] := 'NÃO';

    GridStructFields.Cells[5, R] := Flds[I].DefaultValue;
  end;

  // DDL
  MemoDDL.Text := TFBMetaDataExtractor.GenerateCreateTableDDL(ATableName);
end;

procedure TFBExplorerMainForm.TreeViewMetaSelectionChanged(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
  begin
    LoadTableStructure(Tbl);
  end;
end;

procedure TFBExplorerMainForm.TreeViewMetaDblClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    OpenSelectedTableData(Tbl, 100);
end;

procedure TFBExplorerMainForm.OpenSelectedTableData(const ATableName: string; TopCount: Integer);
var
  Sql: string;
begin
  Sql := TFBMetaDataExtractor.GenerateSelectTopSQL(Trim(ATableName), TopCount);
  FSynEdit.Text := Sql;
  PageControlMain.ActivePage := TabSheetSQL;
  BtnRunSQLClick(Self);
end;

procedure TFBExplorerMainForm.MenuItemSelectTopClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    OpenSelectedTableData(Tbl, 100);
end;

procedure TFBExplorerMainForm.MenuItemDDLClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
  begin
    LoadTableStructure(Tbl);
    PageControlMain.ActivePage := TabSheetStructure;
  end;
end;

procedure TFBExplorerMainForm.MenuItemDropTableClick(Sender: TObject);
var
  Tbl: string;
  Rows: Integer;
begin
  Tbl := GetSelectedTableName;
  if Tbl = '' then Exit;

  if MessageDlg('Confirmação',
    Format('ATENÇÃO: Deseja realmente excluir permanentemente a tabela "%s" e todos os seus dados?', [Tbl]),
    mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FBConnManager.ExecuteDirect(TFBMetaDataExtractor.GenerateDropTableSQL(Tbl), Rows);
      ShowMessage('Tabela excluída com sucesso.');
      RefreshMetaDataTree;
    except
      on E: Exception do
        ShowMessage('Erro ao excluir tabela: ' + E.Message);
    end;
  end;
end;

end.
