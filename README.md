# Portal Auth TLS

Système d'authentification automatique pour portail captif sur routeur OpenWrt.

## ⚠️ Avertissement

**Ce projet a été développé dans un cadre strictement éducatif**, dans le but d'étudier les mécanismes d'authentification des portails captifs et l'automatisation de tâches réseau sous OpenWrt.

L'utilisateur est seul responsable de l'usage qu'il fait de ce code. L'auteur ne peut être tenu responsable d'une utilisation inappropriée ou non conforme aux règlements en vigueur dans votre établissement ou organisation.

## 📋 Prérequis

- Routeur OpenWrt avec accès SSH root
- Connexion Internet (pour l'installation initiale)
- Identifiants du portail captif

## 🚀 Installation rapide

### Une commande

```bash
wget -qO- https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/install.sh | sh
```

### Manuelle

```bash
cd /tmp
wget -O install.sh https://raw.githubusercontent.com/FilouzMC/portal-auth-tls/main/install.sh
chmod +x install.sh
sh install.sh
```

Le script d'installation va :
- ✅ Installer les dépendances (`curl`)
- ✅ Télécharger les scripts dans `/root/scripts/`
- ✅ Créer la configuration template
- ✅ Configurer les tâches cron automatiques
- ✅ Installer l'interface LuCI web

> ℹ️ Les versions récentes d'OpenWrt utilisent `apk` comme gestionnaire de paquets. Le script détecte automatiquement `apk` et bascule sur `opkg` si nécessaire.

**Note** : Après l'installation, éditez `/root/scripts/portal_config.sh` avec vos identifiants.

## 🌐 Interfaces

### SSH (Ligne de commande)

```bash
# Authentification immédiate
sh /root/scripts/auth.sh

# Déconnexion
sh /root/scripts/logout.sh
```

### LuCI (Web)

Accédez à : **Services > Portail Captif**
- Gestion de la configuration
- Statut en temps réel
- Patches personnalisés
- Export / partage des logs

## 📚 Documentation

Pour plus de détails, consultez le dossier `docs/` :

- **[Configuration](docs/CONFIGURATION.md)** : Setup détaillé et options
- **[Fonctionnement](docs/FONCTIONNEMENT.md)** : Architecture et flux des scripts
- **[Interface LuCI](docs/LUCI.md)** : Utilisation complète
- **[Patches](docs/PATCHES.md)** : Créer et déployer des patches
- **[Logs et Monitoring](docs/MONITORING.md)** : Debugging et alertes
- **[Dépannage](docs/TROUBLESHOOTING.md)** : Solutions aux problèmes courants

## 📄 Licence

Ce projet est fourni tel quel, sans garantie. Utilisation à vos propres risques.
