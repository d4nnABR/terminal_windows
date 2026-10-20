# bootstrap.ps1
# Instala (portable, SIN admin) las dependencias de la terminal y restaura la
# configuracion de este repo. Descarga SOLO de releases oficiales de GitHub.
#
# Uso:
#   pwsh -File .\bootstrap.ps1
#   pwsh -File .\bootstrap.ps1 -Yes            # sin preguntas
#   pwsh -File .\bootstrap.ps1 -SkipFont       # no instalar la Nerd Font
#   pwsh -File .\bootstrap.ps1 -SkipPwsh       # usar un PowerShell ya instalado
#   pwsh -File .\bootstrap.ps1 -SkipModules    # no instalar modulos de PSGallery
#   pwsh -File .\bootstrap.ps1 -BaseDir "D:\Projects"
#
# Que instala (en <BaseDir>\Tools):
#   - PowerShell 7 portable   -> Tools\pwsh
#   - oh-my-posh              -> Tools\oh-my-posh\oh-my-posh.exe
#   - fastfetch               -> Tools\fastfetch\fastfetch.exe
#   - Nerd Font CaskaydiaCove -> fuentes de usuario (%LOCALAPPDATA%\...\Fonts)
#
# Opcionalmente instala los modulos Terminal-Icons y posh-git (usuario).

[CmdletBinding()]
param(
    [string]$BaseDir = (Join-Path $env:USERPROFILE 'Downloads\Projects'),
    [switch]$SkipFont,
    [switch]$SkipPwsh,
    [switch]$SkipModules,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$repo  = $PSScriptRoot
$tools = Join-Path $BaseDir 'Tools'
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

Write-Host '=== Bootstrap Terminal (portable, sin admin) ===' -ForegroundColor Cyan
Write-Host "Destino de herramientas: $tools"
Write-Host "Raiz de proyectos:       $BaseDir"
if (-not (Ask 'Continuar con la descarga e instalacion?')) { Write-Host 'Cancelado.'; return }

# --- PowerShell 7 portable ---
$pwshDir = Join-Path $tools 'pwsh'
if ($SkipPwsh) {
    Write-Host '[skip] PowerShell' -ForegroundColor Yellow
} elseif (Test-Path (Join-Path $pwshDir 'pwsh.exe')) {
    Write-Host "[ok]   PowerShell ya existe en $pwshDir" -ForegroundColor Green
} else {
    Write-Host '[..]   Instalando PowerShell 7 portable' -ForegroundColor Cyan
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
    Write-Host '[ok]   oh-my-posh ya existe' -ForegroundColor Green
} else {
    Write-Host '[..]   Instalando oh-my-posh' -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ompDir -Force | Out-Null
    $url = Get-GhAsset 'JanDeDobbeleer/oh-my-posh' '(oh-my-posh|posh)-windows-amd64\.exe$'
    Download $url $ompExe
}

# --- fastfetch ---
$ffDir = Join-Path $tools 'fastfetch'
if (Test-Path (Join-Path $ffDir 'fastfetch.exe')) {
    Write-Host '[ok]   fastfetch ya existe' -ForegroundColor Green
} else {
    Write-Host '[..]   Instalando fastfetch' -ForegroundColor Cyan
    $url = Get-GhAsset 'fastfetch-cli/fastfetch' 'fastfetch-windows-amd64\.zip$'
    $zip = Join-Path $tools 'fastfetch.zip'
    Download $url $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $ffDir -Force
    Remove-Item $zip -Force
}

# --- Nerd Font (CaskaydiaCove) a fuentes de usuario ---
if ($SkipFont) {
    Write-Host '[skip] Nerd Font' -ForegroundColor Yellow
} else {
    Write-Host '[..]   Instalando Nerd Font CaskaydiaCove (usuario)' -ForegroundColor Cyan
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    $tmp = Join-Path $tools 'nerd-fonts'
    $zip = Join-Path $tools 'CaskaydiaCove.zip'
    $url = Get-GhAsset 'ryanoasis/nerd-fonts' '(CascadiaCode|CaskaydiaCove)\.zip$'
    Download $url $zip
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    $reg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
    Get-ChildItem $tmp -Filter *.ttf -Recurse | ForEach-Object {
        $dst = Join-Path $fontDir $_.Name
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
        New-ItemProperty -Path $reg -Name ('{0} (TrueType)' -f $_.BaseName) -Value $dst -PropertyType String -Force | Out-Null
    }
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Modulos de PowerShell (opcional) ---
if ($SkipModules) {
    Write-Host '[skip] Modulos de PowerShell' -ForegroundColor Yellow
} elseif (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
    Write-Warning 'Install-Module no esta disponible; se omiten Terminal-Icons y posh-git.'
} else {
    foreach ($module in @('Terminal-Icons', 'posh-git')) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "[ok]   Modulo $module ya instalado" -ForegroundColor Green
            continue
        }
        Write-Host "[..]   Instalando modulo $module" -ForegroundColor Cyan
        try {
            Install-Module $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo instalar ${module}: $($_.Exception.Message)"
        }
    }
}

# --- PATH de usuario ---
$add = @($pwshDir, $ompDir, $ffDir) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
$cur = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($cur -split ';' | Where-Object { $_ })
foreach ($p in $add) { if ($parts -notcontains $p) { $parts = @($p) + $parts } }
[Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
Write-Host '[ok]   PATH de usuario actualizado' -ForegroundColor Green

# --- Raiz de proyectos no estandar ---
$defaultBase = Join-Path $env:USERPROFILE 'Downloads\Projects'
if ($BaseDir.TrimEnd('\') -ne $defaultBase.TrimEnd('\')) {
    [Environment]::SetEnvironmentVariable('TERMINAL_PROJECTS', $BaseDir, 'User')
    Write-Host "[ok]   TERMINAL_PROJECTS = $BaseDir (variable de usuario)" -ForegroundColor Green
}

# --- Restaurar configuracion ---
$restore = Join-Path $repo 'restore.ps1'
if (Test-Path $restore) {
    Write-Host '[..]   Restaurando configuracion (restore.ps1)' -ForegroundColor Cyan
    & $restore -ProjectsDir $BaseDir
}

# --- Ajustar la ruta del perfil de Windows Terminal si BaseDir es distinto ---
if ($BaseDir.TrimEnd('\') -ne $defaultBase.TrimEnd('\')) {
    $wtSettings = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    if ($wtSettings) {
        $content = Get-Content -LiteralPath $wtSettings -Raw
        # En el JSON las barras invertidas estan escapadas (\\), por eso se
        # reemplaza la version escapada y se escapa la ruta nueva.
        $oldWtBase = '%USERPROFILE%\\Downloads\\Projects'
        $newWtBase = $BaseDir.TrimEnd('\').Replace('/', '\').Replace('\', '\\')
        if ($content.Contains($oldWtBase)) {
            $content = $content.Replace($oldWtBase, $newWtBase)
            Set-Content -LiteralPath $wtSettings -Value $content -NoNewline -Encoding UTF8
            Write-Host '[ok]   Ruta de PowerShell ajustada en Windows Terminal' -ForegroundColor Green
        }
    }
}

Write-Host ''
Write-Host 'Terminado.' -ForegroundColor Cyan
Write-Host '1) Abre una terminal NUEVA.' -ForegroundColor Yellow
Write-Host '2) Reinicia Windows Terminal (para el acrilico de la barra de pestanas).' -ForegroundColor Yellow
Write-Host "3) El perfil resuelve las rutas desde TERMINAL_PROJECTS; si usaste -BaseDir, define esa variable o edita tu .local.ps1." -ForegroundColor Yellow
