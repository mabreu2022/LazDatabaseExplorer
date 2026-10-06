unit uFBExplorerMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, DBGrids, Grids, Menus, db, sqldb,
  // SynEdit
  SynEdit, SynHighlighterSQL,
  // Local units
  uFBTypes, uFBConnectionManager, uFBMetaData, uFBConnectionDialog,
  uFBCreateTableForm, uFBConstraintForm, uFBAlterFieldForm;

type
  TNodeKind = (nkDatabase, nkTablesGroup, nkTable, nkField, nkViewsGroup, nkView, nkProcsGroup, nkProc, nkTrigsGroup, nkTrig, nkGensGroup, nkGen);

  { TNodeInfo }
  TNodeInfo = class
  public
    Kind: TNodeKind;
    Name: string;
    Manager: TFBConnectionManager;
    constructor Create(AKind: TNodeKind; const AName: string; AManager: TFBConnectionManager = nil);
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
    BtnConstraints: TButton;

    PanelClient: TPanel;
    PanelLeft: TPanel;
    SplitterLeft: TSplitter;
    TreeViewMeta: TTreeView;

    PageControlMain: TPageControl;
    TabSheetSQL: TTabSheet;
    PanelEditorContainer: TPanel;
    SplitterEditor: TSplitter;
    PageControlResults: TPageControl;

    { Aba de Dados / Resultados }
    TabSheetGrid: TTabSheet;
    PanelDataTools: TPanel;
    BtnInsertRow: TButton;
    BtnDeleteRow: TButton;
    BtnPostRow: TButton;
    BtnCancelRow: TButton;
    BtnRefreshData: TButton;
    LabelDataHint: TLabel;
    DBGridResults: TDBGrid;

    { Aba de Log }
    TabSheetLog: TTabSheet;
    MemoLog: TMemo;

    { Aba de Estrutura da Tabela }
    TabSheetStructure: TTabSheet;
    PanelStructTop: TPanel;
    LabelStructTable: TLabel;
    BtnAddField: TButton;
    BtnAlterFieldType: TButton;
    BtnRenameField: TButton;
    BtnDropField: TButton;
    BtnRefreshStruct: TButton;
    GridStructFields: TStringGrid;
    SplitterStruct: TSplitter;
    MemoDDL: TMemo;

    StatusBar1: TStatusBar;
    DataSource1: TDataSource;
    SQLQuery1: TSQLQuery;

    PopupMenuTree: TPopupMenu;
    MenuItemSelectTop: TMenuItem;
    MenuItemConstraints: TMenuItem;
    MenuItemAlterFields: TMenuItem;
    MenuItemSeparator1: TMenuItem;
    MenuItemNewTable: TMenuItem;
    MenuItemDDL: TMenuItem;
    MenuItemDropTable: TMenuItem;
    MenuItemSeparator2: TMenuItem;
    MenuItemReconnectDb: TMenuItem;
    MenuItemDisconnectDb: TMenuItem;
    MenuItemRemoveDb: TMenuItem;
    MenuItemSeparator3: TMenuItem;
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
    procedure BtnConstraintsClick(Sender: TObject);

    procedure TreeViewMetaSelectionChanged(Sender: TObject);
    procedure TreeViewMetaDblClick(Sender: TObject);
    procedure TreeViewMetaDeletion(Sender: TObject; Node: TTreeNode);

    { Menus de contexto }
    procedure MenuItemSelectTopClick(Sender: TObject);
    procedure MenuItemDDLClick(Sender: TObject);
    procedure MenuItemDropTableClick(Sender: TObject);
    procedure MenuItemAlterFieldsClick(Sender: TObject);
    procedure MenuItemReconnectDbClick(Sender: TObject);
    procedure MenuItemDisconnectDbClick(Sender: TObject);
    procedure MenuItemRemoveDbClick(Sender: TObject);

    { Edição de Dados no Grid }
    procedure BtnInsertRowClick(Sender: TObject);
    procedure BtnDeleteRowClick(Sender: TObject);
    procedure BtnPostRowClick(Sender: TObject);
    procedure BtnCancelRowClick(Sender: TObject);
    procedure BtnRefreshDataClick(Sender: TObject);

    { Edição de Estrutura de Campos }
    procedure BtnAddFieldClick(Sender: TObject);
    procedure BtnAlterFieldTypeClick(Sender: TObject);
    procedure BtnRenameFieldClick(Sender: TObject);
    procedure BtnDropFieldClick(Sender: TObject);
    procedure BtnRefreshStructClick(Sender: TObject);
  private
    FSynEdit: TSynEdit;
    FSynSQLSyn: TSynSQLSyn;
    procedure InitSynEdit;
    procedure SetupStructGridHeaders;
    procedure OnConnectionChanged(Sender: TObject; Connected: Boolean; const Msg: string);
    procedure RefreshMetaDataTree;
    procedure AddOrRefreshDatabaseNode(AManager: TFBConnectionManager);
    function GetSelectedTableName: string;
    function GetSelectedDatabaseManager: TFBConnectionManager;
    procedure LoadTableStructure(const ATableName: string);
    procedure LogMsg(const Msg: string);
    procedure UpdateStatusBarInfo;
  public
    procedure OpenSelectedTableData(const ATableName: string; TopCount: Integer = 100);
  end;

var
  FBExplorerMainForm: TFBExplorerMainForm = nil;

procedure ShowFBExplorerForm;

implementation

{$R *.lfm}

{ TNodeInfo }

constructor TNodeInfo.Create(AKind: TNodeKind; const AName: string; AManager: TFBConnectionManager);
begin
  inherited Create;
  Kind := AKind;
  Name := AName;
  Manager := AManager;
end;

procedure ShowFBExplorerForm;
begin
  if FBExplorerMainForm = nil then
    Application.CreateForm(TFBExplorerMainForm, FBExplorerMainForm);
  FBExplorerMainForm.Show;
  FBExplorerMainForm.BringToFront;
end;

{ TFBExplorerMainForm }

procedure TFBExplorerMainForm.FormCreate(Sender: TObject);
var
  LastCfg: TFBConnectionConfig;
begin
  FBExplorerMainForm := Self;
  FBConnManager.OnConnectionChange := @OnConnectionChanged;

  InitSynEdit;
  SetupStructGridHeaders;

  PageControlMain.ActivePage := TabSheetSQL;
  PageControlResults.ActivePage := TabSheetGrid;

  // Tenta carregar último perfil usado
  if FBConnManager.LoadLastConnection(LastCfg) then
  begin
    StatusBar1.Panels[0].Text := 'Último perfil: ' + LastCfg.ProfileName;
  end;
end;

procedure TFBExplorerMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if SQLQuery1.Active then
    SQLQuery1.Close;
end;

procedure TFBExplorerMainForm.InitSynEdit;
begin
  FSynEdit := TSynEdit.Create(Self);
  FSynEdit.Parent := PanelEditorContainer;
  FSynEdit.Align := alClient;
  FSynEdit.Font.Name := 'Courier New';
  FSynEdit.Font.Size := 10;
  FSynEdit.Gutter.Width := 30;

  FSynSQLSyn := TSynSQLSyn.Create(Self);
  FSynSQLSyn.SQLDialect := sqlFirebird25;
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

procedure TFBExplorerMainForm.UpdateStatusBarInfo;
begin
  if (FBConnManager <> nil) and FBConnManager.IsConnected then
  begin
    StatusBar1.Panels[0].Text := Format('Ativo: %s (%s)',
      [FBConnManager.CurrentConfig.Host, ExtractFileName(FBConnManager.CurrentConfig.DatabasePath)]);
    StatusBar1.Panels[2].Text := 'Dialeto: ' + IntToStr(FBConnManager.CurrentConfig.SqlDialect);
    BtnDisconnect.Enabled := True;
  end
  else
  begin
    StatusBar1.Panels[0].Text := 'Banco Desconectado';
    BtnDisconnect.Enabled := False;
  end;
end;

procedure TFBExplorerMainForm.OnConnectionChanged(Sender: TObject; Connected: Boolean; const Msg: string);
begin
  UpdateStatusBarInfo;
  StatusBar1.Panels[1].Text := Msg;
  if not Connected then
  begin
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
  NewMgr: TFBConnectionManager;
begin
  if TFBConnectionDialog.Execute(Cfg) then
  begin
    NewMgr := FBMultiManager.FindByDatabasePath(Cfg.DatabasePath);
    if NewMgr = nil then
      NewMgr := FBMultiManager.CreateConnection(Cfg);

    if not NewMgr.IsConnected then
      NewMgr.Connect(Cfg);

    FBMultiManager.Active := NewMgr;
    FBConnManager := NewMgr;
    AddOrRefreshDatabaseNode(NewMgr);
    UpdateStatusBarInfo;
    LogMsg('Conectado com sucesso ao banco: ' + Cfg.DatabasePath);
  end;
end;

procedure TFBExplorerMainForm.BtnDisconnectClick(Sender: TObject);
var
  CurMgr: TFBConnectionManager;
begin
  CurMgr := GetSelectedDatabaseManager;
  if CurMgr = nil then CurMgr := FBConnManager;
  if CurMgr <> nil then
  begin
    CurMgr.Disconnect;
    AddOrRefreshDatabaseNode(CurMgr);
    UpdateStatusBarInfo;
    LogMsg('Banco desconectado: ' + CurMgr.CurrentConfig.DatabasePath);
  end;
end;

function TFBExplorerMainForm.GetSelectedDatabaseManager: TFBConnectionManager;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := TreeViewMeta.Selected;
  while Node <> nil do
  begin
    if (Node.Data <> nil) and (TNodeInfo(Node.Data).Manager <> nil) then
    begin
      Result := TNodeInfo(Node.Data).Manager;
      Exit;
    end;
    Node := Node.Parent;
  end;
  if Result = nil then
    Result := FBConnManager;
end;

procedure TFBExplorerMainForm.AddOrRefreshDatabaseNode(AManager: TFBConnectionManager);
var
  RootNode, TablesNode, ViewsNode, ProcsNode, TrigsNode, GensNode, TableNode: TTreeNode;
  List: TStringList;
  I, J: Integer;
  TblName, Title: string;
  Flds: TFBMetaFieldList;
  OldMgr: TFBConnectionManager;
begin
  if AManager = nil then Exit;

  RootNode := nil;
  for I := 0 to TreeViewMeta.Items.Count - 1 do
  begin
    if (TreeViewMeta.Items[I].Level = 0) and (TreeViewMeta.Items[I].Data <> nil) then
    begin
      if TNodeInfo(TreeViewMeta.Items[I].Data).Manager = AManager then
      begin
        RootNode := TreeViewMeta.Items[I];
        Break;
      end;
    end;
  end;

  Title := ExtractFileName(AManager.CurrentConfig.DatabasePath);
  if Title = '' then Title := AManager.CurrentConfig.ProfileName;
  if Title = '' then Title := 'Firebird DB';

  if AManager.IsConnected then
    Title := Title + ' (' + AManager.CurrentConfig.Host + ') [Conectado]'
  else
    Title := Title + ' (' + AManager.CurrentConfig.Host + ') [Desconectado]';

  if RootNode = nil then
    RootNode := TreeViewMeta.Items.AddObject(nil, Title,
      TNodeInfo.Create(nkDatabase, Title, AManager))
  else
  begin
    RootNode.Text := Title;
    RootNode.DeleteChildren;
  end;

  if not AManager.IsConnected then Exit;

  OldMgr := FBConnManager;
  FBConnManager := AManager;
  List := TStringList.Create;
  try
    // Tabelas
    TablesNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Tabelas',
      TNodeInfo.Create(nkTablesGroup, '', AManager));
    TFBMetaDataExtractor.GetTables(List, False);
    for I := 0 to List.Count - 1 do
    begin
      TblName := Trim(List[I]);
      TableNode := TreeViewMeta.Items.AddChildObject(TablesNode, TblName,
        TNodeInfo.Create(nkTable, TblName, AManager));

      Flds := TFBMetaDataExtractor.GetTableFields(TblName);
      for J := 0 to High(Flds) do
      begin
        if Flds[J].IsPrimaryKey then
          TreeViewMeta.Items.AddChildObject(TableNode, Format('PK: %s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName, AManager))
        else
          TreeViewMeta.Items.AddChildObject(TableNode, Format('%s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName, AManager));
      end;
    end;

    // Views
    ViewsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Views',
      TNodeInfo.Create(nkViewsGroup, '', AManager));
    TFBMetaDataExtractor.GetViews(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(ViewsNode, List[I],
        TNodeInfo.Create(nkView, List[I], AManager));

    // Procedures
    ProcsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Procedures',
      TNodeInfo.Create(nkProcsGroup, '', AManager));
    TFBMetaDataExtractor.GetProcedures(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(ProcsNode, List[I],
        TNodeInfo.Create(nkProc, List[I], AManager));

    // Triggers
    TrigsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Triggers',
      TNodeInfo.Create(nkTrigsGroup, '', AManager));
    TFBMetaDataExtractor.GetTriggers(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(TrigsNode, List[I],
        TNodeInfo.Create(nkTrig, List[I], AManager));

    // Sequences / Generators
    GensNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Sequences / Generators',
      TNodeInfo.Create(nkGensGroup, '', AManager));
    TFBMetaDataExtractor.GetGenerators(List);
    for I := 0 to List.Count - 1 do
      TreeViewMeta.Items.AddChildObject(GensNode, List[I],
        TNodeInfo.Create(nkGen, List[I], AManager));

    RootNode.Expand(False);
    TablesNode.Expand(False);
  finally
    List.Free;
    FBConnManager := OldMgr;
  end;
end;

procedure TFBExplorerMainForm.RefreshMetaDataTree;
var
  I: Integer;
begin
  TreeViewMeta.Items.BeginUpdate;
  try
    TreeViewMeta.Items.Clear;
    for I := 0 to FBMultiManager.Count - 1 do
      AddOrRefreshDatabaseNode(FBMultiManager[I]);
  finally
    TreeViewMeta.Items.EndUpdate;
  end;
end;

procedure TFBExplorerMainForm.BtnRefreshMetaClick(Sender: TObject);
var
  CurMgr: TFBConnectionManager;
begin
  CurMgr := GetSelectedDatabaseManager;
  if CurMgr <> nil then
  begin
    TreeViewMeta.Items.BeginUpdate;
    try
      AddOrRefreshDatabaseNode(CurMgr);
    finally
      TreeViewMeta.Items.EndUpdate;
    end;
  end
  else
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

procedure TFBExplorerMainForm.BtnConstraintsClick(Sender: TObject);
var
  Tbl: string;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de gerenciar chaves.');
    Exit;
  end;

  Tbl := GetSelectedTableName;
  TFBConstraintForm.Execute(Tbl);
  RefreshMetaDataTree;
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

  while (Length(Sql) > 0) and (Sql[Length(Sql)] in [';', ' ', #10, #13, #9]) do
    Delete(Sql, Length(Sql), 1);

  if Sql = '' then Exit;

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
        SQLQuery1.Close;
        SQLQuery1.DataBase := FBConnManager.Connection;
        SQLQuery1.Transaction := FBConnManager.Transaction;
        SQLQuery1.ParseSQL := True;
        SQLQuery1.UpdateMode := upWhereKeyOnly;
        SQLQuery1.SQL.Text := Sql;
        SQLQuery1.Open;

        ElapsedMs := GetTickCount64 - StartTime;
        PageControlResults.ActivePage := TabSheetGrid;
        LogMsg(Format('Consulta SELECT concluída em %d ms. Registros carregados.', [ElapsedMs]));
        StatusBar1.Panels[1].Text := Format('Linhas: %d | Tempo: %d ms (Edição Habilitada)', [SQLQuery1.RecordCount, ElapsedMs]);
      end
      else
      begin
        FBConnManager.ExecuteDirect(Sql, Rows);
        ElapsedMs := GetTickCount64 - StartTime;

        PageControlResults.ActivePage := TabSheetLog;
        LogMsg(Format('Comando executado com sucesso em %d ms. Linhas afetadas: %d.', [ElapsedMs, Rows]));
        StatusBar1.Panels[1].Text := Format('Afetadas: %d | Tempo: %d ms', [Rows, ElapsedMs]);

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

  LabelStructTable.Caption := 'Tabela: ' + ATableName;
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

  MemoDDL.Text := TFBMetaDataExtractor.GenerateCreateTableDDL(ATableName);
end;

procedure TFBExplorerMainForm.TreeViewMetaSelectionChanged(Sender: TObject);
var
  Tbl: string;
  Node: TTreeNode;
  Info: TNodeInfo;
begin
  Node := TreeViewMeta.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Manager <> nil then
    begin
      FBMultiManager.Active := Info.Manager;
      FBConnManager := Info.Manager;
      UpdateStatusBarInfo;
    end;
  end;

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
  Tbl, Sql: string;
  Rows: Integer;
begin
  Tbl := GetSelectedTableName;
  if Tbl = '' then Exit;

  if MessageDlg('Confirmação de Exclusão',
     Format('Deseja realmente EXCLUIR a tabela "%s"?' + LineEnding +
            'Esta ação apagará permanentemente todos os dados da tabela!', [Tbl]),
     mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Sql := TFBMetaDataExtractor.GenerateDropTableSQL(Tbl);
  try
    FBConnManager.ExecuteDirect(Sql, Rows);
    LogMsg('Tabela "' + Tbl + '" excluída com sucesso.');
    RefreshMetaDataTree;
  except
    on E: Exception do
      ShowMessage('Erro ao excluir tabela: ' + LineEnding + E.Message);
  end;
end;

procedure TFBExplorerMainForm.MenuItemAlterFieldsClick(Sender: TObject);
begin
  BtnAlterFieldTypeClick(Sender);
end;

procedure TFBExplorerMainForm.MenuItemReconnectDbClick(Sender: TObject);
var
  CurMgr: TFBConnectionManager;
begin
  CurMgr := GetSelectedDatabaseManager;
  if CurMgr <> nil then
  begin
    if not CurMgr.IsConnected then
      CurMgr.Connect(CurMgr.CurrentConfig);
    AddOrRefreshDatabaseNode(CurMgr);
    UpdateStatusBarInfo;
  end;
end;

procedure TFBExplorerMainForm.MenuItemDisconnectDbClick(Sender: TObject);
begin
  BtnDisconnectClick(Sender);
end;

procedure TFBExplorerMainForm.MenuItemRemoveDbClick(Sender: TObject);
var
  CurMgr: TFBConnectionManager;
  Node: TTreeNode;
begin
  CurMgr := GetSelectedDatabaseManager;
  if CurMgr = nil then Exit;

  if MessageDlg('Remover Banco',
     'Deseja remover este banco da lista de conexões?',
     mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    CurMgr.Disconnect;
    Node := TreeViewMeta.Selected;
    while (Node <> nil) and (Node.Level > 0) do
      Node := Node.Parent;
    if Node <> nil then
      Node.Free;
    FBMultiManager.RemoveConnection(CurMgr, True);
    UpdateStatusBarInfo;
  end;
end;

procedure TFBExplorerMainForm.TreeViewMetaDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Node.Data <> nil then
  begin
    TObject(Node.Data).Free;
    Node.Data := nil;
  end;
end;

{ Edição Direta de Dados no Grid }

procedure TFBExplorerMainForm.BtnInsertRowClick(Sender: TObject);
begin
  if not SQLQuery1.Active then
  begin
    ShowMessage('Abra uma tabela ou execute um SELECT antes de inserir registros.');
    Exit;
  end;
  SQLQuery1.Append;
  DBGridResults.SetFocus;
end;

procedure TFBExplorerMainForm.BtnDeleteRowClick(Sender: TObject);
begin
  if not SQLQuery1.Active or SQLQuery1.IsEmpty then Exit;
  if MessageDlg('Confirmação', 'Deseja excluir a linha selecionada do banco de dados?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      SQLQuery1.Delete;
      SQLQuery1.ApplyUpdates;
      FBConnManager.Transaction.CommitRetaining;
      LogMsg('Linha excluída com sucesso do banco.');
      StatusBar1.Panels[1].Text := 'Linha excluída.';
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao excluir linha: ' + LineEnding + E.Message);
        LogMsg('Erro na exclusão: ' + E.Message);
      end;
    end;
  end;
end;

procedure TFBExplorerMainForm.BtnPostRowClick(Sender: TObject);
begin
  if not SQLQuery1.Active then Exit;
  try
    if SQLQuery1.State in [dsEdit, dsInsert] then
      SQLQuery1.Post;

    SQLQuery1.ApplyUpdates;
    FBConnManager.Transaction.CommitRetaining;
    LogMsg('Alterações salvas com sucesso no banco de dados!');
    StatusBar1.Panels[1].Text := 'Dados salvos no Firebird com sucesso.';
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao salvar alterações no banco: ' + LineEnding + E.Message);
      LogMsg('Erro ao salvar dados: ' + E.Message);
    end;
  end;
end;

procedure TFBExplorerMainForm.BtnCancelRowClick(Sender: TObject);
begin
  if not SQLQuery1.Active then Exit;
  if SQLQuery1.State in [dsEdit, dsInsert] then
    SQLQuery1.Cancel;
  SQLQuery1.CancelUpdates;
  FBConnManager.Transaction.RollbackRetaining;
  LogMsg('Edição cancelada.');
  StatusBar1.Panels[1].Text := 'Edição cancelada.';
end;

procedure TFBExplorerMainForm.BtnRefreshDataClick(Sender: TObject);
var
  CurSQL: string;
begin
  CurSQL := Trim(SQLQuery1.SQL.Text);
  if CurSQL <> '' then
  begin
    SQLQuery1.Close;
    SQLQuery1.Open;
    LogMsg('Dados recarregados.');
    StatusBar1.Panels[1].Text := Format('Registros: %d', [SQLQuery1.RecordCount]);
  end;
end;

{ Edição da Estrutura de Campos (Alter Table) }

procedure TFBExplorerMainForm.BtnAddFieldClick(Sender: TObject);
var
  Tbl: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para adicionar campo.');
    Exit;
  end;
  if TFBAlterFieldForm.Execute(Tbl, afmAdd) then
  begin
    LoadTableStructure(Tbl);
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.BtnAlterFieldTypeClick(Sender: TObject);
var
  Tbl, SelFld: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para alterar o campo.');
    Exit;
  end;
  SelFld := '';
  if GridStructFields.Row > 0 then
    SelFld := Trim(GridStructFields.Cells[0, GridStructFields.Row]);
  if TFBAlterFieldForm.Execute(Tbl, afmAlterType, SelFld) then
  begin
    LoadTableStructure(Tbl);
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.BtnRenameFieldClick(Sender: TObject);
var
  Tbl, SelFld: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para renomear campo.');
    Exit;
  end;
  SelFld := '';
  if GridStructFields.Row > 0 then
    SelFld := Trim(GridStructFields.Cells[0, GridStructFields.Row]);
  if TFBAlterFieldForm.Execute(Tbl, afmRename, SelFld) then
  begin
    LoadTableStructure(Tbl);
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.BtnDropFieldClick(Sender: TObject);
var
  Tbl, SelFld: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para excluir campo.');
    Exit;
  end;
  SelFld := '';
  if GridStructFields.Row > 0 then
    SelFld := Trim(GridStructFields.Cells[0, GridStructFields.Row]);
  if TFBAlterFieldForm.Execute(Tbl, afmDrop, SelFld) then
  begin
    LoadTableStructure(Tbl);
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.BtnRefreshStructClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    LoadTableStructure(Tbl);
end;

end.
