-- Copyright (C) 2006-2017 Alexey Kopytov <akopytov@gmail.com>

-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

-- Retrieved from Huawei for its internal benchmark
-- Modified by Liu Yuxuan for Barbell Loadgen on June 18th, 2024

-- ----------------------------------------------------------------------
-- General OLTP benchmark
-- ----------------------------------------------------------------------

-- local current_file_path = debug.getinfo(1, "S").source:sub(2)
-- local common_file_directory = current_file_path:match("(.*[/\\])")
-- package.path = package.path .. ";" .. common_file_directory .. "?.lua"
-- package.path = ";./?.lua" .. package.path
-- require("oltp_common")

protocol = {}

--- Software Timestamp
--- Should be declared here and implemented in C/C++
---@return integer
local function timestamp_soft()
    return 10
end

--- Hardware Timestamp
--- Should be declared here and implemented in C/C++
---@return integer
local function timestamp_hard()
    return 20
end

--- TODO: issue KVStore GET request
--- @param key string: key of GET request
--- @return boolean: whether the GET request miss or not
function protocol.get(key)
    return true
end

--- TODO: issue KVStore SET request
---@param key string: key of SET request
---@param value string: value of SET request
---@return boolean: whether the SET request succeeds
function protocol.set(key, value)    
    return false
end

--- TODO: randomly generate a string with fixed length
---@param size integer: length of the output string
---@return string: output string
local function get_rand_str(size)
    return "hello world"
end

local function event()
    local rand = math.random()
    if (rand < 0.05) then
        local key = get_rand_str(200)
        local value = get_rand_str(2000)
        local re_get = true
        if not protocol.get(key) then
            return
        end
        if not protocol.set(key, value) then
            error("Failed SET request")
            return
        end
        if (re_get) then
            protocol.get(key)            
        end
    elseif (rand < 0.05 + 0.90) then
        local key = get_rand_str(200)
        if not protocol.get(key) then
            error("GET miss")
        end
    else
        local key = get_rand_str(200)
        local value = get_rand_str(4000)
        if not protocol.set(key, value) then
            error("Failed SET request")
            return
        end
    end
end

event()
