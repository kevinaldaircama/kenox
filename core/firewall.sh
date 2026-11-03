#!/bin/bash
# ==========================================
# Módulo: Firewall Seguro y Anti-DDoS
# ==========================================
C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       ESCUDO ANTI-DDOS (MODO SEGURO)           ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] 1. Asegurando acceso SSH (Salvavidas)...${C_NC}"
# Reglas críticas para NUNCA perder acceso
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

if command -v ufw > /dev/null; then
    ufw allow 22/tcp >/dev/null 2>&1
fi

echo -e "${C_YELLOW}[+] 2. Aplicando protección en el Kernel (sysctl)...${C_NC}"
cat << EOF > /etc/sysctl.d/99-anti-ddos.conf
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF
sysctl -p /etc/sysctl.d/99-anti-ddos.conf >/dev/null 2>&1

echo -e "${C_YELLOW}[+] 3. Aplicando mitigación de ataques básicos...${C_NC}"
# Limitar Ping para evitar saturación
iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
iptables -A INPUT -p icmp -j DROP

# Guardar reglas
iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save >/dev/null 2>&1

echo -e "${C_GREEN}[✔] Firewall Seguro activado. Tu puerto 22 está blindado.${C_NC}"
read -p "Presiona Enter para regresar..."
