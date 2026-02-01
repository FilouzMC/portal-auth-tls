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
    entry({"admin", "services", "portal", "patches_list"}, call("action_patches_list"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_run"}, call("action_patch_run"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_view"}, call("action_patch_view"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_download"}, call("action_patch_download"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_logs"}, call("action_patch_logs"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_upload"}, call("action_patch_upload"), nil).leaf = true
    entry({"admin", "services", "portal", "patch_delete"}, call("action_patch_delete"), nil).leaf = true
    entry({"admin", "services", "portal", "export_logs"}, call("action_export_logs"), nil).leaf = true
    entry({"admin", "services", "portal", "paste_logs"}, call("action_paste_logs"), nil).leaf = true
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

function action_patches_list()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    local util = require "luci.util"
    
    local patches_dir = "/root/patches"
    local scripts_dir = "/root/scripts"
    
    fs.mkdir(patches_dir)
    
    local patches = {}
    
    if fs.access(scripts_dir) then
        for file in fs.dir(scripts_dir) do
            if file:match("patch") and file:match("%.sh$") then
                local path = scripts_dir .. "/" .. file
                local timestamp = util.exec("stat -c %Y " .. path .. " 2>/dev/null") or ""
                timestamp = timestamp:gsub("\n", "")
                table.insert(patches, {
                    name = file,
                    path = path,
                    timestamp = timestamp
                })
            end
        end
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, patches = patches })
end

function action_patch_run()
    local http = require "luci.http"
    local util = require "luci.util"
    local fs = require "nixio.fs"
    
    local patch_name = http.formvalue("patch")
    if not patch_name or not patch_name:match("patch") or not patch_name:match("%.sh$") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Patch invalide" })
        return
    end
    
    local patch_path = "/root/scripts/" .. patch_name
    if not fs.access(patch_path) then
        http.status(404, "Not Found")
        http.write_json({ success = false, output = "Patch non trouve" })
        return
    end
    
    fs.mkdir("/root/patches")
    
    local output = util.exec("sh " .. patch_path .. " 2>&1") or ""
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_file = "/root/patches/" .. patch_name .. ".log"
    
    local log_entry = "[" .. timestamp .. "] PATCH: " .. patch_name .. "\nOUTPUT:\n" .. output .. "\n---\n"
    local f = io.open(log_file, "a")
    if f then
        f:write(log_entry)
        f:close()
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, output = output, timestamp = timestamp })
end

function action_patch_view()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local patch_name = http.formvalue("patch")
    if not patch_name or not patch_name:match("patch") or not patch_name:match("%.sh$") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Patch invalide" })
        return
    end
    
    local patch_path = "/root/scripts/" .. patch_name
    if not fs.access(patch_path) then
        http.status(404, "Not Found")
        http.write_json({ success = false, output = "Patch non trouve" })
        return
    end
    
    local content = fs.readfile(patch_path) or ""
    
    http.prepare_content("application/json")
    http.write_json({ success = true, content = content })
end

function action_patch_download()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local patch_name = http.formvalue("patch")
    if not patch_name or not patch_name:match("patch") or not patch_name:match("%.sh$") then
        http.status(400, "Bad Request")
        return
    end
    
    local patch_path = "/root/scripts/" .. patch_name
    if not fs.access(patch_path) then
        http.status(404, "Not Found")
        return
    end
    
    local content = fs.readfile(patch_path) or ""
    
    http.prepare_content("application/octet-stream")
    http.header("Content-Disposition", "attachment; filename=" .. patch_name)
    http.write(content)
end

function action_patch_logs()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local patch_name = http.formvalue("patch")
    if not patch_name or not patch_name:match("patch") or not patch_name:match("%.sh$") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Patch invalide" })
        return
    end
    
    local log_file = "/root/patches/" .. patch_name .. ".log"
    local logs = ""
    
    if fs.access(log_file) then
        logs = fs.readfile(log_file) or ""
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, logs = logs })
end

function action_patch_upload()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local file = http.formvalue("file")
    local filename = http.formvalue("filename")
    
    if not file or not filename then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Fichier ou nom manquant" })
        return
    end
    
    if not filename:match("patch") or not filename:match("%.sh$") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Nom invalide (doit contenir 'patch' et finir par .sh)" })
        return
    end
    
    if filename:match("%.%.") or filename:match("/") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Nom avec chemin non autorise" })
        return
    end
    
    fs.mkdir("/root/scripts")
    
    local patch_path = "/root/scripts/" .. filename
    local f = io.open(patch_path, "w")
    if not f then
        http.status(500, "Error")
        http.write_json({ success = false, output = "Impossible d'ecrire le fichier" })
        return
    end
    
    f:write(file)
    f:close()
    
    fs.chmod(patch_path, "755")
    
    http.prepare_content("application/json")
    http.write_json({ success = true, output = "Patch " .. filename .. " uploaded" })
end

function action_patch_delete()
    local http = require "luci.http"
    local fs = require "nixio.fs"
    
    local patch_name = http.formvalue("patch")
    if not patch_name or not patch_name:match("patch") or not patch_name:match("%.sh$") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Patch invalide" })
        return
    end
    
    if patch_name:match("%.%.") or patch_name:match("/") then
        http.status(400, "Bad Request")
        http.write_json({ success = false, output = "Nom avec chemin non autorise" })
        return
    end
    
    local patch_path = "/root/scripts/" .. patch_name
    if not fs.access(patch_path) then
        http.status(404, "Not Found")
        http.write_json({ success = false, output = "Patch non trouve" })
        return
    end
    
    local ok = fs.remove(patch_path)
    if not ok then
        http.status(500, "Error")
        http.write_json({ success = false, output = "Impossible de supprimer le fichier" })
        return
    end
    
    local log_file = "/root/patches/" .. patch_name .. ".log"
    fs.remove(log_file)
    
    http.prepare_content("application/json")
    http.write_json({ success = true, output = "Patch " .. patch_name .. " supprime" })
end

function action_export_logs()
    local http = require "luci.http"
    local util = require "luci.util"
    
    local logs = util.exec("logread 2>/dev/null") or ""
    
    if logs == "" then
        logs = "Aucun log systeme trouve."
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, logs = logs })
end

function action_paste_logs()
    local http = require "luci.http"
    local util = require "luci.util"
    local fs = require "nixio.fs"
    
    local logs = util.exec("logread 2>/dev/null") or ""
    
    if logs == "" then
        logs = "Aucun log systeme trouve."
    end
    
    -- Write logs to temp file
    local tmpfile = "/tmp/portal_logs_" .. os.time() .. ".txt"
    local f = io.open(tmpfile, "w")
    if not f then
        http.prepare_content("application/json")
        http.write_json({ success = false, output = "Erreur creation fichier temp", url = "" })
        return
    end
    f:write(logs)
    f:close()
    
    -- Send to paste.rs
    local paste_service = "https://paste.rs"
    local output = util.exec("curl -s -X POST --data-binary @" .. tmpfile .. " " .. paste_service) or ""
    
    -- Clean up
    os.execute("rm -f " .. tmpfile)
    
    if output == "" or output:match("error") or output:match("Error") then
        http.prepare_content("application/json")
        http.write_json({ success = false, output = "Erreur lors de l'envoi au service de paste", url = "" })
        return
    end
    
    http.prepare_content("application/json")
    http.write_json({ success = true, output = "Logs uploades", url = output:gsub("\n", "") })
end
