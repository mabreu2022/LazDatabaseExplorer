# Firebird Database Explorer para Lazarus (IDE Package & Standalone)

[![Lazarus](https://img.shields.io/badge/Lazarus-2.2%20%7C%203.x%20%7C%204.x-blue.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/FPC-3.2.2+-red.svg)](https://www.freepascal.org/)
[![Firebird](https://img.shields.io/badge/Firebird-2.5%20%7C%203.0%20%7C%204.0%20%7C%205.0-orange.svg)](https://firebirdsql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey.svg)]()

Uma ferramenta completa, nativa e de alto desempenho para administração, exploração e modelagem de bancos de dados **Firebird**, inspirada em utilitários consagrados como o *IBExpert* e *DBeaver*. 

Projetada para funcionar em dois modos:
1. **Pacote Integrado à IDE Lazarus ("OTA" / IDEIntf)**: Janela acoplável (*Dockable*) ao ambiente com suporte nativo ao **AnchorDocking**.
2. **Aplicação Standalone (Independente)**: Executável autônomo de uso rápido sem necessidade de recompilar a IDE.

---

## 🌟 Principais Recursos e Módulos

### 🔌 1. Gerenciador de Conexões e Múltiplos Bancos
- **Bancos Simultâneos**: Conexão e navegação em múltiplos bancos de dados ao mesmo tempo na mesma árvore de metadados.
- **Servidores Locais e Remotos**: Configuração flexível de Host, Porta (padrão 3050) e caminho do banco (`.fdb`).
- **Autenticação Flexível**: Suporte ao usuário padrão `SYSDBA` ou usuários personalizados com senhas e charsets (`UTF8`, `WIN1252`, `ISO8859_1`, `NONE`).
- **Seleção da Biblioteca Cliente**: Especificação opcional do caminho da biblioteca `fbclient.dll` / `libfbclient.so`.
- **Criação de Novos Bancos**: Assistente para criação de arquivos de banco vazios diretamente da interface (`CREATE DATABASE`).
- **Persistência de Conexões**: Armazenamento automático e seguro dos perfis de conexão em arquivo de configuração `.ini`.
- **Menu Contextual por Banco**: Reconectar, desconectar ou remover qualquer banco individualmente com um clique.

---

### 🌳 2. Navegador de Metadados com Ícones Gráficos Nativos
- **Ícones Gráficos Vetoriais Nativos**: Desenhados proceduralmente em tempo de execução (`uFBTreeIcons`), garantindo nitidez sem dependências externas de pacotes de imagens.
- **Hierarquia Completa de Objetos**:
  - 🗄️ **Bancos de Dados**: Lista de instâncias conectadas.
  - 📁 **Tabelas de Usuário**: Listagem com identificação de colunas e chave primária destacada (🔑).
  - 👁️ **Views / Visões**.
  - ⚙️ **Stored Procedures**.
  - ⚡ **Triggers / Gatilhos**.
  - 🔢 **Generators / Sequences**.
- **Navegação Ágil**: Seleção automática de nó ao clicar com o botão direito (`TreeViewMetaMouseDown`) para acesso instantâneo ao menu de contexto.
- **Duplo Clique Inteligente**: Abertura automática da consulta rápida com os 100 primeiros registros da tabela selecionada.

---

### 📝 3. Editor SQL Multi-Abas com Histórico e Execução
- **Múltiplas Abas de Consulta**: Crie e feche abas de scripts SQL independentes para trabalhar em consultas simultâneas.
- **Realce de Sintaxe SQL**: Editor de alto desempenho integrado via `TSynEdit` e `TSynSQLSyn`.
- **Histórico Automático**: Dropdown de histórico que armazena os últimos comandos executados para recuperação e reuso imediato.
- **Controle Transacional Manual**: Botões de controle explícito de transações (**Commit** e **Rollback**) com feedback visual do estado da transação.
- **Métricas de Execução**: Relatório do número de linhas retornadas ou afetadas e tempo total de processamento em milissegundos (ms).
- **Atalhos Produtivos**:
  - `F9`: Executar a consulta ou o bloco de texto selecionado.
  - `F5`: Atualizar metadados do banco de dados.

---

### 📊 4. Visualização e Edição Inline de Dados (Data Grid)
- **Grade Interativa**: Exibição fluida de conjuntos de dados retornados (`TDBGrid` / `TSQLQuery`).
- **Edição Inline Direta**: Edite valores diretamente nas células da grade de resultados.
- **Barra de Ferramentas de Dados**:
  - ➕ **Inserir Linha**: Adiciona novos registros no dataset.
  - 🗑️ **Excluir Linha**: Remove a linha selecionada com confirmação.
  - 💾 **Salvar Alterações**: Persiste as modificações via `Post` transacional.
  - ✖ **Cancelar**: Reverte alterações pendentes da linha.
  - 🔄 **Recarregar**: Atualiza os dados da grade.
- **Visualizador Avançado de Célula (Cell Viewer)**:
  - Janela dedicada (`uFBCellViewerForm`) aberta com **duplo clique** em qualquer célula ou campo de texto longo.
  - Quebra automática de linhas (*Word Wrap*), contador de caracteres e botão de cópia rápida.
  - Ideal para inspeção de textos longos, conteúdos JSON, XML ou BLOBs.

---

### 📤 5. Exportador de Dados Avançado (CSV, JSON, SQL)
- **Exportação Multiformato**: Exporte o resultado de qualquer consulta ou os dados de uma tabela inteira.
  - **CSV**: Configuração de separador (ponto-e-vírgula, vírgula, tabulação) e aspas.
  - **JSON**: Formato legível e estruturado pronto para integrações web e APIs.
  - **SQL INSERTs**: Geração de scripts `INSERT INTO` em lotes prontos para migração entre bancos.
- Acesso rápido tanto pela aba de resultados quanto pelo menu de contexto da tabela na árvore.

---

### 🏗️ 6. Assistente Visual de Criação de Tabelas
- **Definição Completa de Campos**:
  - Nome da coluna.
  - Tipos de dados nativos: `BIGINT`, `INTEGER`, `SMALLINT`, `VARCHAR`, `CHAR`, `NUMERIC`, `TIMESTAMP`, `DATE`, `TIME`, `BLOB`, `BOOLEAN`.
  - Controle preciso de tamanho e escala decimal.
  - Restrições `NOT NULL` e `DEFAULT`.
  - Definição de Chave Primária (`PRIMARY KEY`).
  - Suporte a Auto Incremento (`IDENTITY` para Firebird 3.0+ ou vinculação de Generator/Trigger para Firebird 2.5).
- **Adicionar Campos de Auditoria**: Botão de 1 clique para inclusão automática de campos corporativos padrão (`DATA_CADASTRO`, `ATIVO`, `USUARIO_CADASTRO`).
- **Gestão Integrada de Chaves Estrangeiras (FK)**: Aba embutida para criar e vincular chaves estrangeiras já durante a concepção da tabela.
- **Pré-visualização do Script DDL**: Geração em tempo real do script `CREATE TABLE` com execução transacional direta.

---

### 🛠️ 7. Gestor e Alteração de Estrutura de Campos (DDL)
- **Alteração de Tabelas Existentes**:
  - ➕ **Adicionar Campo**: Inclusão de novas colunas em tabelas de produção.
  - ✏️ **Alterar Tipo / Tamanho**: Modificação assistida de tipo ou expansão de tamanho de campos (`VARCHAR`, `NUMERIC`, etc.) com carregamento automático dos parâmetros originais.
  - 🔤 **Renomear Campo**: Renomeação segura de campos via `ALTER COLUMN ... TO ...`.
  - 🗑️ **Excluir Campo (DROP)**: Remoção de colunas com validação de segurança.
- **Edição por Duplo Clique**: Duplo clique sobre a coluna na grade de estrutura abre o assistente de alteração pré-preenchido.

---

### 🔑 8. Gerenciador de Chaves e Restrições (PK / FK) - Estilo IBExpert
- **Chaves Primárias (Primary Keys)**:
  - Leitura e visualização da PK existente na tabela.
  - Seleção visual de múltiplos campos via `TCheckListBox` para criação de **Chaves Primárias Compostas**.
  - Criação e exclusão assistida de constraints de PK.
- **Chaves Estrangeiras (Foreign Keys)**:
  - Listagem de todas as FKs existentes lidas diretamente de `RDB$RELATION_CONSTRAINTS`.
  - Mapeamento visual claro: `[Campo Local da Tabela] ➔ APONTA PARA ➔ [Tabela e Campo de Destino]`.
  - Regras de integridade referencial: `ON UPDATE` e `ON DELETE` (`NO ACTION`, `CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT`).
  - Geração automática e execução de scripts `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...`.

---

### ⚡ 9. Gerenciador de Índices (Index Manager)
- **Inspeção de Índices**: Listagem de índices da tabela selecionada ou de todo o banco de dados.
- **Informações Detalhadas**: Visualização de seletividade, unicidade (Unique / Non-Unique) e ordenação (Ascending / Descending).
- **Ativação e Desativação**: Ativar (`ACTIVE`) ou inativar (`INACTIVE`) índices com um clique — essencial para otimizar cargas massivas de dados.
- **Recálculo de Estatísticas**: Execução direta de `SET STATISTICS INDEX <NOME>` para recomputar seletividades desatualizadas e acelerar o otimizador do Firebird.
- **Criação e Exclusão**: Assistente visual para criação de novos índices ou remoção (`DROP INDEX`).

---

### 🔢 10. Gerenciador de Sequences / Generators
- **Visão Geral de Sequências**: Leitura das sequences diretamente das tabelas de catálogo `RDB$GENERATORS`.
- **Valores Atuais em Tempo Real**: Consulta instantânea do valor atual da sequência via `GEN_ID(seq, 0)`.
- **Criar Nova Sequence**: Assistente para criação de geradores com valor inicial personalizado.
- **Alterar / Reiniciar Valor**: Reinicialização do valor da sequência (`ALTER SEQUENCE ... RESTART WITH ...`).
- **Remover Sequence**: Exclusão segura de sequences obsoletas (`DROP SEQUENCE`).

---

### 🩺 11. Diagnóstico e Saúde do Banco (MON$ Tables)
- **Monitoramento em Tempo Real**: Coleta de métricas dinâmicas através do subsistema `MON$` do Firebird.
- **Transações e Análise OIT/OAT**:
  - *Next Transaction*: Próximo ID de transação.
  - *Oldest Active Transaction (OAT)*: Transação ativa mais antiga.
  - *Oldest Interesting Transaction (OIT)*: Transação interessante mais antiga.
  - *Diferença OAT - OIT*: Alerta preventivo contra acúmulo excessivo de versões de registro (prevenção de *sweep* e lentidão).
- **Conexões Ativas (`MON$ATTACHMENTS`)**: Listagem de conexões de usuários, IPs e programas conectados no momento.
- **Consultas em Execução (`MON$STATEMENTS`)**: Visualização de instruções SQL ativas no servidor.

---

### 📜 12. Extrator Full DDL e Visualizador PSQL
- **Extrator Completo do Banco (Full DDL)**:
  - Gera em uma única tela o script DDL completo do banco de dados: tabelas, campos, chaves primárias, chaves estrangeiras, índices, sequences, triggers e procedures.
  - Botão de cópia rápida e exportação para arquivo `.sql`.
- **Visualizador / Editor de Código PSQL**:
  - Exibição do código-fonte original de **Stored Procedures** e **Triggers** com realce de sintaxe SQL/PSQL.

---

## ⌨️ Atalhos Rápidos de Produtividade

| Tecla / Ação | Contexto | Ação Realizada |
| :--- | :--- | :--- |
| **`F9`** | Editor SQL | Executa a consulta SQL ou script selecionado |
| **`F5`** | Janela Principal | Atualiza a árvore de metadados do banco conectado |
| **`Clique Direito`** | Árvore de Metadados | Seleciona o objeto e abre o menu de contexto |
| **`Duplo Clique`** | Tabela na Árvore | Executa consulta rápida dos primeiros 100 registros |
| **`Duplo Clique`** | Célula no Grid de Dados | Abre o Visualizador de Célula (**Cell Viewer**) |
| **`Duplo Clique`** | Campo no Grid de Estrutura | Abre o assistente para alterar tipo e tamanho do campo |

---

## 📁 Estrutura do Repositório

```
LazarusDataBaseExplorer/
├── LazarusDataBaseExplorer.lpk    # Pacote de Extensão da IDE Lazarus
├── LazarusDataBaseExplorer.pas    # Unidade mestre de registro do pacote
├── FBExplorerApp.lpi              # Projeto da aplicação Standalone (independente)
├── FBExplorerApp.lpr              # Programa principal da aplicação Standalone
├── bin/
│   └── FBExplorerApp.exe          # Executável gerado
├── src/
│   ├── uFBTypes.pas               # Definições de tipos, enums e conversões Firebird
│   ├── uFBConnectionManager.pas   # Gerenciador de conexão (TIBConnection / TSQLTransaction)
│   ├── uFBConnectionDialog.pas    # Diálogo de configuração, teste e perfil de conexões
│   ├── uFBConnectionDialog.lfm    # Layout do diálogo de conexão
│   ├── uFBMetaData.pas            # Leitura de dicionário RDB$, catálogo e gerador DDL
│   ├── uFBTreeIcons.pas           # Desenho nativo procedural de ícones gráficos da árvore
│   ├── uFBCreateTableForm.pas     # Assistente visual para criação de novas tabelas
│   ├── uFBCreateTableForm.lfm     # Layout do assistente de tabelas
│   ├── uFBConstraintForm.pas      # Gerenciador visual de chaves PK e FK (estilo IBExpert)
│   ├── uFBConstraintForm.lfm      # Layout do gerenciador de chaves
│   ├── uFBAlterFieldForm.pas      # Assistente de alteração de colunas (tipo, tamanho, renomear)
│   ├── uFBAlterFieldForm.lfm      # Layout do assistente de campos
│   ├── uFBIndexManagerForm.pas    # Gerenciador de índices (status, recomputação e DDL)
│   ├── uFBIndexManagerForm.lfm    # Layout do gerenciador de índices
│   ├── uFBGeneratorForm.pas       # Gerenciador de Sequences / Generators
│   ├── uFBGeneratorForm.lfm       # Layout do gerenciador de sequences
│   ├── uFBDatabaseHealthForm.pas  # Painel de saúde e diagnóstico MON$ do banco
│   ├── uFBDatabaseHealthForm.lfm  # Layout do painel de diagnóstico
│   ├── uFBDataExportForm.pas      # Exportador de dados para CSV, JSON e SQL INSERT
│   ├── uFBDataExportForm.lfm      # Layout do exportador de dados
│   ├── uFBCellViewerForm.pas      # Visualizador avançado de célula (texto longo / BLOB)
│   ├── uFBCellViewerForm.lfm      # Layout do visualizador de célula
│   ├── uFBExplorerMainForm.pas    # Janela principal do Explorer (Tree, SQL, Grid, DDL)
│   ├── uFBExplorerMainForm.lfm    # Layout da janela principal
│   └── uFBExplorerRegister.pas    # Registro na IDE (Menu Tools e AnchorDocking)
└── README.md
```

---

## 🛠️ Instalação e Execução

### Opção 1: Instalar como Pacote Integrado à IDE Lazarus ("OTA")
1. Abra o **Lazarus IDE**.
2. No menu superior, clique em **Pacote (Package)** $\rightarrow$ **Abrir Arquivo de Pacote (.lpk)...**.
3. Selecione o arquivo `LazarusDataBaseExplorer.lpk`.
4. Na janela do pacote, clique no botão **Compilar (Compile)**.
5. Em seguida, clique em **Usar (Use)** $\rightarrow$ **Instalar (Install)**.
6. Confirme a solicitação do Lazarus para recompilar a IDE.
7. Após reiniciar o Lazarus, acesse a ferramenta no menu:
   **Ferramentas (Tools)** $\rightarrow$ **Firebird Database Explorer**.
8. A janela pode ser usada livremente ou acoplada a qualquer área do ambiente através do **AnchorDocking**.

---

### Opção 2: Executar como Aplicativo Standalone
Você pode usar a aplicação de forma independente sem alterar ou recompilar a sua IDE:
- **Pelo executável já compilado**:
  Basta executar `bin/FBExplorerApp.exe`.
- **Compilando via código-fonte**:
  Abra o projeto `FBExplorerApp.lpi` no Lazarus e pressione `F9`, ou utilize o utilitário `lazbuild`:
  ```bash
  lazbuild FBExplorerApp.lpi
  ```

---

## 📋 Compatibilidade e Pré-requisitos
- **Lazarus**: 2.2.0 ou superior (totalmente testado e homologado nas versões 2.2, 3.x e 4.x).
- **Free Pascal (FPC)**: 3.2.2 ou superior.
- **Firebird**: Versões 2.5, 3.0, 4.0 e 5.0 (Dialetos 1 e 3).
- **Cliente Firebird**: `fbclient.dll` (Windows) ou `libfbclient.so` (Linux) compatível com a arquitetura compilada (32-bit ou 64-bit).

---

## 📄 Licença
Distribuído sob a licença **MIT**. Consulte o arquivo de licença para mais informações.
