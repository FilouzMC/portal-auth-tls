module("luci.controller.portal_auth", package.seeall)

function index()
    local fs = require "nixio.fs"

    -- On affiche le menu seulement si la config existe
    if not fs.access("/etc/config/portal_auth") then
        return
    end

    -- Menu : Administration -> Services -> Portail Captif
    entry(
        {"admin", "services", "portal_auth"},
        cbi("portal_auth"),
        _("Portail Captif"),
        30
    ).dependent = true
end
