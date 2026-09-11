# TerminalSetup

Copia literal de mi configuración de **PowerShell / Windows Terminal** para
replicarla en otra PC o restaurarla tras formatear.

## Contenido

```
windows-terminal/settings.json              -> Windows Terminal (perfiles, tema Catppuccin Mocha, acrílico)
powershell/Microsoft.PowerShell_profile.ps1 -> $PROFILE (perfil real: tema, fastfetch, codex, postgres, dotnet)
powershell/Microsoft.PowerShell_profile.ps1.stub -> stub que redirige $PROFILE a la carpeta Tools (opcional)
oh-my-posh/tokyo.omp.json                   -> tema actual del prompt
oh-my-posh/liquid-glass.omp.json            -> tema alternativo
fastfetch/glass.jsonc                       -> config de fastfetch (logo + módulos)
fastfetch/logo.txt                          -> logo ASCII custom (bandera Windows)
restore.ps1                                 -> copia todo a las rutas correctas
```

## Requisitos previos

- **PowerShell 7** (portable o instalado).
- **Nerd Font** `CaskaydiaCove Nerd Font` (iconos del prompt/fastfetch).
- `oh-my-posh`, `fastfetch` disponibles en el PATH.
- `git` (opcional, solo para clonar este repo).

## Dónde va cada archivo (esta máquina)

| Archivo del repo | Destino |
|---|---|
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` (`...\Documentos\PowerShell\Microsoft.PowerShell_profile.ps1`) |
| `oh-my-posh/*.omp.json` | `C:\Users\<usuario>\Downloads\Projects\ThemesPosh\` |
| `fastfetch/glass.jsonc` y `logo.txt` | `C:\Users\<usuario>\.config\fastfetch\` |

## Restauración rápida

```powershell
# 1. Clona (o copia) este repo y entra a la carpeta
git clone https://github.com/<usuario>/<repo>.git
cd TerminalSetup

# 2. Ejecuta el restaurador (hace backup de lo existente)
pwsh -File .\restore.ps1
```

## Notas importantes

- El perfil `Microsoft.PowerShell_profile.ps1` usa **rutas absolutas**
  (`C:\Users\gary.abrigo\Downloads\Projects\...`) para codex, postgres, dotnet
  y los temas. En otra PC/usuario hay que ajustarlas o mantener la misma
  estructura de carpetas `Downloads\Projects`.
- El tema del prompt actual es **tokyo.omp.json**; `liquid-glass.omp.json` es
  una alternativa guardada.
- Windows Terminal: la transparencia "liquid glass" depende de
  `useAcrylic: true`, `opacity` (~48), `useAcrylicInTabRow: true` y de que en
  Windows → Personalización → Colores → **Efectos de transparencia** esté
  **Activado**. `useAcrylicInTabRow` requiere reiniciar Windows Terminal.
- El formato del fastfetch usa `"logo": { "type": "small" }` (el pequeño).
