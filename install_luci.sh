#!/bin/sh
# install_luci.sh
# Installe l'interface LuCI pour Portal Auth TLS

set -e

SRC_ROOT="$1"
LUCI_SRC_DIR="$SRC_ROOT/luci"
LUCI_CONTROLLER_SRC="$LUCI_SRC_DIR/controller/portal.lua"
LUCI_VIEWS_SRC="$LUCI_SRC_DIR/view/portal"
LUCI_CONTROLLER_DST="/usr/lib/lua/luci/controller"
LUCI_VIEWS_DST="/usr/lib/lua/luci/view/portal"

log() {
    echo "[portal-luci] $1"
    logger -t "PORTAL_LUCI" "$1" 2>/dev/null || true
}

if [ -z "$SRC_ROOT" ] || [ ! -d "$LUCI_SRC_DIR" ]; then
    log "ERREUR : dossier source LuCI introuvable"
    exit 1
fi

if [ ! -d "/usr/lib/lua/luci" ]; then
    log "LuCI absent, installation via opkg..."
    opkg update
    opkg install luci-base luci-mod-admin-full
fi

mkdir -p "$LUCI_CONTROLLER_DST"
mkdir -p "$LUCI_VIEWS_DST"

cp "$LUCI_CONTROLLER_SRC" "$LUCI_CONTROLLER_DST/portal.lua"
cp "$LUCI_VIEWS_SRC"/index.htm "$LUCI_VIEWS_DST/"
chmod 644 "$LUCI_CONTROLLER_DST/portal.lua" "$LUCI_VIEWS_DST/index.htm"

rm -rf /tmp/luci-indexcache /tmp/luci-modulecache 2>/dev/null || true

if /etc/init.d/uhttpd status >/dev/null 2>&1; then
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true
fi

log "Interface LuCI installée. Accessible via Système > Portail Captif"
