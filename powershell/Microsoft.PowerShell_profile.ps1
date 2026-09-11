# ─── PATH ───────────────────────────────────────────────
$env:PATH += ";C:\Users\gary.abrigo\Downloads\PortableGit\bin"
$env:PATH += ";C:\Users\gary.abrigo\Downloads\PortableGit\usr\bin"
$env:PATH += ";C:\Users\gary.abrigo\.local\bin"
$env:PATH += ";C:\Users\gary.abrigo\Downloads\Projects\Tools\codex\node_modules\.bin"

# ─── OH MY POSH ─────────────────────────────────────────
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "C:\Users\gary.abrigo\Downloads\Projects\ThemesPosh\tokyo.omp.json" | Invoke-Expression
}

# ─── MÓDULOS ────────────────────────────────────────────
if (Get-Module -ListAvailable -Name Terminal-Icons) { Import-Module Terminal-Icons }
if (Get-Module -ListAvailable -Name posh-git)       { Import-Module posh-git }

# ─── FASTFETCH ──────────────────────────────────────────
if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c "C:\Users\gary.abrigo\.config\fastfetch\glass.jsonc" }

# ─── PSREADLINE ─────────────────────────────────────────
if (-not [Console]::IsOutputRedirected -and $Host.Name -eq 'ConsoleHost') {
    $psrlVersion = (Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    if ($psrlVersion -ge [Version]"2.2.0") {
        try {
            Set-PSReadLineOption -PredictionSource History
            Set-PSReadLineOption -PredictionViewStyle ListView
        } catch { }
    }
}

# ─── POSTGRESQL PORTABLE ────────────────────────────────
$PG_BIN  = "C:\Users\gary.abrigo\Downloads\Projects\postgres\pgsql\bin"
$PG_DATA = "C:\\Users\\gary.abrigo\\Downloads\\Projects\\postgres\\pgsql\\data_pg"
$PG_LOG  = "C:\Users\gary.abrigo\Downloads\Projects\postgres\pg.log"
$env:PATH += ";$PG_BIN"

function pg-start  { & "$PG_BIN\pg_ctl.exe" start  -D $PG_DATA -l $PG_LOG; Write-Host "PostgreSQL iniciado."  -ForegroundColor Green  }
function pg-stop   { & "$PG_BIN\pg_ctl.exe" stop   -D $PG_DATA -m fast;    Write-Host "PostgreSQL detenido."  -ForegroundColor Yellow }
function pg-status { & "$PG_BIN\pg_ctl.exe" status -D $PG_DATA }

# ─── DOTNET PORTABLE ────────────────────────────────
$env:DOTNET_ROOT="C:\Users\gary.abrigo\Downloads\Projects\Tools\dotnet-sdk-8.0.421-win-x64"
$env:PATH="$env:DOTNET_ROOT;$env:PATH"

# ─── FONDO CMI ──────────────────────────────────────────
function fondo-cmi { & "C:\Users\gary.abrigo\Downloads\Projects\Utils Win\Set-FondoCMI.ps1" }
