#!/bin/sh
#
# load_portal_config.sh
# Charge la configuration UCI du portail captif
# et expose des variables shell simples (PORTAL_USER, BASE_URL, etc.)
#

# On charge les fonctions UCI d'OpenWrt
. /lib/functions.sh

SECTION="general"

# Charge le fichier /etc/config/portal_auth
config_load portal_auth

# Récupération des options UCI -> variables shell
config_get PORTAL_USER     "$SECTION" portal_user     ""
config_get PORTAL_PASS     "$SECTION" portal_pass     ""
config_get DISCORD_WEBHOOK "$SECTION" discord_webhook ""
config_get BASE_URL        "$SECTION" base_url        "https://exemple.fr:8090"
config_get STATE_FILE      "$SECTION" state_file      "/tmp/portal_auth_state"
config_get STATUS_FILE     "$SECTION" status_file     "/tmp/portal_auth_status"
config_get INSTALL_DIR     "$SECTION" install_dir     "/root/scripts"

# Fichier de version utilisé pour l'affichage dans LuCI
LOCAL_VERSION_FILE="/etc/portal_auth_version"

if [ -f "$LOCAL_VERSION_FILE" ]; then
    PORTAL_AUTH_VERSION="$(cat "$LOCAL_VERSION_FILE" 2>/dev/null | tr -d '\r\n')"
else
    # Valeur par défaut si le fichier n'existe pas encore
    PORTAL_AUTH_VERSION="dev"
fi

# On peut exporter si tu veux que ce soit visible par des sous-shell
export PORTAL_AUTH_VERSION
