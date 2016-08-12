local setmetatable = setmetatable
local type = type
local string_format = string.format
local cjson = require("cjson")
local now = ngx.now


local Dispatcher = {}

function Dispatcher:new(id)
    local instance = {}
    instance.id = id or 0
    instance.name = "dispatcher-" .. id
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
                return "Dispatcher.tostring() error"
            end
        end
    })
    return instance
end

function Dispatcher:send_to(cid, msg)
    
end

function Dispatcher:broadcast(msg)

end

function Dispatcher:multicast(gid, msg)
    
end


return Dispatcher
