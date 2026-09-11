# restore.ps1 - restaura la configuracion de terminal en esta PC
# Uso:  pwsh -File .\restore.ps1
# Hace backup (con timestamp) de los archivos existentes antes de sobrescribir.

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$user = $env:USERPROFILE

function Copy-WithBackup($src, $dst) {
    $dir = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path -LiteralPath $dst) { Copy-Item -LiteralPath $dst -Destination "$dst.$stamp.bak" -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Force
    Write-Host "OK  $dst" -ForegroundColor Green
}

# --- Windows Terminal ---
$wtDst = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-WithBackup "$repo\windows-terminal\settings.json" $wtDst

# --- Perfil de PowerShell ---
Copy-WithBackup "$repo\powershell\Microsoft.PowerShell_profile.ps1" $PROFILE

# --- Oh My Posh (temas) ---
$themesDst = "$user\Downloads\Projects\ThemesPosh"
Copy-WithBackup "$repo\oh-my-posh\tokyo.omp.json"        "$themesDst\tokyo.omp.json"
Copy-WithBackup "$repo\oh-my-posh\liquid-glass.omp.json" "$themesDst\liquid-glass.omp.json"

# --- fastfetch ---
$ffDst = "$user\.config\fastfetch"
Copy-WithBackup "$repo\fastfetch\glass.jsonc" "$ffDst\glass.jsonc"
Copy-WithBackup "$repo\fastfetch\logo.txt"    "$ffDst\logo.txt"

Write-Host ""
Write-Host "Listo. Abre una terminal NUEVA (y reinicia Windows Terminal para el acrilico de la barra)." -ForegroundColor Cyan
Write-Host "Revisa que las rutas absolutas del perfil apunten a tus carpetas (codex, postgres, dotnet)." -ForegroundColor Yellow
