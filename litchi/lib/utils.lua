local pcall = pcall
local require = require
local json = require("cjson")


local _M = {}


function _M.json_encode(data, empty_table_as_object)
    local json_value
    if json.encode_empty_table_as_object then
        json.encode_empty_table_as_object(empty_table_as_object or false) -- 空的table默认为array
    end
    if require("ffi").os ~= "Windows" then
        json.encode_sparse_array(true)
    end
    pcall(function(data) json_value = json.encode(data) end, data)
    return json_value
end

function _M.json_decode(str)
    if not str then return nil end

    local json_object
    pcall(function(data)
        json_object = json.decode(data)
    end, str)
    return json_object
end


return _M
