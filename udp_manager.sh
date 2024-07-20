#!/bin/bash

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_DB="$CONFIG_DIR/udpusers.db"


mkdir -p "$CONFIG_DIR"
touch "$USER_DB"


add_user() {
    echo "Enter username:"
    read -r username
    echo "Enter password:"
    read -r password

   
    echo "$username:$password" >> "$USER_DB"

    
    jq ".auth.config += [\"$password\"]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "User $username added successfully."
}


change_domain() {
    echo "Enter new domain:"
    read -r domain

   
    jq ".server = \"$domain\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Domain changed to $domain successfully."
}


change_obfs() {
    echo "Enter new obfuscation string:"
    read -r obfs

   
    jq ".obfs = \"$obfs\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Obfuscation string changed to $obfs successfully."
}

show_menu() {
    echo "----------------------------"
    echo " AGNUDP Manager"
    echo "----------------------------"
    echo "1. Add new user"
    echo "2. Change domain"
    echo "3. Change obfuscation string"
    echo "4. Restart server"
    echo "5. Exit"
    echo "----------------------------"
    echo "Enter your choice: "
}


restart_server() {
    systemctl restart hysteria-server
    echo "Server restarted successfully."
}


show_banner() {
    echo "---------------------------------------------"
    echo " AGNUDP Manager"
    echo " (c) 2023 Khaled AGN"
    echo " Telegram: @khaledagn"
    echo "---------------------------------------------"
}


uninstall_server() {
    echo "Uninstalling AGN-UDP server..."

   
    systemctl stop hysteria-server
    systemctl disable hysteria-server

   
    rm -f "$SYSTEMD_SERVICE"
    systemctl daemon-reload

    
    rm -rf "$CONFIG_DIR"

    
    rm -f /usr/local/bin/hysteria

    echo "AGN-UDP server uninstalled successfully."
}


show_banner
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            add_user
            ;;
        2)
            change_domain
            ;;
        3)
            change_obfs
            ;;
        4)
            restart_server
            ;;
        5)
            uninstall_server
            exit 0
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done