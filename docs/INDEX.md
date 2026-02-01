# Documentation complète

Bienvenue dans la documentation détaillée du projet Portal Auth TLS.

## 📖 Table des matières

### 1. **[Configuration](CONFIGURATION.md)**
   - Setup initial du portail
   - Variables de configuration
   - Webhooks Discord
   - Structure des fichiers

### 2. **[Fonctionnement](FONCTIONNEMENT.md)**
   - Architecture du système
   - Flux d'authentification
   - Tâches cron
   - Fichiers d'état

### 3. **[Interface LuCI](LUCI.md)**
   - Accès et navigation
   - Gestion de la configuration
   - Contrôle du portail
   - Patches et logs

### 4. **[Patches personnalisés](PATCHES.md)**
   - Créer des patches
   - Déployer et exécuter
   - Cas d'usage courants
   - Bonnes pratiques

### 5. **[Logs et Monitoring](MONITORING.md)**
   - Accéder aux logs
   - Export et partage
   - Alerts Discord
   - Dashboard en temps réel

### 6. **[Dépannage](TROUBLESHOOTING.md)**
   - Solutions aux problèmes courants
   - Diagnostic complet
   - Debugging avancé
   - Support

## 🎯 Workflows courants

### Configuration initiale
1. Installer via SSH
2. Éditer `/root/scripts/portal_config.sh`
3. Tester l'authentification
4. Vérifier l'interface LuCI

👉 Voir [Configuration](CONFIGURATION.md)

### Utilisation quotidienne
1. Consulter l'interface LuCI
2. Vérifier le statut
3. Exporter les logs si besoin
4. Contacter support avec lien paste.rs

👉 Voir [Interface LuCI](LUCI.md)

### Déployer des modifications
1. Créer un patch shell
2. Uploader via LuCI
3. Exécuter et vérifier
4. Consulter l'historique

👉 Voir [Patches](PATCHES.md)

### Debugging
1. Vérifier les logs
2. Tester manuellement
3. Consulter le dépannage
4. Partager les logs avec support

👉 Voir [Monitoring](MONITORING.md) et [Dépannage](TROUBLESHOOTING.md)

## 🔍 Recherche rapide

**Besoin de...** | **Voir**
---|---
Configurer le portail | [Configuration](CONFIGURATION.md)
Changer l'URL du portail | [Configuration](CONFIGURATION.md)
Ajouter des alertes Discord | [Configuration](CONFIGURATION.md)
Comprendre le fonctionnement | [Fonctionnement](FONCTIONNEMENT.md)
Modifier les horaires cron | [Fonctionnement](FONCTIONNEMENT.md)
Accéder à l'interface web | [Interface LuCI](LUCI.md)
Uploader un patch | [Interface LuCI](LUCI.md) ou [Patches](PATCHES.md)
Créer un patch personnalisé | [Patches](PATCHES.md)
Voir les logs | [Monitoring](MONITORING.md)
Partager les logs | [Monitoring](MONITORING.md)
Résoudre un problème | [Dépannage](TROUBLESHOOTING.md)

## 🚀 Quick start

### Accès SSH
```bash
ssh root@openwrt.lan
cd /root/scripts
cat portal_config.sh
```

### Accès Web
```
http://openwrt.lan
Système > Services > Portail Captif
```

### Logs
```bash
logread | grep PORTAL_AUTH
tail -50 /tmp/portal_auth_cron.log
```

### Tester
```bash
sh /root/scripts/auth.sh
```

## 📞 Support

### Avant de demander de l'aide

1. ✅ Vérifiez la configuration
2. ✅ Testez manuellement
3. ✅ Consultez le dépannage
4. ✅ Collectez les logs
5. ✅ Exportez vers paste.rs

👉 Voir [Dépannage](TROUBLESHOOTING.md)

## 📝 Notes

- Toute la documentation est en Markdown
- Les exemples sont testés sur OpenWrt
- Pour les questions, consultez le dépannage d'abord
- N'hésitez pas à créer des patches personnalisés