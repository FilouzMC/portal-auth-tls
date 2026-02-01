# Dépannage

Guide complet pour résoudre les problèmes courants.

## Le script ne fonctionne pas

### Vérification 1 : Configuration existe

```bash
ls -la /root/scripts/portal_config.sh
```

**Si le fichier n'existe pas** :
1. Réinstallez via `install.sh`
2. OU créez manuellement :
   ```bash
   cat > /root/scripts/portal_config.sh << 'EOF'
   #!/bin/sh
   export BASE_URL="https://portail.exemple.com:8090"
   export PORTAL_USER="identifiant"
   export PORTAL_PASS="password"
   export DISCORD_WEBHOOK=""
   EOF
   chmod 600 /root/scripts/portal_config.sh
   ```

### Vérification 2 : Configuration valide

```bash
cat /root/scripts/portal_config.sh
```

**Assurez-vous que les variables sont correctes** :
- `BASE_URL` : URL complète avec `https://` et port (sans le / à la fin de l'URL)
- `PORTAL_USER` : Identifiant correct
- `PORTAL_PASS` : Mot de passe correct

### Vérification 3 : Tester manuellement

```bash
# Test simple
sh /root/scripts/auth.sh

# Avec debug détaillé
sh -x /root/scripts/auth.sh
```

### Vérification 4 : curl installé

```bash
curl --version

# Si absent
opkg update && opkg install curl
```

### Vérification 5 : Vérifier les logs

```bash
logread | grep -i portal
tail -50 /tmp/portal_auth_cron.log
```

## État OFFLINE constant

### Causes possibles

1. **Portail injoignable**
2. **Identifiants invalides**
3. **Mauvaise URL**
4. **Pas de connexion Internet**

### Diagnostic

```bash
# Test 1 : Ping Google
ping -c 1 8.8.8.8

# Test 2 : Joindre le portail
curl -v https://votre-portail.com:8090

# Test 3 : Vérifier l'URL
cat /root/scripts/portal_config.sh | grep BASE_URL

# Test 4 : Tester l'authentification
sh -x /root/scripts/auth.sh

# Test 5 : Vérifier les logs
tail -20 /tmp/portal_auth_cron.log
```

## Les crons ne s'exécutent pas

### Vérifier le service cron

```bash
# Statut
/etc/init.d/cron status

# Redémarrer
/etc/init.d/cron restart

# Voir les tâches
crontab -l
```

### Format crontab attendu

```
* * * * * /root/scripts/auth.sh >> /tmp/portal_auth_cron.log 2>&1
0 0 * * * /root/scripts/check_update.sh >> /tmp/portal_auth_check_update.log 2>&1
```

### Reconfigurer manuellement

```bash
# Afficher la crontab actuelle
crontab -l

# Supprimer et recréer
crontab -e

# Ajouter les lignes :
* * * * * /root/scripts/auth.sh >> /tmp/portal_auth_cron.log 2>&1
0 0 * * * /root/scripts/check_update.sh >> /tmp/portal_auth_check_update.log 2>&1
```

## Réponse vide du portail

### Causes

1. URL incorrecte
2. Portail down
3. Firewall bloquant
4. SSL/TLS incompatible

### Solutions

```bash
# Tester la connexion
curl -v https://votre-portail.com:8090

# Ignorer les erreurs SSL (test)
curl -k -v https://votre-portail.com:8090

# Voir les headers
curl -i https://votre-portail.com:8090

# Avec authentification
curl -u utilisateur:motdepasse https://votre-portail.com:8090
```

## Interface LuCI indisponible

### Vérifier l'installation LuCI

```bash
# LuCI installé ?
opkg list-installed | grep luci

# Réinstaller
opkg install luci-base luci-mod-admin-full

# Redémarrer uhttpd
/etc/init.d/uhttpd restart
```

### Accès web

Vérifiez l'URL dans le navigateur :
- `http://openwrt.lan` (localhost)
- `http://192.168.1.1` (ou IP du routeur)

Si le menu n'apparaît pas :
1. Videz le cache du navigateur
2. Essayez un autre navigateur
3. Redémarrez LuCI :
   ```bash
   /etc/init.d/uhttpd restart
   ```

## Uploads de patches ne fonctionnent pas

### Vérifications

```bash
# Vérifier le dossier des scripts
ls -la /root/scripts/

# Permissions
chmod 755 /root/scripts/

# Vérifier les logs
logread | grep -i patch
tail -20 /tmp/portal_auth_cron.log
```

### Règles de nommage

Le fichier DOIT :
- Contenir le mot `patch` dans le nom
- Finir par `.sh`
- Être un script shell valide

**Exemples valides** :
- `patch_wifi.sh` ✅
- `patch_custom_network.sh` ✅
- `my_patch.sh` ✅

**Exemples invalides** :
- `wifi.sh` ❌ (pas "patch")
- `patch_wifi.txt` ❌ (pas .sh)
- `patch_wifi` ❌ (pas d'extension)

## Logs et monitoring ne montrent rien

### Créer les fichiers manuellement

```bash
# Créer les fichiers de log
touch /tmp/portal_auth_cron.log
touch /tmp/portal_auth_check_update.log
mkdir -p /root/patches

# Permissions
chmod 666 /tmp/portal_auth_*.log
chmod 755 /root/patches
```

### Vérifier logread

```bash
# Voir les logs système
logread

# Vérifier que logread fonctionne
logread | wc -l

# Les logs du portail
logread | grep -i portal
```

## Erreur "Internal Server Error" (500) dans LuCI

### Causes communes

1. Permission denied (fichiers)
2. Erreur Lua (script)
3. Commande manquante
4. Configuration cassée

### Debugging

```bash
# Vérifier les permissions des fichiers
ls -la /root/scripts/
ls -la /root/patches/

# Vérifier le contenu de la config
cat /root/scripts/portal_config.sh

# Tester les scripts manuellement
sh /root/scripts/auth.sh
sh /root/scripts/logout.sh

# Voir les logs d'erreur système
logread | tail -50
```

### Solutions

```bash
# Permissions correctes
chmod 644 /root/scripts/portal_config.sh
chmod 755 /root/scripts/*.sh
chmod 755 /root/patches

# Recréer la config
rm /root/scripts/portal_config.sh
sh /root/scripts/auth.sh  # Va créer une template

# Redémarrer LuCI
/etc/init.d/uhttpd restart
```

## Problèmes de mise à jour automatique

### Vérifier les mises à jour

```bash
# Exécuter manuellement
sh /root/scripts/check_update.sh

# Voir les logs
cat /tmp/portal_auth_check_update.log
logread | grep -i "check_update"

# Vérifier les versions
cat /etc/portal_auth_version
```

### Désactiver les mises à jour (si problème)

```bash
crontab -e
# Commentez la ligne du check_update.sh
```

### Réinstaller la dernière version

```bash
sh /root/scripts/check_update.sh
```

## Erreur curl / HTTP

### Codes HTTP courants

| Code | Signification | Solution |
|------|---------------|----------|
| 200 | OK | ✅ Tout va bien |
| 401 | Non autorisé | Vérifier les identifiants |
| 403 | Interdit | Vérifier les permissions |
| 404 | Non trouvé | Vérifier l'URL |
| 500 | Erreur serveur | Serveur down |
| 503 | Indisponible | Portail down |

### Test manuel

```bash
# Voir les codes de réponse
curl -w "\nCode: %{http_code}\n" https://portail.exemple.com:8090

# Voir les headers
curl -i https://portail.exemple.com:8090

# Ignorer SSL (test only)
curl -k https://portail.exemple.com:8090

# Avec timeout
curl --max-time 5 https://portail.exemple.com:8090
```

## Discord Webhook ne fonctionne pas

### Vérifier la configuration

```bash
cat /root/scripts/portal_config.sh | grep DISCORD
```

### Tester le webhook

```bash
# Remplacer par votre URL
WEBHOOK="https://discord.com/api/webhooks/..."
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  $WEBHOOK
```

### Créer un nouveau webhook

1. Allez dans les paramètres du serveur Discord
2. **Intégrations > Webhooks > Créer un Webhook**
3. Sélectionnez le canal
4. Copiez l'URL
5. Mettez à jour la config : `DISCORD_WEBHOOK="..."`

## Besoin d'aide ?

### Collecter les informations

```bash
#!/bin/bash
echo "=== Diagnostic Complet ===" > diagnostic.txt
echo "" >> diagnostic.txt
echo "Version:" >> diagnostic.txt
cat /etc/portal_auth_version >> diagnostic.txt
echo "" >> diagnostic.txt
echo "État:" >> diagnostic.txt
cat /tmp/portal_auth_state >> diagnostic.txt
echo "" >> diagnostic.txt
echo "Configuration:" >> diagnostic.txt
cat /root/scripts/portal_config.sh >> diagnostic.txt
echo "" >> diagnostic.txt
echo "Logs récents:" >> diagnostic.txt
tail -50 /tmp/portal_auth_cron.log >> diagnostic.txt
echo "" >> diagnostic.txt
echo "Logread:" >> diagnostic.txt
logread | grep -i portal | tail -50 >> diagnostic.txt

# Télécharger le diagnostic
```

### Partager les logs

1. Allez dans LuCI
2. **Portail Captif > Logs Système > Partager via Paste**
3. Partagez le lien avec support
