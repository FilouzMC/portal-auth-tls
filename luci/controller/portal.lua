-- LuCI Controller for Portal Auth TLS
module("luci.controller.portal", package.seeall)

function index()
    if not nixio.fs.access("/root/scripts/auth.sh") then
        return
    end

    entry({"admin", "system", "portal"}, call("action_index"), _("Portail Captif"), 60).dependent = true
    entry({"admin", "system", "portal", "run"}, call("action_run"), nil).leaf = true
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
