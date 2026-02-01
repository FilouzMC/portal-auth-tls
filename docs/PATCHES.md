# Patches personnalisés

Les patches permettent d'appliquer des modifications personnalisées au système via LuCI.

## Créer un patch

### Structure

Un patch est un simple script shell `.sh` avec :
- **Nom** : DOIT contenir le mot `patch` (ex: `patch_custom_network.sh`)
- **Extension** : `.sh` obligatoire
- **Contenu** : Commandes shell standard
- ⚠️ **Ne pas exécuter n'importe quoi !**

## Déployer un patch

### Via LuCI (Graphique)

1. Allez dans **Services > Portail Captif**
2. Section **Upload Patch**
3. Glissez-déposez votre fichier `.sh` OU cliquez pour sélectionner
4. Le fichier est uploadé automatiquement

### Via SSH (Ligne de commande)

```bash
# Copier le patch sur le routeur
scp patch_custom.sh root@openwrt.lan:/root/scripts/

# Rendre exécutable
ssh root@openwrt.lan chmod +x /root/scripts/patch_custom.sh

# Exécuter
ssh root@openwrt.lan sh /root/scripts/patch_custom.sh
```

## Exécuter un patch

### Via LuCI

1. Dans la **Liste des Patches**, cliquez sur **RUN**
2. Le résultat s'affiche avec :
   - Timestamp d'exécution
   - Code de succès [OK] ou [FAIL]
   - Sortie complète du script

### Via SSH

```bash
sh /root/scripts/patch_custom.sh
```

## Consulter l'historique

### Via LuCI

1. Dans la **Liste des Patches**, cliquez sur **VIEW**
2. Cliquez sur **Voir logs**
3. L'historique complet s'affiche

### Via SSH

```bash
# Voir l'historique d'un patch
cat /root/patches/patch_custom.log
```

## Supprimer un patch

### Via LuCI

1. Dans la **Liste des Patches**, cliquez sur **DEL**
2. Confirmez la suppression
3. Le fichier et son historique sont supprimés

### Via SSH

```bash
# Supprimer le patch
rm /root/scripts/patch_custom.sh

# Supprimer l'historique
rm /root/patches/patch_custom.log
```

## Bonnes pratiques

### À faire ✅

- **Commentez votre code** : Expliquez ce que fait le patch
- **Testez d'abord** : Testez le script manuellement avant de l'uploader
- **Vérifiez les dépendances** : Assurez-vous que les outils existent (ex: `uci`)
- **Utilisez des chemins absolus** : `/root/scripts/` plutôt que `./scripts/`
- **Captez les erreurs** : Utilisez `set -e` pour arrêter en cas d'erreur
- **Affiche des messages** : `echo` pour tracer l'exécution

### À éviter ❌

- Ne supprimez pas `/root/scripts/` !
- Ne modifiez pas `portal_config.sh` directement dans un patch
- Ne modifiez pas les tâches cron
- N'oubliez pas l'extension `.sh`
- N'oubliez pas le mot `patch` dans le nom

## Debugging

### Afficher les logs en temps réel

```bash
# SSH sur le routeur
ssh root@openwrt.lan

# Suivre les logs du patch
logread -f | grep -i patch
```

### Tester un patch manuellement

```bash
# SSH sur le routeur
ssh root@openwrt.lan

# Exécuter avec debug
sh -x /root/scripts/patch_custom.sh
```

### Vérifier l'historique d'exécution

```bash
cat /root/patches/patch_custom.log
tail -50 /root/patches/patch_custom.log  # Dernières 50 lignes
```
