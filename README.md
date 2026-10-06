# Firebird Database Explorer para Lazarus (IDE Package & Standalone)

Um complemento de IDE (*IDE Package / "OTA" do Lazarus*) e ferramenta completa para gerenciamento e exploração de bancos de dados **Firebird** diretamente no **Lazarus IDE**.

---

## 🚀 Recursos Implementados

1. **Integração com a IDE Lazarus ("OTA" / IDEIntf)**:
   - Registrado no menu **Ferramentas (Tools) $\rightarrow$ Firebird Database Explorer**.
   - Janela acoplável (*Dockable*) via `IDEWindowCreators` (compatível com AnchorDocking do Lazarus).

2. **Gerenciador de Conexões**:
   - Suporte a servidores locais e remotos (Host, Porta 3050, Caminho do arquivo `.fdb`).
   - Autenticação configurável (`SYSDBA`, senha, Charset UTF8/WIN1252/NONE).
   - Seleção opcional de biblioteca cliente (`fbclient.dll`).
   - Gerenciamento de perfis de conexão salvos (armazenamento automático em `.ini`).
   - **Criação de novos bancos de dados** diretamente pelo assistente (`CreateDB`).

3. **Navegador de Metadados (Árvore de Esquema)**:
   - **Tabelas de Usuário**: Listagem com ícones, colunas com tipos detalhados e destaque para chaves primárias (🔑).
   - **Views / Visões**.
   - **Stored Procedures**.
   - **Triggers / Gatilhos**.
   - **Generators / Sequences**.

4. **Assistente Visual de Criação de Tabelas**:
   - Definição do nome da tabela.
   - Grade interativa de campos:
     - Nome da coluna
     - Tipo (`BIGINT`, `INTEGER`, `SMALLINT`, `VARCHAR`, `CHAR`, `NUMERIC`, `TIMESTAMP`, `DATE`, `TIME`, `BLOB`, `BOOLEAN`)
     - Tamanho e escala
     - Não nulo (`NOT NULL`)
     - Chave primária (`PRIMARY KEY`)
     - Auto Incremento / Identidade (`IDENTITY` para Firebird 3.0+ ou generator para Firebird 2.5)
     - Valor padrão (`DEFAULT`)
   - **Gestor Completo de Chaves Estrangeiras (Foreign Keys / FK)**:
     - Aba dedicada para configuração e listagem de FKs.
     - Botão de atalho na grade de colunas: `🔗 Criar FK deste Campo`.
     - Sugestão inteligente de nomes de constraint (`FK_<TABELA>_<CAMPO>`).
     - Detecção automática de tabela referenciada e chave primária a partir do catálogo do banco.
     - Suporte a regras de integridade referencial: `ON UPDATE` e `ON DELETE` (`NO ACTION`, `CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT`).
   - Visualização do comando SQL `CREATE TABLE` gerado em tempo real.
   - Botão para execução direta no banco com transação controlada.
   - Botão para adicionar campos padrão de auditoria (`DATA_CADASTRO`, `ATIVO`, etc.).

5. **Gerenciador Visual de Chaves e Restrições (PK / FK) - Estilo IBExpert**:
   - Disponível pelo menu de contexto da tabela (`🔑 Gerenciar Chaves e FKs (IBExpert)...`), botão na barra de ferramentas e no assistente de tabela.
   - **Chaves Estrangeiras (FK)**:
     - Listagem de FKs existentes na tabela lidas diretamente do catálogo Firebird (`RDB$RELATION_CONSTRAINTS`).
     - Assistente visual de mapeamento de campos: `[Campo Local] ➔ APONTA PARA ➔ [Campo Destino]`.
     - Seleção de regras referenciais: `ON UPDATE` e `ON DELETE` (`NO ACTION`, `CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT`).
     - Execução direta com geração de `ALTER TABLE <TABELA> ADD CONSTRAINT ...`.
     - Exclusão de restrições existentes com confirmação de segurança (`ALTER TABLE ... DROP CONSTRAINT`).
   - **Chaves Primárias (PK)**:
     - Leitura da chave primária atual da tabela.
     - Seleção visual de múltiplos campos com lista de caixas de seleção (`TCheckListBox`) para Chaves Primárias Simples ou Compostas.
     - Criação (`ALTER TABLE ... ADD CONSTRAINT ... PRIMARY KEY`) e remoção de PK.
     - Script DDL gerado em tempo real com realce de sintaxe.

6. **Editor SQL e Visualizador de Dados**:
   - Editor de código com realce de sintaxe SQL via `TSynEdit` / `TSynSQLSyn`.
   - Execução de consultas `SELECT` com exibição em grade de dados (`TDBGrid`).
   - Execução de comandos DDL/DML (`CREATE`, `ALTER`, `DROP`, `INSERT`, `UPDATE`, `DELETE`) com relatório de linhas afetadas e tempo de execução (ms).
   - Controle de transação manual: botões **Commit** e **Rollback**.

7. **Ações Rápidas de Tabela**:
   - Visualizar primeiros 100 registros com duplo clique.
   - Visualização e engenharia reversa do script DDL (`CREATE TABLE`) da tabela selecionada.
   - Exclusão assistida de tabela (`DROP TABLE`) com confirmação de segurança.

---

## 📁 Estrutura do Projeto

```
LazarusDataBaseExplorer/
├── LazarusDataBaseExplorer.lpk    # Pacote de Extensão da IDE Lazarus
├── LazarusDataBaseExplorer.pas    # Unidade mestre de registro do pacote
├── FBExplorerApp.lpi              # Projeto da aplicação Standalone (teste rápido)
├── FBExplorerApp.lpr              # Programa principal Standalone
├── bin/
│   └── FBExplorerApp.exe          # Executável gerado
├── src/
│   ├── uFBTypes.pas               # Definições de tipos, registros e conversões Firebird
│   ├── uFBConnectionManager.pas   # Gerenciador de conexão (TIBConnection / TSQLTransaction)
│   ├── uFBConnectionDialog.pas    # Diálogo de configuração e teste de conexões
│   ├── uFBConnectionDialog.lfm    # Layout do formulário de conexão
│   ├── uFBMetaData.pas            # Leitura de dicionário RDB$ e gerador DDL
│   ├── uFBCreateTableForm.pas     # Assistente visual para criação de tabelas
│   ├── uFBCreateTableForm.lfm     # Layout do formulário do assistente
│   ├── uFBConstraintForm.pas      # Gerenciador visual de chaves PK e FK (estilo IBExpert)
│   ├── uFBConstraintForm.lfm      # Layout do formulário de chaves
│   ├── uFBExplorerMainForm.pas    # Janela principal do Explorer
│   ├── uFBExplorerMainForm.lfm    # Layout da janela principal
│   └── uFBExplorerRegister.pas    # Registro na IDE (MenuIntf e IDEWindowCreators)
└── README.md
```

---

## 🛠️ Como Usar e Instalar

### Opção 1: Instalar como Pacote na IDE do Lazarus (Modo "OTA")
1. Abra o **Lazarus IDE**.
2. No menu superior, vá em **Pacote (Package)** $\rightarrow$ **Abrir Arquivo de Pacote (.lpk)...**.
3. Selecione o arquivo `c:\Projetos Antigravity\LazarusDataBaseExplorer\LazarusDataBaseExplorer.lpk`.
4. Na janela do pacote que se abrir, clique em **Compilar (Compile)**.
5. Após compilar com sucesso, clique em **Usar (Use)** $\rightarrow$ **Instalar (Install)**.
6. O Lazarus solicitará confirmação para recompilar a IDE. Clique em **Sim**.
7. Após reiniciar, acesse o menu **Ferramentas (Tools)** $\rightarrow$ **Firebird Database Explorer**.

---

### Opção 2: Executar como Aplicativo Standalone
Você pode executar diretamente sem precisar recompilar a IDE:
- Executando o binário já compilado:
  `c:\Projetos Antigravity\LazarusDataBaseExplorer\bin\FBExplorerApp.exe`
- Ou abrindo o projeto `FBExplorerApp.lpi` no Lazarus e pressionando `F9`.
