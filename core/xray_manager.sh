#!/bin/bash
# ==========================================
# Módulo: Xray Multi-Protocol Manager (Instalar / Desinstalar)
# Golbert VPS V5.0 LTS
# ==========================================

clear
echo -e "\033[1;36m================================================\033[0m"
echo -e " \033[1;33mXRAY MULTI-PROTOCOL MANAGER\033[0m"
echo -e "\033[1;36m================================================\033[0m"
echo -e " 1. 📥 Instalar / Actualizar Xray (VMess/VLESS/Trojan)"
echo -e " 2. ❌ Desinstalar Xray (Liberar puertos 80 y 443)"
echo -e " 0. 🚪 Volver al Menú"
echo -e "\033[1;36m================================================\033[0m"
read -p " Selecciona una opción: " opt

case $opt in
    1)
        echo -e "\n\033[1;33m[+] Instalando o actualizando Xray Core...\033[0m"
        apt update -y && apt install -y curl wget unzip jq >/dev/null 2>&1

        # Crear directorios necesarios
        mkdir -p /etc/xray /var/log/xray

        # Instalar Xray Core oficial
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1

        # Configurar config.json optimizado para puertos 80 (WS) y 443 (TLS)
        cat << 'EOF' > /etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 80,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

        systemctl daemon-reload
        systemctl enable xray
        systemctl restart xray

        echo -e "\n\033[1;32m[✔] Xray instalado correctamente en los puertos 80 y 443.\033[0m"
        sleep 2
        ;;
    2)
        echo -e "\n\033[1;31m[-] Desinstalando Xray Core y liberando puertos...\033[0m"
        
        # Detener y deshabilitar servicio
        systemctl stop xray 2>/dev/null
        systemctl disable xray 2>/dev/null

        # Ejecutar script oficial de desinstalación de Xray si existe, o eliminar directorios
        if [ -f /usr/local/bin/xray ]; then
            bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge >/dev/null 2>&1
        fi

        # Limpieza profunda de archivos residuales y puertos
        rm -rf /etc/xray /var/log/xray /usr/local/share/xray
        fuser -k 80/tcp 2>/dev/null
        fuser -k 443/tcp 2>/dev/null

        echo -e "\n\033[1;32m[✔] Xray desinstalado con éxito. Puertos 80 y 443 liberados.\033[0m"
        sleep 2
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "\n\033[1;31mOpción inválida.\033[0m"
        sleep 1
        ;;
esac
