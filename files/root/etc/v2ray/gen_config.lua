local ucursor = require "luci.model.uci"
local json = require "luci.jsonc"

local proxy_section = ucursor:get_first("v2ray", "transparent_proxy")
local proxy = ucursor:get_all("v2ray", proxy_section)

local server_section = proxy.main_server --"cfg044a8f"
local server = ucursor:get_all("v2ray", server_section)

local function gen_routing()
    local r = {
        {
            type = "field",
            outboundTag = "direct",
            ip = {"geoip:private"}
        }
    }
    if proxy.bypass_china_addr == "1" then
        table.insert(
            r,
            {
                type = "field",
                outboundTag = "direct",
                domain = {"geosite:cn"}
            }
        )
    end
    if proxy.bypass_china_ip == "1" then
        table.insert(
            r,
            {
                type = "field",
                outboundTag = "direct",
                ip = {"geoip:cn"}
            }
        )
    end
    if proxy.dns_enable == "1" then
        table.insert(r, {
            type = "field",
            inboundTag = {"dns_inbound", "dns_inbound_tag"},
            outboundTag = "dns_outbound"
        })
    end
    return r
end

local function dokodemo_conf()
    return {
        port = proxy.local_port,
        protocol = "dokodemo-door",
        settings = {
            network = "tcp,udp",
            followRedirect = true
        },
        streamSettings = {
            sockopt = {
                tproxy = "redirect"
            },
        },
        sniffing = {
            enabled = true,
            destOverride = {"http", "tls"}
        }
    }
end 

local function dns_conf() 
    return {
        port = proxy.ldns_port,
        protocol = "dokodemo-door",
        settings = {
            network = "tcp,udp",
        },
        tag = "dns_inbound",
        sniffing = {
            enabled = true,
            destOverride = {"http", "tls"}
        }
    }
end

local function socks_conf()
    return {
        port = proxy.socks_port,
        protocol = "socks",
        settings = {
            udp = true
        },
        sniffing = {
            enabled = true,
            destOverride = {"http", "tls"}
        }
    }
end

local function inbounds()
    t = {
        dokodemo_conf()
    }
    if proxy.socks_enable == "1" then
        table.insert(t, socks_conf())
    end
    if proxy.dns_enable == "1" then 
        table.insert(t, dns_conf()) 
    end
    return t
end

local v2ray = {
    -- 传入连接
    inbounds = inbounds(),
    -- 传出连接
    outbounds = {
        {
            protocol = "vmess",
            settings = {
                vnext = {
                    {
                        address = server.server,
                        port = tonumber(server.server_port),
                        users = {
                            {
                                id = server.vmess_id,
                                alterId = tonumber(server.alter_id),
                                security = server.security
                            }
                        }
                    }
                }
            },
            -- 底层传输配置
            streamSettings = {
                network = server.transport,
                security = (server.tls == "1") and "tls" or "none",
                sockopt = {
                    mark = tonumber(proxy.mark)
                },
                tcpSettings = server.transport == "tcp" and
                    {
                        header = {
                            type = server.tcp_guise,
                            request = server.tcp_guise == "http" and
                                {
                                    version = "1.1",
                                    method = "GET",
                                    path = server.http_path,
                                    headers = {
                                        Host = server.http_host,
                                        User_Agent = {
                                            "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                                            "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                                        },
                                        Accept_Encoding = {"gzip, deflate"},
                                        Connection = {"keep-alive"},
                                        Pragma = "no-cache"
                                    }
                                } or
                                nil,
                            response = server.tcp_guise == "http" and
                                {
                                    version = "1.1",
                                    status = "200",
                                    reason = "OK",
                                    headers = {
                                        Content_Type = {"application/octet-stream", "video/mpeg"},
                                        Transfer_Encoding = {"chunked"},
                                        Connection = {"keep-alive"},
                                        Pragma = "no-cache"
                                    }
                                } or
                                nil
                        }
                    } or
                    nil,
                kcpSettings = (server.transport == "kcp") and
                    {
                        mtu = tonumber(server.mtu),
                        tti = tonumber(server.tti),
                        uplinkCapacity = tonumber(server.uplink_capacity),
                        downlinkCapacity = tonumber(server.downlink_capacity),
                        congestion = (server.congestion == "1") and true or false,
                        readBufferSize = tonumber(server.read_buffer_size),
                        writeBufferSize = tonumber(server.write_buffer_size),
                        header = {
                            type = server.kcp_guise
                        }
                    } or
                    nil,
                wsSettings = (server.transport == "ws") and
                    {
                        path = server.ws_path,
                        headers = (server.ws_host ~= nil) and
                            {
                                Host = server.ws_host
                            } or
                            nil
                    } or
                    nil,
                httpSettings = (server.transport == "h2") and
                    {
                        path = server.h2_path,
                        host = server.h2_host
                    } or
                    nil
            }
        },
        {
            protocol = "freedom",
            tag = "direct",
            settings = {keep = ""},
            streamSettings = {
                sockopt = {
                    mark = tonumber(proxy.mark)
                }
            }
        }
    },
    -- 路由
    routing = {
        strategy = "rules",
        settings = {
            domainStrategy = "IPIfNonMatch",
            rules = gen_routing()
        }
    },
    dns = {
        servers = {
            {
                address = "114.114.114.114",
                port = "53",
                domains = {
                    "geosite:cn"
                }
            },
            "localhost"
        },
        clientIp = "202.99.166.4",
        tag = "dns_inbound_tag"
    }
}
print(json.stringify(v2ray))
