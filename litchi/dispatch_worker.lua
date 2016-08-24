--- worker级别的消息分发器，用于从queue里接收消息然后在w对应orker内部分发
local setmetatable = setmetatable
local type = type
local string_format= string.format
local os_exit = os.exit
local now = ngx.now
local utils = require("litchi.lib.utils")


local function calc_wait_time(last, last_get_result)
    -- deprecated
end

--- fetch msgs from worker queue and dispatch them to clients
-- the log only support ngx.ERR level
local function dispatch_msg_from_queue(dw)
    local queue, key, dispatcher, sema, limit, worker_id = dw.related_queue, dw.msg_key, dw.dispatcher, dw.sema, 10, dw.worker_id
    while(true) do
        local ok, err = sema:wait(60)
        if ok then
            local start = 0
            while start < limit do
                start = start + 1
                local msg, err = queue:rpop(key)
                if err then
                    ngx.log(ngx.ERR, string_format("dispatch worker %d consume msg, get error:%s", worker_id, err))
                    break
                elseif not msg then
                    ngx.log(ngx.ERR, string_format("dispatch worker %d consume msg, msg is nil", worker_id))
                    break
                elseif type(msg) == "string" then
                    local msg_object = utils.json_decode(msg)
                    if msg_object then
                        ngx.log(ngx.ERR, string_format("dispatch worker %d consume msg:%s", worker_id, msg))
                        dispatcher:dispatch(msg)
                    else
                        ngx.log(ngx.ERR, string_format("dispatch worker %d consume msg, parse error:%s", worker_id, err))
                    end
                end
            end
        elseif err == "timeout" then
            ngx.log(ngx.ERR, string_format("dispatch worker %d wait timeout....", worker_id))
        else
            ngx.log(ngx.ERR, string_format("semaphore wait error, dispatch_worker_id:%d, err:%s", id, err))
        end
    end
end


local _M = {}


--- init stuff...
function _M:new(dispatcher)
    local instance = {}
    instance.dispatcher = dispatcher
    instance.msg_queue_prefix = "msg_queue_"
    instance.msg_key = "msg"
    instance.worker_id = ngx.worker.id()
    instance.worker_count = ngx.worker.count()
    instance.msg_queue = instance.msg_queue_prefix .. instance.worker_id
    instance.related_queue = ngx.shared[instance.msg_queue]
    instance.create_time = now()

    local semaphore = require "ngx.semaphore"
    local sema, err = semaphore.new()
    if err or not sema then
        ngx.log(ngx.ERR, "create semaphore failed: ", err)
        os_exit(1)
    end
    instance.sema = sema

    setmetatable(instance, {
        __index = self,
        __tostring = function(s)
            local ok, result = pcall(function()
                return "(dispatch_worker->create_time:" .. s.create_time .. ")"
            end)

            if ok then
                return result
            else
                return "DispatchWorker.tostring() error"
            end
        end
    })

    ngx.log(ngx.ERR, "dispatch worker ", instance.worker_id, " is running...")
    return instance
end

function _M:notify()
    self.sema:post(1)
end

function _M:dispatch()
    ngx.thread.spawn(dispatch_msg_from_queue, self)
end


return _M
