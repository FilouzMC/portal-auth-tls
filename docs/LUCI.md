# Interface LuCI

## Accès à l'interface

1. Ouvrez votre navigateur et allez sur `http://openwrt.lan` (ou l'IP de votre routeur)
2. Connectez-vous avec vos identifiants OpenWrt
3. Allez dans **Système > Services > Portail Captif**

## Sections disponibles

### 📊 Statut

Affiche l'état courant du portail captif en temps réel :
- **État** : ONLINE ou OFFLINE
- **Statut** : Message détaillé (code HTTP + description)
- Bouton **Rafraichir** : Mise à jour manuelle

### 🔐 Actions

Boutons pour contrôler les scripts principaux :

- **Authentifier** : Lance l'authentification immédiatement
- **Déconnecter** : Déconnecte du portail
- **Maj** : Télécharge la dernière version et redémarre

Le résultat de chaque action s'affiche dans une textarea en bas.

### ⚙️ Configuration

Éditez directement le fichier de configuration (`portal_config.sh`) via l'interface :

1. Cliquez sur **Charger** pour récupérer la configuration actuelle
2. Éditez le contenu (BASE_URL, identifiants, webhook Discord)
3. Cliquez sur **Sauvegarder** pour appliquer les modifications

**Fichier éditable** :
```bash
#!/bin/sh
export BASE_URL="https://portail.exemple.com:8090"
export PORTAL_USER="identifiant"
export PORTAL_PASS="mot_de_passe"
export DISCORD_WEBHOOK=""
```

### 🔧 Patches

Les patches permettent d'appliquer des modifications au système.

#### Upload Patch

1. Préparez un fichier `.sh` contenant votre patch
   - Le nom DOIT contenir `patch` (ex: `patch_custom_network.sh`)
2. Glissez-déposez le fichier dans la zone de dépôt OU cliquez pour sélectionner
3. Le fichier est automatiquement uploadé et rendu exécutable

#### Liste des Patches

Tableau affichant tous les patches disponibles avec trois actions :

- **RUN** : Exécute le patch immédiatement
  - Affiche le résultat avec timestamp
  - Historique enregistré automatiquement

- **VIEW** : Affiche le code source du patch
  - Permet de télécharger le fichier
  - Permet de consulter l'historique d'exécution

- **DEL** : Supprime le patch
  - Demande une confirmation
  - Supprime aussi l'historique
  - ⚠️ Il ne supprime pas les commandes mis en place !

### 📜 Logs Système

Gestion complète des logs système.

#### Exporter les logs

Bouton **Exporter** :
1. Récupère tous les logs système (`logread`)
2. Les affiche dans une textarea
3. Options disponibles :
   - **Télécharger** : Sauvegarde en fichier `.txt` local
   - **Copier** : Copie les logs dans le presse-papiers

#### Partager les logs

Bouton **Partager via Paste** :
1. Demande une **confirmation** (⚠️ données publiques)
2. Envoie tous les logs au service paste.rs
3. Génère un **lien public** pour partager

**Important** :
- ⚠️ Les logs sont accessibles publiquement via le lien
- 🔗 Lien permanent pour partage avec support technique

## Workflow typique

### Configuration initiale

1. **Installation** : Exécutez l'install.sh
2. **Configuration** : LuCI → Portail Captif → Configuration → Charger/Sauvegarder
3. **Test** : Cliquez sur **Authentifier**
4. **Vérification** : Consultez le **Statut**

### Maintenance

1. **Monitoring** : Consultez régulièrement le **Statut**
2. **Debugging** : Utilisez **Exporter** pour voir les logs
3. **Support** : **Partager via Paste** pour envoyer à un technicien
4. **Patches** : Uploadez et exécutez des patches personnalisés au besoin

### Dépannage

1. Accédez à l'interface LuCI
2. Consultez le **Statut** : message d'erreur ?
3. **Exporter** les logs pour analyser
4. **Authentifier** manuellement pour tester
5. Consultez `docs/TROUBLESHOOTING.md` pour solutions

## Points d'accès directs

| URL | Description |
|-----|-------------|
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/` | Portail Captif (tableau de bord) |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/status` | API - Statut JSON |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/run` | API - Exécuter script |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/config_get` | API - Récupérer config |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/config_set` | API - Sauvegarder config |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/export_logs` | API - Exporter logs |
| `http://openwrt.lan/cgi-bin/luci/admin/services/portal/paste_logs` | API - Partager logs |
