#!/bin/bash
# ==========================================
# GESTIÓN DE USUARIOS SSH / VPN
# ==========================================

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_ORANGE='\033[38;5;214m'
C_NC='\033[0m'

# 1. Crear Usuario
crear_usuario() {
    while true; do
        clear
        echo -e "${C_ORANGE}======================================================${C_NC}"
        echo -e "               ${C_BLUE}[ TIPO DE CUENTA A CREAR ]${C_NC}"
        echo -e "${C_ORANGE}======================================================${C_NC}"
        echo -e " 1. 👤 Crear Cuenta Normal"
        echo -e " 2. 📱 Crear Cuenta HWID (Bloqueo por Dispositivo)"
        echo -e " 3. 🎫 Crear Cuenta Token"
        echo -e " 0. 🚪 VOLVER"
        echo -e "${C_ORANGE}======================================================${C_NC}"
        read -p " Selecciona una opción: " tipo_op

        case $tipo_op in
            1) tipo_cuenta="Normal"; break ;;
            2) tipo_cuenta="HWID"; break ;;
            3) tipo_cuenta="Token"; break ;;
            0) return ;;
            *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 1 ;;
        esac
    done

    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "         ${C_BLUE}[ CREANDO USUARIO - $tipo_cuenta ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' ya existe.${C_NC}"
        sleep 2
        return
    fi
    
    read -p " Contraseña: " password
    read -p " Días de duración: " dias
    read -p " Límite de conexiones: " limite

    valor_extra=""
    if [ "$tipo_cuenta" = "HWID" ]; then
        read -p " Ingresa el HWID del cliente: " valor_extra
    elif [ "$tipo_cuenta" = "Token" ]; then
        read -p " Ingresa el Token del cliente: " valor_extra
    fi

    useradd -M -s /bin/false -e $(date -d "+$dias days" +%Y-%m-%d) "$username"
    echo "$username:$password" | chpasswd
    
    mkdir -p /root/usuarios
    echo "$limite" > /root/usuarios/$username.limit

    if [ "$tipo_cuenta" = "HWID" ] && [ -n "$valor_extra" ]; then
        mkdir -p /root/usuarios/hwid
        echo "$valor_extra" > /root/usuarios/hwid/$username.hwid
    elif [ "$tipo_cuenta" = "Token" ] && [ -n "$valor_extra" ]; then
        mkdir -p /root/usuarios/token
        echo "$valor_extra" > /root/usuarios/token/$username.token
    fi

    IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)

    clear
    echo -e "${C_GREEN}✅ Usuario $tipo_cuenta creado con éxito.${C_NC}"
    echo -e "${C_CYAN}======================================================${C_NC}"
    echo -e " 👤 Usuario   : $username"
    echo -e " 🔑 Pass      : $password"
    echo -e " ⏳ Vence     : $(date -d "+$dias days" +%d/%m/%Y)"
    echo -e " ⚙️ Límite    : $limite conexión(es)"
    
    if [ "$tipo_cuenta" = "HWID" ]; then
        echo -e " 📱 HWID      : $valor_extra"
    elif [ "$tipo_cuenta" = "Token" ]; then
        echo -e " 🎫 Token     : $valor_extra"
    fi
    
    echo -e " 🌐 IP Server : $IP"
    echo -e "${C_CYAN}======================================================${C_NC}"
    echo -e "${C_ORANGE}          🚀 MÉTODOS DE CONEXIÓN ACTIVOS 🚀${C_NC}"
    echo -e "${C_CYAN}======================================================${C_NC}"

    echo -e " 🔹 SSH Directo : 22"

    if systemctl is-active --quiet bhttp; then
        PORT_BHTTP=$(grep -oP '(?<="port": )[0-9]+' /etc/vps-manager/bhttp/BHTTP.py 2>/dev/null | head -1)
        echo -e " 🔹 BHTTP Proxy : ${PORT_BHTTP:-8180}"
    fi

    if systemctl is-active --quiet hcr; then
        PORT_HCR=$(systemctl show hcr.service -p ExecStart 2>/dev/null | grep -oP '(?<=--listen :)[0-9]+' | head -1)
        echo -e " 🔹 HCR Plain   : ${PORT_HCR:-8880}"
    fi

    if systemctl is-active --quiet udp-custom; then
        echo -e " 🔹 UDP Custom  : Activo (Puertos 1-65535)"
    fi

    if systemctl is-active --quiet zivpn; then
        echo -e " 🔹 ZiVPN UDP   : Activo (Puerto 25000)"
    fi

    if systemctl is-active --quiet stunnel4; then
        echo -e " 🔹 SSL / TLS   : 443, 444"
    fi

    # Búsqueda Universal y Copia Automática de OpenVPN (CORREGIDO PUERTO 2081)
    if systemctl is-active --quiet openvpn@server-tcp || systemctl is-active --quiet openvpn@server || systemctl is-active --quiet openvpn; then
        OVPN_PATH=$(find /root /etc/vps-manager/openvpn_files /var/www/html /home /etc/openvpn -maxdepth 3 -name "*.ovpn" 2>/dev/null | head -n 1)
        
        if [ -n "$OVPN_PATH" ]; then
            OVPN_NAME=$(basename "$OVPN_PATH")
            mkdir -p /etc/vps-manager/openvpn_files
            cp -f "$OVPN_PATH" "/etc/vps-manager/openvpn_files/$OVPN_NAME" 2>/dev/null
            chmod 644 "/etc/vps-manager/openvpn_files/$OVPN_NAME" 2>/dev/null
            
            PORT_WEB="2081"
            
            echo -e " 🔹 OpenVPN     : ACTIVO"
            echo -e " 📥 Link OVPN   : http://$IP:$PORT_WEB/$OVPN_NAME"
        else
            echo -e " 🔹 OpenVPN     : ACTIVO (Debes crear/generar tu primer perfil .ovpn)"
        fi
    fi

    if pgrep -x "dns-server" > /dev/null || systemctl is-active --quiet slowdns; then
        SL_KEY="No configurada"
        NS_DOMAIN="No configurado"
        for path in /etc/slowdns/server.pub /root/server.pub /root/Slowdns/server.pub /etc/slowdns/pub.key; do
            if [ -f "$path" ]; then
                SL_KEY=$(cat "$path")
                break
            fi
        done
        for path in /etc/slowdns/domain.ns /root/domain.ns /root/Slowdns/domain.ns; do
            if [ -f "$path" ]; then
                NS_DOMAIN=$(cat "$path")
                break
            fi
        done

        echo -e " 🔹 SlowDNS     : ACTIVO"
        echo -e " 📝 NS Domain   : $NS_DOMAIN"
        echo -e " 🔑 Pub Key     : $SL_KEY"
    fi
    
    if systemctl is-active --quiet hysteria; then
        echo -e " 🔹 Hysteria    : Activo (UDP)"
    fi

    echo -e "${C_CYAN}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 2. Eliminar Usuario
eliminar_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_RED}[ ELIMINAR USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre del usuario a eliminar: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    userdel --force "$username" 2>/dev/null
    rm -f /root/usuarios/$username.limit
    rm -f /root/usuarios/hwid/$username.hwid
    rm -f /root/usuarios/token/$username.token
    
    echo -e "\n ${C_GREEN}✅ Usuario '$username' eliminado correctamente.${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 3. Renovar Usuario
renovar_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_GREEN}[ RENOVAR USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Días a extender desde hoy: " dias
    chage -E $(date -d "+$dias days" +%Y-%m-%d) "$username"
    
    echo -e "\n ${C_GREEN}✅ Usuario renovado. Nueva fecha de vencimiento: $(date -d "+$dias days" +%d/%m/%Y)${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 4. Cambiar Contraseña
cambiar_contrasena() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "             ${C_CYAN}[ CAMBIAR CONTRASEÑA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Nueva contraseña: " password
    echo "$username:$password" | chpasswd
    
    echo -e "\n ${C_GREEN}✅ Contraseña actualizada correctamente.${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 5. Límite de Conexiones
limite_conexiones() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_BLUE}[ ESTABLECER LÍMITE DE CONEXIONES ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Nuevo límite de conexiones: " limite
    mkdir -p /root/usuarios
    echo "$limite" > /root/usuarios/$username.limit
    
    echo -e "\n ${C_GREEN}✅ Límite actualizado a $limite conexión(es).${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 6. Detalles de Usuario
detalles_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_CYAN}[ DETALLES DE USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    exp_date=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | sed 's/^ *//')
    status=$(passwd -S "$username" | awk '{print $2}')
    limit="Sin límite"
    
    [ -f "/root/usuarios/$username.limit" ] && limit=$(cat "/root/usuarios/$username.limit")
    [ "$status" = "L" ] && st="${C_RED}Bloqueado${C_NC}" || st="${C_GREEN}Activo${C_NC}"

    echo -e "\n 👤 Usuario   : $username"
    echo -e " 📅 Vencimiento: $exp_date"
    echo -e " ⚙️ Límite    : $limit"
    echo -e " 🛡️ Estado    : $st"
    
    if [ -f "/root/usuarios/hwid/$username.hwid" ]; then
        echo -e " 📱 HWID      : $(cat /root/usuarios/hwid/$username.hwid)"
    elif [ -f "/root/usuarios/token/$username.token" ]; then
        echo -e " 🎫 Token     : $(cat /root/usuarios/token/$username.token)"
    fi
    
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 7. Bloquear / Desbloquear Cuenta
bloquear_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_RED}[ BLOQUEAR / DESBLOQUEAR CUENTA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    echo -e "\n 1. 🔒 Bloquear cuenta"
    echo -e " 2. 🔓 Desbloquear cuenta"
    read -p " Opción: " block_op

    if [ "$block_op" = "1" ]; then
        usermod -L "$username"
        echo -e "\n ${C_GREEN}✅ Usuario '$username' bloqueado.${C_NC}"
    elif [ "$block_op" = "2" ]; then
        usermod -U "$username"
        echo -e "\n ${C_GREEN}✅ Usuario '$username' desbloqueado.${C_NC}"
    else
        echo -e "\n ${C_RED}Opción inválida.${C_NC}"
    fi
    read -p " Presiona Enter para continuar..."
}

# 8. Lista de Usuarios
lista_usuarios() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_CYAN}[ LISTA DE USUARIOS Y VENCIMIENTOS ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    printf " %-15s | %-20s | %-10s\n" "USUARIO" "VENCIMIENTO" "ESTADO"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
        exp=$(chage -l "$user" | grep "Account expires" | cut -d: -f2 | sed 's/^ *//')
        status=$(passwd -S "$user" | awk '{print $2}')
        [ "$status" = "L" ] && st="${C_RED}Bloqueado${C_NC}" || st="${C_GREEN}Activo${C_NC}"
        
        [ "$exp" = "never" ] && exp="Nunca"
        
        printf " %-15s | %-20s | %-10s\n" "$user" "$exp" "$st"
    done
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 9. Usuarios Online
usuarios_online() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "           ${C_GREEN}[ USUARIOS CONECTADOS EN LÍNEA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    printf " %-15s | %-10s | %-15s\n" "USUARIO" "PID" "PROTOCOLO"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    
    ps -ef | grep -E 'sshd|dropbear' | grep -v root | grep -v grep | awk '{print $1, $2, $8}' | while read user pid proc; do
        if id "$user" &>/dev/null; then
            protocolo="SSH"
            [[ "$proc" == *"dropbear"* ]] && protocolo="Dropbear"
            printf " %-15s | %-10s | %-15s\n" "$user" "$pid" "$protocolo"
        fi
    done
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# ==========================================
# Menú Interactivo de Usuarios
# ==========================================
while true; do
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 👤 GESTIÓN DE CUENTAS SSH / VPN"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 1. ➕ Crear nuevo usuario"
    echo -e " 2. ❌ Eliminar usuario"
    echo -e " 3. 🔄 Renovar usuario (Extender días)"
    echo -e " 4. 🔑 Cambiar contraseña"
    echo -e " 5. ⚙️ Establecer límite de conexiones"
    echo -e " 6. 📋 Detalles de un usuario"
    echo -e " 7. 🔓 Bloquear / Desbloquear cuenta"
    echo -e " 8. 👥 Lista de usuarios y vencimientos"
    echo -e " 9. 📡 Ver usuarios conectados en línea"
    echo -e " 0. 🚪 VOLVER al Menú Principal"
    echo -e "${C_CYAN}================================================${C_NC}"
    read -p " Selecciona una opción: " user_op
    
    case $user_op in
        1) crear_usuario ;;
        2) eliminar_usuario ;;
        3) renovar_usuario ;;
        4) cambiar_contrasena ;;
        5) limite_conexiones ;;
        6) detalles_usuario ;;
        7) bloquear_usuario ;;
        8) lista_usuarios ;;
        9) usuarios_online ;;
        0) break ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 1 ;;
    esac
done
