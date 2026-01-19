#!/bin/sh
#
# portal_config.sh
# Configuration centralisée pour le portail captif
# À modifier selon vos besoins et copié dans /root/scripts/portal_config.sh
#

# ========================================
# IDENTIFIANTS PORTAIL CAPTIF
# ========================================
PORTAL_USER=""              # Votre nom d'utilisateur
PORTAL_PASS=""              # Votre mot de passe

# ========================================
# URL DU PORTAIL
# ========================================
BASE_URL="https://exemple.com:8090"

# ========================================
# ALERTES DISCORD (optionnel)
# ========================================
# Laisser vide pour désactiver les notifications Discord
DISCORD_WEBHOOK=""

# ========================================
# FICHIERS DE STATUT
# ========================================
STATE_FILE="/tmp/portal_auth_state"        # Fichier simple : ONLINE/OFFLINE
STATUS_FILE="/tmp/portal_auth_status"      # Fichier détaillé : CODE|Message

# ========================================
# VERSION
# ========================================
LOCAL_VERSION_FILE="/etc/portal_auth_version"

if [ -f "$LOCAL_VERSION_FILE" ]; then
    PORTAL_AUTH_VERSION="$(cat "$LOCAL_VERSION_FILE" 2>/dev/null | tr -d '\r\n')"
else
    PORTAL_AUTH_VERSION="dev"
fi

# ========================================
# EXPORT DES VARIABLES
# ========================================
export PORTAL_USER
export PORTAL_PASS
export BASE_URL
export DISCORD_WEBHOOK
export STATE_FILE
export STATUS_FILE
export PORTAL_AUTH_VERSION
