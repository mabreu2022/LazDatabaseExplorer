unit uFBExplorerMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, DBGrids, Grids, Menus, LCLType, db, sqldb,
  // SynEdit
  SynEdit, SynHighlighterSQL,
  // Local units
  uFBTypes, uFBConnectionManager, uFBMetaData, uFBConnectionDialog,
  uFBCreateTableForm, uFBConstraintForm, uFBAlterFieldForm,
  uFBDataExportForm, uFBGeneratorForm, uFBCellViewerForm, uFBTreeIcons,
  uFBIndexManagerForm, uFBDatabaseHealthForm;

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
    BtnAlterTable: TButton;
    BtnRunSQL: TButton;
    BtnCommit: TButton;
    BtnRollback: TButton;
    BtnConstraints: TButton;
    BtnGenerators: TButton;
    BtnHealth: TButton;
    BtnExtractAllDDL: TButton;

    PanelClient: TPanel;
    PanelLeft: TPanel;
    SplitterLeft: TSplitter;
    TreeViewMeta: TTreeView;

    PageControlMain: TPageControl;
    TabSheetSQL: TTabSheet;
    PanelSQLBar: TPanel;
    BtnNewQueryTab: TButton;
    BtnCloseQueryTab: TButton;
    LabelHistory: TLabel;
    ComboSQLHistory: TComboBox;
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
    BtnExportData: TButton;
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
    BtnStructConstraints: TButton;
    BtnIndices: TButton;
    BtnRefreshStruct: TButton;
    GridStructFields: TStringGrid;
    SplitterStruct: TSplitter;
    MemoDDL: TMemo;

    StatusBar1: TStatusBar;
    DataSource1: TDataSource;
    SQLQuery1: TSQLQuery;

    PopupMenuTree: TPopupMenu;
    MenuItemSelectTop: TMenuItem;
    MenuItemExportTable: TMenuItem;
    MenuItemConstraints: TMenuItem;
    MenuItemAlterFields: TMenuItem;
    MenuItemIndices: TMenuItem;
    MenuItemEditPSQL: TMenuItem;
    MenuItemSeparator1: TMenuItem;
    MenuItemNewTable: TMenuItem;
    MenuItemGenerators: TMenuItem;
    MenuItemDDL: TMenuItem;
    MenuItemDropTable: TMenuItem;
    MenuItemSeparator2: TMenuItem;
    MenuItemHealth: TMenuItem;
    MenuItemExtractAllDDL: TMenuItem;
    MenuItemReconnectDb: TMenuItem;
    MenuItemDisconnectDb: TMenuItem;
    MenuItemRemoveDb: TMenuItem;
    MenuItemSeparator3: TMenuItem;
    MenuItemRefresh: TMenuItem;

    PopupMenuGridStruct: TPopupMenu;
    MenuItemGridAlterType: TMenuItem;
    MenuItemGridAdd: TMenuItem;
    MenuItemGridRename: TMenuItem;
    MenuItemGridDrop: TMenuItem;
    MenuItemGridSep1: TMenuItem;
    MenuItemGridKeys: TMenuItem;
    MenuItemGridIndices: TMenuItem;
    MenuItemGridSep2: TMenuItem;
    MenuItemGridRefresh: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnDisconnectClick(Sender: TObject);
    procedure BtnRefreshMetaClick(Sender: TObject);
    procedure BtnNewTableClick(Sender: TObject);
    procedure BtnAlterTableClick(Sender: TObject);
    procedure BtnRunSQLClick(Sender: TObject);
    procedure BtnCommitClick(Sender: TObject);
    procedure BtnRollbackClick(Sender: TObject);
    procedure BtnConstraintsClick(Sender: TObject);
    procedure BtnGeneratorsClick(Sender: TObject);
    procedure BtnHealthClick(Sender: TObject);
    procedure BtnExtractAllDDLClick(Sender: TObject);

    procedure TreeViewMetaSelectionChanged(Sender: TObject);
    procedure TreeViewMetaDblClick(Sender: TObject);
    procedure TreeViewMetaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TreeViewMetaDeletion(Sender: TObject; Node: TTreeNode);

    { Menus de contexto }
    procedure PopupMenuTreePopup(Sender: TObject);
    procedure MenuItemSelectTopClick(Sender: TObject);
    procedure MenuItemExportTableClick(Sender: TObject);
    procedure MenuItemDDLClick(Sender: TObject);
    procedure MenuItemDropTableClick(Sender: TObject);
    procedure MenuItemAlterFieldsClick(Sender: TObject);
    procedure MenuItemGeneratorsClick(Sender: TObject);
    procedure MenuItemIndicesClick(Sender: TObject);
    procedure MenuItemEditPSQLClick(Sender: TObject);
    procedure MenuItemHealthClick(Sender: TObject);
    procedure MenuItemExtractAllDDLClick(Sender: TObject);
    procedure MenuItemReconnectDbClick(Sender: TObject);
    procedure MenuItemDisconnectDbClick(Sender: TObject);
    procedure MenuItemRemoveDbClick(Sender: TObject);

    { Edição de Dados no Grid }
    procedure BtnInsertRowClick(Sender: TObject);
    procedure BtnDeleteRowClick(Sender: TObject);
    procedure BtnPostRowClick(Sender: TObject);
    procedure BtnCancelRowClick(Sender: TObject);
    procedure BtnRefreshDataClick(Sender: TObject);
    procedure BtnExportDataClick(Sender: TObject);
    procedure DBGridResultsDblClick(Sender: TObject);

    { Abas e Histórico de SQL }
    procedure BtnNewQueryTabClick(Sender: TObject);
    procedure BtnCloseQueryTabClick(Sender: TObject);
    procedure ComboSQLHistoryChange(Sender: TObject);

    { Edição de Estrutura de Campos e Índices }
    procedure BtnAddFieldClick(Sender: TObject);
    procedure BtnAlterFieldTypeClick(Sender: TObject);
    procedure BtnRenameFieldClick(Sender: TObject);
    procedure BtnDropFieldClick(Sender: TObject);
    procedure BtnRefreshStructClick(Sender: TObject);
    procedure BtnIndicesClick(Sender: TObject);
    procedure GridStructFieldsDblClick(Sender: TObject);
  private
    FSynEdit: TSynEdit;
    FSynSQLSyn: TSynSQLSyn;
    FImageList: TImageList;
    PageControlQueries: TPageControl;
    function GetActiveSynEdit: TSynEdit;
    function CreateQueryTab(const ATitle: string = ''; const AText: string = ''): TSynEdit;
    function GetSelectedFieldName: string;
    procedure OpenProcedureSource(const AProcName: string);
    procedure OpenTriggerSource(const ATrigName: string);
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
    procedure LoadSQLHistory;
    procedure SaveSQLHistory;
    procedure AddSQLToHistory(const ASQL: string);
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

function GetHistoryFilePath: string;
var
  BaseDir: string;
begin
  BaseDir := GetEnvironmentVariable('APPDATA');
  if BaseDir = '' then
    BaseDir := GetEnvironmentVariable('USERPROFILE');
  Result := IncludeTrailingPathDelimiter(BaseDir) + 'LazDatabaseExplorer';
  ForceDirectories(Result);
  Result := IncludeTrailingPathDelimiter(Result) + 'sql_history.txt';
end;

procedure TFBExplorerMainForm.LoadSQLHistory;
var
  FPath: string;
begin
  FPath := GetHistoryFilePath;
  if FileExists(FPath) then
  begin
    ComboSQLHistory.Items.LoadFromFile(FPath);
    if ComboSQLHistory.Items.Count > 0 then
      ComboSQLHistory.ItemIndex := 0;
  end;
end;

procedure TFBExplorerMainForm.SaveSQLHistory;
var
  FPath: string;
begin
  FPath := GetHistoryFilePath;
  try
    ComboSQLHistory.Items.SaveToFile(FPath);
  except
    // ignore
  end;
end;

procedure TFBExplorerMainForm.AddSQLToHistory(const ASQL: string);
var
  Clean: string;
  Idx: Integer;
begin
  Clean := Trim(ASQL);
  if Clean = '' then Exit;

  Idx := ComboSQLHistory.Items.IndexOf(Clean);
  if Idx >= 0 then
    ComboSQLHistory.Items.Delete(Idx);

  ComboSQLHistory.Items.Insert(0, Clean);
  while ComboSQLHistory.Items.Count > 30 do
    ComboSQLHistory.Items.Delete(ComboSQLHistory.Items.Count - 1);

  ComboSQLHistory.ItemIndex := 0;
  SaveSQLHistory;
end;

procedure TFBExplorerMainForm.ComboSQLHistoryChange(Sender: TObject);
var
  Ed: TSynEdit;
begin
  if ComboSQLHistory.ItemIndex >= 0 then
  begin
    Ed := GetActiveSynEdit;
    if Ed <> nil then
      Ed.Text := ComboSQLHistory.Items[ComboSQLHistory.ItemIndex];
  end;
end;

function TFBExplorerMainForm.GetActiveSynEdit: TSynEdit;
var
  Page: TTabSheet;
  I: Integer;
begin
  Result := nil;
  if (PageControlQueries <> nil) and (PageControlQueries.ActivePage <> nil) then
  begin
    Page := PageControlQueries.ActivePage;
    for I := 0 to Page.ControlCount - 1 do
    begin
      if Page.Controls[I] is TSynEdit then
      begin
        Result := TSynEdit(Page.Controls[I]);
        Exit;
      end;
    end;
  end;
  if Result = nil then
    Result := FSynEdit;
end;

function TFBExplorerMainForm.CreateQueryTab(const ATitle: string; const AText: string): TSynEdit;
var
  Tab: TTabSheet;
  Ed: TSynEdit;
begin
  Tab := PageControlQueries.AddTabSheet;
  if ATitle <> '' then
    Tab.Caption := ATitle
  else
    Tab.Caption := 'Query ' + IntToStr(PageControlQueries.PageCount);

  Ed := TSynEdit.Create(Tab);
  Ed.Parent := Tab;
  Ed.Align := alClient;
  Ed.Font.Name := 'Courier New';
  Ed.Font.Size := 10;
  Ed.Gutter.Width := 30;
  Ed.Highlighter := FSynSQLSyn;

  if AText <> '' then
    Ed.Text := AText
  else
    Ed.Text := 'SELECT * FROM RDB$DATABASE' + LineEnding;

  PageControlQueries.ActivePage := Tab;
  FSynEdit := Ed;
  Result := Ed;
end;

procedure TFBExplorerMainForm.BtnNewQueryTabClick(Sender: TObject);
begin
  CreateQueryTab;
end;

procedure TFBExplorerMainForm.BtnCloseQueryTabClick(Sender: TObject);
var
  CurTab: TTabSheet;
begin
  if (PageControlQueries <> nil) and (PageControlQueries.PageCount > 1) and (PageControlQueries.ActivePage <> nil) then
  begin
    CurTab := PageControlQueries.ActivePage;
    CurTab.Free;
    FSynEdit := GetActiveSynEdit;
  end
  else if (PageControlQueries <> nil) and (PageControlQueries.PageCount = 1) then
  begin
    if GetActiveSynEdit <> nil then
      GetActiveSynEdit.Clear;
  end;
end;
procedure TFBExplorerMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F9 then
  begin
    BtnRunSQLClick(Sender);
    Key := 0;
  end
  else if Key = VK_F5 then
  begin
    BtnRefreshMetaClick(Sender);
    Key := 0;
  end
  else if (Key = VK_S) and (ssCtrl in Shift) then
  begin
    if SQLQuery1.Active and (SQLQuery1.State in [dsEdit, dsInsert]) then
    begin
      BtnPostRowClick(Sender);
      Key := 0;
    end;
  end;
end;

procedure TFBExplorerMainForm.FormCreate(Sender: TObject);
var
  LastCfg: TFBConnectionConfig;
begin
  FBExplorerMainForm := Self;
  FBConnManager.OnConnectionChange := @OnConnectionChanged;

  FImageList := CreateMetaDataImageList(Self);
  TreeViewMeta.Images := FImageList;

  InitSynEdit;
  SetupStructGridHeaders;
  LoadSQLHistory;

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
  SaveSQLHistory;
  if SQLQuery1.Active then
    SQLQuery1.Close;
end;

procedure TFBExplorerMainForm.InitSynEdit;
begin
  FSynSQLSyn := TSynSQLSyn.Create(Self);
  FSynSQLSyn.SQLDialect := sqlFirebird25;

  PageControlQueries := TPageControl.Create(Self);
  PageControlQueries.Parent := PanelEditorContainer;
  PageControlQueries.Align := alClient;

  FSynEdit := CreateQueryTab('Query 1', 'SELECT * FROM RDB$DATABASE' + LineEnding);
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
  RootNode, TablesNode, ViewsNode, ProcsNode, TrigsNode, GensNode, TableNode, FieldNode, SubNode: TTreeNode;
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

  if AManager.IsConnected then
    RootNode.ImageIndex := ICON_DB_CONNECTED
  else
    RootNode.ImageIndex := ICON_DB_DISCONNECTED;
  RootNode.SelectedIndex := RootNode.ImageIndex;

  if not AManager.IsConnected then Exit;

  OldMgr := FBConnManager;
  FBConnManager := AManager;
  List := TStringList.Create;
  try
    // Tabelas
    TablesNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Tabelas',
      TNodeInfo.Create(nkTablesGroup, '', AManager));
    TablesNode.ImageIndex := ICON_FOLDER;
    TablesNode.SelectedIndex := ICON_FOLDER;

    TFBMetaDataExtractor.GetTables(List, False);
    for I := 0 to List.Count - 1 do
    begin
      TblName := Trim(List[I]);
      TableNode := TreeViewMeta.Items.AddChildObject(TablesNode, TblName,
        TNodeInfo.Create(nkTable, TblName, AManager));
      TableNode.ImageIndex := ICON_TABLE;
      TableNode.SelectedIndex := ICON_TABLE;

      Flds := TFBMetaDataExtractor.GetTableFields(TblName);
      for J := 0 to High(Flds) do
      begin
        if Flds[J].IsPrimaryKey then
        begin
          FieldNode := TreeViewMeta.Items.AddChildObject(TableNode, Format('PK: %s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName, AManager));
          FieldNode.ImageIndex := ICON_PRIMARY_KEY;
          FieldNode.SelectedIndex := ICON_PRIMARY_KEY;
        end
        else
        begin
          FieldNode := TreeViewMeta.Items.AddChildObject(TableNode, Format('%s (%s)', [Flds[J].FieldName, Flds[J].TypeName]),
            TNodeInfo.Create(nkField, Flds[J].FieldName, AManager));
          FieldNode.ImageIndex := ICON_FIELD;
          FieldNode.SelectedIndex := ICON_FIELD;
        end;
      end;
    end;

    // Views
    ViewsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Views',
      TNodeInfo.Create(nkViewsGroup, '', AManager));
    ViewsNode.ImageIndex := ICON_FOLDER;
    ViewsNode.SelectedIndex := ICON_FOLDER;
    TFBMetaDataExtractor.GetViews(List);
    for I := 0 to List.Count - 1 do
    begin
      SubNode := TreeViewMeta.Items.AddChildObject(ViewsNode, List[I],
        TNodeInfo.Create(nkView, List[I], AManager));
      SubNode.ImageIndex := ICON_VIEW;
      SubNode.SelectedIndex := ICON_VIEW;
    end;

    // Procedures
    ProcsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Procedures',
      TNodeInfo.Create(nkProcsGroup, '', AManager));
    ProcsNode.ImageIndex := ICON_FOLDER;
    ProcsNode.SelectedIndex := ICON_FOLDER;
    TFBMetaDataExtractor.GetProcedures(List);
    for I := 0 to List.Count - 1 do
    begin
      SubNode := TreeViewMeta.Items.AddChildObject(ProcsNode, List[I],
        TNodeInfo.Create(nkProc, List[I], AManager));
      SubNode.ImageIndex := ICON_PROCEDURE;
      SubNode.SelectedIndex := ICON_PROCEDURE;
    end;

    // Triggers
    TrigsNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Triggers',
      TNodeInfo.Create(nkTrigsGroup, '', AManager));
    TrigsNode.ImageIndex := ICON_FOLDER;
    TrigsNode.SelectedIndex := ICON_FOLDER;
    TFBMetaDataExtractor.GetTriggers(List);
    for I := 0 to List.Count - 1 do
    begin
      SubNode := TreeViewMeta.Items.AddChildObject(TrigsNode, List[I],
        TNodeInfo.Create(nkTrig, List[I], AManager));
      SubNode.ImageIndex := ICON_TRIGGER;
      SubNode.SelectedIndex := ICON_TRIGGER;
    end;

    // Sequences / Generators
    GensNode := TreeViewMeta.Items.AddChildObject(RootNode, 'Sequences / Generators',
      TNodeInfo.Create(nkGensGroup, '', AManager));
    GensNode.ImageIndex := ICON_FOLDER;
    GensNode.SelectedIndex := ICON_FOLDER;
    TFBMetaDataExtractor.GetGenerators(List);
    for I := 0 to List.Count - 1 do
    begin
      SubNode := TreeViewMeta.Items.AddChildObject(GensNode, List[I],
        TNodeInfo.Create(nkGen, List[I], AManager));
      SubNode.ImageIndex := ICON_GENERATOR;
      SubNode.SelectedIndex := ICON_GENERATOR;
    end;

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

procedure TFBExplorerMainForm.BtnAlterTableClick(Sender: TObject);
var
  Tbl: string;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de editar tabelas.');
    Exit;
  end;

  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela na árvore de metadados à esquerda.');
    Exit;
  end;

  LoadTableStructure(Tbl);
  PageControlMain.ActivePage := TabSheetStructure;
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
  Ed: TSynEdit;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Não conectado a um banco de dados.');
    Exit;
  end;

  Ed := GetActiveSynEdit;
  if Ed = nil then Exit;

  if Ed.SelText <> '' then
    Sql := Trim(Ed.SelText)
  else
    Sql := Trim(Ed.Text);

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
        AddSQLToHistory(Sql);
        LogMsg(Format('Consulta SELECT concluída em %d ms. Registros carregados.', [ElapsedMs]));
        StatusBar1.Panels[1].Text := Format('Linhas: %d | Tempo: %d ms (Edição Habilitada)', [SQLQuery1.RecordCount, ElapsedMs]);
      end
      else
      begin
        FBConnManager.ExecuteDirect(Sql, Rows);
        ElapsedMs := GetTickCount64 - StartTime;
        AddSQLToHistory(Sql);
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

function TFBExplorerMainForm.GetSelectedFieldName: string;
var
  Node: TTreeNode;
  Info: TNodeInfo;
begin
  Result := '';
  // Se o nó selecionado na árvore for um campo, usa o campo da árvore
  Node := TreeViewMeta.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Kind = nkField then
      Result := Trim(Info.Name);
  end;

  // Se não foi selecionado na árvore, tenta obter da linha selecionada no GridStructFields
  if (Result = '') and (GridStructFields <> nil) and (GridStructFields.Row > 0) and (GridStructFields.Row < GridStructFields.RowCount) then
    Result := Trim(GridStructFields.Cells[0, GridStructFields.Row]);
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
  Node: TTreeNode;
  Info: TNodeInfo;
begin
  Node := TreeViewMeta.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Kind = nkGen then
    begin
      TFBGeneratorForm.Execute(Info.Name);
      Exit;
    end
    else if Info.Kind = nkProc then
    begin
      OpenProcedureSource(Info.Name);
      Exit;
    end
    else if Info.Kind = nkTrig then
    begin
      OpenTriggerSource(Info.Name);
      Exit;
    end
    else if Info.Kind = nkField then
    begin
      Tbl := GetSelectedTableName;
      if (Tbl <> '') and TFBAlterFieldForm.Execute(Tbl, afmAlterType, Info.Name) then
      begin
        LoadTableStructure(Tbl);
        RefreshMetaDataTree;
      end;
      Exit;
    end;
  end;

  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    OpenSelectedTableData(Tbl, 100);
end;

procedure TFBExplorerMainForm.OpenSelectedTableData(const ATableName: string; TopCount: Integer);
var
  Sql: string;
  Ed: TSynEdit;
  PKList: TStringList;
  I: Integer;
begin
  Sql := TFBMetaDataExtractor.GenerateSelectTopSQL(Trim(ATableName), TopCount);
  Ed := GetActiveSynEdit;
  if Ed <> nil then
    Ed.Text := Sql;
  PageControlMain.ActivePage := TabSheetSQL;
  BtnRunSQLClick(Self);

  // Assegura que chaves primárias sejam identificadas para permitir edição inline sem erros
  if SQLQuery1.Active and (ATableName <> '') then
  begin
    PKList := TStringList.Create;
    try
      TFBMetaDataExtractor.GetPrimaryKeys(ATableName, PKList);
      for I := 0 to SQLQuery1.Fields.Count - 1 do
      begin
        if PKList.IndexOf(SQLQuery1.Fields[I].FieldName) >= 0 then
          SQLQuery1.Fields[I].ProviderFlags := [pfInUpdate, pfInWhere, pfInKey]
        else
          SQLQuery1.Fields[I].ProviderFlags := [pfInUpdate];
      end;
    finally
      PKList.Free;
    end;
  end;
end;

procedure TFBExplorerMainForm.MenuItemSelectTopClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    OpenSelectedTableData(Tbl, 100);
end;

procedure TFBExplorerMainForm.MenuItemExportTableClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl = '' then Exit;
  OpenSelectedTableData(Tbl, 100);
  TFBDataExportForm.Execute(SQLQuery1, Tbl);
end;

procedure TFBExplorerMainForm.BtnGeneratorsClick(Sender: TObject);
begin
  TFBGeneratorForm.Execute;
end;

procedure TFBExplorerMainForm.MenuItemGeneratorsClick(Sender: TObject);
begin
  BtnGeneratorsClick(Sender);
end;

procedure TFBExplorerMainForm.TreeViewMetaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Node: TTreeNode;
begin
  if Button = mbRight then
  begin
    Node := TreeViewMeta.GetNodeAt(X, Y);
    if Node <> nil then
      TreeViewMeta.Selected := Node;
  end;
end;

procedure TFBExplorerMainForm.MenuItemDDLClick(Sender: TObject);
var
  Tbl, DDL: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para visualizar o script DDL.');
    Exit;
  end;

  DDL := TFBMetaDataExtractor.GenerateCreateTableDDL(Tbl);
  LoadTableStructure(Tbl);

  CreateQueryTab('DDL: ' + Tbl, DDL);
  PageControlMain.ActivePage := TabSheetSQL;
  LogMsg('Script DDL gerado para a tabela "' + Tbl + '".');
  StatusBar1.Panels[1].Text := 'Script DDL exibido no Editor SQL.';
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

procedure TFBExplorerMainForm.PopupMenuTreePopup(Sender: TObject);
var
  Node: TTreeNode;
  Info: TNodeInfo;
  Tbl, Fld: string;
begin
  Node := TreeViewMeta.Selected;
  Tbl := GetSelectedTableName;
  Fld := '';

  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Kind = nkField then
      Fld := Trim(Info.Name);
  end;

  if Fld <> '' then
  begin
    MenuItemAlterFields.Caption := Format('✏️ Alterar Tipo do Campo "%s"...', [Fld]);
    MenuItemAlterFields.Visible := True;
  end
  else if Tbl <> '' then
  begin
    MenuItemAlterFields.Caption := Format('🛠️ Alterar Estrutura de "%s"...', [Tbl]);
    MenuItemAlterFields.Visible := True;
  end
  else
    MenuItemAlterFields.Visible := False;
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

procedure TFBExplorerMainForm.BtnExportDataClick(Sender: TObject);
begin
  if not SQLQuery1.Active or SQLQuery1.IsEmpty then
  begin
    ShowMessage('Não há dados ativos para exportação.');
    Exit;
  end;
  TFBDataExportForm.Execute(SQLQuery1, GetSelectedTableName);
end;

procedure TFBExplorerMainForm.DBGridResultsDblClick(Sender: TObject);
begin
  if (DBGridResults.SelectedField <> nil) then
    TFBCellViewerForm.Execute(DBGridResults.SelectedField);
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
  SelFld := GetSelectedFieldName;
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
  SelFld := GetSelectedFieldName;
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
  SelFld := GetSelectedFieldName;
  if TFBAlterFieldForm.Execute(Tbl, afmDrop, SelFld) then
  begin
    LoadTableStructure(Tbl);
    RefreshMetaDataTree;
  end;
end;

procedure TFBExplorerMainForm.GridStructFieldsDblClick(Sender: TObject);
begin
  BtnAlterFieldTypeClick(Sender);
end;

procedure TFBExplorerMainForm.BtnRefreshStructClick(Sender: TObject);
var
  Tbl: string;
begin
  Tbl := GetSelectedTableName;
  if Tbl <> '' then
    LoadTableStructure(Tbl);
end;

procedure TFBExplorerMainForm.BtnIndicesClick(Sender: TObject);
var
  Tbl: string;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de gerenciar índices.');
    Exit;
  end;

  Tbl := GetSelectedTableName;
  if Tbl = '' then
  begin
    ShowMessage('Selecione uma tabela para gerenciar seus índices.');
    Exit;
  end;

  TFBIndexManagerForm.Execute(Tbl);
  RefreshMetaDataTree;
end;

procedure TFBExplorerMainForm.MenuItemIndicesClick(Sender: TObject);
begin
  BtnIndicesClick(Sender);
end;

procedure TFBExplorerMainForm.BtnHealthClick(Sender: TObject);
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de verificar a saúde do banco.');
    Exit;
  end;

  TFBDatabaseHealthForm.Execute;
end;

procedure TFBExplorerMainForm.MenuItemHealthClick(Sender: TObject);
begin
  BtnHealthClick(Sender);
end;

procedure TFBExplorerMainForm.BtnExtractAllDDLClick(Sender: TObject);
var
  FullDDL: string;
begin
  if not FBConnManager.IsConnected then
  begin
    ShowMessage('Conecte-se a uma base Firebird antes de extrair metadados.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FullDDL := TFBMetaDataExtractor.ExtractFullDatabaseDDL;
  finally
    Screen.Cursor := crDefault;
  end;

  CreateQueryTab('Full DDL', FullDDL);
  PageControlMain.ActivePage := TabSheetSQL;
  LogMsg('Metadados completos (Full DDL) extraídos com sucesso.');
  StatusBar1.Panels[1].Text := 'Full DDL gerado em nova aba.';
end;

procedure TFBExplorerMainForm.MenuItemExtractAllDDLClick(Sender: TObject);
begin
  BtnExtractAllDDLClick(Sender);
end;

procedure TFBExplorerMainForm.OpenProcedureSource(const AProcName: string);
var
  Src: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Screen.Cursor := crHourGlass;
  try
    Src := TFBMetaDataExtractor.GetProcedureSource(AProcName);
  finally
    Screen.Cursor := crDefault;
  end;

  CreateQueryTab('Proc: ' + AProcName, Src);
  PageControlMain.ActivePage := TabSheetSQL;
  LogMsg('Código da Procedure "' + AProcName + '" carregado.');
  StatusBar1.Panels[1].Text := 'Procedure exibida no Editor.';
end;

procedure TFBExplorerMainForm.OpenTriggerSource(const ATrigName: string);
var
  Src: string;
begin
  if not FBConnManager.IsConnected then Exit;
  Screen.Cursor := crHourGlass;
  try
    Src := TFBMetaDataExtractor.GetTriggerSource(ATrigName);
  finally
    Screen.Cursor := crDefault;
  end;

  CreateQueryTab('Trig: ' + ATrigName, Src);
  PageControlMain.ActivePage := TabSheetSQL;
  LogMsg('Código da Trigger "' + ATrigName + '" carregado.');
  StatusBar1.Panels[1].Text := 'Trigger exibida no Editor.';
end;

procedure TFBExplorerMainForm.MenuItemEditPSQLClick(Sender: TObject);
var
  Node: TTreeNode;
  Info: TNodeInfo;
begin
  Node := TreeViewMeta.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Info := TNodeInfo(Node.Data);
    if Info.Kind = nkProc then
      OpenProcedureSource(Info.Name)
    else if Info.Kind = nkTrig then
      OpenTriggerSource(Info.Name)
    else
      ShowMessage('Selecione uma Stored Procedure ou Trigger para visualizar o código PSQL.');
  end;
end;

end.
