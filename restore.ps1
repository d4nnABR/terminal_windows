# restore.ps1 - restaura la configuracion de terminal en esta PC.
#
# Uso:
#   pwsh -File .\restore.ps1
#   pwsh -File .\restore.ps1 -ProjectsDir "D:\Projects"
#   pwsh -File .\restore.ps1 -NoBackup
#
# Hace backup (con timestamp) de los archivos existentes antes de sobrescribir.

[CmdletBinding()]
param(
    [string]$ProjectsDir = (Join-Path $env:USERPROFILE 'Downloads\Projects'),
    [string]$ThemesDir,
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'
$repo  = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not $ThemesDir) { $ThemesDir = Join-Path $ProjectsDir 'ThemesPosh' }

function Copy-WithBackup {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Warning "No existe en el repo: $Source"
        return
    }

    $dir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if (-not $NoBackup -and (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Destination -Destination "$Destination.$stamp.bak" -Force
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "OK  $Destination" -ForegroundColor Green
}

# --- Windows Terminal (Store, Preview o instalacion sin paquete) ---
$wtCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
$wtDst = $wtCandidates |
    Where-Object { Test-Path -LiteralPath (Split-Path -Parent $_) } |
    Select-Object -First 1

if ($wtDst) {
    Copy-WithBackup -Source (Join-Path $repo 'windows-terminal\settings.json') -Destination $wtDst
} else {
    Write-Warning 'No se encontro Windows Terminal instalado; se omite settings.json.'
}

# --- Perfil de PowerShell ---
Copy-WithBackup -Source (Join-Path $repo 'powershell\Microsoft.PowerShell_profile.ps1') -Destination $PROFILE

# --- Oh My Posh (temas) ---
Copy-WithBackup -Source (Join-Path $repo 'oh-my-posh\tokyo.omp.json')        -Destination (Join-Path $ThemesDir 'tokyo.omp.json')
Copy-WithBackup -Source (Join-Path $repo 'oh-my-posh\liquid-glass.omp.json') -Destination (Join-Path $ThemesDir 'liquid-glass.omp.json')

# --- fastfetch ---
$ffDst = Join-Path $env:USERPROFILE '.config\fastfetch'
Copy-WithBackup -Source (Join-Path $repo 'fastfetch\glass.jsonc') -Destination (Join-Path $ffDst 'glass.jsonc')
Copy-WithBackup -Source (Join-Path $repo 'fastfetch\logo.txt')    -Destination (Join-Path $ffDst 'logo.txt')

Write-Host ''
Write-Host 'Listo. Abre una terminal NUEVA (y reinicia Windows Terminal para el acrilico de la barra).' -ForegroundColor Cyan
Write-Host "Raiz de proyectos usada: $ProjectsDir" -ForegroundColor DarkGray
Write-Host 'Si usas otra estructura, define TERMINAL_PROJECTS o edita tu archivo .local.ps1.' -ForegroundColor Yellow
