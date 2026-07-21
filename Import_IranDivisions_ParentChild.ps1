<#
============================================================
 HOW TO RUN THIS SCRIPT IN POWERSHELL
============================================================
 1. Open PowerShell (search "PowerShell" in the Start Menu).
 2. Navigate to the folder that contains this script, e.g.:
      cd C:\Projects\Import_IranDivisions_ParentChild.ps1
 3. If this is the first time you're running a script on this
    machine, allow script execution for this session only:
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
 4. Update the SETTINGS block below with your own CSV path,
    server, database, username, and password.
 5. Run the script:
      .\Import_IranDivisions_ParentChild.ps1

 ⚠ Do not commit real credentials to git. Revert the SETTINGS
   block back to placeholders before committing this file.
============================================================
#>

# ---------------- SETTINGS: update these ----------------
$csvPath  = "D:\IranDivisions_ParentChild.csv"   # <-- update: path to your CSV file
$server   = "your-server-address"                # <-- update: e.g. "localhost" or "myserver.database.windows.net"
$database = "your-database-name"                 # <-- update
$username = "your-username"                      # <-- update
$password = "your-password"                      # <-- update
# ----------------------------------------------------------

if (-not (Test-Path $csvPath)) {
    throw "CSV file not found: $csvPath"
}

$connectionString = "Server=$server;Database=$database;User ID=$username;Password=$password;TrustServerCertificate=True;"

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$connection.Open()

try {
    # --- Step 1: Ensure the table exists (create table if missing) ---
    $createTableSql = @"
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'IranDivisions' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE dbo.IranDivisions
    (
        [Id]        INT           NOT NULL PRIMARY KEY,
        [Parent]    INT           NULL,
        [Level]     INT           NULL,
        [Code]      NVARCHAR(100) NULL,
        [NameFa]    NVARCHAR(255) NULL,
        [Name]      NVARCHAR(255) NULL, -- It is preserved for English name of the place
        [CODEREC]   INT           NULL,
        [Diag]      INT           NULL,

        CONSTRAINT FK_IranDivisions_Parent
            FOREIGN KEY (Parent) REFERENCES dbo.IranDivisions(Id)
    );

    CREATE INDEX IX_IranDivisions_Parent ON dbo.IranDivisions(Parent);
    CREATE INDEX IX_IranDivisions_Code   ON dbo.IranDivisions(Code);
END
"@

    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $createTableSql
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Host "✅ Table verified/created." -ForegroundColor Green

    # --- Step 2: Insert rows inside a transaction ---
    $transaction = $connection.BeginTransaction()

    $command = $connection.CreateCommand()
    $command.Transaction = $transaction
    $command.CommandText = @"
INSERT INTO dbo.IranDivisions
(
    [Id], [Parent], [Level], [Code], [NameFa], [Name], [CODEREC], [Diag]
)
VALUES
(
    @Id, @Parent, @Level, @Code, @NameFa, @Name, @CODEREC, @Diag
)
"@

    $null = $command.Parameters.Add("@Id",      [System.Data.SqlDbType]::Int)
    $null = $command.Parameters.Add("@Parent",  [System.Data.SqlDbType]::Int)
    $null = $command.Parameters.Add("@Level",   [System.Data.SqlDbType]::Int)
    $null = $command.Parameters.Add("@Code",    [System.Data.SqlDbType]::NVarChar, 100)
    $null = $command.Parameters.Add("@NameFa",  [System.Data.SqlDbType]::NVarChar, 255)
    $null = $command.Parameters.Add("@Name",    [System.Data.SqlDbType]::NVarChar, 255)
    $null = $command.Parameters.Add("@CODEREC", [System.Data.SqlDbType]::Int)
    $null = $command.Parameters.Add("@Diag",    [System.Data.SqlDbType]::Int)

    $rows = Import-Csv -Path $csvPath -Delimiter "," -Encoding UTF8
    $count = 0

    foreach ($row in $rows) {
        $command.Parameters["@Id"].Value      = if ([string]::IsNullOrWhiteSpace($row.Id))      { [DBNull]::Value } else { [int]$row.Id }
        $command.Parameters["@Parent"].Value  = if ([string]::IsNullOrWhiteSpace($row.Parent))  { [DBNull]::Value } else { [int]$row.Parent }
        $command.Parameters["@Level"].Value   = if ([string]::IsNullOrWhiteSpace($row.Level))   { [DBNull]::Value } else { [int]$row.Level }
        $command.Parameters["@Code"].Value    = if ([string]::IsNullOrWhiteSpace($row.Code))    { [DBNull]::Value } else { $row.Code.Trim() }
        $command.Parameters["@NameFa"].Value  = if ([string]::IsNullOrWhiteSpace($row.NameFa))  { [DBNull]::Value } else { $row.NameFa.Trim() }
        $command.Parameters["@Name"].Value    = if ([string]::IsNullOrWhiteSpace($row.Name))    { [DBNull]::Value } else { $row.Name.Trim() }
        $command.Parameters["@CODEREC"].Value = if ([string]::IsNullOrWhiteSpace($row.CODEREC)) { [DBNull]::Value } else { [int]$row.CODEREC }
        $command.Parameters["@Diag"].Value    = if ([string]::IsNullOrWhiteSpace($row.Diag))    { [DBNull]::Value } else { [int]$row.Diag }

        $command.ExecuteNonQuery() | Out-Null
        $count++

        if ($count % 500 -eq 0) {
            Write-Host "$count rows inserted..." -ForegroundColor Cyan
        }
    }

    $transaction.Commit()
    Write-Host "✅ Done! Successfully inserted $count rows into IranDivisions." -ForegroundColor Green
}
catch {
    if ($transaction) { $transaction.Rollback() }
    Write-Error "Error occurred: $($_.Exception.Message)"
}
finally {
    $connection.Close()
}
