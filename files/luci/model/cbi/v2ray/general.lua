local m, s, o
local v2ray = "v2ray"
local uci = luci.model.uci.cursor()

local v2ray_bin = uci:get_first(v2ray, "general", "v2ray_bin")

-- 命令是否存在
local function has_bin(name)
    return luci.sys.call("command -v %s >/dev/null" % { name }) == 0
end

-- 是否运行
local function is_running(name)
    return luci.sys.call("pidof %s >/dev/null" % { name }) == 0
end

-- 获取状态
local function get_status(b)
    return b and translate("RUNNING") or translate("NOT RUNNING")
end

local has_v2ray = has_bin(v2ray_bin)

--[[ 没有找到V2ray提示 ]] --
--if not has_v2ray then
--    return Map(v2ray, "%s - %s" % {
--        translate("V2ray"),
--        translate("General Settings")
--    }, '<b style="color:red">v2ray-core binary file not found.</b>')
--end

m = Map(v2ray, "%s - %s" % { translate("V2ray"), translate("General Settings") })
m.template = "v2ray/general"

--[[ 运行状态 ]] --

if has_v2ray then
    s = m:section(TypedSection, "general", translate("Running Status"))
    s.anonymous = true

    o = s:option(DummyValue, "_v2ray_status", translate("V2ray Service"))
    o.value = "<span id=\"_v2ray_status\">%s</span>" % { get_status(is_running('v2ray')) }
    o.rawhtml = true
end

--[[ 全局设置 ]] --
s = m:section(TypedSection, "general", translate("Global Settings"))
s.anonymous = true

if has_v2ray then
    o = s:option(Value, "startup_delay", translate("Startup Delay"))
    o:value(0, translate("Not enabled"))
    for _, v in ipairs({ 5, 10, 15, 25, 40 }) do
        o:value(v, translatef("%u seconds", v))
    end
    o.datatype = "uinteger"
    o.default = 0
    o.rmempty = false
end

o = s:option(Value, "v2ray_bin", translate("V2ray Installation Path"), has_v2ray and "" or translate("File does not exist"))
o.rmempty = false

--[[ 透明代理 ]] --
if has_v2ray then
    s = m:section(TypedSection, "transparent_proxy", translate("Proxy Settings"))
    s.anonymous = true

    -- 主服务器
    o = s:option(Value, "main_server", translate("Main Server"))
    o:value("nil", translate("Disabled"))
    uci:foreach(v2ray, "servers", function(s)
        if s.server and s.server_port then
            o:value(s[".name"], s.alias or "%s:%s" % { s.server, s.server_port })
        end
    end)
    o.default = "nil"
    o.rmempty = false

    o = s:option(Value, "tproxy_port", translate("Tproxy Port"))
    o.datatype = "port"
    o.default = 1080
    o.rmempty = false

    o = s:option(Value, "http_port", translate("Http Proxy Port"))
    o.datatype = "port"
    o.default = 1081
    o.rmempty = false

    o = s:option(Value, "socks_port", translate("Socks5 Proxy Port"))
    o.datatype = "port"
    o.default = 1082
    o.rmempty = false

    o = s:option(Value, "dns_port", translate("DNS Tunnel Port"))
    o.datatype = "port"
    o.default = 5300
    o.rmempty = false

    o = s:option(Value, "mark", translate("MARK"), translate("Avoid proxy loopback problems with local (gateway) traffic"))
    o.datatype = "uinteger"
    o.default = 255
    o.rmempty = false

    s = m:section(TypedSection, "dns", translate("DNS Settings"))
    s.anonymous = true

    o = s:option(Value, "fast_dns", translate("DNS for geosite:cn"))
    o.rmempty = false 

    o = s:option(Value, "secure_dns", translate("DNS for geosite:geolocation-!cn"))
    o.rmempty = false 

    o = s:option(Value, "default_dns", translate("Default DNS"))
    o.rmempty = false 
end

return m
