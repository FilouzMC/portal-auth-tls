# Fonctionnement

## Architecture

Le système fonctionne autour de trois scripts principaux :

1. **auth.sh** : Authentification et keep-alive (toutes les minutes)
2. **logout.sh** : Déconnexion du portail
3. **check_update.sh** : Vérification des mises à jour (00h00 quotidienne)

## Authentification automatique

Le script `auth.sh` s'exécute **automatiquement toutes les minutes** via cron :

### Flux d'exécution

1. **Test Internet** : Ping vers 8.8.8.8
   - ✅ Si OK → Envoie un keep-alive au portail
   - ❌ Si KO → Passe à l'étape suivante

2. **Test Portail** : Vérifie que le portail est joignable
   - ❌ Si injoignable → Alerte et sortie

3. **Connexion** : Tente l'authentification (mode=191)
   - ✅ Si réussite → Connexion établie
   - ❌ Si échec → Log l'erreur

### Exécution manuelle

```bash
# Lancer manuellement
sh /root/scripts/auth.sh

# Voir les logs en temps réel
logread -f | grep PORTAL_AUTH
```

## Déconnexion

### Manuelle

```bash
sh /root/scripts/logout.sh
```

### Automatique

Pas de déconnexion automatique. À faire manuellement ou via un script personnalisé.

## Mises à jour automatiques

Par défaut, le script `check_update.sh` s'exécute **chaque nuit à 00h00** :

### Processus

1. Compare la version locale (`/etc/portal_auth_version`) avec celle du dépôt GitHub (`version.txt`)
2. Si nouvelle version détectée → télécharge et lance automatiquement `install.sh`
3. La configuration existante (`portal_config.sh`) est **préservée** lors des mises à jour
4. Les configurations réseau sont réappliquées automatiquement

### Versions détectées

Toutes les versions (majeures, mineures et patches) sont prises en compte.

### Exécution manuelle

```bash
sh /root/scripts/check_update.sh
```

## Tâches Cron

### Voir les tâches configurées

```bash
crontab -l
```

### Format typique

```
* * * * * /root/scripts/auth.sh >> /tmp/portal_auth_cron.log 2>&1
0 0 * * * /root/scripts/check_update.sh >> /tmp/portal_auth_check_update.log 2>&1
```

### Modifier les tâches

```bash
crontab -e
```

**Exemples de modifications** :

- Exécuter `auth.sh` toutes les 5 minutes au lieu de 1 :
  ```
  */5 * * * * /root/scripts/auth.sh
  ```

- Exécuter `check_update.sh` tous les jours à 3h00 au lieu de 00h00 :
  ```
  0 3 * * * /root/scripts/check_update.sh
  ```

## Fichiers d'état

### État du portail

```bash
# État simple (ONLINE / OFFLINE)
cat /tmp/portal_auth_state
```

### Statut détaillé

```bash
# Statut détaillé (CODE|Message)
cat /tmp/portal_auth_status
```

Exemple :
```
200|Authentification réussie
```

### Version installée

```bash
cat /etc/portal_auth_version
```

## Logs système

```bash
# Voir tous les logs du portail
logread | grep PORTAL_AUTH

# Suivre les logs en temps réel
logread -f | grep PORTAL_AUTH
```

## Fichiers de log

### Logs d'authentification

```bash
cat /tmp/portal_auth_cron.log
```

### Logs de mise à jour

```bash
cat /tmp/portal_auth_check_update.log
```
