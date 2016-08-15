local setmetatable = setmetatable
local type = type
local string_format = string.format
local cjson = require("cjson")
local now = ngx.now


local Dispatcher = {}

function Dispatcher:new(context)
    local instance = {}
    instance.context = context
    instance.create_time = now()

    setmetatable(instance, {
        __index = self,
        __tostring = function(s)
            local ok, result = pcall(function()
                return "(dispatcher->create_time:" .. s.create_time .. ")"
            end)

            if ok then
                return result
            else
                return "Dispatcher.tostring() error"
            end
        end
    })
    return instance
end

function Dispatcher:dispatch(msg)
    if not msg or type(msg) ~= "table" then return end

    if msg.type == 0 then -- send to some uid
        self:send_to(msg.cid, msg.content)
    elseif msg.type == 1 then -- broadcast
        self:broadcast(msg.content)
    elseif msg.type == 2 then -- multicast
        self:multicast(msg.gid, msg.content)
    end
end

function Dispatcher:send_to(cid, content)
    local to_client = self.context.clients[cid]
    if to_client then
        to_client:notify(content)
    else
        ngx.log(ngx.INFO, "nil client to send: ", cid)
    end
end

function Dispatcher:broadcast(content)

end

function Dispatcher:multicast(gid, content)
    
end

function Dispatcher:find_client(cid)

end


return Dispatcher
