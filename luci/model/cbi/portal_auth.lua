local fs  = require "nixio.fs"
local sys = require "luci.sys"

-- Map = page de config pour le fichier UCI "portal_auth"
local m = Map("portal_auth", translate("Portail Captif"),
    translate("Configuration de l'authentification automatique et du keep-alive pour le portail captif."))

-- Section unique "general" (config portal_auth 'general')
-- Type = "portal_auth" (comme dans /etc/config/portal_auth)
local s = m:section(TypedSection, "portal_auth", translate("Paramètres généraux"))
s.anonymous = true
s.addremove = false

-- ==========
--  CONFIG
-- ==========

-- Nom d'utilisateur du portail
local user = s:option(Value, "portal_user", translate("Nom d'utilisateur"))
user.datatype    = "string"
user.placeholder = "login portail"

-- Mot de passe du portail
local pass = s:option(Value, "portal_pass", translate("Mot de passe"))
pass.password    = true
pass.datatype    = "string"

-- Webhook Discord (optionnel)
local webhook = s:option(Value, "discord_webhook", translate("Webhook Discord"))
webhook.datatype    = "string"
webhook.placeholder = "https://discord.com/api/webhooks/..."

-- URL du portail
local base = s:option(Value, "base_url", translate("URL du portail"))
base.datatype    = "string"
base.placeholder = "https://exemple.fr:8090"

-- Fichier d'état (ONLINE / OFFLINE)
local state_file = s:option(Value, "state_file", translate("Fichier d'état simple"))
state_file.datatype    = "string"
state_file.placeholder = "/tmp/portal_auth_state"

-- Fichier de statut détaillé (CODE|Message)
local status_file = s:option(Value, "status_file", translate("Fichier de statut détaillé"))
status_file.datatype    = "string"
status_file.placeholder = "/tmp/portal_auth_status"

-- Dossier d'installation des scripts
local install_dir = s:option(Value, "install_dir", translate("Dossier des scripts"))
install_dir.datatype    = "string"
install_dir.placeholder = "/root/scripts"

-- ==========
--  VERSION
-- ==========

local ver = s:option(DummyValue, "_version", translate("Version installée"))

function ver.cfgvalue(self, section)
    local v = fs.readfile("/etc/portal_auth_version") or "inconnue"
    v = v:gsub("%s+$", "")   -- on enlève les \n et espaces fin de ligne
    return v
end

-- ==========
--  STATUT
-- ==========

local status = s:option(DummyValue, "_status", translate("Statut actuel"))

function status.cfgvalue(self, section)
    -- On récupère le chemin du fichier de statut depuis UCI
    local file = m.uci:get("portal_auth", section, "status_file") or "/tmp/portal_auth_status"

    local line = fs.readfile(file)
    if not line or line == "" then
        return translate("Aucune information (le script ne s'est pas encore exécuté).")
    end

    -- Format attendu : CODE|Message
    local code, msg = line:match("^(.-)%|(.*)$")
    code = code or "UNKNOWN"
    msg  = msg  or ""

    return string.format("%s - %s", code, msg)
end

-- ==========
--  BOUTON : TESTER MAINTENANT
-- ==========

local btn_test = s:option(Button, "_test", translate("Tester maintenant"))
btn_test.inputtitle = translate("Lancer un test de connexion")
btn_test.inputstyle = "apply"

function btn_test.write(self, section)
    -- On lance le script auth.sh en tâche de fond
    sys.call("/root/scripts/auth.sh >/tmp/portal_auth_manual.log 2>&1 &")
end

-- ==========
--  BOUTON : VÉRIFIER & METTRE À JOUR
-- ==========

local btn_update = s:option(Button, "_update", translate("Mises à jour"))
btn_update.inputtitle = translate("Vérifier et mettre à jour")
btn_update.inputstyle = "reset"

function btn_update.write(self, section)
    -- Lancement du check_update + éventuel update en tâche de fond
    sys.call("/root/scripts/check_update.sh >/tmp/portal_auth_update.log 2>&1 &")
end

return m
