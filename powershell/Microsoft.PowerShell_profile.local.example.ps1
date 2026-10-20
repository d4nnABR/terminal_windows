# ─── EJEMPLO DE PERSONALIZACION LOCAL ───────────────────
# Copia este archivo como:
#   powershell/Microsoft.PowerShell_profile.local.ps1
#
# El archivo .local.ps1 esta en .gitignore: puedes poner aqui
# rutas, funciones o preferencias propias sin publicarlas.
# ------------------------------------------------------

# Raiz de proyectos alternativa solo para esta maquina.
# $env:TERMINAL_PROJECTS = 'D:\Projects'

# Funcion de ejemplo que no depende del nombre de usuario.
# $fondo = Join-Path $env:USERPROFILE 'Downloads\Projects\Utils Win\Set-FondoCMI.ps1'
# if (Test-Path -LiteralPath $fondo) {
#     function fondo-cmi { & $fondo }
# }

# Alias y preferencias personales.
# Set-Alias ll Get-ChildItem
# Set-PSReadLineOption -EditMode Windows
