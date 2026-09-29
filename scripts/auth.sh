#!/bin/sh
#
# auth.sh
# Script d'authentification / keep-alive du portail captif
#

# Charger la configuration
. /root/scripts/portal_config.sh

# Vérifier que les variables essentielles sont définies
if [ -z "$PORTAL_USER" ] || [ -z "$PORTAL_PASS" ] || [ -z "$BASE_URL" ]; then
    echo "ERREUR : Configuration incomplète dans /root/scripts/portal_config.sh"
    echo "PORTAL_USER=$PORTAL_USER"
    echo "PORTAL_PASS=($([ -n "$PORTAL_PASS" ] && echo 'défini' || echo 'vide'))"
    echo "BASE_URL=$BASE_URL"
    exit 1
fi

# Timestamp en millisecondes pour le portail (paramètre "a")
TIMESTAMP="$(date +%s)000"

log() {
    local MSG="$1"
    logger -t "PORTAL_AUTH" "$MSG"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [v$PORTAL_AUTH_VERSION] - $MSG"
}

discord_alert() {
    [ -z "$DISCORD_WEBHOOK" ] && return

    local MSG="$1"
    local COLOR="$2"

    local JSON
    JSON="{\"embeds\": [{\"title\": \"🔐 Portail Captif v$PORTAL_AUTH_VERSION\", \"description\": \"$MSG\", \"color\": $COLOR}]}"

    curl -s -H "Content-Type: application/json" -d "$JSON" "$DISCORD_WEBHOOK" >/dev/null 2>&1
}

set_status() {
    local CODE="$1"
    local MSG="$2"

    [ -z "$STATUS_FILE" ] && STATUS_FILE="/tmp/portal_auth_status"
    echo "${CODE}|${MSG}" > "$STATUS_FILE"
}

# ===========================
#  ÉTAPE 1 : TEST INTERNET
# ===========================
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    # Internet OK -> KeepAlive
    LIVE_URL="$BASE_URL/live?mode=192&username=$PORTAL_USER&a=$TIMESTAMP&producttype=0"

    curl -k -s "$LIVE_URL" >/dev/null 2>&1

    echo "ONLINE" > "$STATE_FILE"
    set_status "OK" "Internet OK, KeepAlive envoyé (v$PORTAL_AUTH_VERSION)."
    log "Internet OK, KeepAlive envoyé au portail."

    exit 0
else
    log "Ping 8.8.8.8 échoué, tentative de connexion au portail..."
fi

# ===========================
#  ÉTAPE 2 : PORTAIL JOIGNABLE ?
# ===========================
if ! curl -k -s --max-time 5 "$BASE_URL" >/dev/null 2>&1; then
    log "Impossible d'atteindre le portail : $BASE_URL"
    set_status "ERROR" "Portail injoignable ($BASE_URL)."

    if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE" 2>/dev/null)" != "OFFLINE" ]; then
        discord_alert "⚠️ Portail injoignable ($BASE_URL)" "16711680"
        echo "OFFLINE" > "$STATE_FILE"
    fi

    exit 1
fi

# ===========================
#  ÉTAPE 3 : CONNEXION (mode=191)
# ===========================
LOGIN_BODY="mode=191&username=$PORTAL_USER&password=$PORTAL_PASS&a=$TIMESTAMP&producttype=0"
LOGIN_RESP="$(curl -k -s -X POST -d "$LOGIN_BODY" "$BASE_URL/login.xml")"

log "Réponse login brute : $LOGIN_RESP"

if echo "$LOGIN_RESP" | grep -q "LIVE"; then
    # Connexion OK
    log "Connexion réussie (Status: LIVE)."
    echo "ONLINE" > "$STATE_FILE"

    set_status "OK" "Connexion réussie pour $PORTAL_USER (v$PORTAL_AUTH_VERSION)."

    if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE" 2>/dev/null)" != "ONLINE" ]; then
        discord_alert "✅ Connexion rétablie pour **$PORTAL_USER** (v$PORTAL_AUTH_VERSION)." "65280"
    fi

    exit 0
fi

# Si on arrive ici, la connexion a échoué
REASON="Échec de la connexion (voir logs)."

# Tentative de deviner la cause avec quelques patterns
if echo "$LOGIN_RESP" | grep -qi "password"; then
    REASON="Identifiants possiblement incorrects."
elif echo "$LOGIN_RESP" | grep -qi "max user"; then
    REASON="Limite d'utilisateurs atteinte sur le portail."
fi

SHORT_RESP="$(echo "$LOGIN_RESP" | tr '\n' ' ' | cut -c1-120)"

set_status "ERROR" "$REASON Réponse: $SHORT_RESP"

log "Échec de la connexion. Raison probable : $REASON"

if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE" 2>/dev/null)" != "OFFLINE" ]; then
    discord_alert "🔥 Impossible de se connecter au portail (v$PORTAL_AUTH_VERSION)." "16711680"
    echo "OFFLINE" > "$STATE_FILE"
fi

exit 1
