module("luci.controller.v2ray", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/v2ray") then
        return
    end

    entry({ "admin", "vpn", "v2ray" },
        alias("admin", "vpn", "v2ray", "general"),
        _("V2ray"), 10).dependent = true

    entry({ "admin", "vpn", "v2ray", "general" },
        cbi("v2ray/general"),
        _("General Settings"), 10).leaf = true

    entry({ "admin", "vpn", "v2ray", "status" },
        call("action_status")).leaf = true

    entry({ "admin", "vpn", "v2ray", "servers" },
        arcombine(cbi("v2ray/servers"), cbi("v2ray/servers-details")),
        _("Servers Manage"), 20).leaf = true
end

function action_status()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        v2ray = luci.sys.call("pidof v2ray >/dev/null") == 0,
        rules = luci.sys.call("iptables-save | grep V2RAY | grep REDIRECT >/dev/null") == 0
    })
end
