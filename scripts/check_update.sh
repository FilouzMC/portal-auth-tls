#!/bin/sh
#
# check_update.sh
# Vérifie s'il existe une nouvelle version sur le repo
# et télécharge / exécute update.sh si c'est le cas.
#

LOCAL_VERSION_FILE="/etc/portal_auth_version"

# 🔧 À ADAPTER : URL de ta version distante et de ton update.sh
REMOTE_VERSION_URL="https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/version.txt"
REMOTE_UPDATE_URL="https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/update.sh"

log() {
    local MSG="$1"
    echo "[portal-update-check] $MSG"
    logger -t "PORTAL_UPDATE" "$MSG" 2>/dev/null || true
}

# Version locale : "0" si non définie
LOCAL_VERSION="0"
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION="$(cat "$LOCAL_VERSION_FILE" 2>/dev/null | tr -d '\r\n')"
fi

# Récupération de la version distante
REMOTE_VERSION="$(curl -fsS "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '\r\n')"

if [ -z "$REMOTE_VERSION" ]; then
    log "Impossible de récupérer la version distante (URL: $REMOTE_VERSION_URL)."
    exit 0
fi

if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
    log "Aucune mise à jour disponible (locale: $LOCAL_VERSION, distante: $REMOTE_VERSION)."
    exit 0
fi

log "Nouvelle version détectée (locale: $LOCAL_VERSION, distante: $REMOTE_VERSION)."

TMP_UPDATE="/tmp/portal_auth_update.sh"

if ! curl -fsS "$REMOTE_UPDATE_URL" -o "$TMP_UPDATE"; then
    log "Échec du téléchargement de update.sh (URL: $REMOTE_UPDATE_URL)."
    exit 1
fi

chmod +x "$TMP_UPDATE"

# Exécution du script d'update en root avec la nouvelle version en argument
sh "$TMP_UPDATE" "$REMOTE_VERSION"
RET="$?"

if [ "$RET" -eq 0 ]; then
    log "Mise à jour vers la version $REMOTE_VERSION effectuée avec succès."
else
    log "Échec de la mise à jour (code de retour: $RET)."
fi

exit "$RET"
