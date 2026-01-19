#!/bin/sh
#
# setup_wizard.sh
# Assistant de configuration interactif pour Portal Auth
#

# ========================================
# VARIABLES GLOBALES
# ========================================
PORTAL_USER=""
PORTAL_PASS=""
BASE_URL=""
DISCORD_WEBHOOK=""

# ========================================
# FONCTIONS D'AFFICHAGE
# ========================================
show_header() {
    clear
    echo "=========================================="
    echo "  Portal Auth - Assistant d'installation"
    echo "=========================================="
    echo ""
}

# ========================================
# ÉTAPE 1 : URL DU PORTAIL
# ========================================
prompt_base_url() {
    show_header
    echo "📡 Configuration du portail captif"
    echo ""
    echo "Entrez l'URL du portail captif (ex: https://portail.exemple.com:8090)"
    printf "URL du portail : "
    read BASE_URL
    
    if [ -z "$BASE_URL" ]; then
        echo ""
        echo "❌ L'URL ne peut pas être vide."
        sleep 2
        prompt_base_url
        return
    fi
    
    # Extraire le hostname de l'URL pour le test (supporte http://, https://, et avec/sans port)
    HOSTNAME=$(echo "$BASE_URL" | sed 's|^https\?://||' | sed 's|[:/].*||')
    
    echo ""
    echo "🔍 Vérification de l'accessibilité de $HOSTNAME..."
    
    if ping -c 2 -W 3 "$HOSTNAME" >/dev/null 2>&1; then
        echo "✅ Le portail est joignable !"
        sleep 1
    else
        echo ""
        echo "⚠️  AVERTISSEMENT : Impossible de joindre $HOSTNAME"
        echo ""
        echo "Cela peut être dû à :"
        echo "  • Un problème de résolution DNS"
        echo "  • Le portail n'est pas encore accessible"
        echo "  • Problème de connectivité réseau"
        echo ""
        echo "💡 Si c'est un problème DNS, configurez dnsmasq sur OpenWrt"
        echo "   ou ajoutez une entrée DNS via l'interface LuCI."
        echo ""
        printf "Continuer malgré tout ? (o/n) : "
        read CONTINUE_CHOICE
        
        if [ "$CONTINUE_CHOICE" != "o" ] && [ "$CONTINUE_CHOICE" != "O" ]; then
            echo ""
            echo "❌ Installation annulée."
            exit 1
        fi
    fi
}

# ========================================
# ÉTAPE 2 : IDENTIFIANTS
# ========================================
prompt_credentials() {
    show_header
    echo "🔐 Identifiants du portail captif"
    echo ""
    printf "Nom d'utilisateur : "
    read PORTAL_USER
    
    if [ -z "$PORTAL_USER" ]; then
        echo ""
        echo "❌ Le nom d'utilisateur ne peut pas être vide."
        sleep 2
        prompt_credentials
        return
    fi
    
    echo ""
    printf "Mot de passe : "
    read PORTAL_PASS
    
    if [ -z "$PORTAL_PASS" ]; then
        echo ""
        echo "❌ Le mot de passe ne peut pas être vide."
        sleep 2
        prompt_credentials
        return
    fi
}

# ========================================
# ÉTAPE 3 : WEBHOOK DISCORD (OPTIONNEL)
# ========================================
prompt_discord() {
    show_header
    echo "🔔 Notifications Discord (optionnel)"
    echo ""
    echo "Si vous souhaitez recevoir des alertes Discord,"
    echo "entrez l'URL de votre webhook. Sinon, laissez vide."
    echo ""
    printf "Webhook Discord : "
    read DISCORD_WEBHOOK
    
    if [ -n "$DISCORD_WEBHOOK" ]; then
        echo ""
        echo "✅ Notifications Discord activées !"
        sleep 1
    fi
}

# ========================================
# ÉTAPE 4 : RÉCAPITULATIF
# ========================================
confirm_config() {
    show_header
    echo "📋 Récapitulatif de la configuration"
    echo ""
    echo "URL du portail  : $BASE_URL"
    echo "Utilisateur     : $PORTAL_USER"
    echo "Mot de passe    : $(echo "$PORTAL_PASS" | sed 's/./*/g')"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        echo "Discord         : Activé"
    else
        echo "Discord         : Désactivé"
    fi
    echo ""
    printf "Confirmer et lancer l'installation ? (o/n) : "
    read CONFIRM
    
    if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
        echo ""
        echo "❌ Installation annulée."
        exit 1
    fi
}

# ========================================
# FONCTION PRINCIPALE
# ========================================
run_wizard() {
    prompt_base_url
    prompt_credentials
    prompt_discord
    confirm_config
    
    # Exporter les variables pour le script parent
    export PORTAL_USER
    export PORTAL_PASS
    export BASE_URL
    export DISCORD_WEBHOOK
}

# Lancer l'assistant si appelé directement
if [ "$1" = "run" ]; then
    run_wizard
fi
