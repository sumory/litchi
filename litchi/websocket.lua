local server = require("resty.websocket.server")
local cjson = require("cjson")
local mrandom = math.random
local Client = require("litchi.client")
math.randomseed(ngx.now())



local function start_client()
    local wb, err = server:new{
        timeout = 3600000, -- 10s
        max_payload_len = 65535,
    }

    if not wb then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end

    local client = Client:new(mrandom(10000, 99999), wb)
    client:receive_msg()
end

-- invoke, start a new client
start_client()

