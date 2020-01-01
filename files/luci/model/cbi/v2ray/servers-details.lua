local m, s, o
local v2ray = "v2ray"
local sid = arg[1]
local securitys = {
    "auto",
    "none",
    "aes-128-gcm",
    "chacha20-poly1305"
}

m = Map(v2ray, "%s - %s" % { translate("V2ray"), translate("Edit Server") })
m.redirect = luci.dispatcher.build_url("admin/services/v2ray/servers")
m.sid = sid
--m.template = "v2ray/servers-details"

if m.uci:get(v2ray, sid) ~= "servers" then
    luci.http.redirect(m.redirect)
    return
end

-- [[ 编辑服务器 ]]--
s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false

-- [[ 基本信息 ]]--

-- 别名
o = s:option(Value, "alias", translate("Alias(optional)"))
o.rmempty = true

-- 服务器地址
o = s:option(Value, "server", translate("Server Address"))
o.rmempty = false

-- 服务器端口
o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

-- AlterId
o = s:option(Value, "alter_id", translate("AlterId"))
o.datatype = "port"
o.default = 16
o.rmempty = false

-- VmessId
o = s:option(Value, "vmess_id", translate("VmessId"))
o.rmempty = false

-- 加密方式
o = s:option(ListValue, "security", translate("Encrypt Method"))
for _, v in ipairs(securitys) do o:value(v, v:upper()) end
o.rmempty = false

-- 传输协议
o = s:option(ListValue, "transport", translate("Transport"))
o:value("tcp", "TCP")
o:value("kcp", "mKCP")
o:value("ws", "WebSocket")
o:value("h2", "HTTP/2")
o.rmempty = false

-- [[ TCP部分 ]]--

-- TCP伪装
o = s:option(ListValue, "tcp_guise", translate("Camouflage Type"))
o:depends("transport", "tcp")
o:value("none", translate("None"))
o:value("http", "HTTP")
o.rmempty = true

-- HTTP域名
o = s:option(DynamicList, "http_host", translate("HTTP Host"))
o:depends("tcp_guise", "http")
o.rmempty = true

-- HTTP路径
o = s:option(DynamicList, "http_path", translate("HTTP Path"))
o:depends("tcp_guise", "http")
o.rmempty = true

-- [[ WS部分 ]]--

-- WS域名
o = s:option(Value, "ws_host", translate("WebSocket Host"))
o:depends("transport", "ws")
o.rmempty = true

-- WS路径
o = s:option(Value, "ws_path", translate("WebSocket Path"))
o:depends("transport", "ws")
o.rmempty = true

-- [[ H2部分 ]]--

-- H2域名
o = s:option(DynamicList, "h2_host", translate("HTTP/2 Host"))
o:depends("transport", "h2")
o.rmempty = true

-- H2路径
o = s:option(Value, "h2_path", translate("HTTP/2 Path"))
o:depends("transport", "h2")
o.rmempty = true

-- [[ mKCP部分 ]]--

o = s:option(ListValue, "kcp_guise", translate("Camouflage Type"))
o:depends("transport", "kcp")
o:value("none", translate("None"))
o:value("srtp", translate("VideoCall (SRTP)"))
o:value("utp", translate("BitTorrent (uTP)"))
o:value("wechat-video", translate("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

o = s:option(Value, "mtu", translate("MTU"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 1350
o.rmempty = true

o = s:option(Value, "tti", translate("TTI"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 50
o.rmempty = true

o = s:option(Value, "uplink_capacity", translate("Uplink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 5
o.rmempty = true

o = s:option(Value, "downlink_capacity", translate("Downlink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 20
o.rmempty = true

o = s:option(Value, "read_buffer_size", translate("Read Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Value, "write_buffer_size", translate("Write Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Flag, "congestion", translate("Congestion"))
o:depends("transport", "kcp")
o.rmempty = true

-- [[ TLS ]]--
o = s:option(Flag, "tls", translate("TLS"))
o.rmempty = false

o = s:option(Value, "tls_host", translate("TLS Host"))
o:depends("tls", true)
o.rmempty = true

o = s:option(Flag, "tls_insecure", translate("Allow Insecure"))
o:depends("tls", true)
o.rmempty = false

return m
