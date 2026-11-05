#!/usr/bin/env bash
# ==========================================================
# KEVINTECH / KENOX - INSTALADOR PRINCIPAL
# UI Premium + AutoStart + Core + validación de licencia por API
# Ubuntu / Debian
# ==========================================================

set -Eeuo pipefail

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_ORANGE='\033[38;5;214m'
C_NC='\033[0m'

log()  { echo -e "${C_GREEN}[OK]${C_NC} $*"; }
warn() { echo -e "${C_ORANGE}[!]${C_NC} $*"; }
die()  { echo -e "${C_RED}[ERROR]${C_NC} $*" >&2; exit 1; }

[[ "${EUID}" -eq 0 ]] || die "Ejecuta como root: sudo bash install.sh"
command -v apt-get >/dev/null 2>&1 || die "Este instalador requiere Ubuntu o Debian."

export DEBIAN_FRONTEND=noninteractive

# -------- CONFIGURACIÓN --------
BOT_API="https://api.kevintechtutorials.site/"
REPO_URL="https://raw.githubusercontent.com/kevinaldaircama/kenox/main"
INSTALL_DIR="/etc/vps-manager"
CORE_DIR="${INSTALL_DIR}/core"
MENU_PATH="/usr/local/bin/menu"

clear || true
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_ORANGE}       KEVINTECH - KEY DE INSTALACIÓN           ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -r -p "🔑 Ingresa tu KEY: " USER_KEY
[[ -n "${USER_KEY//[[:space:]]/}" ]] || die "No ingresaste una key."

# IP pública IPv4 del servidor
VPS_IP="$(curl -4fsS --connect-timeout 8 --max-time 15 https://ipv4.icanhazip.com | tr -d '[:space:]')" \
  || die "No se pudo detectar la IP pública."
[[ -n "$VPS_IP" ]] || die "La IP pública llegó vacía."

echo
echo "Validando la key con la API: ${BOT_API}"

# Se envían parámetros URL-encoded y se comprueba HTTP + respuesta.
# Respuestas aceptadas:
#   {"status":"valid"}  o  {"valid":true}
# Respuestas como {"status":"invalid"} o {"valid":false} se rechazan.
API_RESPONSE="$(curl -4fsS --connect-timeout 8 --max-time 20 \
  --get "$BOT_API" \
  --data-urlencode "key=${USER_KEY}" \
  --data-urlencode "ip=${VPS_IP}")" \
  || die "La API no respondió correctamente. Verifica DNS, SSL y que el servicio API esté activo."

if printf '%s' "$API_RESPONSE" | grep -Eiq '"status"[[:space:]]*:[[:space:]]*"valid"|"valid"[[:space:]]*:[[:space:]]*true'; then
    log "Key aceptada. Continuando con la instalación."
else
    echo -e "${C_RED}Respuesta de la API:${C_NC} ${API_RESPONSE:0:500}"
    die "KEY inválida, vencida, usada o no autorizada para esta IP."
fi

# -------- INFORMACIÓN DEL SISTEMA --------
os_name="$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-Linux}")"
cpu_info="$(awk -F': ' '/vendor_id/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
ip_addr="$VPS_IP"
arch="$(uname -m)"

clear || true
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "             PREPARANDO INSTALACIÓN"
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e " ${C_RED}SISTEMA:${C_NC} ${os_name}"
echo -e " ${C_RED}CPU:${C_NC} ${cpu_info:-No detectada}"
echo -e " ${C_RED}IP:${C_NC} ${ip_addr}"
echo -e " ${C_RED}ARQUITECTURA:${C_NC} ${arch}"
echo -e "${C_ORANGE}======================================================${C_NC}"

# -------- DEPENDENCIAS --------
apt-get update
PACKAGES=(
  ca-certificates curl wget sudo cron screen nginx nload htop
  python3 python3-pip nodejs npm lsof psmisc socat bc
  netcat-openbsd net-tools dos2unix
)
apt-get install -y "${PACKAGES[@]}"
log "Dependencias instaladas."

# -------- NGINX --------
systemctl unmask nginx >/dev/null 2>&1 || true
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
systemctl enable nginx
systemctl restart nginx
log "Nginx habilitado y reiniciado."

# -------- DESCARGA DE ARCHIVOS --------
mkdir -p "$CORE_DIR"

download_file() {
  local remote="$1"
  local destination="$2"
  local tmp="${destination}.tmp"
  if ! curl -fLsS --retry 3 --retry-delay 2 --connect-timeout 10 \
      "${REPO_URL}/${remote}" -o "$tmp"; then
    rm -f "$tmp"
    die "No se pudo descargar ${remote} desde GitHub."
  fi
  [[ -s "$tmp" ]] || { rm -f "$tmp"; die "El archivo ${remote} llegó vacío."; }
  mv "$tmp" "$destination"
}

echo
echo -e "${C_GREEN}Descargando menú y módulos desde GitHub...${C_NC}"

download_file "menu.sh" "$MENU_PATH"
download_file "languages.sh" "${INSTALL_DIR}/languages.sh"
download_file "version" "${INSTALL_DIR}/version"

CORE_FILES=(
  "BHTTP.py" "Bbr.sh" "Slowdns.sh" "edit_ovpn_user.sh" "badvpn.sh"
  "banner.sh" "bhttp.sh" "bot.sh" "checkuser.sh" "domain.sh"
  "firewall.sh" "fix_ports.sh" "hcr-server" "hcr.sh" "hysteria.sh"
  "limiter.sh" "master.py" "php.sh" "ports.sh" "proxy.py"
  "setup_dns.sh" "setup_hysteria.sh" "setup_openvpn.sh" "setup_zivpn.sh"
  "specs.sh" "ssh.sh" "sshws.sh" "ssl.sh" "trojan.sh"
  "udp_custom.sh" "update.sh" "user.sh" "vless.sh" "vmess.sh"
  "webpanel.sh" "websocket.sh" "xray_manager.sh" "zivpn.sh"
)

for file in "${CORE_FILES[@]}"; do
  download_file "core/${file}" "${CORE_DIR}/${file}"
done

chmod +x "$MENU_PATH"
find "$CORE_DIR" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
dos2unix "$MENU_PATH" "${INSTALL_DIR}/languages.sh" "${CORE_DIR}"/*.sh >/dev/null 2>&1 || true

log "Menú y módulos descargados correctamente."

# -------- AUTOINICIO DEL MENÚ --------
BASHRC="/root/.bashrc"
if ! grep -Fq '[[ -x /usr/local/bin/menu ]] && /usr/local/bin/menu' "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" <<'EOF'

# KEVINTECH MENU - iniciar menú al entrar en una sesión interactiva
if [[ $- == *i* ]] && [[ -x /usr/local/bin/menu ]] && [[ -z "${TMUX:-}" ]]; then
  /usr/local/bin/menu
fi
EOF
fi

echo
log "INSTALACIÓN BASE COMPLETADA."
warn "No se reinició el VPS automáticamente. Reinicia manualmente cuando hayas comprobado que todo funciona: reboot"
echo "Para abrir el menú ahora ejecuta: menu"
