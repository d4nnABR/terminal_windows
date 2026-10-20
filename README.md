# TerminalSetup

Configuración **portable** de PowerShell 7 y Windows Terminal para replicarla
en otra PC o restaurarla después de formatear.

No contiene rutas absolutas ni nombres de usuario: todas las rutas se resuelven
en tiempo de ejecución con variables de entorno y valores por defecto.

## Contenido

```
windows-terminal/settings.json                    -> Windows Terminal (perfiles, Catppuccin Mocha, acrílico)
powershell/Microsoft.PowerShell_profile.ps1       -> $PROFILE (tema, fastfetch, postgres, dotnet)
powershell/Microsoft.PowerShell_profile.ps1.stub  -> stub opcional que redirige $PROFILE a Tools
powershell/...local.example.ps1                   -> ejemplo de personalización NO versionada
oh-my-posh/tokyo.omp.json                         -> tema actual del prompt
oh-my-posh/liquid-glass.omp.json                  -> tema alternativo
fastfetch/glass.jsonc                             -> config de fastfetch (logo + módulos)
fastfetch/logo.txt                                -> logo ASCII custom (bandera Windows)
restore.ps1                                       -> copia todo a las rutas correctas (con backup)
bootstrap.ps1                                     -> instala dependencias portables (sin admin) + restore
```

## Requisitos

- **PowerShell 7** (portable o instalado). `bootstrap.ps1` puede instalarlo.
- **Nerd Font** `CaskaydiaCove Nerd Font` (iconos del prompt/fastfetch).
- `oh-my-posh` y `fastfetch` en el `PATH` (bootstrap los instala).
- `git` (opcional, solo para clonar el repo).

## Inicio rápido

```powershell
git clone https://github.com/d4nnABR/terminal_windows.git
cd terminal_windows

# Todo automático: instala dependencias portables + restaura la config
pwsh -File .\bootstrap.ps1

# O solo restaurar, si ya tienes las dependencias
pwsh -File .\restore.ps1
```

Opciones de `bootstrap.ps1`:

| Opción | Efecto |
|---|---|
| `-Yes` | No hace preguntas |
| `-SkipFont` | No instala la Nerd Font |
| `-SkipPwsh` | No instala PowerShell portable |
| `-SkipModules` | No instala `Terminal-Icons` ni `posh-git` |
| `-BaseDir <ruta>` | Cambia la raíz de proyectos (por defecto `%USERPROFILE%\Downloads\Projects`) |

`bootstrap.ps1` descarga solo de releases oficiales de GitHub y no requiere
permisos de administrador. Instala en `<BaseDir>\Tools`:

- PowerShell 7 portable
- `oh-my-posh`
- `fastfetch`
- Nerd Font CaskaydiaCove en las fuentes del usuario

## Dónde va cada archivo

| Archivo del repo | Destino |
|---|---|
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` (también detecta Preview y la versión sin paquete) |
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` (normalmente `...\Documentos\PowerShell\Microsoft.PowerShell_profile.ps1`) |
| `oh-my-posh/*.omp.json` | `<ProjectsDir>\ThemesPosh\` |
| `fastfetch/glass.jsonc` y `logo.txt` | `%USERPROFILE%\.config\fastfetch\` |

`restore.ps1` hace un backup con timestamp (`archivo.20250101-120000.bak`) antes
de sobrescribir. Usa `-NoBackup` si no lo quieres.

## Configuración sin editar archivos

Windows Terminal expande variables de entorno, por eso `settings.json` usa
`%USERPROFILE%` en el perfil de PowerShell. El perfil de PowerShell usa estas
variables:

| Variable | Valor por defecto | Uso |
|---|---|---|
| `TERMINAL_PROJECTS` | `%USERPROFILE%\Downloads\Projects` | Raíz de `PortableGit`, `Tools`, `postgres`, etc. |
| `TERMINAL_THEMES` | `<TERMINAL_PROJECTS>\ThemesPosh` | Carpeta de temas de oh-my-posh |
| `TERMINAL_PROFILE` | `<TERMINAL_PROJECTS>\Tools\pwsh\profile\...` | Solo para el stub del perfil |

Ejemplo si tus proyectos viven en `D:\Projects`:

```powershell
# Opción 1: variable de usuario (permanente)
[Environment]::SetEnvironmentVariable('TERMINAL_PROJECTS', 'D:\Projects', 'User')

# Opción 2: solo esta sesión
$env:TERMINAL_PROJECTS = 'D:\Projects'
```

Después de cambiar la variable, abre una terminal nueva.

## Personalización local (no se publica)

Copia el ejemplo y pon ahí tus rutas, funciones o alias:

```powershell
Copy-Item .\powershell\Microsoft.PowerShell_profile.local.example.ps1 `
          "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.local.ps1"
```

El perfil carga automáticamente `Microsoft.PowerShell_profile.local.ps1` si
existe. Ese archivo está en `.gitignore`.

## Notas

- El perfil no falla si la ruta de algún componente no existe: no rompe la
  terminal si falta Postgres, .NET o Codex.
- Los temas se buscan primero en `TERMINAL_THEMES` y, si no están, en
  `oh-my-posh/` dentro del repo.
- La transparencia "liquid glass" depende de `useAcrylic`, `opacity` (~48),
  `useAcrylicInTabRow` y de que en Windows → Personalización → Colores →
  **Efectos de transparencia** esté activado. `useAcrylicInTabRow` requiere
  reiniciar Windows Terminal.
- fastfetch usa `"logo": { "type": "small" }` (logo pequeño).
- El tema actual del prompt es `tokyo.omp.json`; `liquid-glass.omp.json` es una
  alternativa guardada.

## Solución de problemas

**Windows Terminal no abre el perfil "PowerShell (Tools)"**
La ruta del ejecutable se resuelve con `%USERPROFILE%\Downloads\Projects\Tools\pwsh\pwsh.exe`.
Si instalaste PowerShell en otro lugar, edita `windows-terminal/settings.json`
o ejecuta `bootstrap.ps1` con `-BaseDir` y ajusta esa ruta.

**El prompt no carga**
Verifica que `oh-my-posh` esté en el `PATH`:

```powershell
Get-Command oh-my-posh
Get-Command fastfetch
```

**Postgres no arranca**
El perfil solo define `pg-start`, `pg-stop` y `pg-status` si existe
`<TERMINAL_PROJECTS>\postgres\pgsql\bin\pg_ctl.exe`. Ajusta `TERMINAL_PROJECTS`
o revisa la estructura de carpetas.

## Privacidad

Este repo es público: no agregues tokens, contraseñas ni rutas con tu nombre de
usuario. Usa el archivo `.local.ps1` para lo específico de tu máquina.
