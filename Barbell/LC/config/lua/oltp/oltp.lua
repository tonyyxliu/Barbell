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

local current_file_path = debug.getinfo(1, "S").source:sub(2)
local common_file_directory = current_file_path:match("(.*[/\\])")
package.path = package.path .. ";" .. common_file_directory .. "?.lua"
package.path = ";./?.lua" .. package.path
require("oltp_common")

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

local i
local tables = {}
for i = 1, sysbench.opt.tables do
    tables[i] = string.format("sbtest%i WRITE", i)
end
local begin_query = "LOCK TABLES " .. table.concat(tables, ",")
local commit_query = "UNLOCK TABLES"

function get_range_str()
    local start = math.random(1, sysbench.opt.table_size)
    return string.format(" WHERE id BETWEEN %u AND %u", start, start + sysbench.opt.range_size - 1)
end

function event()
    local rs
    local i
    local table_name
    local c_val
    local pad_val
    local query

    table_name = "sbtest" .. get_table_num()

    if sysbench.opt.oltp_read_only and sysbench.opt.oltp_write_only then
        error("oltp_read_only and oltp_write_only are mutually exclusive")
    end

    if not sysbench.opt.skip_trx then
        connection:query(begin_query)
    end

    if not sysbench.opt.oltp_write_only then
        for i = 1, sysbench.opt.point_selects do
            rs = connection:query("SELECT c FROM " .. table_name .. " WHERE id=" .. get_id())
        end
        if sysbench.opt.oltp_range_selects then
            for i = 1, sysbench.opt.simple_ranges do
                rs = connection:query("SELECT c FROM " .. table_name .. get_range_str())
            end
            for i = 1, sysbench.opt.sum_ranges do
                rs = connection:query("SELECT SUM(k) FROM " .. table_name .. get_range_str())
            end
            for i = 1, sysbench.opt.order_ranges do
                rs = connection:query("SELECT c FROM " .. table_name .. get_range_str() .. " ORDER BY c")
            end
            for i = 1, sysbench.opt.distinct_ranges do
                rs = connection:query("SELECT DISTINCT c FROM " .. table_name .. get_range_str() .. " ORDER BY c")
            end
        end
    end -- oltp_read_only

    if not sysbench.opt.oltp_read_only then
        for i = 1, sysbench.opt.index_updates do
            rs = connection:query("UPDATE " .. table_name .. " SET k=k+1 WHERE id=" .. get_id())
        end
        for i = 1, sysbench.opt.non_index_updates do
            c_val = get_c_value()
            rs = connection:query("UPDATE " .. table_name .. " SET c='" .. c_val .. "' WHERE id=" .. get_id())
        end
        for i = 1, sysbench.opt.delete_inserts do
            -- the id to manipulate is identical for both delete and insert
            i = get_id()
            -- delete part
            rs = connection:query("DELETE FROM " .. table_name .. " WHERE id=" .. i)
            -- insert part
            c_val = get_c_value()
            pad_val = get_pad_value()
            if (sysbench.opt.auto_inc) then
                -- remove id if the table's primary key is AUTO_INCREMENT
                rs = connection:query("INSERT INTO " ..
                    table_name ..
                    " (k, c, pad) VALUES " .. string.format("(%d, '%s', '%s')", get_id(), c_val, pad_val))
            else
                rs = connection:query("INSERT INTO " ..
                    table_name ..
                    " (id, k, c, pad) VALUES " .. string.format("(%d, %d, '%s', '%s')", i, get_id(), c_val, pad_val))
            end
        end
    end -- oltp_write_only

    if not sysbench.opt.skip_trx then
        connection:query(commit_query)
    end
end
