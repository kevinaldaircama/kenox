#!/bin/bash
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 INICIANDO ACTUALIZACIÓN DEL PANEL..."
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[1/6] Preparando dependencias de limpieza...${C_NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y dos2unix wget curl > /dev/null 2>&1

REPO_URL="https://raw.githubusercontent.com/kevinaldaircama/kenox/main"
mkdir -p /etc/vps-manager/core

echo -e "\n${C_YELLOW}[2/6] Actualizando archivos base del sistema...${C_NC}"
descargar_base() {
    local url=$1
    local dest=$2
    local nombre=$3
    if wget -qO "$dest" "$url"; then
        echo -e "   ${C_GREEN}[✔]${C_NC} $nombre"
    else
        echo -e "   ${C_RED}[✘]${C_NC} Error al descargar: $nombre"
    fi
}

descargar_base "$REPO_URL/menu.sh" "/usr/local/bin/menu" "Menú Principal"
descargar_base "$REPO_URL/languages.sh" "/etc/vps-manager/languages.sh" "Módulo de Idiomas"
descargar_base "$REPO_URL/version" "/etc/vps-manager/version" "Control de Versión"

echo -e "\n${C_YELLOW}[3/6] Sincronizando módulos Core al detalle...${C_NC}"
CORE_FILES=(
    "BHTTP.py" "bbr.sh" "slowdns.sh" "edit_ovpn_user.sh" "badvpn.sh" 
    "banner.sh" "bhttp.sh" "bot.sh" "checkuser.sh" "domain.sh" 
    "firewall.sh" "fix_ports.sh" "hcr-server" "hcr.sh" "hysteria.sh" 
    "limiter.sh" "master.py" "php.sh" "ports.sh" "proxy.py" 
    "setup_dns.sh" "setup_hysteria.sh" "setup_zivpn.sh" 
    "specs.sh" "ssh.sh" "sshws.sh" "ssl.sh" "trojan.sh" 
    "udp_custom.sh" "update.sh" "user.sh" "vless.sh" "vmess.sh" 
    "webpanel.sh" "websocket.sh" "xray_manager.sh" "zivpn.sh"
)

for file in "${CORE_FILES[@]}"; do
    if wget -qO "/etc/vps-manager/core/$file" "$REPO_URL/core/$file"; then
        echo -e "   ${C_CYAN}➜${C_NC} Actualizado: ${C_GREEN}$file${C_NC}"
    else
        echo -e "   ${C_RED}➜${C_NC} Falla de red: ${C_RED}$file${C_NC}"
    fi
done

echo -e "\n${C_YELLOW}[4/6] Aplicando permisos y limpieza de formato...${C_NC}"
chmod +x /usr/local/bin/menu
chmod +x /etc/vps-manager/core/*.sh
dos2unix /usr/local/bin/menu > /dev/null 2>&1
dos2unix /etc/vps-manager/core/*.sh > /dev/null 2>&1
echo -e "   ${C_GREEN}[✔]${C_NC} Permisos ejecutables y formato corregido."

echo -e "\n${C_YELLOW}[5/6] Instalando Motor de Banner Dinámico (Dropbear)...${C_NC}"
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    # 1. Descargamos el binario a un temporal primero para validar su peso
    wget -qO /tmp/dropbear_mod "$REPO_URL/core/dropbear"
    
    if [ "$(stat -c%s /tmp/dropbear_mod 2>/dev/null || echo 0)" -gt 100000 ]; then
        # Detenemos servicio y aplicamos el nuevo binario
        systemctl stop dropbear >/dev/null 2>&1
        mv /tmp/dropbear_mod /usr/sbin/dropbear
        chmod +x /usr/sbin/dropbear
        
        # 2. Descargamos la configuración exacta para los puertos y el banner
        wget -qO /etc/default/dropbear "$REPO_URL/core/dropbear.conf"
        
        # 3. Reiniciamos el servicio
        systemctl daemon-reload
        systemctl restart dropbear >/dev/null 2>&1
        echo -e "   ${C_GREEN}[✔]${C_NC} Núcleo Dropbear y configuración aplicados desde tu repositorio."
    else
        echo -e "   ${C_RED}[✘]${C_NC} Error al descargar el binario desde tu GitHub. Revisa que el archivo exista."
    fi
else
     echo -e "   ${C_YELLOW}[!]${C_NC} Arquitectura $ARCH. Dropbear dinámico requiere x86_64."
fi

echo -e "\n${C_YELLOW}[6/6] Verificando conflictos de puertos (Nginx)...${C_NC}"
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
systemctl restart nginx > /dev/null 2>&1
echo -e "   ${C_GREEN}[✔]${C_NC} Puertos HTTP liberados exitosamente."

echo -e "\n${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN} ✅ ACTUALIZACIÓN COMPLETADA CON ÉXITO.${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
sleep 2
menu
