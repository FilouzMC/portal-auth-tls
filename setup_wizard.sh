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
    read -r BASE_URL
    
    # Nettoyer les espaces et vérifier si vide
    BASE_URL=$(echo "$BASE_URL" | tr -d '[:space:]')
    
    if [ -z "$BASE_URL" ] || [ "$BASE_URL" = "" ]; then
        echo ""
        echo "❌ L'URL ne peut pas être vide."
        sleep 2
        prompt_base_url
        return
    fi
    
    echo ""
    echo "✅ URL enregistrée !"
    sleep 1
}

# ========================================
# ÉTAPE 2 : IDENTIFIANTS
# ========================================
prompt_credentials() {
    show_header
    echo "🔐 Identifiants du portail captif"
    echo ""
    printf "Nom d'utilisateur : "
    read -r PORTAL_USER
    
    # Nettoyer les espaces
    PORTAL_USER=$(echo "$PORTAL_USER" | tr -d '[:space:]')
    
    if [ -z "$PORTAL_USER" ] || [ "$PORTAL_USER" = "" ]; then
        echo ""
        echo "❌ Le nom d'utilisateur ne peut pas être vide."
        sleep 2
        prompt_credentials
        return
    fi
    
    echo ""
    printf "Mot de passe : "
    read -r PORTAL_PASS
    
    # Nettoyer les espaces
    PORTAL_PASS=$(echo "$PORTAL_PASS" | tr -d '[:space:]')
    
    if [ -z "$PORTAL_PASS" ] || [ "$PORTAL_PASS" = "" ]; then
        echo ""
        echo "❌ Le mot de passe ne peut pas être vide."
        sleep 2
        prompt_credentials
        return
    fi
    
    echo ""
    echo "✅ Identifiants enregistrés !"
    sleep 1
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
    read -r DISCORD_WEBHOOK
    
    # Nettoyer les espaces
    DISCORD_WEBHOOK=$(echo "$DISCORD_WEBHOOK" | tr -d '[:space:]')
    
    if [ -n "$DISCORD_WEBHOOK" ] && [ "$DISCORD_WEBHOOK" != "" ]; then
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
    if [ -n "$DISCORD_WEBHOOK" ] && [ "$DISCORD_WEBHOOK" != "" ]; then
        echo "Discord         : Activé"
    else
        echo "Discord         : Désactivé"
    fi
    echo ""
    printf "Confirmer et lancer l'installation ? (o/n) : "
    read -r CONFIRM
    
    # Nettoyer et normaliser la réponse
    CONFIRM=$(echo "$CONFIRM" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    if [ "$CONFIRM" != "o" ]; then
        echo ""
        echo "❌ Installation annulée."
        exit 1
    fi
}

# ========================================
# ÉCRITURE DU FICHIER DE CONFIGURATION
# ========================================
write_config() {
    CONFIG_FILE="$1"
    
    echo ""
    echo "💾 Création du fichier de configuration..."
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" <<EOF
#!/bin/sh
#
# portal_config.sh
# Configuration du portail captif
# Généré automatiquement par l'assistant d'installation
#

# URL du portail captif (avec protocole et port)
export BASE_URL="$BASE_URL"

# Identifiants du portail
export PORTAL_USER="$PORTAL_USER"
export PORTAL_PASS="$PORTAL_PASS"

# Webhook Discord (optionnel)
export DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
EOF
    
    chmod 600 "$CONFIG_FILE"
    
    echo "✅ Configuration enregistrée dans $CONFIG_FILE"
    sleep 1
}

# ========================================
# FONCTION PRINCIPALE
# ========================================
run_wizard() {
    CONFIG_PATH="$1"
    
    if [ -z "$CONFIG_PATH" ]; then
        echo "❌ ERREUR : Chemin du fichier de configuration non spécifié."
        exit 1
    fi
    
    prompt_base_url
    prompt_credentials
    prompt_discord
    confirm_config
    write_config "$CONFIG_PATH"
}

# Lancer l'assistant si appelé directement
if [ "$1" = "run" ] && [ -n "$2" ]; then
    run_wizard "$2"
fi
