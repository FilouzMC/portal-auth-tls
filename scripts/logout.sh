#!/bin/sh
#
# logout.sh
# Déconnexion manuelle du portail captif
#

. /root/scripts/load_portal_config.sh

TIMESTAMP="$(date +%s)000"

log() {
    local MSG="$1"
    logger -t "PORTAL_AUTH" "$MSG"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [v$PORTAL_AUTH_VERSION] - $MSG"
}

set_status() {
    local CODE="$1"
    local MSG="$2"

    [ -z "$STATUS_FILE" ] && STATUS_FILE="/tmp/portal_auth_status"
    echo "${CODE}|${MSG}" > "$STATUS_FILE"
}

echo "Déconnexion du portail en cours..."

LOGOUT_BODY="mode=193&username=$PORTAL_USER&a=$TIMESTAMP&producttype=0"
LOGOUT_RESP="$(wget -q --tries=1 --no-check-certificate --post-data="$LOGOUT_BODY" -O - "$BASE_URL/logout.xml" 2>/dev/null)"

if echo "$LOGOUT_RESP" | grep -q "LOGIN"; then
    echo "✅ Déconnecté avec succès."
    log "Déconnexion manuelle effectuée."

    rm -f "$STATE_FILE"

    set_status "LOGOUT" "Déconnexion manuelle réussie (v$PORTAL_AUTH_VERSION)."
else
    echo "⚠️ Erreur lors de la déconnexion."
    echo "$LOGOUT_RESP"

    SHORT_RESP="$(echo "$LOGOUT_RESP" | tr '\n' ' ' | cut -c1-120)"
    set_status "ERROR" "Erreur lors de la déconnexion. Réponse: $SHORT_RESP"
    log "Erreur lors de la déconnexion : $SHORT_RESP"
fi
