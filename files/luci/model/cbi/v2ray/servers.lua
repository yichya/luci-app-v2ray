local m, s, o
local v2ray = "v2ray"

m = Map(v2ray, "%s - %s" % { translate("V2ray"), translate("Servers Manage") })

-- [[ 服务器列表 ]]--
s = m:section(TypedSection, "servers")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/vpn/v2ray/servers/%s")
function s.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(s.extedit % sid)
        return
    end
end

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "security", translate("Encrypt Method"))
function o.cfgvalue(...)
    local v = Value.cfgvalue(...)
    return v and v:upper() or "?"
end

--o = s:option(DummyValue, "plugin", translate("Plugin"))
--function o.cfgvalue(...)
--	return Value.cfgvalue(...) or translate("None")
--end

return m
