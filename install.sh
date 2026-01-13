#!/bin/sh
#
# install.sh
# Installation / mise à jour du portail captif sur un routeur OpenWrt.
#
# Usage typique :
#   cd /root/portal-auth
#   sh ./install.sh
#
# Quand appelé depuis update.sh, on peut lui passer la version en paramètre :
#   sh ./install.sh 1.0.3
#

set -e  # stop en cas d'erreur

NEW_VERSION="$1"   # éventuellement passé par update.sh (peut être vide)

echo "[*] Installation / mise à jour du portail captif..."

# Répertoire du repo (là où se trouve ce script)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# === Variables customisables ===
# Tu peux modifier ces chemins si tu veux tout déplacer autre part

INSTALL_SCRIPTS_DIR="/root/scripts"                 # Où installer les scripts
LUCI_CTRL_DST="/usr/lib/lua/luci/controller"        # Controllers LuCI
LUCI_CBI_DST="/usr/lib/lua/luci/model/cbi"          # Modèles CBI LuCI
UCI_CONFIG_DST="/etc/config/portal_auth"            # Fichier UCI final
LOCAL_VERSION_FILE="/etc/portal_auth_version"       # Fichier de version installé

SCRIPTS_SRC="$REPO_DIR/scripts"
LUCI_CTRL_SRC="$REPO_DIR/luci/controller"
LUCI_CBI_SRC="$REPO_DIR/luci/model/cbi"
CONFIG_SRC="$REPO_DIR/config/portal_auth"
VERSION_SRC="$REPO_DIR/version.txt"

echo "[*] Repo : $REPO_DIR"

# 1) Vérifs de base
# --------------------------------------------------

[ -d "$SCRIPTS_SRC" ] || { echo "[!] Dossier scripts introuvable : $SCRIPTS_SRC"; exit 1; }
[ -d "$LUCI_CTRL_SRC" ] || { echo "[!] Dossier LuCI controller introuvable : $LUCI_CTRL_SRC"; exit 1; }
[ -d "$LUCI_CBI_SRC" ] || { echo "[!] Dossier LuCI CBI introuvable : $LUCI_CBI_SRC"; exit 1; }
[ -f "$CONFIG_SRC" ] || { echo "[!] Fichier config UCI par défaut introuvable : $CONFIG_SRC"; exit 1; }

if [ ! -f "$VERSION_SRC" ]; then
    echo "[!] version.txt introuvable dans le repo."
    echo "    Ce n'est pas bloquant, la version sera 'dev'."
fi

# 2) Scripts
# --------------------------------------------------
echo "[*] Installation des scripts..."

mkdir -p "$INSTALL_SCRIPTS_DIR"
cp "$SCRIPTS_SRC"/*.sh "$INSTALL_SCRIPTS_DIR"/
chmod +x "$INSTALL_SCRIPTS_DIR"/*.sh

echo "[✓] Scripts installés dans $INSTALL_SCRIPTS_DIR"

# 3) LuCI
# --------------------------------------------------
echo "[*] Installation des fichiers LuCI..."

mkdir -p "$LUCI_CTRL_DST"
mkdir -p "$LUCI_CBI_DST"

cp "$LUCI_CTRL_SRC"/*.lua "$LUCI_CTRL_DST"/
cp "$LUCI_CBI_SRC"/*.lua  "$LUCI_CBI_DST"/

echo "[✓] LuCI installé dans :"
echo "    - $LUCI_CTRL_DST"
echo "    - $LUCI_CBI_DST"

# 4) Config UCI
# --------------------------------------------------
if [ ! -f "$UCI_CONFIG_DST" ]; then
    echo "[*] Aucune config trouvée, création de $UCI_CONFIG_DST à partir du repo..."
    cp "$CONFIG_SRC" "$UCI_CONFIG_DST"
    echo "[✓] Config UCI créée."
else
    echo "[i] $UCI_CONFIG_DST existe déjà, je ne la remplace pas."
    echo "    (Tu peux la modifier via LuCI ou à la main.)"
fi

# 5) Version locale
# --------------------------------------------------
# Priorité :
#  - si NEW_VERSION passé en paramètre -> on l'utilise
#  - sinon, on lit version.txt du repo
VERSION_VALUE="dev"

if [ -n "$NEW_VERSION" ]; then
    VERSION_VALUE="$NEW_VERSION"
elif [ -f "$VERSION_SRC" ]; then
    VERSION_VALUE="$(cat "$VERSION_SRC" 2>/dev/null | tr -d '\r\n')"
fi

echo "$VERSION_VALUE" > "$LOCAL_VERSION_FILE"

echo "[✓] Version locale = $VERSION_VALUE (stockée dans $LOCAL_VERSION_FILE)"

# 6) Redémarrage uHTTPd (LuCI)
# --------------------------------------------------
if [ -x /etc/init.d/uhttpd ]; then
    echo "[*] Redémarrage du service web (uHTTPd)..."
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true
    echo "[✓] uHTTPd redémarré."
else
    echo "[i] Service uHTTPd non trouvé, redémarrage manuel possible."
fi

# 7) Ajouter automatiquement les tâches cron si absentes
# ------------------------------------------------------

echo "[*] Configuration automatique du cron..."

# Récupère le cron actuel (ou vide)
CRON_CONTENT="$(crontab -l 2>/dev/null || echo '')"
NEW_CRON="$CRON_CONTENT"

# Tâche : authentification keep-alive toutes les 3min
AUTH_CRON="*/3 * * * * $INSTALL_SCRIPTS_DIR/auth.sh >/tmp/portal_auth_cron.log 2>&1"
if ! echo "$CRON_CONTENT" | grep -q "$INSTALL_SCRIPTS_DIR/auth.sh"; then
    NEW_CRON="${NEW_CRON}\n${AUTH_CRON}"
    echo "[+] Ajout du cron auth.sh"
fi

# Tâche : vérification de mise à jour toutes les heures
UPDATE_CRON="0 * * * * $INSTALL_SCRIPTS_DIR/check_update.sh >/tmp/portal_auth_check_update.log 2>&1"
if ! echo "$CRON_CONTENT" | grep -q "$INSTALL_SCRIPTS_DIR/check_update.sh"; then
    NEW_CRON="${NEW_CRON}\n${UPDATE_CRON}"
    echo "[+] Ajout du cron check_update.sh"
fi

# Appliquer uniquement si changement
if [ "$NEW_CRON" != "$CRON_CONTENT" ]; then
    printf "%b\n" "$NEW_CRON" | crontab -
    echo "[✓] Cron mis à jour."
else
    echo "[i] Les tâches cron sont déjà présentes."
fi

# 8) Récapitulatif
# --------------------------------------------------
cat <<EOF

[✓] Installation terminée.

Scripts installés dans : $INSTALL_SCRIPTS_DIR
Config UCI : $UCI_CONFIG_DST
LuCI :
  - Controller : $LUCI_CTRL_DST
  - CBI        : $LUCI_CBI_DST

Version installée : $VERSION_VALUE

Pense à vérifier / ajouter dans crontab (crontab -e) par exemple :

  # Authentification / keep-alive toutes les 3 minutes
  */3 * * * * $INSTALL_SCRIPTS_DIR/auth.sh >/tmp/portal_auth_cron.log 2>&1

  # Vérification de nouvelles versions toutes les heures
  0 * * * * $INSTALL_SCRIPTS_DIR/check_update.sh >/tmp/portal_auth_check_update.log 2>&1

EOF

exit 0
