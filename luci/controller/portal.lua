-- LuCI Controller for Portal Auth TLS
module("luci.controller.portal", package.seeall)

function index()
    if not nixio.fs.access("/root/scripts/auth.sh") then
        return
    end

    entry({"admin", "services", "portal"}, call("action_index"), _("Portal Captif"), 60).dependent = true
    entry({"admin", "services", "portal", "run"}, call("action_run"), nil).leaf = true
    entry({"admin", "services", "portal", "status"}, call("action_status"), nil).leaf = true
    entry({"admin", "services", "portal", "config_get"}, call("action_config_get"), nil).leaf = true
    entry({"admin", "services", "portal", "config_set"}, call("action_config_set"), nil).leaf = true
end

function action_index()
    luci.template.render("portal/index")
end

function action_run()
    local http = require "luci.http"
    local util = require "luci.util"

    local script = http.formvalue("script")
    local allowed = {
        auth = "/root/scripts/auth.sh",
        logout = "/root/scripts/logout.sh",
        update = "/root/scripts/check_update.sh"
    }

    local path = allowed[script]
    if not path then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Script non autorisé" })
        return
    end

    local output = util.exec("sh " .. path .. " 2>&1") or ""

    http.prepare_content("application/json")
    http.write_json({ success = true, output = output })
end

function action_status()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local status_file = "/tmp/portal_auth_status"
    local state_file = "/tmp/portal_auth_state"
    
    local status_text = "Aucun statut disponible"
    local state_text = "UNKNOWN"
    
    if fs.access(status_file) then
        status_text = fs.readfile(status_file) or "Erreur lecture"
    end
    
    if fs.access(state_file) then
        state_text = fs.readfile(state_file) or "UNKNOWN"
    end
    
    status_text = status_text:gsub("\n", ""):gsub("\r", "")
    state_text = state_text:gsub("\n", ""):gsub("\r", "")
    
    http.prepare_content("application/json")
    http.write_json({ status = status_text, state = state_text })
end

function action_config_get()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local config_file = "/root/scripts/portal_config.sh"
    local content = ""
    
    if fs.access(config_file) then
        content = fs.readfile(config_file) or ""
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, content = content })
end

function action_config_set()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local config_file = "/root/scripts/portal_config.sh"
    local content = http.formvalue("content") or ""
    
    if not content or content == "" then
        http.prepare_content("application/json")
        http.write_json({ success = false, output = "Contenu vide" })
        return
    end
    
    local ok = fs.writefile(config_file, content)
    if ok then
        fs.chmod(config_file, "600")
        http.prepare_content("application/json")
        http.write_json({ success = true, output = "Config sauvegardée" })
    else
        http.status(500, "Error")
        http.prepare_content("application/json")
        http.write_json({ success = false, output = "Erreur écriture fichier" })
    end
end
