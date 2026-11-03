#!/bin/bash
LANG_FILE="/etc/vps-manager/lang.txt"
[ -f "$LANG_FILE" ] && current_lang=$(cat "$LANG_FILE") || current_lang="es"

if [ "$current_lang" = "en" ]; then
    t_mgmt="[ ACCOUNT MANAGEMENT ]"
    t_tools="[ TOOLS & SYSTEM ]"
    t_select="Select an option: "
elif [ "$current_lang" = "pt" ]; then
    t_mgmt="[ GERENCIAMENTO DE CONTAS ]"
    t_tools="[ FERRAMENTAS & SISTEMA ]"
    t_select="Selecione uma opção: "
else
    t_mgmt="[ GESTIÓN DE CUENTAS ]"
    t_tools="[ HERRAMIENTAS Y SISTEMA ]"
    t_select="Selecciona una opción: "
fi
