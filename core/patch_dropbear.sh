#!/bin/bash
# ==========================================
# Parche: Dropbear Modificado (Banner Dinámico)
# Soporte para variables %USER%, %EXP%, %DIAS%, %LIMITE%
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALANDO DROPBEAR MODIFICADO (BANNER)      ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[1/4] Deteniendo servicio Dropbear actual...${C_NC}"
systemctl stop dropbear >/dev/null 2>&1
killall -9 dropbear >/dev/null 2>&1

echo -e "${C_YELLOW}[2/4] Detectando arquitectura del servidor...${C_NC}"
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    echo -e "${C_RED}[!] Este binario modificado requiere arquitectura x86_64. Arquitectura detectada: $ARCH${C_NC}"
    echo -e "${C_YELLOW}Se cancela el parche para evitar colapsos del sistema.${C_NC}"
    exit 1
fi

echo -e "${C_YELLOW}[3/4] Respaldando binario original y descargando parche...${C_NC}"
if [ -f /usr/sbin/dropbear ]; then
    mv /usr/sbin/dropbear /usr/sbin/dropbear.bak
fi

# Descarga del binario Dropbear parcheado (estable para paneles LATAM)
wget -qO /usr/sbin/dropbear "https://raw.githubusercontent.com/ChumoGH/ChumoGH-Script/master/binarios/dropbear"

if [ ! -s /usr/sbin/dropbear ]; then
    echo -e "${C_RED}[✘] Error al descargar el binario modificado. Restaurando original...${C_NC}"
    mv /usr/sbin/dropbear.bak /usr/sbin/dropbear
    systemctl start dropbear
    exit 1
fi

chmod +x /usr/sbin/dropbear

echo -e "${C_YELLOW}[4/4] Reiniciando servicios con el nuevo núcleo...${C_NC}"
systemctl daemon-reload
systemctl restart dropbear >/dev/null 2>&1

if systemctl is-active --quiet dropbear; then
    echo -e "\n${C_GREEN}[✔] Dropbear Modificado instalado correctamente.${C_NC}"
    echo -e "${C_CYAN}Ahora los marcadores en /etc/issue.net mostrarán datos reales.${C_NC}"
else
    echo -e "\n${C_RED}[!] Error al iniciar el nuevo Dropbear. Restaurando...${C_NC}"
    mv -f /usr/sbin/dropbear.bak /usr/sbin/dropbear
    systemctl restart dropbear
fi
