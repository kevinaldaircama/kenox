#!/bin/bash
# ==========================================
# Módulo: Instalador SlowDNS (DNSTT Original Público)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
SLOW_DIR="/etc/slowdns"

instalar_slowdns() {
    clear
    echo -e "${C_YELLOW}[1/4] Obteniendo Dominio NS...${C_NC}"
    read -p " Ingresa tu NS Domain (ej. ns1.tudominio.com): " NS_DOMAIN
    [ -z "$NS_DOMAIN" ] && NS_DOMAIN="ns-colo.golbertvps.online"

    echo -e "${C_YELLOW}[2/4] Instalando dependencias (Evitando menús bloqueantes)...${C_NC}"
    
    # ---------------------------------------------------------
    # PARCHE ANTI-CONGELAMIENTO (Responde "SÍ" automáticamente)
    # ---------------------------------------------------------
    export DEBIAN_FRONTEND=noninteractive
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y iptables iptables-persistent dnsutils wget curl >/dev/null 2>&1
    
    systemctl stop slowdns >/dev/null 2>&1
    killall -9 sldns-server >/dev/null 2>&1
    fuser -k -9 53/udp >/dev/null 2>&1

    iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables-save > /etc/iptables/rules.v4 2>/dev/null

    echo -e "${C_YELLOW}[3/4] Descargando motor DNSTT del repositorio público oficial...${C_NC}"
    mkdir -p $SLOW_DIR
    cd $SLOW_DIR
    
    wget -qO server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
    wget -qO server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
    wget -qO sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"
    chmod +x sldns-server server.key server.pub
    
    # Guardamos el dominio en la ruta exacta que tu user.sh lee
    echo "$NS_DOMAIN" > $SLOW_DIR/domain.ns

    echo -e "${C_YELLOW}[4/4] Iniciando Servicio SlowDNS...${C_NC}"
    cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (DNSTT Público)
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$SLOW_DIR
ExecStart=$SLOW_DIR/sldns-server -udp :5300 -privkey-file $SLOW_DIR/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable slowdns >/dev/null 2>&1
    systemctl restart slowdns

    if systemctl is-active --quiet slowdns; then
        PUB=$(cat $SLOW_DIR/server.pub)
        echo -e "\n${C_GREEN}[✔] ¡SlowDNS (DNSTT) instalado exitosamente!${C_NC}"
        echo -e " 🌍 NS Domain : ${C_YELLOW}$NS_DOMAIN${C_NC}"
        echo -e " 🗝️ Pub Key   : ${C_YELLOW}$PUB${C_NC}"
    else
        echo -e "\n${C_RED}[✘] Error al iniciar SlowDNS Server.${C_NC}"
    fi
    read -p "Presione Enter para regresar..."
}

desinstalar_slowdns() {
    clear
    echo -e "${C_YELLOW}[+] Desinstalando SlowDNS...${C_NC}"
    systemctl stop slowdns >/dev/null 2>&1
    systemctl disable slowdns >/dev/null 2>&1
    killall -9 sldns-server >/dev/null 2>&1
    fuser -k -9 53/udp >/dev/null 2>&1
    
    rm -f /etc/systemd/system/slowdns.service
    rm -rf $SLOW_DIR
    
    iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    
    systemctl daemon-reload
    echo -e "\n${C_GREEN}[✔] SlowDNS eliminado exitosamente.${C_NC}"
    read -p "Presione Enter para regresar..."
}

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🐢 GESTIÓN DE SLOWDNS V5.0 (DNSTT PÚBLICO)"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 1. 🟢 Instalar SlowDNS"
echo -e " 2. 🔴 Desinstalar SlowDNS"
echo -e " 0. 🚪 Volver al Menú"
echo -e "${C_CYAN}================================================${C_NC}"
read -p " Opción: " opc

case $opc in
    1) instalar_slowdns ;;
    2) desinstalar_slowdns ;;
    0) exit 0 ;;
    *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 1 ;;
esac
