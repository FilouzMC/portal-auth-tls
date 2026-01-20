#!/bin/sh
#
# install.sh
# Script d'installation / mise à jour autonome pour routeurs OpenWrt.
# Il télécharge l'archive GitHub du projet, installe les fichiers et met à jour la version locale.
#

set -e

NEW_VERSION="$1"

# --- Paramètres repo ---
GITHUB_USER="FilouzMC"
GITHUB_REPO="portal-auth-tls"
GITHUB_BRANCH="main"
ARCHIVE_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.tar.gz"

# --- Dossiers temporaires ---
WORK_DIR="/tmp/portal_auth_install"
ARCHIVE_FILE="$WORK_DIR/portal-auth-tls.tar.gz"

# --- Destinations ---
INSTALL_SCRIPTS_DIR="/root/scripts"
LUCI_CTRL_DST="/usr/lib/lua/luci/controller"
LUCI_CBI_DST="/usr/lib/lua/luci/model/cbi"
UCI_CONFIG_DST="/etc/config/portal_auth"
LOCAL_VERSION_FILE="/etc/portal_auth_version"

log() {
    echo "[portal-install] $1"
    logger -t "PORTAL_INSTALL" "$1" 2>/dev/null || true
}

cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

log "Téléchargement de l'archive GitHub ($ARCHIVE_URL)..."
if ! wget -q -O "$ARCHIVE_FILE" "$ARCHIVE_URL"; then
    log "Échec du téléchargement de l'archive."
    exit 1
fi

log "Extraction dans $WORK_DIR..."
if ! tar -xzf "$ARCHIVE_FILE" -C "$WORK_DIR"; then
    log "Impossible d'extraire l'archive."
    exit 1
fi

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

SCRIPTS_SRC="$SRC_ROOT/scripts"
LUCI_CTRL_SRC="$SRC_ROOT/luci/controller"
LUCI_CBI_SRC="$SRC_ROOT/luci/model/cbi"
CONFIG_SRC="$SRC_ROOT/config/portal_auth"
VERSION_SRC="$SRC_ROOT/version.txt"

[ -d "$SCRIPTS_SRC" ] || { log "Dossier scripts introuvable"; exit 1; }
[ -d "$LUCI_CTRL_SRC" ] || { log "Controller LuCI introuvable"; exit 1; }
[ -d "$LUCI_CBI_SRC" ] || { log "CBI LuCI introuvable"; exit 1; }
[ -f "$CONFIG_SRC" ] || { log "Config UCI par défaut introuvable"; exit 1; }

log "Installation des scripts dans $INSTALL_SCRIPTS_DIR..."
mkdir -p "$INSTALL_SCRIPTS_DIR"
for file in auth.sh check_update.sh load_portal_config.sh logout.sh; do
    rm -f "$INSTALL_SCRIPTS_DIR/$file"
done
cp "$SCRIPTS_SRC"/*.sh "$INSTALL_SCRIPTS_DIR"/
chmod +x "$INSTALL_SCRIPTS_DIR"/*.sh

log "Installation des fichiers LuCI..."
mkdir -p "$LUCI_CTRL_DST" "$LUCI_CBI_DST"
rm -f "$LUCI_CTRL_DST/portal_auth.lua"
rm -f "$LUCI_CBI_DST/portal_auth.lua"
cp "$LUCI_CTRL_SRC"/portal_auth.lua "$LUCI_CTRL_DST"/
cp "$LUCI_CBI_SRC"/portal_auth.lua "$LUCI_CBI_DST"/

if [ ! -f "$UCI_CONFIG_DST" ]; then
    log "Création du fichier de configuration UCI (première installation)."
    cp "$CONFIG_SRC" "$UCI_CONFIG_DST"
else
    log "Config UCI déjà présente, conservée."
fi

log "Mise à jour des tâches cron..."
AUTH_CRON="* * * * * $INSTALL_SCRIPTS_DIR/auth.sh >/tmp/portal_auth_cron.log 2>&1"
UPDATE_CRON="0 0 * * * $INSTALL_SCRIPTS_DIR/check_update.sh >/tmp/portal_auth_check_update.log 2>&1"

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"
FILTERED_CRON="$(echo "$CURRENT_CRON" | grep -v "$INSTALL_SCRIPTS_DIR/auth.sh" | grep -v "$INSTALL_SCRIPTS_DIR/check_update.sh" || true)"
printf "%s\n%s\n%s\n" "$FILTERED_CRON" "$AUTH_CRON" "$UPDATE_CRON" | sed '/^$/d' | crontab -

if [ -x /etc/init.d/uhttpd ]; then
    log "Redémarrage de uHTTPd..."
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true
fi

if [ -x /etc/init.d/rpcd ]; then
    log "Redémarrage de rpcd..."
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
fi

VERSION_VALUE="dev"
if [ -n "$NEW_VERSION" ]; then
    VERSION_VALUE="$NEW_VERSION"
elif [ -f "$VERSION_SRC" ]; then
    VERSION_VALUE="$(cat "$VERSION_SRC" 2>/dev/null | tr -d '\r\n')"
fi

log "Mise à jour du fichier de version ($LOCAL_VERSION_FILE -> $VERSION_VALUE)..."
echo "$VERSION_VALUE" > "$LOCAL_VERSION_FILE"

log "Installation terminée."
exit 0
