# Firebird Database Explorer for Lazarus (IDE Package & Standalone)

<p align="center">
  <b>🇺🇸 English</b> &nbsp;|&nbsp; <a href="README.md#readme-pt">🇧🇷 Português</a>
</p>

[![Lazarus](https://img.shields.io/badge/Lazarus-2.2%20%7C%203.x%20%7C%204.x-blue.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/FPC-3.2.2+-red.svg)](https://www.freepascal.org/)
[![Firebird](https://img.shields.io/badge/Firebird-2.5%20%7C%203.0%20%7C%204.0%20%7C%205.0-orange.svg)](https://firebirdsql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey.svg)]()

A comprehensive, native, high-performance database management, exploration, and modeling tool for **Firebird**, inspired by established tools such as *IBExpert* and *DBeaver*.

Designed to work in two modes:
1. **Lazarus IDE Integrated Package ("OTA" / IDEIntf)**: Dockable window within the IDE environment with native **AnchorDocking** support.
2. **Standalone Application**: Self-contained, lightweight executable for quick usage without needing to recompile the Lazarus IDE.

---

## 🌟 Key Features & Modules

### 🔌 1. Connection Manager & Multiple Databases
- **Simultaneous Databases**: Connect to and browse multiple databases concurrently within the same metadata tree.
- **Local & Remote Servers**: Flexible configuration for Host, Port (default 3050), and database file path (`.fdb`).
- **Flexible Authentication**: Support for the default `SYSDBA` user or custom user accounts, passwords, and charsets (`UTF8`, `WIN1252`, `ISO8859_1`, `NONE`).
- **Client Library Selection**: Optional custom path configuration for `fbclient.dll` / `libfbclient.so`.
- **Database Creation Wizard**: Built-in wizard to initialize empty database files directly from the UI (`CREATE DATABASE`).
- **Connection Persistence**: Automatic, secure storage of connection profiles in a `.ini` configuration file.
- **Context Menu per Database**: Reconnect, disconnect, or remove any database individually with a single click.

---

### 🌳 2. Metadata Browser with Native Procedural Icons
- **Native Procedural Vector Icons**: Drawn procedurally at runtime (`uFBTreeIcons`), ensuring crisp rendering across DPI scales without external image package dependencies.
- **Comprehensive Object Hierarchy**:
  - 🗄️ **Databases**: List of active connected instances.
  - 📁 **User Tables**: Listing with column details and visual primary key indicators (🔑).
  - 👁️ **Views**.
  - ⚙️ **Stored Procedures**.
  - ⚡ **Triggers**.
  - 🔢 **Generators / Sequences**.
- **Responsive Navigation**: Automatic node selection on right-click (`TreeViewMetaMouseDown`) for immediate access to context menus.
- **Smart Double-Click**: Automatically opens a quick query displaying the first 100 records of the selected table.

---

### 📝 3. Multi-Tab SQL Editor with History & Execution
- **Multi-Tab Query Sheets**: Create and close independent SQL script tabs to work on simultaneous queries.
- **SQL Syntax Highlighting**: High-performance editor integrated via `TSynEdit` and `TSynSQLSyn`.
- **Automatic History**: Dropdown history storing recently executed statements for immediate recall and re-execution.
- **Manual Transaction Control**: Explicit transaction management buttons (**Commit** and **Rollback**) with visual transaction status indicators.
- **Execution Metrics**: Accurate reporting of returned or affected row counts and elapsed time in milliseconds (ms).
- **Productive Shortcuts**:
  - `F9`: Execute the current query or selected SQL block.
  - `F5`: Refresh metadata for the connected database.

---

### 📊 4. Data Grid with Inline Editing & Cell Viewer
- **Interactive Data Grid**: Fluid tabular display of returned datasets (`TDBGrid` / `TSQLQuery`).
- **Direct Inline Editing**: Edit field values directly within the query result cells.
- **Data Toolbar**:
  - ➕ **Insert Row**: Add new records to the dataset.
  - 🗑️ **Delete Row**: Remove the selected record with confirmation.
  - 💾 **Save Changes**: Persist modifications via transactional `Post`.
  - ✖ **Cancel**: Revert pending row edits.
  - 🔄 **Reload**: Refresh grid records.
- **Advanced Cell Viewer**:
  - Dedicated viewer window (`uFBCellViewerForm`) opened via **double-click** on any cell or long text field.
  - Automatic word wrap, live character counter, and one-click copy button.
  - Ideal for inspecting large text payloads, JSON, XML, or BLOB contents.

---

### 📤 5. Advanced Data Export (CSV, JSON, SQL)
- **Multi-Format Export**: Export query results or complete table data effortlessly.
  - **CSV**: Configurable delimiters (semicolon, comma, tab) and quoting options.
  - **JSON**: Clean, structured format ready for web integrations, APIs, and microservices.
  - **SQL INSERTs**: Batch `INSERT INTO` script generation tailored for cross-database migrations.
- Rapid access available both from the query results tab and the table context menu in the metadata tree.

---

### 🏗️ 6. Visual Table Creation Wizard
- **Complete Column Definitions**:
  - Column name.
  - Native data types: `BIGINT`, `INTEGER`, `SMALLINT`, `VARCHAR`, `CHAR`, `NUMERIC`, `TIMESTAMP`, `DATE`, `TIME`, `BLOB`, `BOOLEAN`.
  - Precise length, precision, and decimal scale controls.
  - `NOT NULL` constraints and `DEFAULT` values.
  - Primary Key (`PRIMARY KEY`) definition.
  - Auto-increment support (`IDENTITY` for Firebird 3.0+ or automated Generator/Trigger binding for Firebird 2.5).
- **Add Audit Fields**: One-click button to automatically append standard enterprise audit columns (`DATA_CADASTRO`, `ATIVO`, `USUARIO_CADASTRO`).
- **Integrated Foreign Key (FK) Management**: Embedded tab to define and link foreign keys directly during table design.
- **DDL Script Preview**: Real-time generation of the `CREATE TABLE` script with direct transactional execution.

---

### 🛠️ 7. Column DDL & Structure Alteration Manager
- **Existing Table Alterations**:
  - ➕ **Add Column**: Append new columns to live production tables.
  - ✏️ **Alter Type / Size**: Guided modifications or width expansions (`VARCHAR`, `NUMERIC`, etc.) pre-populating original attributes.
  - 🔤 **Rename Column**: Safe column renaming via `ALTER COLUMN ... TO ...`.
  - 🗑️ **Drop Column**: Secure column deletion with validation.
- **Double-Click Editing**: Double-clicking any column in the structure grid immediately opens the pre-filled alteration dialog.

---

### 🔑 8. Key & Constraint Manager (PK / FK) — IBExpert Style
- **Primary Keys (PK)**:
  - Inspection and display of active primary keys.
  - Multi-column visual selection via `TCheckListBox` for composite primary keys.
  - Guided creation and deletion of primary key constraints.
- **Foreign Keys (FK)**:
  - Complete listing of existing FKs queried directly from `RDB$RELATION_CONSTRAINTS`.
  - Clear visual relationship mapping: `[Local Column] ➔ REFERENCES ➔ [Target Table & Column]`.
  - Referential integrity actions: `ON UPDATE` and `ON DELETE` (`NO ACTION`, `CASCADE`, `SET NULL`, `SET DEFAULT`, `RESTRICT`).
  - Automated script generation and execution for `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...`.

---

### ⚡ 9. Index Manager
- **Index Inspection**: Detailed index breakdown for individual tables or across the entire database.
- **In-Depth Metrics**: Real-time display of selectivity, uniqueness (Unique / Non-Unique), and sort order (Ascending / Descending).
- **Activate & Deactivate**: Toggle indices (`ACTIVE` / `INACTIVE`) with one click — crucial for high-throughput bulk data imports.
- **Recalculate Statistics**: One-click execution of `SET STATISTICS INDEX <NAME>` to recompute outdated selectivities and optimize the Firebird query planner.
- **Create & Drop**: Visual wizard for creating new custom indices or dropping obsolete ones (`DROP INDEX`).

---

### 🔢 10. Sequence / Generator Manager
- **Sequence Overview**: Complete inspection of generators queried directly from `RDB$GENERATORS`.
- **Live Current Values**: Instant query of current sequence counters via `GEN_ID(seq, 0)`.
- **Create New Sequence**: Wizard for creating generators with customized initial values.
- **Alter / Restart Value**: Reset or update sequence values (`ALTER SEQUENCE ... RESTART WITH ...`).
- **Drop Sequence**: Safe deletion of deprecated sequences (`DROP SEQUENCE`).

---

### 🩺 11. Database Health & Diagnostics (MON$ Tables)
- **Live Monitoring**: Real-time metric gathering through Firebird's `MON$` system monitoring tables.
- **Transaction & OIT/OAT Health Analysis**:
  - *Next Transaction*: Next transaction ID.
  - *Oldest Active Transaction (OAT)*: Oldest running transaction.
  - *Oldest Interesting Transaction (OIT)*: Oldest interesting transaction.
  - *OAT - OIT Delta*: Early warning against uncommitted transaction backlogs (preventing performance degradation and excessive record version sweeps).
- **Active Connections (`MON$ATTACHMENTS`)**: Detailed breakdown of connected users, IP addresses, and client programs.
- **Running Statements (`MON$STATEMENTS`)**: Real-time view of SQL statements currently executing on the server.

---

### 📜 12. Full DDL Extractor & PSQL Viewer
- **Full Database DDL Extractor**:
  - Generates the complete database DDL schema script in a single window: tables, columns, primary keys, foreign keys, indices, sequences, triggers, and stored procedures.
  - Quick-copy button and direct export to `.sql` file.
- **PSQL Code Viewer / Editor**:
  - Inspect original source code for **Stored Procedures** and **Triggers** with dedicated SQL/PSQL syntax highlighting.

---

## ⌨️ Productivity Shortcuts

| Key / Action | Context | Description |
| :--- | :--- | :--- |
| **`F9`** | SQL Editor | Execute the current SQL query or selected block |
| **`F5`** | Main Window | Refresh metadata tree for the active database |
| **`Right Click`** | Metadata Tree | Select node and open contextual actions menu |
| **`Double Click`** | Table in Tree | Open quick query showing the first 100 rows |
| **`Double Click`** | Grid Cell | Open the dedicated **Cell Viewer** dialog |
| **`Double Click`** | Column in Structure Grid | Open the column alteration wizard (type, size, rename) |

---

## 📁 Repository Structure

```
LazarusDataBaseExplorer/
├── LazarusDataBaseExplorer.lpk    # Lazarus IDE Extension Package
├── LazarusDataBaseExplorer.pas    # Package master registration unit
├── FBExplorerApp.lpi              # Standalone application project file
├── FBExplorerApp.lpr              # Standalone application entry point
├── bin/
│   └── FBExplorerApp.exe          # Compiled standalone executable
├── src/
│   ├── uFBTypes.pas               # Type definitions, enums, and Firebird conversion helpers
│   ├── uFBConnectionManager.pas   # Connection orchestrator (TIBConnection / TSQLTransaction)
│   ├── uFBConnectionDialog.pas    # Connection configuration, testing, and profile manager
│   ├── uFBConnectionDialog.lfm    # Connection dialog visual layout
│   ├── uFBMetaData.pas            # RDB$ system catalog parser and DDL generator
│   ├── uFBTreeIcons.pas           # Procedural native vector icons for metadata tree
│   ├── uFBCreateTableForm.pas     # Visual wizard for creating new database tables
│   ├── uFBCreateTableForm.lfm     # Table wizard layout
│   ├── uFBConstraintForm.pas      # Visual constraint manager for PK and FK (IBExpert style)
│   ├── uFBConstraintForm.lfm      # Constraint manager layout
│   ├── uFBAlterFieldForm.pas      # Column alteration wizard (type, size, rename)
│   ├── uFBAlterFieldForm.lfm      # Column alteration layout
│   ├── uFBIndexManagerForm.pas    # Index manager (status, recalculate statistics, DDL)
│   ├── uFBIndexManagerForm.lfm    # Index manager layout
│   ├── uFBGeneratorForm.pas       # Sequence and generator manager
│   ├── uFBGeneratorForm.lfm       # Sequence manager layout
│   ├── uFBDatabaseHealthForm.pas  # MON$ database diagnostic and health dashboard
│   ├── uFBDatabaseHealthForm.lfm  # Diagnostic dashboard layout
│   ├── uFBDataExportForm.pas      # Data exporter for CSV, JSON, and SQL INSERT scripts
│   ├── uFBDataExportForm.lfm      # Data exporter layout
│   ├── uFBCellViewerForm.pas      # Advanced cell viewer (long text, JSON, XML, BLOB)
│   ├── uFBCellViewerForm.lfm      # Cell viewer layout
│   ├── uFBExplorerMainForm.pas    # Main explorer window (Tree, SQL, Grid, DDL)
│   ├── uFBExplorerMainForm.lfm    # Main explorer layout
│   └── uFBExplorerRegister.pas    # Lazarus IDE integration (Tools Menu & AnchorDocking)
└── README.md
```

---

## 🛠️ Installation & Execution

### Option 1: Install as Lazarus IDE Integrated Package ("OTA")
1. Open **Lazarus IDE**.
2. From the top menu, click **Package** $\rightarrow$ **Open Package File (.lpk)...**.
3. Select `LazarusDataBaseExplorer.lpk`.
4. In the package manager window, click **Compile**.
5. Then click **Use** $\rightarrow$ **Install**.
6. Confirm Lazarus' prompt to rebuild the IDE.
7. After Lazarus restarts, access the tool via:
   **Tools** $\rightarrow$ **Firebird Database Explorer**.
8. The window can float freely or be docked anywhere inside the IDE using **AnchorDocking**.

---

### Option 2: Run as Standalone Application
You can use the application independently without modifying or rebuilding your Lazarus IDE:
- **Using the pre-compiled binary**:
  Simply launch `bin/FBExplorerApp.exe`.
- **Compiling from source code**:
  Open `FBExplorerApp.lpi` in Lazarus and press `F9`, or compile via `lazbuild`:
  ```bash
  lazbuild FBExplorerApp.lpi
  ```

---

## 📋 Compatibility & Requirements
- **Lazarus**: 2.2.0 or higher (fully tested on 2.2, 3.x, and 4.x).
- **Free Pascal (FPC)**: 3.2.2 or higher.
- **Firebird**: Versions 2.5, 3.0, 4.0, and 5.0 (Dialects 1 and 3).
- **Firebird Client**: `fbclient.dll` (Windows) or `libfbclient.so` (Linux) matching the target architecture (32-bit or 64-bit).

---

## 📄 License
Distributed under the **MIT** License. See the license file for more details.