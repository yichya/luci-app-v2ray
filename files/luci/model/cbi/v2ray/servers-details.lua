local m, s, o
local v2ray = "v2ray"
local sid = arg[1]

m = Map(v2ray, "%s - %s" % { translate("V2ray"), translate("Edit Server") })
m.redirect = luci.dispatcher.build_url("admin/vpn/v2ray/servers")
m.sid = sid

if m.uci:get(v2ray, sid) ~= "servers" then
    luci.http.redirect(m.redirect)
    return
end

s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false

o = s:option(Value, "alias", translate("Alias (optional)"))
o.rmempty = true

o = s:option(ListValue, "protocol", translate("Protocol"))
o:value("vmess", "VMess")
o:value("vless", "VLESS")
o:value("trojan", "Trojan")
o:value("shadowsocks", "Shadowsocks")
o.rmempty = false

o = s:option(Value, "server", translate("Server Address"))
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "password", translate("UserId / Password"))
o.rmempty = false

o = s:option(ListValue, "transport", translate("Transport"))
o:value("tcp", "TCP")
o:value("mkcp", "mKCP")
o:value("ws", "WebSocket")
o:value("h2", "HTTP/2")
o:value("quic", "QUIC")
o.rmempty = false

o = s:option(ListValue, "tcp_guise", translate("[tcp] Fake Header Type"))
o:depends("transport", "tcp")
o:value("none", translate("None"))
o:value("http", "HTTP")
o.rmempty = true

o = s:option(DynamicList, "http_host", translate("[tcp][fake_http] Host"))
o:depends("tcp_guise", "http")
o.rmempty = true

o = s:option(DynamicList, "http_path", translate("[tcp][fake_http] Path"))
o:depends("tcp_guise", "http")
o.rmempty = true

o = s:option(ListValue, "mkcp_guise", translate("[mkcp] Fake Header Type"))
o:depends("transport", "mkcp")
o:value("none", translate("None"))
o:value("srtp", translate("VideoCall (SRTP)"))
o:value("utp", translate("BitTorrent (uTP)"))
o:value("wechat-video", translate("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

o = s:option(Value, "mkcp_mtu", translate("[mkcp] Maximum Transmission Unit"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 1350
o.rmempty = true

o = s:option(Value, "mkcp_tti", translate("[mkcp] Transmission Time Interval"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 50
o.rmempty = true

o = s:option(Value, "mkcp_uplink_capacity", translate("[mkcp] Uplink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 5
o.rmempty = true

o = s:option(Value, "mkcp_downlink_capacity", translate("[mkcp] Downlink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 20
o.rmempty = true

o = s:option(Value, "mkcp_read_buffer_size", translate("[mkcp] Read Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 2
o.rmempty = true

o = s:option(Value, "mkcp_write_buffer_size", translate("[mkcp] Write Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "mkcp")
o.default = 2
o.rmempty = true

o = s:option(Flag, "mkcp_congestion", translate("[mkcp] Congestion Control"))
o:depends("transport", "mkcp")
o.rmempty = true

o = s:option(Value, "mkcp_seed", translate("[mkcp] Seed"))
o:depends("transport", "mkcp")
o.rmempty = true

o = s:option(ListValue, "quic_security", translate("[quic] Security"))
o:depends("transport", "quic")
o:value("none", "none") 
o:value("aes-128-gcm", "aes-128-gcm") 
o:value("chacha20-poly1305", "chacha20-poly1305") 
o.rmempty = false

o = s:option(Value, "quic_key", translate("[quic] Key"))
o:depends("transport", "quic")
o.rmempty = true

o = s:option(ListValue, "quic_guise", translate("[quic] Fake Header Type"))
o:depends("transport", "quic")
o:value("none", translate("None"))
o:value("srtp", translate("VideoCall (SRTP)"))
o:value("utp", translate("BitTorrent (uTP)"))
o:value("wechat-video", translate("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

o = s:option(DynamicList, "h2_host", translate("[http2] Host"))
o:depends("transport", "h2")
o.rmempty = true

o = s:option(Value, "h2_path", translate("[http2] Path"))
o:depends("transport", "h2")
o.rmempty = true

o = s:option(Value, "ws_host", translate("[websocket] Host"))
o:depends("transport", "ws")
o.rmempty = true

o = s:option(Value, "ws_path", translate("[websocket] Path"))
o:depends("transport", "ws")
o.rmempty = true

o = s:option(ListValue, "shadowsocks_security", translate("[shadowsocks] Encrypt Method"))
o:depends("protocol", "shadowsocks")
o:value("none", "none") 
o:value("aes-256-gcm", "aes-256-gcm") 
o:value("aes-128-gcm", "aes-128-gcm") 
o:value("chacha20-poly1305", "chacha20-poly1305") 
o.rmempty = false

o = s:option(ListValue, "shadowsocks_tls", translate("[shadowsocks] Stream Security"))
o:depends("protocol", "shadowsocks")
o:value("none", "None")
o:value("tls", "TLS")
o.rmempty = false

o = s:option(Value, "shadowsocks_tls_host", translate("[shadowsocks][tls] Server Name"))
o:depends("shadowsocks_tls", "tls")
o.rmempty = true

o = s:option(Flag, "shadowsocks_tls_insecure", translate("[shadowsocks][tls] Allow Insecure"))
o:depends("shadowsocks_tls", "tls")
o.rmempty = false

o = s:option(ListValue, "trojan_tls", translate("[trojan] Stream Security"))
o:depends("protocol", "trojan")
o:value("none", "None")
o:value("tls", "TLS")
o:value("xtls", "XTLS")
o.rmempty = false

o = s:option(Value, "trojan_tls_host", translate("[trojan][tls] Server Name"))
o:depends("trojan_tls", "tls")
o.rmempty = true

o = s:option(Flag, "trojan_tls_insecure", translate("[trojan][tls] Allow Insecure"))
o:depends("trojan_tls", "tls")
o.rmempty = false

o = s:option(Value, "trojan_xtls_host", translate("[trojan][xtls] Server Name"))
o:depends("trojan_tls", "xtls")
o.rmempty = true

o = s:option(Flag, "trojan_xtls_insecure", translate("[trojan][xtls] Allow Insecure"))
o:depends("trojan_tls", "xtls")
o.rmempty = false

o = s:option(ListValue, "vmess_security", translate("[vmess] Encrypt Method"))
o:depends("protocol", "vmess")
o:value("none", "none") 
o:value("auto", "auto") 
o:value("aes-128-gcm", "aes-128-gcm") 
o:value("chacha20-poly1305", "chacha20-poly1305") 
o.rmempty = false

o = s:option(ListValue, "vmess_alter_id", translate("[vmess] AlterId"))
o:depends("protocol", "vmess")
o:value(0, "0 (this enables VMessAEAD)")
o:value(1, "1")
o:value(4, "4")
o:value(16, "16")
o:value(64, "64")
o:value(256, "256")
o.rmempty = false

o = s:option(ListValue, "vmess_tls", translate("[vmess] Stream Security"))
o:depends("protocol", "vmess")
o:value("none", "None")
o:value("tls", "TLS")
o.rmempty = false

o = s:option(Value, "vmess_tls_host", translate("[vmess][tls] Server Name"))
o:depends("vmess_tls", "tls")
o.rmempty = true

o = s:option(Flag, "vmess_tls_insecure", translate("[vmess][tls] Allow Insecure"))
o:depends("vmess_tls", "tls")
o.rmempty = false

o = s:option(ListValue, "vless_encryption", translate("[vless] Encrypt Method"))
o:depends("protocol", "vless")
o:value("none", "none") 
o.rmempty = false

o = s:option(ListValue, "vless_flow", translate("[vless] Flow"))
o:depends("protocol", "vless")
o:value("", "[none]")
o:value("xtls-rprx-origin", "xtls-rprx-origin")
o:value("xtls-rprx-direct", "xtls-rprx-direct")
o:value("xtls-rprx-origin-udp443", "xtls-rprx-origin-udp443")
o:value("xtls-rprx-direct-udp443", "xtls-rprx-direct-udp443")
o.rmempty = false

o = s:option(ListValue, "vless_tls", translate("[vless] Stream Security"))
o:depends("protocol", "vless")
o:value("none", "None")
o:value("tls", "TLS")
o:value("xtls", "XTLS")
o.rmempty = false

o = s:option(Value, "vless_tls_host", translate("[vless][tls] Server Name"))
o:depends("vless_tls", "tls")
o.rmempty = true

o = s:option(Flag, "vless_tls_insecure", translate("[vless][tls] Allow Insecure"))
o:depends("vless_tls", "tls")
o.rmempty = false

o = s:option(Value, "vless_xtls_host", translate("[vless][xtls] Server Name"))
o:depends("vless_tls", "xtls")
o.rmempty = true

o = s:option(Flag, "vless_xtls_insecure", translate("[vless][xtls] Allow Insecure"))
o:depends("vless_tls", "xtls")
o.rmempty = false

return m
