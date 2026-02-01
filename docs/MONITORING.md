# Logs et Monitoring

## Vue d'ensemble

Le système fournit plusieurs niveaux de logging et de monitoring pour diagnostiquer les problèmes.

## Logs système (syslog)

### Afficher tous les logs du portail

```bash
logread | grep PORTAL_AUTH
```

### Suivre les logs en temps réel

```bash
logread -f | grep PORTAL_AUTH
```

### Filtrer par script

```bash
# Logs de l'authentification
logread | grep -i auth

# Logs de la mise à jour
logread | grep -i "check_update"

# Logs des patches
logread | grep -i patch
```

## Fichiers de log

### Logs d'authentification

```bash
cat /tmp/portal_auth_cron.log
tail -50 /tmp/portal_auth_cron.log  # Dernières 50 lignes
```

### Logs de mise à jour

```bash
cat /tmp/portal_auth_check_update.log
tail -50 /tmp/portal_auth_check_update.log
```

### Logs des patches

```bash
cat /root/patches/patch_custom_network.log
tail -100 /root/patches/patch_custom_network.log
```

## État du portail

### État simple

```bash
cat /tmp/portal_auth_state
```

Valeurs possibles :
- `ONLINE` : Connecté au portail
- `OFFLINE` : Non connecté ou erreur

### Statut détaillé

```bash
cat /tmp/portal_auth_status
```

Format : `CODE|Message`

**Exemples** :
```
200|Authentification réussie
401|Identifiants invalides
503|Portail injoignable
```

### Version installée

```bash
cat /etc/portal_auth_version
```

## Export des logs

### Via LuCI

1. **Système > Services > Portail Captif**
2. Section **Logs Système**
3. Cliquez sur **Exporter**
4. Options :
   - **Télécharger** : Fichier `.txt` local
   - **Copier** : Presse-papiers

### Via SSH

```bash
# Exporter tous les logs
logread > logs.txt

# Filtrer les logs du portail
logread | grep PORTAL_AUTH > portal_logs.txt

# Créer une archive complète
tar czf logs-backup-$(date +%Y%m%d).tar.gz \
    /tmp/portal_auth_cron.log \
    /tmp/portal_auth_check_update.log \
    /root/patches/*.log
```

## Partage des logs

### Via LuCI

1. **Système > Services > Portail Captif**
2. Section **Logs Système**
3. Cliquez sur **Partager via Paste**
4. Confirmez l'avertissement
5. Copiez le lien généré

**Important** :
- ⚠️ Les logs sont publics et accessibles via le lien
- ✅ Les données personnelles ne sont pas incluses
- 🔗 Idéal pour partager avec support technique

### Service de paste

Utilise **paste.rs** (service public sans expiration automatique).

Format du lien : `https://paste.rs/<id>`

## Alertes Discord (optionnel)

### Configuration

Dans `/root/scripts/portal_config.sh` :

```bash
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/123456789/abcdefgh..."
```

### Alertes reçues

- ⚠️ **Portail injoignable** : Impossible de joindre le portail
- 🔥 **Échec de connexion** : Authentification échouée
- ✅ **Connexion rétablie** : Reconnexion réussie après erreur

### Créer un webhook

1. Allez dans les **Paramètres du serveur Discord**
2. **Intégrations > Webhooks > Créer un Webhook**
3. Sélectionnez le canal (ex: #notifications)
4. Copiez l'URL
5. Collez-la dans la configuration

## Monitoring en temps réel

### Terminal 1 : Suivre les logs

```bash
ssh root@openwrt.lan logread -f | grep PORTAL
```

### Terminal 2 : Vérifier l'état

```bash
ssh root@openwrt.lan 'while sleep 5; do clear; echo "=== État ==="; cat /tmp/portal_auth_state; echo "=== Statut ==="; cat /tmp/portal_auth_status; done'
```

## Diagnostic rapide

### Vérifier que tout fonctionne

```bash
#!/bin/bash
echo "=== Vérification du système ==="

# 1. Vérifier que les scripts existent
echo "✓ Scripts:"
ssh root@openwrt.lan ls -1 /root/scripts/*.sh

# 2. Vérifier l'état
echo ""
echo "✓ État:"
ssh root@openwrt.lan cat /tmp/portal_auth_state

# 3. Vérifier la version
echo ""
echo "✓ Version:"
ssh root@openwrt.lan cat /etc/portal_auth_version

# 4. Vérifier crontab
echo ""
echo "✓ Crontab:"
ssh root@openwrt.lan crontab -l | grep -E "(auth|check_update)"

# 5. Vérifier les logs récents
echo ""
echo "✓ Derniers logs:"
ssh root@openwrt.lan tail -3 /tmp/portal_auth_cron.log

echo ""
echo "Diagnostic terminé"
```

## Troubleshooting via logs

### Problème : État OFFLINE constant

1. **Vérifier l'authentification** :
   ```bash
   ssh root@openwrt.lan sh /root/scripts/auth.sh
   ```

2. **Vérifier la configuration** :
   ```bash
   ssh root@openwrt.lan cat /root/scripts/portal_config.sh
   ```

3. **Vérifier la connexion Internet** :
   ```bash
   ssh root@openwrt.lan ping 8.8.8.8
   ```

4. **Vérifier curl** :
   ```bash
   ssh root@openwrt.lan curl --version
   ```

### Problème : Les crons ne s'exécutent pas

```bash
# Vérifier le service cron
ssh root@openwrt.lan /etc/init.d/cron status

# Redémarrer cron
ssh root@openwrt.lan /etc/init.d/cron restart

# Vérifier les tâches
ssh root@openwrt.lan crontab -l
```

### Problème : Logs vides

```bash
# Vérifier les permissions
ssh root@openwrt.lan ls -la /root/scripts/auth.sh

# Vérifier logread
ssh root@openwrt.lan logread | wc -l
```
