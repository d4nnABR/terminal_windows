# ======================================================
#  Perfil de PowerShell 7 (portable)
# ======================================================
# No contiene rutas absolutas de usuario: todo se resuelve en
# tiempo de ejecucion desde variables de entorno.
#
# Puedes cambiar la raiz de proyectos sin editar este archivo:
#   $env:TERMINAL_PROJECTS = 'D:\Projects'
#   $env:TERMINAL_THEMES   = 'D:\ThemesPosh'
#
# Para configuracion personal usa el archivo NO versionado:
#   Microsoft.PowerShell_profile.local.ps1
# (hay un ejemplo en Microsoft.PowerShell_profile.local.example.ps1)
# ------------------------------------------------------

$ProjectsDir = if ($env:TERMINAL_PROJECTS) { $env:TERMINAL_PROJECTS } else { Join-Path $env:USERPROFILE 'Downloads\Projects' }
$ToolsDir    = Join-Path $ProjectsDir 'Tools'
$ThemesDir   = if ($env:TERMINAL_THEMES) { $env:TERMINAL_THEMES } else { Join-Path $ProjectsDir 'ThemesPosh' }

function Add-PathEntry {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (($env:PATH -split ';') -notcontains $Path) {
        $env:PATH = "$Path;$env:PATH"
    }
}

# ─── PATH ───────────────────────────────────────────────
Add-PathEntry (Join-Path $ProjectsDir 'PortableGit\bin')
Add-PathEntry (Join-Path $ProjectsDir 'PortableGit\usr\bin')
Add-PathEntry (Join-Path $env:USERPROFILE '.local\bin')
Add-PathEntry (Join-Path $ToolsDir 'codex\node_modules\.bin')

# ─── OH MY POSH ─────────────────────────────────────────
$ompConfig = Join-Path $ThemesDir 'tokyo.omp.json'
if (-not (Test-Path -LiteralPath $ompConfig) -and $PSScriptRoot) {
    # Fallback: usar el tema incluido en el repo si no se ejecuto restore.ps1.
    $ompConfig = Join-Path (Split-Path -Parent $PSScriptRoot) 'oh-my-posh\tokyo.omp.json'
}
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $ompConfig)) {
    oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
}

# ─── MÓDULOS ────────────────────────────────────────────
if (Get-Module -ListAvailable -Name Terminal-Icons) { Import-Module Terminal-Icons }
if (Get-Module -ListAvailable -Name posh-git)       { Import-Module posh-git }

# ─── FASTFETCH ──────────────────────────────────────────
$fastfetchConfig = Join-Path $env:USERPROFILE '.config\fastfetch\glass.jsonc'
if ((Get-Command fastfetch -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $fastfetchConfig)) {
    fastfetch -c $fastfetchConfig
}

# ─── PSREADLINE ─────────────────────────────────────────
if (-not [Console]::IsOutputRedirected -and $Host.Name -eq 'ConsoleHost') {
    $psrlVersion = (Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    if ($psrlVersion -and $psrlVersion -ge [Version]'2.2.0') {
        try {
            Set-PSReadLineOption -PredictionSource History
            Set-PSReadLineOption -PredictionViewStyle ListView
        } catch { }
    }
}

# ─── POSTGRESQL PORTABLE (opcional) ─────────────────────
$PG_BIN  = Join-Path $ProjectsDir 'postgres\pgsql\bin'
$PG_DATA = Join-Path $ProjectsDir 'postgres\pgsql\data_pg'
$PG_LOG  = Join-Path $ProjectsDir 'postgres\pg.log'

if (Test-Path -LiteralPath (Join-Path $PG_BIN 'pg_ctl.exe')) {
    Add-PathEntry $PG_BIN
    $pgCtl = Join-Path $PG_BIN 'pg_ctl.exe'

    function pg-start  { & $pgCtl start  -D $PG_DATA -l $PG_LOG; Write-Host 'PostgreSQL iniciado.'  -ForegroundColor Green }
    function pg-stop   { & $pgCtl stop   -D $PG_DATA -m fast;    Write-Host 'PostgreSQL detenido.'  -ForegroundColor Yellow }
    function pg-status { & $pgCtl status -D $PG_DATA }
}

# ─── DOTNET PORTABLE (opcional) ─────────────────────────
$dotnetSdk = Get-ChildItem -LiteralPath $ToolsDir -Directory -Filter 'dotnet-sdk-*-win-x64' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($dotnetSdk) {
    $env:DOTNET_ROOT = $dotnetSdk.FullName
    Add-PathEntry $dotnetSdk.FullName
}

# ─── FONDO CMI (opcional) ───────────────────────────────
$fondoCmiScript = Join-Path $ProjectsDir 'Utils Win\Set-FondoCMI.ps1'
if (Test-Path -LiteralPath $fondoCmiScript) {
    function fondo-cmi { & $fondoCmiScript }
}

# ─── PERSONALIZACIÓN LOCAL (no versionada) ──────────────
$localProfile = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.local.ps1' } else { $null }
if ($localProfile -and (Test-Path -LiteralPath $localProfile)) {
    . $localProfile
}
