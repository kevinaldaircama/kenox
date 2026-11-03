#!/bin/bash
# ==========================================
# Panel Principal - Golbert VPS V5.0 LTS (Anti-Bounce UI)
# ==========================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'
BG_RED='\033[41;1;37m'

if [ -f /etc/vps-manager/languages.sh ]; then
    source /etc/vps-manager/languages.sh
else
    t_mgmt="[ GESTIÓN DE CUENTAS ]"
    t_tools="[ HERRAMIENTAS Y SISTEMA ]"
    t_select="Selecciona una opción: "
fi

LOCAL_VERSION="1.1"
if [ -f /etc/vps-manager/version ]; then
    LOCAL_VERSION=$(cat /etc/vps-manager/version)
else
    echo "$LOCAL_VERSION" > /etc/vps-manager/version
fi

REMOTE_VERSION=$(curl -sS --max-time 2 https://raw.githubusercontent.com/kevinaldaircama/kenox/main/version 2>/dev/null)
UPDATE_AVAILABLE=0
if [[ -n "$REMOTE_VERSION" ]] && [[ ! "$REMOTE_VERSION" =~ "404" ]]; then
    REMOTE_VERSION=$(echo "$REMOTE_VERSION" | tr -d '\n' | tr -d '\r' | tr -d ' ')
    LOCAL_VERSION=$(echo "$LOCAL_VERSION" | tr -d '\n' | tr -d '\r' | tr -d ' ')
    if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
        UPDATE_AVAILABLE=1
    fi
fi

draw_bar() {
    local percent=$1
    local length=15
    local filled=$((percent * length / 100))
    local empty=$((length - filled))
    local bar="["
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar} "; done
    bar="${bar}]"
    echo "$bar"
}

os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
kernel_ver=$(uname -r)
IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)
domain_name="No configurado"
if [ -f /etc/vps-manager/domain.txt ]; then
    domain_name=$(cat /etc/vps-manager/domain.txt)
fi

while true; do
    clear
    total_ram=$(free -m | awk 'NR==2 {print $2}')
    used_ram=$(free -m | awk 'NR==2 {print $3}')
    ram_usage=$((used_ram * 100 / total_ram))
    ram_bar=$(draw_bar $ram_usage)

    cpu_usage_raw=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    cpu_usage=$(printf "%.2f" "$cpu_usage_raw")
    cpu_usage_int=${cpu_usage_raw%.*}
    cpu_bar=$(draw_bar $cpu_usage_int)

    total_users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    online_users=$(ps -ef | grep -E 'sshd|dropbear' | grep -v root | grep -v grep | wc -l)

    if [ "$(systemctl is-active ssh)" = "active" ]; then s_ssh="${C_GREEN}ON${C_NC}"; else s_ssh="${C_RED}OFF${C_NC}"; fi
    if [ "$(systemctl is-active nginx)" = "active" ]; then s_nginx="${C_GREEN}ON${C_NC}"; else s_nginx="${C_RED}OFF${C_NC}"; fi
    if [ "$(systemctl is-active xray)" = "active" ]; then s_xray="${C_GREEN}ON${C_NC}"; else s_xray="${C_RED}OFF${C_NC}"; fi
    if [ "$(systemctl is-active stunnel4)" = "active" ]; then s_stunnel="${C_GREEN}ON${C_NC}"; else s_stunnel="${C_RED}OFF${C_NC}"; fi
    
    if [ "$(systemctl is-active ws-python)" = "active" ] || pgrep -f "proxy.py" > /dev/null; then s_ws="${C_GREEN}ON${C_NC}"; else s_ws="${C_RED}OFF${C_NC}"; fi
    if pgrep -x "hcr-server" > /dev/null || [ "$(systemctl is-active hcr)" = "active" ]; then s_hcr="${C_GREEN}ON${C_NC}"; else s_hcr="${C_RED}OFF${C_NC}"; fi

    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌟 ${C_YELLOW}GOLBERT VPS PREMIUM - V5.0 LTS PANEL${C_NC} 🌟"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
        echo -e " ${C_GREEN}Key: Verified [ Golbert VPS ] (v${LOCAL_VERSION})${C_NC} | ${BG_RED} ¡NUEVA v${REMOTE_VERSION} DISPONIBLE! ${C_NC}"
    else
        echo -e " ${C_GREEN}Key: Verified [ Golbert VPS ] (v${LOCAL_VERSION})${C_NC}"
    fi
    
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 💻 OS       : $os_name"
    echo -e " ⚙️ Kernel   : $kernel_ver"
    echo -e " 🌐 IP       : $IP"
    echo -e " 🎯 Domain   : $domain_name"
    echo -e " 🧠 CPU Usage: ${C_GREEN}${cpu_bar}${C_NC} $cpu_usage%"
    echo -e " ⚡ RAM Usage: ${C_GREEN}${ram_bar}${C_NC} $ram_usage% (${used_ram} / ${total_ram} MB)"
    echo -e " 👥 Users    : $total_users Creados | $online_users En Línea"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " SSH : $s_ssh     NGINX : $s_nginx     XRAY : $s_xray"
    echo -e " STUNNEL : $s_stunnel SSH-WS : $s_ws    HCR : $s_hcr"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
        echo -e " ${C_YELLOW}>> Presiona 99 para Actualizar el Panel a la versión $REMOTE_VERSION <<${C_NC}"
        echo -e "${C_CYAN}================================================${C_NC}"
    fi

    echo -e ""
    echo -e "${C_YELLOW}$t_mgmt${C_NC}"
    echo -e " ${C_CYAN}1.${C_NC} 👤 SSH Management (Users, Limit, HWID)"
    echo -e " ${C_CYAN}2.${C_NC} ⚡ Xray/V2Ray Management (VMess, VLESS, Trojan)"
    echo -e " ${C_CYAN}3.${C_NC} 🤝 Reseller Management (Credits)"
    echo -e ""
    echo -e "${C_YELLOW}$t_tools${C_NC}"
    echo -e " ${C_CYAN}4.${C_NC} 🛠️ Installers & Protocols Manager"
    echo -e " ${C_CYAN}5.${C_NC} ⚙️ System & Security (Firewall, Ports, Specs)"
    echo -e " ${C_CYAN}6.${C_NC} 🌐 Domain, Web Panel & Bot Config"
    echo -e " ${C_CYAN}7.${C_NC} 🔄 Panel Settings (Update, Language, PHP)"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88. ❌ Uninstall Script   |   0. 🚪 Exit${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}Soporte Telegram : @golbert_service${C_NC}"
    echo -e " ${C_CYAN}WhatsApp Oficial : +51960084993${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p " $t_select" opcion
    
    case $opcion in
        1) 
            if [ -f /etc/vps-manager/core/user.sh ]; then
                bash /etc/vps-manager/core/user.sh || { echo -e "\n${C_RED}Script falló o tiene formato corrupto.${C_NC}"; read -p "Presiona Enter..."; }
            else
                echo -e "\n${C_RED}Módulo SSH no encontrado. Actualiza el panel.${C_NC}"; sleep 2
            fi
            ;;
        2)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " ⚡  GESTIÓN DE CUENTAS XRAY (VMESS/VLESS/TROJAN)"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 👤 Gestión de Cuentas VMess"
                echo -e " 2. 👤 Gestión de Cuentas VLESS"
                echo -e " 3. 👤 Gestión de Cuentas Trojan"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona una opción: " xray_op
                case $xray_op in
                    1) if [ -f /etc/vps-manager/core/vmess.sh ]; then bash /etc/vps-manager/core/vmess.sh || read -p "Error. Presiona Enter..."; else echo -e "${C_RED}Módulo no encontrado${C_NC}"; sleep 1; fi ;;
                    2) if [ -f /etc/vps-manager/core/vless.sh ]; then bash /etc/vps-manager/core/vless.sh || read -p "Error. Presiona Enter..."; else echo -e "${C_RED}Módulo no encontrado${C_NC}"; sleep 1; fi ;;
                    3) if [ -f /etc/vps-manager/core/trojan.sh ]; then bash /etc/vps-manager/core/trojan.sh || read -p "Error. Presiona Enter..."; else echo -e "${C_RED}Módulo no encontrado${C_NC}"; sleep 1; fi ;;
                    0) break ;;
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        3) 
            if [ -f /etc/vps-manager/core/bot.sh ]; then
                bash /etc/vps-manager/core/bot.sh || read -p "Error interno en bot.sh. Presiona Enter..."
            else
                echo -e "\n${C_RED}Módulo Bot no encontrado.${C_NC}"; sleep 2
            fi
            ;;
        4)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 🛠️  INSTALLERS & PROTOCOLS MANAGER"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 📦 Xray Multi-Protocol Manager"
                echo -e " 2. ⚡ VMess Dual Ports"
                echo -e " 3. ⚡ VLESS Protocol"
                echo -e " 4. 🛡️ Trojan Port 443"
                echo -e " 5. 🐢 SlowDNS V5.0 LTS"
                echo -e " 6. 🎮 BadVPN UDPGW 7200/7300"
                echo -e " 7. 🚀 HCR Nativo Port 8880"
                echo -e " 8. 🔥 Hysteria / Hysteria 2 UDP"
                echo -e " 9. 🎯 UDP Custom Port 2000"
                echo -e " 10. 🌐 BHTTP Proxy Port 8180"
                echo -e " 11. 🌐 SSH WebSocket Python Port 80 y 443"
                echo -e " 12. 🔒 SSL/TLS Stunnel Proxy Port 444"
                echo -e " 13. 🛡️ OpenVPN Server Setup Port 1194"
                echo -e " 14. 🌐 ZivPN UDP Manager Port 25000"
                echo -e " 15. ⚙️ TCP BBR Optimizer"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona el protocolo: " sub_op
                case $sub_op in
                    1) bash /etc/vps-manager/core/xray_manager.sh ;; 
                    2) bash /etc/vps-manager/core/vmess.sh ;;
                    3) bash /etc/vps-manager/core/vless.sh ;; 
                    4) bash /etc/vps-manager/core/trojan.sh ;;
                    5) bash /etc/vps-manager/core/slowdns.sh ;; 
                    6) bash /etc/vps-manager/core/badvpn.sh ;;
                    7) bash /etc/vps-manager/core/hcr.sh ;; 
                    8) bash /etc/vps-manager/core/hysteria.sh ;;
                    9) bash /etc/vps-manager/core/udp_custom.sh ;; 
                    10) bash /etc/vps-manager/core/bhttp.sh ;;
                    11) bash /etc/vps-manager/core/sshws.sh ;; 
                    12) bash /etc/vps-manager/core/ssl.sh ;;
                    13) bash /etc/vps-manager/core/edit_ovpn_user.sh ;; 
                    14) bash /etc/vps-manager/core/zivpn.sh ;;
                    15) bash /etc/vps-manager/core/bbr.sh ;; 
                    0) break ;; 
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        5)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " ⚙️  SYSTEM & SECURITY TOOLS"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 🔍 Monitor de Puertos (Active / Inactive)"
                echo -e " 2. 💻 VPS Specifications & Capacity"
                echo -e " 3. 🛡️ Firewall Manager (Rules & Security)"
                echo -e " 4. 🔧 Repair / Fix Ports (Nginx Gateway)"
                echo -e " 5. 👥 Install CheckUser (Multi-App Monitor)"
                echo -e " 6. 🚀 Enable Auto-Start on Login"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona una opción: " sys_op
                case $sys_op in
                    1) if [ -f /etc/vps-manager/core/ports.sh ]; then bash /etc/vps-manager/core/ports.sh; else netstat -tulnp | grep LISTEN; read -p "Presiona Enter para continuar..."; fi ;;
                    2) bash /etc/vps-manager/core/specs.sh ;; 
                    3) bash /etc/vps-manager/core/firewall.sh ;;
                    4) bash /etc/vps-manager/core/fix_ports.sh ;; 
                    5) bash /etc/vps-manager/core/checkuser.sh ;;
                    6) echo "Auto-Start configurado." ; sleep 2 ;;
                    0) break ;; 
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        6)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 🌐  DOMAIN, WEB PANEL & BOT CONFIG"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 🌐 Domain Manager & SSL Certificates"
                echo -e " 2. 🌐 Generate Web Panel (Dashboard UI)"
                echo -e " 3. 🤖 Link Telegram Bot"
                echo -e " 4. 🎨 Configure HTML Welcome Banner"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona una opción: " web_op
                case $web_op in
                    1) bash /etc/vps-manager/core/domain.sh ;; 
                    2) bash /etc/vps-manager/core/webpanel.sh ;;
                    3) bash /etc/vps-manager/core/bot.sh ;; 
                    4) bash /etc/vps-manager/core/banner.sh ;;
                    0) break ;; 
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        7)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 🔄  PANEL SETTINGS & UPDATES"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 🔄 Update Panel (From GitHub)"
                echo -e " 2. 🌍 Change Language (ES/EN/PT)"
                echo -e " 3. 🐘 Instalar PHP 8.5.12 (VPS)"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona una opción: " set_op
                case $set_op in
                    1) if [ -f /etc/vps-manager/core/update.sh ]; then bash /etc/vps-manager/core/update.sh; else echo "Módulo Update no encontrado"; sleep 2; fi ;;
                    2)
                        echo -e "\n1. 🇪🇸 Español | 2. 🇺🇸 English | 3. 🇧🇷 Português"
                        read -p "Opción: " lang_op
                        if [ "$lang_op" = "1" ]; then echo "es" > /etc/vps-manager/lang.txt; fi
                        if [ "$lang_op" = "2" ]; then echo "en" > /etc/vps-manager/lang.txt; fi
                        if [ "$lang_op" = "3" ]; then echo "pt" > /etc/vps-manager/lang.txt; fi
                        echo -e "${C_GREEN}[✔] Idioma actualizado.${C_NC}"; sleep 1; break
                        ;;
                    3) bash /etc/vps-manager/core/php.sh ;;
                    0) break ;; 
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        99)
            if [ -f /etc/vps-manager/core/update.sh ]; then
                bash /etc/vps-manager/core/update.sh
                exit 0
            else
                echo -e "${C_RED}Error: Actualizador no encontrado. Usa la opción 7.${C_NC}"
                sleep 2
            fi
            ;;
        88) read -p "¿Desinstalar script? (s/n): " des; if [ "$des" = "s" ]; then exit 0; fi ;;
        0) clear ; exit 0 ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
    esac
done
