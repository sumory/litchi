local semaphore = require("ngx.semaphore")
local string_format = string.format
local server = require("resty.websocket.server")
local cjson = require("cjson")
local mrandom = math.random
local Client = require("litchi.client")
local Dispather = require("litchi.dispatcher")
math.randomseed(ngx.now())

local context, dispather
local _M = {}




-- start a new client
function _M.start_client(context, dispather)
    local wb, err = server:new{
        timeout = 3600000, -- for test...
        max_payload_len = 65535,
    }

    if not wb then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end

    local client_id = mrandom(10000, 99999) -- mock id
    local sema = semaphore.new()
    local client = Client:new(client_id, wb, sema, dispather)
    ngx.log(ngx.INFO, string_format("[client][%d] login...", client.id))

    context.clients[client.id] = client
    client:send_msg() -- in another thread
    client:receive_msg() -- in main tread
    client:signin() -- login event broadcast, just for test
end


return _M

