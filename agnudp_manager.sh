#!/bin/bash

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_DB="$CONFIG_DIR/udpusers.db"
SYSTEMD_SERVICE="/etc/systemd/system/hysteria-server.service"

mkdir -p "$CONFIG_DIR"
touch "$USER_DB"


fetch_users() {
    if [[ -f "$USER_DB" ]]; then
        sqlite3 "$USER_DB" "SELECT username || ':' || password FROM users;" | paste -sd, -
    fi
}

update_userpass_config() {
    local users=$(fetch_users)
    jq ".auth.config = [\"$users\"]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

add_user() {
    echo "Enter username:"
    read -r username
    echo "Enter password:"
    read -r password

    # Insert the new user into the database
    sqlite3 "$USER_DB" "INSERT INTO users (username, password) VALUES ('$username', '$password');"
    if [[ $? -eq 0 ]]; then
        echo "User $username added successfully."
        update_userpass_config
        restart_server
    else
        echo "Error: Failed to add user $username."
    fi
}

edit_user() {
    echo "Enter username to edit:"
    read -r username
    echo "Enter new password:"
    read -r password

    # Update the user in the database
    sqlite3 "$USER_DB" "UPDATE users SET password = '$password' WHERE username = '$username';"
    if [[ $? -eq 0 ]]; then
        echo "User $username updated successfully."
        update_userpass_config
        restart_server
    else
        echo "Error: Failed to update user $username."
    fi
}

delete_user() {
    echo "Enter username to delete:"
    read -r username

    # Delete the user from the database
    sqlite3 "$USER_DB" "DELETE FROM users WHERE username = '$username';"
    if [[ $? -eq 0 ]]; then
        echo "User $username deleted successfully."
        update_userpass_config
        restart_server
    else
        echo "Error: Failed to delete user $username."
    fi
}

show_users() {
    echo "Current users:"
    sqlite3 "$USER_DB" "SELECT username FROM users;"
}

change_domain() {
    echo "Enter new domain:"
    read -r domain

    jq ".server = \"$domain\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Domain changed to $domain successfully."

    restart_server
}

change_obfs() {
    echo "Enter new obfuscation string:"
    read -r obfs

    jq ".obfs.password = \"$obfs\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Obfuscation string changed to $obfs successfully."

    restart_server
}

change_up_speed() {
    echo "Enter new upload speed (Mbps):"
    read -r up_speed

    jq ".up_mbps = $up_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".up = $up_speed Mbps" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Upload speed changed to $up_speed Mbps successfully."

    restart_server
}

change_down_speed() {
    echo "Enter new download speed (Mbps):"
    read -r down_speed

    jq ".down_mbps = $down_speed" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".down = $down_speed Mbps" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Download speed changed to $down_speed Mbps successfully."

    restart_server
}

show_menu() {
    echo "----------------------------"
    echo " AGNUDP Manager"
    echo "----------------------------"
    echo "1. Add new user"
    echo "2. Edit user password"
    echo "3. Delete user"
    echo "4. Show users"
    echo "5. Change domain"
    echo "6. Change obfuscation string"
    echo "7. Change upload speed"
    echo "8. Change download speed"
    echo "9. Restart server"
    echo "10. Uninstall server"
    echo "11. Exit"
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
            edit_user
            ;;
        3)
            delete_user
            ;;
        4)
            show_users
            ;;
        5)
            change_domain
            ;;
        6)
            change_obfs
            ;;
        7)
            change_up_speed
            ;;
        8)
            change_down_speed
            ;;
        9)
            restart_server
            ;;
        10)
            uninstall_server
            exit 0
            ;;
        11)
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
