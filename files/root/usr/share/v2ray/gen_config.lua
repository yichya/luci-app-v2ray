local ucursor = require "luci.model.uci"
local json = require "luci.jsonc"

local proxy_section = ucursor:get_first("v2ray", "transparent_proxy")
local proxy = ucursor:get_all("v2ray", proxy_section)

local server_section = proxy.main_server --"cfg044a8f"
local server = ucursor:get_all("v2ray", server_section)

local function direct_outbound()
    return {
        protocol = "freedom",
        tag = "direct",
        settings = {keep = ""},
        streamSettings = {
            sockopt = {
                mark = tonumber(proxy.mark)
            }
        }
    }
end

local function vmess_outbound()
    return {
        protocol = "vmess",
        tag = "vmess",
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
            tlsSettings = server.tls == "1" and 
                {
                    serverName = server.tls_host,
                    allowInsecure = server.tls_insecure == "0" and false or true
                } or nil,
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
    }
end

local function dokodemo_conf()
    return {
        port = proxy.local_port,
        protocol = "dokodemo-door",
        tag = "redirect_inbound",
        settings = {
            network = "tcp,udp",
            followRedirect = true
        },
        streamSettings = {
            sockopt = {
                tproxy = "redirect"
            }
        }
    }
end

local function dns_conf()
    return {
        port = proxy.dns_port,
        protocol = "dokodemo-door",
        settings = {
            address = "208.67.220.220",
            port = 443,
            network = "tcp,udp"
        }
    }
end

local function http_conf()
    return {
        port = proxy.http_port,
        protocol = "http",
        tag = "http_inbound",
        settings = {
            allowTransparent = false
        }
    }
end

local function socks_conf()
    return {
        port = proxy.socks_port,
        protocol = "socks",
        tag = "socks_inbound",
        settings = {
            udp = true
        }
    }
end

local v2ray = {
    -- 传入连接
    inbounds = {
        http_conf(),
        dokodemo_conf(),
        socks_conf(),
        dns_conf()
    },
    -- 传出连接
    outbounds = {
        vmess_outbound(),
        direct_outbound()
    },
    -- 路由
    routing = {
        domainStrategy = "AsIs",
        rules = {
            {
                type = "field",
                inboundTag = {"redirect_inbound"},
                outboundTag = "direct",
                ip = {"geoip:private"}
            },
            {
                type = "field",
                inboundTag = {"redirect_inbound"},
                outboundTag = "direct",
                ip = {"geoip:cn"}
            },
            {
                type = "field",
                inboundTag = {"redirect_inbound", "socks_inbound"},
                outboundTag = "vmess"
            }
        }
    },
}

print(json.stringify(v2ray, true))
