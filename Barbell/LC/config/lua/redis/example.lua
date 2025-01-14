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

-- --- Server
-- barbell = {
--     opt = {
--         server = "redis",
--         ip = "127.0.0.1",
--         port = 6379,
--         auth_username = "barbell",
--         auth_password = "barbell",
--         ssh_username = "yuang",
--         ssh_password = "fghjkl;'",
--         --- Client
--         mode = "open",
--         threads = 1,
--         connections = 1,
--         --- output customization
--         output_root_dirname = "/home/yuang/yuxuan/Barbell/LC/config/lua/redis",
--         output_dirname = "output",
--         --- Trace (Load)
--         num_periods = 1,
--         trace_type = "qps",
--         trace = { 100, 100, 100, 100, 100 },
--         --- Duration
--         warmup = 5,
--         formal = #trace,
--         cooldown = 5,
--         --- Statistic Logging
--         report_interval = 1,
--         percentile_latency = { 50, 90, 95, 99 },
--         data_to_collect = "cpu",
--         --- application-dependent variable settings
--         kv_key_range = 10000,
--         kv_key_size = 300,
--         kv_value_size = 2000,
--     }
-- }

--- Server
server = "redis"
ip = "127.0.0.1"
port = 6379
auth_username = "barbell"
auth_password = "barbell"
ssh_username = "yuang"
ssh_password = "fghjkl;'"
--- Client
mode = "close"
threads = 1
connections = 1
--- output customization
output_root_dirname = "/home/yuang/yuxuan/Barbell/LC/config/lua/redis"
output_dirname = "output"
--- Trace (Load)
num_periods = 1
trace_type = "qps"
trace = { 5, 5, 5, 5, 5 }
--- Duration
warmup = 5
formal = #trace
cooldown = 5
--- Statistic Logging
report_interval = 1
percentile_latency = { 50, 90, 95, 99 }
data_to_collect = "cpu"
--- application-dependent variable settings
kv_key_range = 10000
kv_key_size = 300
kv_value_size = 2000

-- ----------------------------------------------------------------------
-- General OLTP benchmark
-- ----------------------------------------------------------------------

local current_file_path = debug.getinfo(1, "S").source:sub(2)
local common_file_directory = current_file_path:match("(.*[/\\])")
package.path = package.path .. ";" .. common_file_directory .. "?.lua"
package.path = package.path .. ";" .. common_file_directory .. "/../utils/?.lua"
-- require("oltp_common")
-- print("Common file directory: " .. common_file_directory)
-- print(package.path);

-- Declare the triple to compile the worklolad to
-- For example
local redis = require("kvstore").Redis
-- local triple = {
--     api = "SQL",
--     target = "MySQL",
-- }

-- Parameters
-- Maybe we can turn the object to a parameter to the domain-specific target instead of directly putting it here
-- For example: triple.init(params)
sysbench = {
    rand = {},
    opt = {
        --- Note: oltp_read_only and oltp_write_only are mutually exclusive
        --- oltp_read_only = false does not mean oltp_write_only is true
        --- They can be both false to send both read and write queries.
        --- However, they cannot be both true.
        oltp_read_only = false,    -- set as true for read-only queries
        oltp_write_only = true,    -- set as true for write-only queries
        oltp_range_selects = true, -- only works when oltp_write_only is false

        schema = "barbell",
        table_size = 10000,
        range_size = 100,
        tables = 4,            -- table index starts from 1, not 0
        point_selects = 10,    -- [Read-only] num of point_select queries
        simple_ranges = 1,     -- [Read-only] num of simple_range_select
        sum_ranges = 1,        -- [Read-only] num of sum_range_select
        order_ranges = 1,      -- [Read-only] num of order range select
        distinct_ranges = 1,   -- [Read-only] num of distinct range select
        index_updates = 1,     -- [Write-only] num of index update
        non_index_updates = 1, -- [Write-only] num of non-index update
        delete_inserts = 1,    -- [Write-only] num of delete-insert query pairs (each pair has one delete and one insert query of the same id)
        auto_inc = true,
        create_table_options = "",
        skip_trx = false,
        secondary = false,
        create_secondary = true,
        reconnect = 0,
        mysql_storage_engine = "innodb",
    }
}

-- initialize connection[global] as ProtocolMysqlCppConn protocol
-- should be called in expose_to_lua() function
-- @params protocol: ProtocolMysqlCppConn
-- protocol:query(const std::string& command)
function init_connection(protocol)
    connection = protocol
end

-- CBMG Declaration
-- TODO: graph structure with probability in edges
-- similar to a state machine
-- CBMG的每个node需要定义具体执行的动作
local cbmg = require("graph").init()
local entry = cbmg:addVertex({})
local exit = cbmg:addVertex({})
local get = cbmg:addVertex({
    template = redis.get,
    params = {
        key = "key",
    }
})
local set = cbmg:addVertex({
    template = redis.set,
    params = {
        key = "key",
        value = "value",
    }
})
cbmg:addEdge(entry, get, 0.9)
cbmg:addEdge(entry, set, 0.1)
cbmg:addEdge(get, exit, 1.0)
cbmg:addEdge(set, exit, 1.0)
-- print(cbmg:vertexCount())
-- print("entry ID: " .. entry.id)
-- print("get ID: " .. get.id)
-- print("set ID: " .. set.id)
-- print("exit ID: " .. exit.id)

-- Definition of event() function
-- How to traverse the CBMG to send out requests
function event()
    local node = entry
    while node.id ~= exit.id do
        local edges = cbmg:adj(node.id)
        local rand = math.random()
        local probability = 0.0
        -- print("length of edges: " .. edges:size())
        -- print("rand: " .. rand)
        for key, edge in pairs(edges:enumerate()) do
            probability = probability + edge.weight
            -- print("key " .. key)
            -- print("probability: " .. probability)
            if (probability > 1.0) then
                error("Sum of probability should not be larger than 1.0")
            elseif (rand < probability) then
                node = cbmg:vertexAt(edge.w)
                -- print("Match node ID: " .. node.id)
                if (node.params.template ~= nil) then
                    -- node.params:template()
                    connection:get(node.params.key)
                end
                break
            end
        end
    end
end

-- Definition of workload frequency and pattern
-- TODO:Unknown
-- should indicate how event() function is called, using it as one parameter
-- Actually, calling CBMG graph (state machine) instead of calling event() function
Loadgen = function()
    math.randomseed(os.time())
    for i = 1, 10 do
        event()
    end
end
-- print("Hello World!")
-- loadgen()
