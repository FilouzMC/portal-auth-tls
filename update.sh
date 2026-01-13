#!/bin/sh
#
# update.sh
# Exécuté sur le routeur, téléchargé depuis ton repo.
# Il :
#   - télécharge l'archive du repo GitHub
#   - l'extrait dans /tmp
#   - lance le install.sh de cette archive
#   - met à jour /etc/portal_auth_version
#
# Argument $1 = nouvelle version (ex: 1.0.3)

set -e

NEW_VERSION="$1"
[ -z "$NEW_VERSION" ] && NEW_VERSION="unknown"

# 🔧 À ADAPTER AVEC TON REPO :
# User, repo, branche
GITHUB_USER="FilouzMC"
GITHUB_REPO="portal-auth-tls"
GITHUB_BRANCH="main"

# URL de l'archive tar.gz du repo
TAR_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.tar.gz"

LOCAL_VERSION_FILE="/etc/portal_auth_version"
TMP_DIR="/tmp/portal_auth_update"
TMP_TAR="/tmp/portal_auth_update.tar.gz"

log() {
    echo "[portal-update] $1"
    logger -t "PORTAL_UPDATE" "$1" 2>/dev/null || true
}

log "Mise à jour vers la version $NEW_VERSION (téléchargement archive repo)..."

# 1) Téléchargement de l'archive
# --------------------------------------------------
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if ! curl -fsSL "$TAR_URL" -o "$TMP_TAR"; then
    log "Échec du téléchargement de l'archive : $TAR_URL"
    exit 1
fi

# 2) Extraction
# --------------------------------------------------
if ! tar -xzf "$TMP_TAR" -C "$TMP_DIR"; then
    log "Échec de l'extraction de l'archive."
    exit 1
fi

# L'archive GitHub crée un dossier du type REPO-BRANCH
EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "$GITHUB_REPO-*\" -o -name \"$GITHUB_REPO-$GITHUB_BRANCH\" 2>/dev/null | head -n 1)"

# fallback un peu plus simple
if [ -z "$EXTRACTED_DIR" ]; then
    EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d | grep "$GITHUB_REPO" | head -n 1)"
fi

if [ -z "$EXTRACTED_DIR" ]; then
    log "Impossible de trouver le dossier extrait dans $TMP_DIR"
    exit 1
fi

log "Dossier extrait : $EXTRACTED_DIR"

# 3) Lancer le install.sh de l'archive
# --------------------------------------------------
if [ ! -x "$EXTRACTED_DIR/install.sh" ]; then
    log "install.sh introuvable ou non exécutable dans $EXTRACTED_DIR"
    exit 1
fi

log "Lancement de install.sh de la nouvelle version..."

(
    cd "$EXTRACTED_DIR"
    sh ./install.sh "$NEW_VERSION"
)

# 4) Mise à jour du fichier de version locale (par sécurité)
# --------------------------------------------------
echo "$NEW_VERSION" > "$LOCAL_VERSION_FILE"

log "Mise à jour terminée. Version actuelle = $NEW_VERSION"

# 5) Nettoyage
# --------------------------------------------------
rm -f "$TMP_TAR"
rm -rf "$TMP_DIR"

exit 0
