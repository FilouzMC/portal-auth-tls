#!/bin/sh
#
# check_update.sh
# Compare la version locale avec celle du dépôt et lance install.sh en cas d'écart.
#

LOCAL_VERSION_FILE="/etc/portal_auth_version"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/version.txt"
REMOTE_INSTALL_URL="https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/install.sh"
TMP_INSTALLER="/tmp/portal_auth_install.sh"

log() {
    local MSG="$1"
    echo "[portal-update-check] $MSG"
    logger -t "PORTAL_UPDATE" "$MSG" 2>/dev/null || true
}

read_local_version() {
    if [ -f "$LOCAL_VERSION_FILE" ]; then
        cat "$LOCAL_VERSION_FILE" 2>/dev/null | tr -d '\r\n'
    else
        echo "0"
    fi
}

LOCAL_VERSION="$(read_local_version)"
REMOTE_VERSION="$(wget -q --tries=1 -O - "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '\r\n')"

if [ -z "$REMOTE_VERSION" ]; then
    log "Impossible de récupérer la version distante ($REMOTE_VERSION_URL)."
    exit 1
fi

if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
    log "Aucune mise à jour : version locale = $LOCAL_VERSION."
    exit 0
fi

log "Nouvelle version détectée (locale: $LOCAL_VERSION, distante: $REMOTE_VERSION). Téléchargement de install.sh..."

if ! wget -q --tries=1 -O "$TMP_INSTALLER" "$REMOTE_INSTALL_URL"; then
    log "Échec du téléchargement de install.sh ($REMOTE_INSTALL_URL)."
    exit 1
fi

chmod +x "$TMP_INSTALLER"

sh "$TMP_INSTALLER" "$REMOTE_VERSION"
RET="$?"

rm -f "$TMP_INSTALLER"

if [ "$RET" -eq 0 ]; then
    log "Mise à jour vers la version $REMOTE_VERSION effectuée avec succès."
else
    log "Échec de la mise à jour (code de retour: $RET)."
fi

exit "$RET"
