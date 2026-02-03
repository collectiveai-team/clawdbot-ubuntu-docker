# Clawdbot Ubuntu Docker Setup

Configuracion Docker basada en Ubuntu 24.04 con Node 24 para ejecutar OpenClaw (Clawdbot).

## Caracteristicas

- **Base:** Ubuntu 24.04 LTS
- **Node.js:** Version 24.x (ultima)
- **Instalacion:** OpenClaw, OpenCode (opencode-ai) y ClawdHub via npm global
- **Coding Agents:** Soporte para coding agents via ClawdHub
- **Auto-actualizacion:** Skipped by default for speed (enable in start-clawdbot.sh)
- **Usuario:** Corre como `nodeuser` (no root)

## 🚀 Inicio Rapido

```bash
# 1. Generar token de seguridad
openssl rand -hex 32

# 2. Crear archivo de configuracion
cp .env.example .env

# 3. Editar .env y poner tu OPENCLAW_GATEWAY_TOKEN
vim .env

# 4. Crear directorio de configuracion
mkdir -p config

# 5. Construir e iniciar el contenedor (primera vez)
docker compose up -d --build

# 6. Ver logs
docker compose logs -f clawdbot-ubuntu

# 7. Acceder al dashboard
# http://localhost:18789
```

## 🔑 Configuracion del Proveedor de IA (Primera Vez)

La primera vez que inicies el contenedor, necesitas configurar tu proveedor de IA (Anthropic, OpenAI, etc.). Tienes dos opciones:

### Opcion 1: Configurar desde el container en ejecucion

```bash
# Con el contenedor ya iniciado, ejecuta:
docker exec -it clawdbot-ubuntu openclaw agents add main
```

### Opcion 2: Modo interactivo (recomendado para primera vez)

```bash
# Detener el contenedor si esta corriendo
docker compose down

# Iniciar en modo interactivo (con acceso a TTY)
docker compose run --service-ports clawdbot-ubuntu
```

Este comando te mostrara un menu interactivo (TUI) donde podras:
1. Seleccionar tu proveedor (Anthropic, OpenAI, etc.)
2. Ingresar tu API key
3. Configurar preferencias adicionales

Despues de configurar, puedes detener con `Ctrl+C` y reiniciar normalmente con `docker compose up -d`.

## 📁 Estructura de Directorios

```
clawdbot-ubuntu/
├── docker-compose.yml      # Configuracion principal
├── Dockerfile             # Definicion de la imagen Ubuntu+Node24
├── start-clawdbot.sh      # Script de inicio con auto-actualizacion
├── .env.example          # Template de variables
├── .env                  # Tu configuracion (NO commitear)
├── config/               # Persistencia de OpenClaw
└── README.md            # Este archivo
```

## 🔒 Seguridad

### Medidas Implementadas

- ✅ **Ubuntu 24.04 LTS:** Sistema base actualizado y estable
- ✅ **Node 24:** Version LTS mas reciente
- ✅ **Usuario no-root:** Ejecuta como `nodeuser` (UID 1000)
- ✅ **No new privileges:** Previene escalada de privilegios
- ✅ **Read-only mounts:** Carpetas del sistema montadas como solo-lectura
- ✅ **Resource limits:** Limites de 4GB RAM y 2 CPUs
- ✅ **Health check:** Verificacion automatica de salud del servicio
- ✅ **Auto-actualizacion:** Siempre ejecuta la ultima version

### Niveles de Acceso

1. **Configuracion (RW)** - Persistencia de memoria y configuracion
2. **Workspace (RW)** - Area de trabajo principal: `/home/lio/Projects/clawdbot`
3. **Projects (RW)** - Acceso a todos tus proyectos: `/home/lio/Projects`
4. **Sistema (RO)** - Documentos y Downloads solo lectura

## 📦 Volumentes Montados

### Activos

- `./config:/home/nodeuser/.openclaw` - Configuracion del bot
- `/home/lio/Projects/clawdbot:/home/nodeuser/.openclaw/workspace` - Workspace
- `/home/lio/Projects:/mnt/projects` - Todos tus proyectos
- `${HOME}/Documents:/mnt/documents:ro` - Documentos (solo lectura)
- `${HOME}/Downloads:/mnt/downloads:ro` - Descargas (solo lectura)

### Opcionales (Comentados)

- `${HOME}/dev:/mnt/dev:rw` - Proyectos de desarrollo
- `${HOME}/repos:/mnt/repos:ro` - Repositorios Git
- `${HOME}/Clawdbot_Output:/mnt/output:rw` - Archivos generados
- `/var/run/docker.sock:/var/run/docker.sock:ro` - Docker socket
- `${HOME}/.ssh:/home/nodeuser/.ssh:ro` - SSH keys
- `${HOME}/.gitconfig:/home/nodeuser/.gitconfig:ro` - Git config
- `${HOME}/.npmrc:/home/nodeuser/.npmrc:ro` - NPM config

## 🖥️ TUI Client (Terminal User Interface)

The TUI client runs **outside** the container and connects to the containerized gateway.

### Setup TUI

```bash
# Add to your ~/.bashrc or ~/.zshrc:
export PATH="$HOME/bin:$PATH"

# Reload shell configuration:
source ~/.bashrc  # or source ~/.zshrc
```

### Using the TUI

```bash
# Launch TUI (connects to localhost:18789)
clawdbot-tui

# The TUI will automatically:
# - Check if the gateway is running
# - Load the token from .env file
# - Connect to the containerized gateway
```

### TUI Features

- **Interactive chat** with your AI agent
- **Session management** (create, switch, list sessions)
- **Tool execution** (file operations, shell commands)
- **Real-time streaming** responses
- **Command history** and auto-completion
- **Multi-agent support**

## 🤖 OpenCode & ClawdHub Setup

El contenedor incluye **OpenCode** y **ClawdHub** preinstalados para capacidades avanzadas de coding agents.

### Configurar Coding Agent

1. **Accede al contenedor como nodeuser:**

```bash
docker exec --user nodeuser -it clawdbot-ubuntu bash
```

2. **Desde el workspace (`/home/nodeuser/.openclaw/workspace`), ejecuta:**

```bash
cd /home/nodeuser/.openclaw/workspace
clawdhub install coding-agent
```

Esto instalará y configurará el coding agent en tu workspace.

### Verificar Instalación

```bash
# Ver versión de OpenCode
docker exec --user nodeuser clawdbot-ubuntu opencode --version

# Ver versión de ClawdHub
docker exec --user nodeuser clawdbot-ubuntu clawdhub --version

# Listar agents instalados
docker exec --user nodeuser clawdbot-ubuntu clawdhub list
```

### Uso de OpenCode

```bash
# Iniciar OpenCode en modo interactivo
docker exec --user nodeuser -it clawdbot-ubuntu opencode

# O desde dentro del contenedor
docker exec --user nodeuser -it clawdbot-ubuntu bash
cd /home/nodeuser/.openclaw/workspace
opencode
```

## 🔧 Comandos Utiles

### Gestion del Servicio

```bash
# Construir e iniciar (primera vez)
docker-compose up -d --build

# Solo iniciar (si ya esta construido)
docker-compose up -d

# Detener
docker-compose down

# Reiniciar
docker-compose restart

# Ver logs en tiempo real
docker-compose logs -f clawdbot-ubuntu

# Ver estado
docker-compose ps
```

### Acceder al Contenedor

> ⚠️ **IMPORTANTE:** El gateway corre como `nodeuser`. Para que los cambios de configuración
> surtan efecto, siempre usa `--user nodeuser` al ejecutar comandos `docker exec`.
> Si ejecutas como root (por defecto), la configuración se guarda en `/root/.openclaw/`
> en lugar de `/home/nodeuser/.openclaw/` y el gateway no la verá.

```bash
# Shell interactivo (como nodeuser - RECOMENDADO)
docker exec --user nodeuser -it clawdbot-ubuntu bash

# Ejecutar comandos openclaw (como nodeuser)
docker exec --user nodeuser clawdbot-ubuntu openclaw <comando>

# Ejemplos:
docker exec --user nodeuser clawdbot-ubuntu openclaw models status
docker exec --user nodeuser clawdbot-ubuntu openclaw models set openai-codex/gpt-5.2
docker exec --user nodeuser clawdbot-ubuntu openclaw agents list

# Como root (solo para debugging - NO para configuración)
docker exec --user root -it clawdbot-ubuntu bash
```

### Uso del CLI

```bash
# Ejecutar comandos de clawdbot
docker-compose --profile cli run --rm clawdbot-cli <comando>

# Ejemplos:
docker-compose --profile cli run --rm clawdbot-cli onboard
docker-compose --profile cli run --rm clawdbot-cli status
docker-compose --profile cli run --rm clawdbot-cli channels list
```

### Actualizar Manualmente

```bash
# El contenedor ya se actualiza automaticamente al iniciar,
# pero si necesitas forzar una actualizacion:
docker exec --user nodeuser clawdbot-ubuntu npm update -g openclaw
docker restart clawdbot-ubuntu
```

### Configurar Modelo

```bash
# Ver modelo actual y estado de autenticación
docker exec --user nodeuser clawdbot-ubuntu openclaw models status

# Listar modelos disponibles
docker exec --user nodeuser clawdbot-ubuntu openclaw models list

# Cambiar modelo por defecto
docker exec --user nodeuser clawdbot-ubuntu openclaw models set openai-codex/gpt-5.2

# Después de cambiar el modelo, reinicia el gateway:
docker restart clawdbot-ubuntu
```

## 🛠️ Resolucion de Problemas

### Permisos (EACCES)

Si ves errores de permisos:

```bash
# Asegurar propiedad correcta
sudo chown -R 1000:1000 /home/lio/Projects/clawdbot-ubuntu/config
```

### Puerto Ocupado

Si el puerto 18789 esta en uso:

```bash
# Ver que proceso lo usa
sudo lsof -i :18789

# Matar el proceso o cambiar el puerto en .env
```

### Reconstruir la Imagen

```bash
# Limpiar y reconstruir desde cero
docker-compose down
docker rmi clawdbot-ubuntu:local
docker-compose up -d --build
```

### Modelo No Se Aplica (TUI muestra modelo incorrecto)

Si configuraste un modelo pero el TUI sigue mostrando otro:

```bash
# El problema es que docker exec corre como root por defecto,
# guardando la config en /root/.openclaw/ en vez de /home/nodeuser/.openclaw/

# Verificar que modelo ve nodeuser (el correcto):
docker exec --user nodeuser clawdbot-ubuntu openclaw models status

# Si muestra el modelo incorrecto, configurarlo como nodeuser:
docker exec --user nodeuser clawdbot-ubuntu openclaw models set <tu-modelo>

# Reiniciar el gateway para aplicar cambios:
docker restart clawdbot-ubuntu
```

### Ver Version Instalada

```bash
docker exec --user nodeuser clawdbot-ubuntu openclaw --version
docker exec --user nodeuser clawdbot-ubuntu node --version
```

## 📚 Diferencias con el Setup Oficial

| Caracteristica | Setup Oficial | Ubuntu Setup |
|----------------|---------------|--------------|
| **Base** | Node:22-bookworm | Ubuntu 24.04 |
| **Node** | 22.x | 24.x |
| **Instalacion** | Desde source (build) | npm global |
| **Actualizacion** | Manual | Auto (startup) |
| **Tamaño** | ~500MB | ~700MB |
| **Herramientas** | Minimo | Full Ubuntu tools |

## 📖 Documentacion

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)
- [Node.js 24](https://nodejs.org/)
- [Docker Compose](https://docs.docker.com/compose/)

## ⚠️ Notas Importantes

1. **NO** commitees el archivo `.env` - contiene tu token secreto
2. El contenedor se actualiza automaticamente al iniciar (`npm update -g openclaw`)
3. La primera ejecucion puede tardar mas debido a la actualizacion
4. El workspace tiene acceso completo a `/home/lio/Projects`
5. Puertos expuestos: 18789 (API), 18790 (Bridge)

## 🤝 Soporte

Para soporte de OpenClaw:
- GitHub Issues: https://github.com/openclaw/openclaw/issues
- Documentacion: https://docs.openclaw.ai

---
**Version:** 1.0.0  
**Fecha:** 2026-02-02
