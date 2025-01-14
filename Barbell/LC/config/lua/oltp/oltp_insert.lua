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

-- Modified by Liu Yuxuan for Barbell Loadgen on May 21st, 2024

-- ----------------------------------------------------------------------
-- Insert-Only OLTP benchmark
-- ----------------------------------------------------------------------

local current_file_path = debug.getinfo(1, "S").source:sub(2)
local common_file_directory = current_file_path:match("(.*[/\\])")
package.path = package.path .. ";" .. common_file_directory .. "?.lua"
package.path = ";./?.lua" .. package.path
require("oltp_common")

sysbench = {
    rand = {},
    opt = {
        schema = "barbell",
        table_size = 10000,
        range_size = 100,
        tables = 4, -- table index starts from 1, not 0
        point_selects = 10,
        simple_ranges = 1,
        sum_ranges = 1,
        order_ranges = 1,
        distinct_ranges = 1,
        index_updates = 1,
        non_index_updates = 1,
        delete_inserts = 1,
        range_selects = true,
        auto_inc = true,
        create_table_options = "",
        skip_trx = false,
        secondary = false,
        create_secondary = true,
        reconnect = 0,
        mysql_storage_engine = "innodb",
    }
}

function event()
    local table_name = "sbtest" .. get_table_num()
    local k_val = math.random(1, sysbench.opt.table_size)
    local c_val = get_c_value()
    local pad_val = get_pad_value()
    if (sysbench.opt.auto_inc) then
        i = 0
        connection:query(string.format("INSERT INTO %s (k, c, pad) VALUES " ..
            "(%d, '%s', '%s')",
            table_name, k_val, c_val, pad_val))
    else
        -- Convert a uint32_t value to SQL INT
        --i = sysbench.rand.unique() - 2147483648
        print("do not support generating id for insert yet")
    end
end
