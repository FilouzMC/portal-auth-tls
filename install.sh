#!/bin/sh
#
# install.sh
# Script d'installation / mise à jour pour OpenWrt
# Télécharge l'archive GitHub, installe les scripts et configure le système
#

set -e

NEW_VERSION="$1"

# ========================================
# CONFIGURATION REPO GITHUB
# ========================================
GITHUB_USER="FilouzMC"
GITHUB_REPO="portal-auth-tls"
GITHUB_BRANCH="speed-project-with-updater"
ARCHIVE_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.tar.gz"

# ========================================
# DOSSIERS TEMPORAIRES
# ========================================
WORK_DIR="/tmp/portal_auth_install"
ARCHIVE_FILE="$WORK_DIR/repo.tar.gz"

# ========================================
# DESTINATIONS SUR LE ROUTEUR
# ========================================
INSTALL_SCRIPTS_DIR="/root/scripts"
UCI_CONFIG_DST="/etc/config/portal_auth"
LOCAL_VERSION_FILE="/etc/portal_auth_version"

# ========================================
# FONCTIONS UTILITAIRES
# ========================================
log() {
    echo "[portal-install] $1"
    logger -t "PORTAL_INSTALL" "$1" 2>/dev/null || true
}

cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

# ========================================
# ÉTAPE 1 : TÉLÉCHARGEMENT DE L'ARCHIVE
# ========================================
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

log "Téléchargement de l'archive GitHub..."
if ! wget -q -O "$ARCHIVE_FILE" "$ARCHIVE_URL"; then
    log "Échec du téléchargement de l'archive."
    exit 1
fi

log "Extraction dans $WORK_DIR..."
if ! tar -xzf "$ARCHIVE_FILE" -C "$WORK_DIR"; then
    log "Impossible d'extraire l'archive."
    exit 1
fi

# ========================================
# ÉTAPE 2 : LOCALISER LE DOSSIER EXTRAIT
# ========================================
# GitHub crée un dossier du type "portal-auth-tls-main"
SRC_ROOT=""
for path in "$WORK_DIR"/$GITHUB_REPO-*; do
    if [ -d "$path" ]; then
        SRC_ROOT="$path"
        break
    fi
done

if [ -z "$SRC_ROOT" ]; then
    log "Impossible de trouver le dossier extrait du repo."
    exit 1
fi

log "Archive extraite dans : $SRC_ROOT"

# ========================================
# ÉTAPE 3 : VÉRIFICATIONS DES FICHIERS
# ========================================
SCRIPTS_SRC="$SRC_ROOT/scripts"
CONFIG_SRC="$SRC_ROOT/config/portal_auth"
VERSION_SRC="$SRC_ROOT/version.txt"

[ -d "$SCRIPTS_SRC" ] || { log "Dossier scripts introuvable"; exit 1; }
[ -f "$CONFIG_SRC" ] || { log "Fichier config UCI introuvable"; exit 1; }

# ========================================
# ÉTAPE 4 : INSTALLATION DES SCRIPTS
# ========================================
log "Installation des scripts dans $INSTALL_SCRIPTS_DIR..."
mkdir -p "$INSTALL_SCRIPTS_DIR"

# Supprimer les anciens scripts
for file in auth.sh check_update.sh load_portal_config.sh logout.sh; do
    rm -f "$INSTALL_SCRIPTS_DIR/$file"
done

# Copier les nouveaux scripts
cp "$SCRIPTS_SRC"/*.sh "$INSTALL_SCRIPTS_DIR"/
chmod +x "$INSTALL_SCRIPTS_DIR"/*.sh

log "Scripts installés : auth.sh, check_update.sh, load_portal_config.sh, logout.sh"

# ========================================
# ÉTAPE 5 : CONFIGURATION UCI
# ========================================
if [ ! -f "$UCI_CONFIG_DST" ]; then
    log "Création du fichier de configuration UCI (première installation)."
    mkdir -p "$(dirname "$UCI_CONFIG_DST")"
    cp "$CONFIG_SRC" "$UCI_CONFIG_DST"
    log "Fichier créé : $UCI_CONFIG_DST"
else
    log "Config UCI déjà présente, conservée."
fi

# ========================================
# ÉTAPE 6 : CONFIGURATION DES TÂCHES CRON
# ========================================
log "Mise à jour des tâches cron..."

# Auth toutes les 1 minute
AUTH_CRON="* * * * * $INSTALL_SCRIPTS_DIR/auth.sh >/tmp/portal_auth_cron.log 2>&1"

# Check update toutes les 30 minutes
UPDATE_CRON="*/30 * * * * $INSTALL_SCRIPTS_DIR/check_update.sh >/tmp/portal_auth_check_update.log 2>&1"

# Récupérer le cron existant et filtrer les anciennes entrées
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"
FILTERED_CRON="$(echo "$CURRENT_CRON" | grep -v "$INSTALL_SCRIPTS_DIR/auth.sh" | grep -v "$INSTALL_SCRIPTS_DIR/check_update.sh" || true)"

# Appliquer les nouvelles tâches
printf "%s\n%s\n%s\n" "$FILTERED_CRON" "$AUTH_CRON" "$UPDATE_CRON" | sed '/^$/d' | crontab -

log "Cron configuré : auth.sh (1 min) et check_update.sh (30 min)"

# ========================================
# ÉTAPE 7 : REDÉMARRAGE DES SERVICES WEB
# ========================================
# Optionnel : redémarrer uhttpd et rpcd pour une future interface LuCI
if [ -x /etc/init.d/uhttpd ]; then
    log "Redémarrage de uHTTPd..."
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true
fi

if [ -x /etc/init.d/rpcd ]; then
    log "Redémarrage de rpcd..."
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
fi

# ========================================
# ÉTAPE 8 : MISE À JOUR DE LA VERSION
# ========================================
VERSION_VALUE="dev"
if [ -n "$NEW_VERSION" ]; then
    VERSION_VALUE="$NEW_VERSION"
elif [ -f "$VERSION_SRC" ]; then
    VERSION_VALUE="$(cat "$VERSION_SRC" 2>/dev/null | tr -d '\r\n')"
fi

echo "$VERSION_VALUE" > "$LOCAL_VERSION_FILE"
log "Version installée : $VERSION_VALUE"

# ========================================
# FIN DE L'INSTALLATION
# ========================================
log "Installation terminée avec succès."
log "Scripts : $INSTALL_SCRIPTS_DIR"
log "Config UCI : $UCI_CONFIG_DST"
log "Version : $LOCAL_VERSION_FILE"

exit 0
