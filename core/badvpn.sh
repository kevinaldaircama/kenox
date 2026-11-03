#!/bin/bash
# ==========================================
# Módulo: BadVPN Nativo (Ultra-Robusto para Ubuntu 22-26 y Debian 11-12)
# ==========================================
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    COMPILACIÓN E INSTALACIÓN DE BADVPN         ${C_NC}"
echo -e "       (Soporte Ubuntu 22/24/26 y Debian 11/12) "
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "\n${C_YELLOW}[1/6] Limpiando procesos y archivos de instalaciones previas...${C_NC}"
systemctl stop badvpn-7300 badvpn-7200 >/dev/null 2>&1
systemctl disable badvpn-7300 badvpn-7200 >/dev/null 2>&1
rm -f /etc/systemd/system/badvpn-7300.service
rm -f /etc/systemd/system/badvpn-7200.service
rm -f /usr/local/bin/badvpn-udpgw
rm -f /bin/badvpn-udpgw
rm -rf /tmp/badvpn*
systemctl daemon-reload

echo -e "\n${C_YELLOW}[2/6] Instalando dependencias de compilación universales...${C_NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1
apt-get install -y build-essential cmake make gcc g++ git wget pkg-config >/dev/null 2>&1

echo -e "\n${C_YELLOW}[3/6] Descargando código fuente oficial de BadVPN...${C_NC}"
cd /tmp
git clone https://github.com/ambrop72/badvpn.git
cd badvpn

echo -e "\n${C_YELLOW}[4/6] Aplicando parche de compatibilidad extremo para CMake moderno...${C_NC}"
# Reemplazo forzoso para evitar el error de versión mínima rechazada
sed -i 's/cmake_minimum_required.*/cmake_minimum_required(VERSION 3.5)/g' CMakeLists.txt

echo -e "\n${C_YELLOW}[5/6] Compilando el código fuente (Construyendo binario)...${C_NC}"
sleep 2

mkdir -p build
cd build
# Forzamos la política mínima directamente en el comando como lo pide la terminal de Ubuntu
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make
make install

# Verificación de compilación exitosa
if [ -f "/usr/local/bin/badvpn-udpgw" ]; then
    BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
elif [ -f "/tmp/badvpn/build/udpgw/badvpn-udpgw" ]; then
    cp /tmp/badvpn/build/udpgw/badvpn-udpgw /usr/local/bin/badvpn-udpgw
    BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
else
    echo -e "\n${C_RED}[!] Error Crítico: La compilación falló. Revisa el texto arriba para ver qué faltó.${C_NC}"
    read -p "Presione Enter para salir..."
    exit 1
fi

chmod +x "$BADVPN_BIN"

echo -e "\n${C_YELLOW}[6/6] Configurando e iniciando servicios Systemd (Puertos 7200 y 7300)...${C_NC}"

cat << EOF > /etc/systemd/system/badvpn-7200.service
[Unit]
Description=BadVPN UDPGW Port 7200
After=network.target

[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 50
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/badvpn-7300.service
[Unit]
Description=BadVPN UDPGW Port 7300
After=network.target

[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 50
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl start badvpn-7200 badvpn-7300

sleep 2

# Verificación de estado final en vivo
ESTADO_7200=\$(systemctl is-active badvpn-7200)
ESTADO_7300=\$(systemctl is-active badvpn-7300)

if [ "\$ESTADO_7200" = "active" ] && [ "\$ESTADO_7300" = "active" ]; then
    echo -e "\n${C_CYAN}================================================${C_NC}"
    echo -e "${C_GREEN} [✔] INSTALACIÓN EXITOSA. BADVPN ESTÁ ACTIVO.${C_NC}"
    echo -e "     - Puerto 7200: ACTIVO"
    echo -e "     - Puerto 7300: ACTIVO"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "\n${C_RED}[!] Error: Los servicios se compilaron pero no pudieron arrancar.${C_NC}"
    echo -e "${C_YELLOW}Log del puerto 7200:${C_NC}"
    journalctl -u badvpn-7200.service -n 5 --no-pager
fi

read -p "Presione Enter para regresar al menú..."
