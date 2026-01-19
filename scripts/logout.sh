#!/bin/sh
#
# logout.sh
# Déconnexion manuelle du portail captif
#

# Charger la configuration
. /root/scripts/portal_config.sh

# Vérifier que les variables essentielles sont définies
if [ -z "$PORTAL_USER" ] || [ -z "$BASE_URL" ]; then
    echo "ERREUR : Configuration incomplète dans /root/scripts/portal_config.sh"
    exit 1
fi

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

LOGOUT_URL="$BASE_URL/logout.xml"
LOGOUT_BODY="mode=193&username=$PORTAL_USER&a=$TIMESTAMP&producttype=0"

TMP_RESP="/tmp/portal_auth_logout_$$"
if wget --no-check-certificate \
     --header="Content-Type: application/x-www-form-urlencoded" \
     --post-data="$LOGOUT_BODY" \
     -O "$TMP_RESP" \
     "$LOGOUT_URL" 2>&1 | logger -t "PORTAL_AUTH_WGET"; then
    LOGOUT_RESP="$(cat "$TMP_RESP" 2>/dev/null)"
else
    LOGOUT_RESP="Erreur wget (code: $?)"
fi
rm -f "$TMP_RESP"

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
