# Configuration

## Configuration de base

### Éditer la configuration

Après l'installation, le fichier de configuration est **automatiquement créé** à partir d'un template.

**Vous devez éditer ce fichier pour y saisir vos identifiants** :

```bash
nano /root/scripts/portal_config.sh
```

### Exemple de fichier de configuration

```bash
#!/bin/sh
#
# portal_config.sh
# Configuration du portail captif
#

# URL du portail captif (avec protocole et port sans le / à la fin)
export BASE_URL="https://portail.exemple.com:8090"

# Identifiants du portail
export PORTAL_USER="votre_identifiant"
export PORTAL_PASS="votre_mot_de_passe"

# Webhook Discord (optionnel)
export DISCORD_WEBHOOK=""
```

### Variables de configuration

| Variable | Description | Exemple |
|----------|-------------|---------|
| `BASE_URL` | URL complète du portail captif | `https://portail.exemple.com:8090` |
| `PORTAL_USER` | Identifiant pour se connecter | `votre_identifiant` |
| `PORTAL_PASS` | Mot de passe pour se connecter | `votre_mot_de_passe` |
| `DISCORD_WEBHOOK` | Webhook Discord pour les alertes (optionnel) | `https://discord.com/api/webhooks/...` |

## Structure des fichiers

### Sur le routeur

```
/root/scripts/
├── auth.sh              # Script d'authentification / keep-alive
├── logout.sh            # Script de déconnexion
├── check_update.sh      # Vérification des mises à jour
├── portal_config.sh     # Configuration (À ÉDITER)
└── patch_*.sh           # Fichiers de patch (optionnels)

/root/patches/
└── patch_*.log          # Historique d'exécution des patches

/etc/portal_auth_version # Version installée
/tmp/portal_auth_state   # État : ONLINE / OFFLINE
/tmp/portal_auth_status  # Statut détaillé : CODE|Message
```

## Webhooks Discord (optionnel)

### Configuration

Pour recevoir des notifications Discord :

1. Créer un webhook Discord dans les paramètres de votre serveur
2. Copier l'URL du webhook
3. L'ajouter dans `/root/scripts/portal_config.sh` :

```bash
DISCORD_WEBHOOK="https://discord.com/api/webhooks/123456789/abcdefgh..."
```

### Alertes reçues

Vous recevrez des alertes pour :
- ⚠️ Portail injoignable
- 🔥 Échec de connexion
- ✅ Connexion rétablie

## Configuration avancée

### Crontab personnalisée

Voir le fichier `docs/FONCTIONNEMENT.md` pour modifier les horaires.

### Mises à jour automatiques

Par défaut, le script `check_update.sh` s'exécute **chaque nuit à 00h00** :
- Compare la version locale avec celle du dépôt GitHub
- Si nouvelle version détectée → télécharge et installe automatiquement
- La configuration existante est **préservée** lors des mises à jour

Pour désactiver les mises à jour automatiques, éditez crontab :

```bash
crontab -e
# Commentez la ligne contenant check_update.sh
```
