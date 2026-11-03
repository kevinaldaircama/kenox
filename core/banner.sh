#!/bin/bash
# ==========================================
# Módulo 4: Configure HTML Welcome Banner
# ==========================================
export LANG=en_US.UTF-8

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

ARCHIVO_BANNER="/etc/issue.net"

# ==========================================
# 1. BLOQUE FIJO: Detalles dinámicos del usuario
# ==========================================
# Estas son las variables estándar (%USER%, %EXP%, etc.) que leen 
# los binarios SSH/Dropbear modificados para inyectar los datos.
BANNER_FIJO="<br>
<div style='text-align:center;'>
<font color=\"cyan\">Usuario:</font> %USER%<br>
<font color=\"green\">Expira:</font> %EXP%<br>
<font color=\"red\">Días:</font> %DIAS%<br>
<font color=\"purple\">Consumo:</font> %CONSUMO% (Max: Ilimitado)<br>
<font color=\"yellow\">IP Límite:</font> %LIMITE%<br>
<hr>
</div>"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🎨 CONFIGURADOR DE BANNER HTML (OPCIÓN 4)"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}El banner dinámico de usuario (Usuario, Expira, Días) está FIJO.${C_NC}"
echo -e "A continuación, puedes escribir tu banner personalizado o publicidad"
echo -e "que aparecerá debajo de los datos del cliente.\n"
echo -e "Reglas HTML soportadas por las apps VPN:"
echo -e " - Salto de línea : <br>"
echo -e " - Color de texto : <font color=\"red\">Texto</font>"
echo -e " - Negrita        : <b>Texto</b>"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "Escribe tu texto personalizado. (Para terminar y guardar, deja una"
echo -e "línea completamente vacía y presiona Enter):\n"

# ==========================================
# 2. BLOQUE PERSONALIZADO: Captura de texto
# ==========================================
BANNER_CUSTOM=""
while IFS= read -r linea; do
    [[ -z "$linea" ]] && break
    BANNER_CUSTOM+="$linea<br>\n"
done

# ==========================================
# 3. CONSTRUCCIÓN Y APLICACIÓN
# ==========================================
echo -e "${C_YELLOW}Aplicando y reiniciando servicios SSH...${C_NC}"

# Escribir el banner combinado en issue.net
echo -e "$BANNER_FIJO" > "$ARCHIVO_BANNER"
if [[ -n "$BANNER_CUSTOM" ]]; then
    echo -e "$BANNER_CUSTOM" >> "$ARCHIVO_BANNER"
fi

# Asegurar que SSHd esté configurado para leer el banner
if grep -q "^#Banner" /etc/ssh/sshd_config; then
    sed -i 's/^#Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
elif ! grep -q "^Banner" /etc/ssh/sshd_config; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi

systemctl restart ssh 2>/dev/null
systemctl restart sshd 2>/dev/null
systemctl restart dropbear 2>/dev/null

echo -e "\n${C_GREEN}[✔] Banner HTML configurado correctamente.${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presiona Enter para volver al menú..."
