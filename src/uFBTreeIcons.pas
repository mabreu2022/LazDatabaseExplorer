unit uFBTreeIcons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics;

const
  ICON_DB_CONNECTED    = 0;
  ICON_DB_DISCONNECTED = 1;
  ICON_FOLDER          = 2;
  ICON_TABLE           = 3;
  ICON_VIEW            = 4;
  ICON_PROCEDURE       = 5;
  ICON_TRIGGER         = 6;
  ICON_GENERATOR       = 7;
  ICON_FIELD           = 8;
  ICON_PRIMARY_KEY     = 9;
  ICON_FOREIGN_KEY     = 10;

type
  TDrawProc = procedure(C: TCanvas);

function CreateMetaDataImageList(AOwner: TComponent): TImageList;

implementation

function CreateIconBitmap(DrawProc: TDrawProc): TBitmap;
begin
  Result := TBitmap.Create;
  Result.SetSize(16, 16);
  Result.Transparent := True;
  Result.TransparentColor := clFuchsia;
  Result.Canvas.Brush.Color := clFuchsia;
  Result.Canvas.FillRect(0, 0, 16, 16);
  DrawProc(Result.Canvas);
end;

procedure DrawDbConnected(C: TCanvas);
begin
  // Base cilíndrica azul do banco de dados
  C.Brush.Color := TColor($00994D00); // Azul petróleo
  C.Pen.Color   := TColor($00663300);
  C.Rectangle(3, 4, 13, 13);
  C.Ellipse(3, 2, 13, 6);
  C.Brush.Color := TColor($00CC6600);
  C.Ellipse(3, 2, 13, 5);
  // Indicador de status conectado (Verde vibrante)
  C.Brush.Color := TColor($0022C55E);
  C.Pen.Color   := TColor($0015803D);
  C.Ellipse(10, 10, 15, 15);
end;

procedure DrawDbDisconnected(C: TCanvas);
begin
  // Base cinza do banco de dados desconectado
  C.Brush.Color := TColor($00808080);
  C.Pen.Color   := TColor($00505050);
  C.Rectangle(3, 4, 13, 13);
  C.Ellipse(3, 2, 13, 6);
  C.Brush.Color := TColor($00A0A0A0);
  C.Ellipse(3, 2, 13, 5);
  // Indicador de status desconectado (Vermelho)
  C.Brush.Color := TColor($003B26E1);
  C.Pen.Color   := TColor($001F1296);
  C.Ellipse(10, 10, 15, 15);
end;

procedure DrawFolder(C: TCanvas);
begin
  // Pasta moderna amarela/âmbar
  C.Brush.Color := TColor($0000A5FF); // Laranja âmbar
  C.Pen.Color   := TColor($00007ACC);
  // Aba
  C.Rectangle(1, 2, 7, 6);
  // Corpo
  C.Brush.Color := TColor($0020B8FF);
  C.Rectangle(1, 4, 15, 14);
end;

procedure DrawTable(C: TCanvas);
begin
  // Grade de Tabela (Azul)
  C.Brush.Color := clWhite;
  C.Pen.Color   := TColor($00B06010);
  C.Rectangle(1, 1, 15, 15);
  // Cabeçalho da tabela
  C.Brush.Color := TColor($00E08020);
  C.FillRect(2, 2, 14, 5);
  // Linhas divisórias internas
  C.Pen.Color := TColor($00D0A070);
  C.Line(7, 5, 7, 14);
  C.Line(2, 9, 14, 9);
end;

procedure DrawView(C: TCanvas);
begin
  // View (Tabela Verde-Esmeralda)
  C.Brush.Color := clWhite;
  C.Pen.Color   := TColor($00208030);
  C.Rectangle(1, 1, 15, 15);
  // Cabeçalho verde
  C.Brush.Color := TColor($0030B040);
  C.FillRect(2, 2, 14, 5);
  // Olho sutil ou grade
  C.Pen.Color := TColor($0050C060);
  C.Line(8, 5, 8, 14);
  C.Line(2, 9, 14, 9);
end;

procedure DrawProcedure(C: TCanvas);
begin
  // Procedure (Engrenagem / Função Púrpura)
  C.Brush.Color := TColor($009030A0);
  C.Pen.Color   := TColor($00601070);
  C.Rectangle(6, 1, 10, 15);
  C.Rectangle(1, 6, 15, 10);
  C.Ellipse(3, 3, 13, 13);
  // Orifício central
  C.Brush.Color := clFuchsia;
  C.Pen.Color   := TColor($00601070);
  C.Ellipse(6, 6, 10, 10);
end;

procedure DrawTrigger(C: TCanvas);
begin
  // Trigger (Raio Amarelo / Laranja)
  C.Brush.Color := TColor($0000C8FF);
  C.Pen.Color   := TColor($000080D0);
  C.Polygon([
    Point(9, 1),
    Point(4, 8),
    Point(8, 8),
    Point(6, 15),
    Point(13, 7),
    Point(9, 7)
  ]);
end;

procedure DrawGenerator(C: TCanvas);
begin
  // Sequence / Generator (Badge numérico azul marinho com contador)
  C.Brush.Color := TColor($00A85500);
  C.Pen.Color   := TColor($00663300);
  C.RoundRect(1, 2, 15, 14, 3, 3);
  // Simbolo #
  C.Pen.Color := clWhite;
  C.Line(5, 4, 5, 12);
  C.Line(9, 4, 9, 12);
  C.Line(3, 6, 11, 6);
  C.Line(3, 10, 11, 10);
end;

procedure DrawField(C: TCanvas);
begin
  // Coluna / Campo comum (Pequena barra azul)
  C.Brush.Color := TColor($00D0E0FF);
  C.Pen.Color   := TColor($008090C0);
  C.Rectangle(2, 3, 14, 13);
  C.Pen.Color   := TColor($00405090);
  C.Line(4, 6, 12, 6);
  C.Line(4, 9, 10, 9);
end;

procedure DrawPrimaryKey(C: TCanvas);
begin
  // Chave Primária (Chave Dourada)
  C.Brush.Color := TColor($0010C0FF);
  C.Pen.Color   := TColor($000080B0);
  // Cabeça da chave
  C.Ellipse(1, 4, 8, 11);
  C.Brush.Color := clFuchsia;
  C.Ellipse(3, 6, 6, 9);
  // Haste e dentes
  C.Pen.Color := TColor($000080B0);
  C.Pen.Width := 2;
  C.Line(7, 7, 14, 7);
  C.Line(11, 7, 11, 11);
  C.Line(14, 7, 14, 11);
  C.Pen.Width := 1;
end;

procedure DrawForeignKey(C: TCanvas);
begin
  // Chave Estrangeira (Elo de corrente prateado)
  C.Brush.Color := clFuchsia;
  C.Pen.Color   := TColor($00606060);
  C.Pen.Width   := 2;
  C.Ellipse(2, 2, 10, 10);
  C.Ellipse(6, 6, 14, 14);
  C.Pen.Width   := 1;
end;

function CreateMetaDataImageList(AOwner: TComponent): TImageList;
var
  Bmp: TBitmap;

  procedure AddIcon(DrawProc: TDrawProc);
  begin
    Bmp := CreateIconBitmap(DrawProc);
    try
      Result.AddMasked(Bmp, clFuchsia);
    finally
      Bmp.Free;
    end;
  end;

begin
  Result := TImageList.CreateSize(16, 16);
  if AOwner <> nil then
    Result.Name := 'ImageListMetaTree';

  AddIcon(@DrawDbConnected);    // 0
  AddIcon(@DrawDbDisconnected); // 1
  AddIcon(@DrawFolder);          // 2
  AddIcon(@DrawTable);           // 3
  AddIcon(@DrawView);            // 4
  AddIcon(@DrawProcedure);       // 5
  AddIcon(@DrawTrigger);         // 6
  AddIcon(@DrawGenerator);       // 7
  AddIcon(@DrawField);           // 8
  AddIcon(@DrawPrimaryKey);      // 9
  AddIcon(@DrawForeignKey);      // 10
end;

end.
