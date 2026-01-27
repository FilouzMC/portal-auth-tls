# Portal Auth

Système d'authentification automatique pour portail captif sur routeur OpenWrt.
> ⚠️ Ce projet est à but éducatif uniquement

## 📋 Prérequis

- Routeur OpenWrt avec accès SSH root
- Connexion Internet (pour l'installation initiale)
- Identifiants du portail captif

## 🚀 Installation

### Installation rapide (une commande)

Connectez-vous en SSH sur votre routeur et exécutez :

```bash
wget -qO- https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/install.sh | sh
```

### Installation manuelle

```bash
cd /tmp
wget -O install.sh https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/install.sh
chmod +x install.sh
sh install.sh
```

Le script d'installation va :
- ✅ Installer `curl` si nécessaire (via opkg)
- ✅ Télécharger et installer les scripts dans `/root/scripts/`
- ✅ Créer le fichier de configuration `/root/scripts/portal_config.sh`
- ✅ Configurer les tâches cron
- ✅ Créer le fichier de version `/etc/portal_auth_version`

## ⚙️ Configuration

Après l'installation, **vous devez éditer le fichier de configuration** :

```bash
vi /root/scripts/portal_config.sh
```

### Paramètres obligatoires

```bash
PORTAL_USER="votre_identifiant"     # Votre login
PORTAL_PASS="votre_mot_de_passe"    # Votre mot de passe
BASE_URL="https://portail.exemple.com:8090"  # URL du portail captif
```

### Paramètres optionnels

```bash
# Webhook Discord pour recevoir des alertes (laisser vide pour désactiver)
DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."

# Fichiers de statut (valeurs par défaut)
STATE_FILE="/tmp/portal_auth_state"
STATUS_FILE="/tmp/portal_auth_status"

# Planification des crons (format standard cron)
AUTH_CRON_SCHEDULE="* * * * *"      # Authentification/keep-alive
UPDATE_CRON_SCHEDULE="0 0 * * *"    # Vérification des mises à jour
```

**Important** : Le fichier de configuration est protégé (chmod 600) car il contient vos identifiants.

## 📂 Structure des fichiers

```
/root/scripts/
├── auth.sh              # Script d'authentification / keep-alive
├── logout.sh            # Script de déconnexion
├── check_update.sh      # Vérification des mises à jour
└── portal_config.sh     # Configuration (À ÉDITER)

/etc/portal_auth_version # Version installée
/tmp/portal_auth_state   # État : ONLINE / OFFLINE
/tmp/portal_auth_status  # Statut détaillé : CODE|Message
```

## 🔄 Fonctionnement

### Authentification automatique

Le script `auth.sh` s'exécute **automatiquement toutes les minutes** via cron :

1. **Test Internet** : Ping vers 8.8.8.8
   - ✅ Si OK → Envoie un keep-alive au portail
   - ❌ Si KO → Passe à l'étape suivante

2. **Test Portail** : Vérifie que le portail est joignable
   - ❌ Si injoignable → Alerte et sortie

3. **Connexion** : Tente l'authentification (mode=191)
   - ✅ Si réussite → Connexion établie
   - ❌ Si échec → Log l'erreur

### Mises à jour automatiques

Par défaut, le script `check_update.sh` s'exécute **chaque nuit à 00h00** (valeur ajustable via `portal_config.sh`) :
- Compare la version locale avec celle du dépôt GitHub
- Si nouvelle version détectée → télécharge et lance `install.sh`
- La configuration existante est **préservée** lors des mises à jour

## 🔧 Utilisation manuelle

### Tester l'authentification

```bash
# Lancer manuellement
sh /root/scripts/auth.sh

# Voir les logs en temps réel
logread -f | grep PORTAL_AUTH
```

### Se déconnecter

```bash
sh /root/scripts/logout.sh
```

### Vérifier les mises à jour

```bash
sh /root/scripts/check_update.sh
```

### Voir les tâches cron

```bash
crontab -l
```

## 📊 Logs et monitoring

### Logs système (syslog)

```bash
# Voir tous les logs du portail
logread | grep PORTAL_AUTH

# Suivre les logs en temps réel
logread -f | grep PORTAL_AUTH
```

### Fichiers de log cron

```bash
# Logs d'authentification
cat /tmp/portal_auth_cron.log

# Logs de mise à jour
cat /tmp/portal_auth_check_update.log
```

### Vérifier l'état

```bash
# État simple (ONLINE / OFFLINE)
cat /tmp/portal_auth_state

# Statut détaillé (CODE|Message)
cat /tmp/portal_auth_status

# Version installée
cat /etc/portal_auth_version
```

## 🔔 Alertes Discord (optionnel)

Pour recevoir des notifications Discord :

1. Créer un webhook Discord dans les paramètres de votre serveur
2. Copier l'URL du webhook
3. L'ajouter dans `/root/scripts/portal_config.sh` :

```bash
DISCORD_WEBHOOK="https://discord.com/api/webhooks/123456789/abcdefgh..."
```

Vous recevrez des alertes pour :
- ⚠️ Portail injoignable
- 🔥 Échec de connexion
- ✅ Connexion rétablie

## 🛠️ Dépannage

### Le script ne fonctionne pas

1. Vérifier la configuration :
```bash
cat /root/scripts/portal_config.sh
```

2. Tester manuellement avec logs :
```bash
sh -x /root/scripts/auth.sh
```

3. Vérifier curl :
```bash
opkg update && opkg install curl
curl --version
```

### Réponse vide du portail

- Vérifier l'URL du portail dans la config
- Tester manuellement :
```bash
curl -v https://votre-portail.com:8090
```

### Les crons ne s'exécutent pas

```bash
# Vérifier que le service cron tourne
/etc/init.d/cron status
/etc/init.d/cron restart

# Voir les tâches cron
crontab -l
```

## 🔄 Désinstallation

```bash
# Supprimer les tâches cron
crontab -l | grep -v "/root/scripts/auth.sh" | grep -v "/root/scripts/check_update.sh" | crontab -

# Supprimer les scripts
rm -rf /root/scripts/auth.sh /root/scripts/logout.sh /root/scripts/check_update.sh /root/scripts/portal_config.sh

# Supprimer les fichiers de version et statut
rm -f /etc/portal_auth_version /tmp/portal_auth_state /tmp/portal_auth_status
```

## 📝 Notes

- La configuration (`portal_config.sh`) est **préservée** lors des mises à jour
- Le système fonctionne **sans interface LuCI** _(pour le moment)
- Compatible avec tous les routeurs OpenWrt
- Le projet est conçu pour être simple, lisible et maintenable

## 📄 Licence

Ce projet est fourni tel quel, sans garantie.
