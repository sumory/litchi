local setmetatable = setmetatable
local type = type
local tostring = tostring
local string_format = string.format
local table_insert = table.insert
local cjson = require("cjson")
local now = ngx.now

local function _start_receive_msg(client)
    local wb = client.wb
    local dispatcher = client.dispatcher
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
            ngx.log(ngx.INFO, string_format("[client:%d] receive a msg， type %s， payload [%s]", client.id, typ, data))

            local ok, body = pcall(function() return cjson.decode(data) end)
            if not ok or not body then
                ngx.log(ngx.ERR, "cannot decode payload to json")
            else
                dispatcher:dispatch(body)
            end
        end
    end
end

local function _start_send_msg(client)
    local id = client.id
    local wb = client.wb
    local msg_count = 0

    while(true) do
        local ok, err = client.sema:wait(3*60)
        if ok then
            local send_queue = client.data
            local i = 1 
            while send_queue[i] do
                local content = table.remove(send_queue,i)
                i = i+1 

                if type(content) ~= "string" then content = tostring(content) end

                ngx.log(ngx.INFO, "send to client:", id, " content:", content)
                local bytes, err = wb:send_text(content)
                if not bytes then
                    ngx.log(ngx.ERR, "failed to send msg, client_id:", id, " err:" , err)
                    return ngx.exit(444)
                end
            end
        elseif err == "timeout" then
            ngx.log(ngx.INFO, "client wait timeout....")
        else
            ngx.log(ngx.ERR, "semaphore wait error, client_id:", id, " err:" , err)
        end
    end
end


local Client = {}

function Client:new(id, wb, sema, dispatcher)
    local instance = {}
    instance.id = id
    instance.name = "client-" .. id
    instance.wb = wb
    instance.sema = sema
    instance.dispatcher = dispatcher
    instance.receive_co = nil -- receive thread
    instance.send_co = nil
    instance.data = {}
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
    local receive_co = ngx.thread.spawn(_start_receive_msg, self)
    self.receive_co = receive_co
end

function Client:send_msg(content)
    local send_co = ngx.thread.spawn(_start_send_msg, self)
    self.send_co = send_co
end

function Client:notify(content)
    table_insert(self.data, content)
    self.sema:post(1)
end

function Client:close()
    local bytes, err = self.wb:send_close(1000, "close now..")
    if not bytes then
        ngx.log(ngx.ERR, "failed to send the close frame: ", err)
    end
end

return Client
