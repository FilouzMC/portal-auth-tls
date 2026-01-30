# Portal Auth TLS

Système d'authentification automatique pour portail captif sur routeur OpenWrt.

## ⚠️ Avertissement

**Ce projet a été développé dans un cadre strictement éducatif**, dans le but d'étudier les mécanismes d'authentification des portails captifs et l'automatisation de tâches réseau sous OpenWrt.

L'utilisateur est seul responsable de l'usage qu'il fait de ce code. L'auteur ne peut être tenu responsable d'une utilisation inappropriée ou non conforme aux règlements en vigueur dans votre établissement ou organisation.

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
- ✅ Créer un fichier de configuration template `/root/scripts/portal_config.sh` (si absent)
- ✅ Configurer les tâches cron pour l'authentification automatique
- ✅ Créer le fichier de version `/etc/portal_auth_version`

**Note** : Après l'installation, vous devez éditer le fichier `/root/scripts/portal_config.sh` pour y saisir vos identifiants (voir section Configuration ci-dessous).

## ⚙️ Configuration

### Configuration du portail captif

Après l'installation, le fichier de configuration est **automatiquement créé** à partir d'un template.

**Vous devez éditer ce fichier pour y saisir vos identifiants** :

```bash
nano /root/scripts/portal_config.sh
```

**Exemple de fichier de configuration :**

```bash
#!/bin/sh
#
# portal_config.sh
# Configuration du portail captif
#

# URL du portail captif (avec protocole et port)
export BASE_URL="https://portail.exemple.com:8090"

# Identifiants du portail
export PORTAL_USER="votre_identifiant"
export PORTAL_PASS="votre_mot_de_passe"

# Webhook Discord (optionnel)
export DISCORD_WEBHOOK=""
```

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

Par défaut, le script `check_update.sh` s'exécute **chaque nuit à 00h00** :
- Compare la version locale (`/etc/portal_auth_version`) avec celle du dépôt GitHub (`version.txt`)
- Si nouvelle version détectée → télécharge et lance automatiquement `install.sh`
- La configuration existante (`portal_config.sh`) est **préservée** lors des mises à jour
- Les configurations réseau (IPv6, DNS, odhcpd) sont réappliquées automatiquement

**Versions détectées** : Toutes les versions (majeures, mineures et patches) sont prises en compte

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

1. **Vérifier que le fichier de configuration existe** :
```bash
ls -la /root/scripts/portal_config.sh
# Si le fichier n'existe pas, créez-le (voir section Configuration)
```

2. **Vérifier le contenu de la configuration** :
```bash
cat /root/scripts/portal_config.sh
# Assurez-vous que BASE_URL, PORTAL_USER et PORTAL_PASS sont définis
```

3. **Tester manuellement avec logs** :
```bash
sh -x /root/scripts/auth.sh
```

4. **Vérifier curl** :
```bash
curl --version
# Si absent :
opkg update && opkg install curl
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

# Voir les tâches cron configurées
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

- Un fichier de configuration template est **créé automatiquement** lors de la première installation
- Vous devez **éditer ce fichier** pour y saisir vos identifiants (BASE_URL, PORTAL_USER, PORTAL_PASS)
- La configuration est **préservée** lors des mises à jour automatiques
- Le système fonctionne **sans interface LuCI**
- Compatible avec tous les routeurs OpenWrt
- Le projet est conçu pour être simple, lisible et maintenable

## 📄 Licence

Ce projet est fourni tel quel, sans garantie. Utilisation à vos propres risques.
