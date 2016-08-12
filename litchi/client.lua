local setmetatable = setmetatable
local type = type
local string_format = string.format
local cjson = require("cjson")
local now = ngx.now

local function _start_receive_msg(client)
    local wb = client.wb
    local msg_count = 0

    while(true) do
        local data, typ, err = wb:recv_frame()
        msg_count = msg_count + 1
        
        if not data then
            ngx.log(ngx.ERR, "failed to receive a frame: ", err)
            return ngx.exit(444)
        end

        if typ == "close" then
            local bytes, err = wb:send_close(1000, "close now!")
            if not bytes then
                ngx.log(ngx.ERR, "failed to send the close frame: ", err)
                return
            end
            ngx.log(ngx.INFO, "closing with status code ", err, " and message ", data)
            return
        end

        if typ == "ping" then
            local bytes, err = wb:send_pong(data)
            if not bytes then
                ngx.log(ngx.ERR, "failed to send frame: ", err)
                return
            end
        elseif typ == "pong" then
            -- ignore pong msg
        else
            ngx.log(ngx.INFO, string_format("[client:%d] received a msg of type %s and payload [%s]", client.id, typ, data))

            local ok, body = pcall(function() return cjson.decode(data) end)
            if not ok or not body then
                ngx.log(ngx.ERR, "cannot decode payload to json")
            else

            end
        end

        -- wb:set_timeout(5000)  -- change the network timeout to 1 second
    end
end


local Client = {}

function Client:new(id, wb)
    local instance = {}
    instance.id = id
    instance.name = "client-" .. id
    instance.wb = wb
    instance.create_time = now()

    setmetatable(instance, {
        __index = self,
        __tostring = function(s)
            local ok, result = pcall(function()
                return "(id:" .. s.id .. "\tname:" .. s.name .. "\tcreate_time:" .. s.create_time .. ")"
            end)

            if ok then
                return result
            else
                return "Client.tostring() error"
            end
        end
    })
    return instance
end

function Client:receive_msg()
    ngx.thread.spawn(_start_receive_msg, self)
end

function Client:send_msg(msg)
    local bytes, err = self.wb:send_text(msg)
    if not bytes then
        ngx.log(ngx.ERR, "failed to send a text frame: ", err)
        return ngx.exit(444)
    end
end

function Client:close()
    local bytes, err = self.wb:send_close(1000, "close now..")
    if not bytes then
        ngx.log(ngx.ERR, "failed to send the close frame: ", err)
    end
end

return Client
