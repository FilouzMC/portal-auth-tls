module("luci.controller.portal_auth", package.seeall)

function index()
    entry({"admin", "services", "portal_auth"}, template("portal_auth"), _("Portal Auth"), 60)
    entry({"admin", "services", "portal_auth", "auth"}, call("action_auth"))
    entry({"admin", "services", "portal_auth", "logout"}, call("action_logout"))
    entry({"admin", "services", "portal_auth", "check_update"}, call("action_check_update"))
end

function action_auth()
    local result = luci.sys.exec("/root/scripts/auth.sh 2>&1")
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        output = result
    })
end

function action_logout()
    local result = luci.sys.exec("/root/scripts/logout.sh 2>&1")
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        output = result
    })
end

function action_check_update()
    local result = luci.sys.exec("/root/scripts/check_update.sh 2>&1")
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        output = result
    })
end
