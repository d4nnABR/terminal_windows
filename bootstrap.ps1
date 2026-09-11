# bootstrap.ps1
# Instala (portable, SIN admin) las dependencias de la terminal y restaura la
# configuracion de este repo. Descarga SOLO de releases oficiales de GitHub.
#
# Uso:
#   pwsh -File .\bootstrap.ps1
#   pwsh -File .\bootstrap.ps1 -Yes            # sin preguntas
#   pwsh -File .\bootstrap.ps1 -SkipFont       # no instalar la Nerd Font
#   pwsh -File .\bootstrap.ps1 -BaseDir "D:\Projects"
#
# Que instala (en <BaseDir>\Tools):
#   - PowerShell 7 portable   -> Tools\pwsh
#   - oh-my-posh              -> Tools\oh-my-posh\oh-my-posh.exe
#   - fastfetch               -> Tools\fastfetch\fastfetch.exe
#   - Nerd Font CaskaydiaCove -> fuentes de usuario (%LOCALAPPDATA%\...\Fonts)

[CmdletBinding()]
param(
    [string]$BaseDir = (Join-Path $env:USERPROFILE 'Downloads\Projects'),
    [switch]$SkipFont,
    [switch]$SkipPwsh,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot
$tools  = Join-Path $BaseDir 'Tools'
New-Item -ItemType Directory -Path $tools -Force | Out-Null

function Ask($msg) {
    if ($Yes) { return $true }
    (Read-Host "$msg [s/N]") -match '^(s|si|sí|y|yes)$'
}
function Get-GhAsset($repoPath, $pattern) {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$repoPath/releases/latest" -Headers @{ 'User-Agent' = 'terminal-bootstrap' }
    $asset = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    if (-not $asset) { throw "No encontre el asset '$pattern' en $repoPath" }
    return $asset.browser_download_url
}
function Download($url, $dest) {
    Write-Host "   -> $url" -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}

Write-Host "=== Bootstrap Terminal (portable, sin admin) ===" -ForegroundColor Cyan
Write-Host "Destino de herramientas: $tools"
if (-not (Ask "Continuar con la descarga e instalacion?")) { Write-Host "Cancelado."; return }

# --- PowerShell 7 portable ---
$pwshDir = Join-Path $tools 'pwsh'
if ($SkipPwsh) {
    Write-Host "[skip] PowerShell" -ForegroundColor Yellow
} elseif (Test-Path (Join-Path $pwshDir 'pwsh.exe')) {
    Write-Host "[ok]   PowerShell ya existe en $pwshDir" -ForegroundColor Green
} else {
    Write-Host "[..]   Instalando PowerShell 7 portable" -ForegroundColor Cyan
    $url = Get-GhAsset 'PowerShell/PowerShell' 'PowerShell-.*-win-x64\.zip$'
    $zip = Join-Path $tools 'pwsh.zip'
    Download $url $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $pwshDir -Force
    Remove-Item $zip -Force
}

# --- oh-my-posh ---
$ompDir = Join-Path $tools 'oh-my-posh'
$ompExe = Join-Path $ompDir 'oh-my-posh.exe'
if (Test-Path $ompExe) {
    Write-Host "[ok]   oh-my-posh ya existe" -ForegroundColor Green
} else {
    Write-Host "[..]   Instalando oh-my-posh" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ompDir -Force | Out-Null
    $url = Get-GhAsset 'JanDeDobbeleer/oh-my-posh' 'oh-my-posh-windows-amd64\.exe$'
    Download $url $ompExe
}

# --- fastfetch ---
$ffDir = Join-Path $tools 'fastfetch'
if (Test-Path (Join-Path $ffDir 'fastfetch.exe')) {
    Write-Host "[ok]   fastfetch ya existe" -ForegroundColor Green
} else {
    Write-Host "[..]   Instalando fastfetch" -ForegroundColor Cyan
    $url = Get-GhAsset 'fastfetch-cli/fastfetch' 'fastfetch-windows-amd64\.zip$'
    $zip = Join-Path $tools 'fastfetch.zip'
    Download $url $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $ffDir -Force
    Remove-Item $zip -Force
}

# --- Nerd Font (CaskaydiaCove) a fuentes de usuario ---
if ($SkipFont) {
    Write-Host "[skip] Nerd Font" -ForegroundColor Yellow
} else {
    Write-Host "[..]   Instalando Nerd Font CaskaydiaCove (usuario)" -ForegroundColor Cyan
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    $tmp = Join-Path $tools 'nerd-fonts'
    $zip = Join-Path $tools 'CaskaydiaCove.zip'
    $url = Get-GhAsset 'ryanoasis/nerd-fonts' 'CaskaydiaCove\.zip$'
    Download $url $zip
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    $reg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
    Get-ChildItem $tmp -Filter *.ttf -Recurse | ForEach-Object {
        $dst = Join-Path $fontDir $_.Name
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
        New-ItemProperty -Path $reg -Name ("{0} (TrueType)" -f $_.BaseName) -Value $dst -PropertyType String -Force | Out-Null
    }
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# --- PATH de usuario ---
$add = @($pwshDir, $ompDir, $ffDir) | Where-Object { $_ }
$cur = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($cur -split ';' | Where-Object { $_ })
foreach ($p in $add) { if ($parts -notcontains $p) { $parts = @($p) + $parts } }
[Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
Write-Host "[ok]   PATH de usuario actualizado" -ForegroundColor Green

# --- Restaurar configuracion ---
$restore = Join-Path $repo 'restore.ps1'
if (Test-Path $restore) {
    Write-Host "[..]   Restaurando configuracion (restore.ps1)" -ForegroundColor Cyan
    & $restore
}

# --- Reparar rutas absolutas del usuario original (C:\Users\gary.abrigo) ---
$oldBase = 'C:\Users\gary.abrigo'
$newBase = $env:USERPROFILE
$targets = @(
    $PROFILE,
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:USERPROFILE '.config\fastfetch\glass.jsonc')
)
foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        $c = Get-Content -LiteralPath $t -Raw
        if ($c -like "*$oldBase*") {
            $c = $c.Replace($oldBase, $newBase)
            $c = $c.Replace('C:/Users/gary.abrigo', ($newBase -replace '\\', '/'))
            Set-Content -LiteralPath $t -Value $c -NoNewline -Encoding UTF8
            Write-Host "[ok]   Rutas ajustadas en $t" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Terminado." -ForegroundColor Cyan
Write-Host "1) Abre una terminal NUEVA." -ForegroundColor Yellow
Write-Host "2) Reinicia Windows Terminal (para el acrilico de la barra de pestanas)." -ForegroundColor Yellow
Write-Host "3) Verifica rutas de codex/postgres/dotnet en el perfil si cambiaste de estructura." -ForegroundColor Yellow
