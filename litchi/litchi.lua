local singleton = require("litchi.singleton")
local Dispather = require("litchi.dispatcher")
local DispathWorker = require("litchi.dispatch_worker")

local Litchi = {}

function Litchi.init()
    local status, err = pcall(function()
        singleton.data = {
            clients = {}, -- cid --> client
            groups = {},
            users = {}
        }
        singleton.dispatch_workers = {}
        singleton.dispather = Dispather:new(singleton.context)
    end)

    if not status then
        ngx.log(ngx.ERR, "init error: ", err)
        os.exit(1)
    end

    Litchi.context = singleton
end

function Litchi.init_worker()
    local dispatch_worker = DispathWorker:new(singleton.dispather)
    local worker_id = ngx.worker.id()
    ngx.log(ngx.ERR, "-------", worker_id)
    
    ngx.timer.at(0, function()
        dispatch_worker:dispatch()
    end)

    singleton.dispatch_workers[worker_id] = dispatch_worker
end


return Litchi
