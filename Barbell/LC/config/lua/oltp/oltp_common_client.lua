-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

-- Modified by Liu Yuxuan for Barbell Loadgen on May 21st, 2024

-- -----------------------------------------------------------------------------
-- Common code for OLTP benchmarks.
-- -----------------------------------------------------------------------------

math.randomseed(os.time()) -- set seed for math randomization

-- ---------------------
-- Local Implementations
-- ---------------------
-- @Note: see public interface at the end of this file

-- templates of static SQL queries (not prepared query)
-- formatted with concrete parameters before issuing to SQL server
local stmt_templates = {
    point_selects = "SELECT c FROM sbtest%u WHERE id=%u",
    simple_ranges = "SELECT c FROM sbtest%u WHERE id BETWEEN %u AND %u",
    sum_ranges = "SELECT SUM(k) FROM sbtest%u WHERE id BETWEEN %u AND %u",
    order_ranges = "SELECT c FROM sbtest%u WHERE id BETWEEN %u AND %u ORDER BY c",
    distinct_ranges = "SELECT DISTINCT c FROM sbtest%u WHERE id BETWEEN %u AND %u ORDER BY c",
    index_updates = "UPDATE sbtest%u SET k=k+1 WHERE id=%u",
    non_index_updates = "UPDATE sbtest%u SET c=%s WHERE id=%u",
    deletes = "DELETE FROM sbtest%u WHERE id=%u",
    inserts = "INSERT INTO sbtest%u (id, k, c, pad) VALUES (%u, %u, %s, %s)",
}

-- templates of prepare statements
-- need to set params before execution
local stmt_defs = {
    point_selects = "SELECT c FROM sbtest%u WHERE id=?",
    simple_ranges = "SELECT c FROM sbtest%u WHERE id BETWEEN ? AND ?",
    sum_ranges = "SELECT SUM(k) FROM sbtest%u WHERE id BETWEEN ? AND ?",
    order_ranges = "SELECT c FROM sbtest%u WHERE id BETWEEN ? AND ? ORDER BY c",
    distinct_ranges = "SELECT DISTINCT c FROM sbtest%u WHERE id BETWEEN ? AND ? ORDER BY c",
    index_updates = "UPDATE sbtest%u SET k=k+1 WHERE id=?",
    non_index_updates = "UPDATE sbtest%u SET c=? WHERE id=?",
    deletes = "DELETE FROM sbtest%u WHERE id=?",
    inserts = "INSERT INTO sbtest%u (id, k, c, pad) VALUES (?, ?, ?, ?)",
}

-- string template of c-value in sbtest dataset
-- 10 groups, 119 characters + 1 last char '\0'
local c_value_template = "###########-###########-###########-" ..
    "###########-###########-###########-" ..
    "###########-###########-###########-" ..
    "###########"

-- string template of pad-value in sbtest dataset
-- 5 groups, 59 characters + 1 last char '\0'
local pad_value_template = "###########-###########-###########-" ..
    "###########-###########"

local function template_format(fmt)
    local function random_digit()
        return math.random(0, 9)
    end

    local function random_char()
        return math.random(string.byte('a'), string.byte('z'))
    end

    local str = fmt:gsub("#", random_digit)
    str = str:gsub("@", random_char)
    return str;
end

-- Create a single table sbtest{table_idx}
local function create_single_table(table_idx)
    print(string.format("Creating table 'sbtest%d'...", table_idx))
    local id_index_def, id_def
    local engine_def = ""
    local extra_table_options = ""
    local query
    if sysbench.opt.secondary then
        id_index_def = "KEY xid"
    else
        id_index_def = "PRIMARY KEY"
    end
    -- Assume MYSQL
    if sysbench.opt.auto_inc then
        id_def = "INTEGER NOT NULL AUTO_INCREMENT"
    else
        id_def = "INTEGER NOT NULL"
    end
    engine_def = "/*! ENGINE = " .. sysbench.opt.mysql_storage_engine .. " */"
    -- Create table structure
    query = string.format([[
CREATE TABLE sbtest%d(
  id %s,
  k INTEGER DEFAULT '0' NOT NULL,
  c CHAR(120) DEFAULT '' NOT NULL,
  pad CHAR(60) DEFAULT '' NOT NULL,
  %s (id)
) %s %s]],
        table_idx, id_def, id_index_def, engine_def,
        sysbench.opt.create_table_options)
    connection:query(query)
    -- Insert data records
    if (sysbench.opt.table_size > 0) then
        print(string.format("Inserting %d records into 'sbtest%d'",
            sysbench.opt.table_size, table_idx))
    end
    if sysbench.opt.auto_inc then
        query = "INSERT INTO sbtest" .. table_idx .. "(k, c, pad) VALUES (?, ?, ?)"
    else
        query = "INSERT INTO sbtest" .. table_idx .. "(id, k, c, pad) VALUES (?, ?, ?, ?)"
    end
    -- bulk insert
    connection:bulk_insert_init(query)
    local c_val
    local pad_val
    for i = 1, sysbench.opt.table_size do
        c_val = get_c_value()
        pad_val = get_pad_value()
        if (sysbench.opt.auto_inc) then
            query = string.format("%d, %s, %s",
                math.random(1, sysbench.opt.table_size),
                c_val, pad_val)
        else
            query = string.format("%d, %d, %s, %s",
                i, math.random(1, sysbench.opt.table_size),
                c_val, pad_val)
        end
        connection:bulk_insert_next(query)
    end
    connection:bulk_insert_done()
    -- Create secondary index
    if sysbench.opt.create_secondary then
        print(string.format("Creating a secondary index on 'sbtest%d'...",
            table_idx))
        connection:query(string.format("CREATE INDEX k_%d ON sbtest%d(k)",
            table_idx, table_idx))
    end
end

-- Drop all sbtest tables (used for cleanup)
local function drop_all_tables()
    for i = 1, sysbench.opt.tables do
        print(string.format("Dropping table 'sbtest%d'...", i))
        connection:query("DROP TABLE IF EXISTS sbtest" .. i)
    end
end

-- -------------------------------------------
-- Public Interface to other oltp test scripts
-- -------------------------------------------

-- initialize connection[global] as ProtocolMysqlCppConn protocol
-- should be called in expose_to_lua() function
-- @params protocol: ProtocolMysqlCppConn
-- protocol:query(const std::string& command)
function init_connection(protocol)
    connection = protocol
end

-- preload dataset for MYSQL
function preload(table_idx)
    create_single_table(table_idx)
end

-- cleanup dataset for MYSQL
function cleanup()
    drop_all_tables()
    print("DROP DATABASE IF EXISTS " .. sysbench.opt.schema)
    connection:query("DROP DATABASE IF EXISTS " .. sysbench.opt.schema)
end

function get_table_num()
    return math.random(1, sysbench.opt.tables)
end

function get_id()
    return math.random(1, sysbench.opt.table_size)
end

function get_c_value()
    return template_format(c_value_template)
end

function get_pad_value()
    return template_format(pad_value_template)
end

-- execute all point select queries (number set by sysbench.opt.point_select)
function execute_point_selects(table_id)
    local command
    for i = 1, sysbench.opt.point_selects do
        -- command = string.format(stmt_templates.point_selects, table_id, get_id())
        -- connection:query(command)
        connection:bind_params_point_select(table_id, "point_selects", get_id())
        -- connection:query_prepare(table_id, "point_selects")
    end
end

-- execute range queries (distinguish types by 'key' parameter)
local function execute_range(key, table_id)
    local table_sum = get_table_num()
    local command
    for i = 1, sysbench.opt[key] do
        local start_id = get_id() -- start index
        local end_id = start_id + sysbench.opt.range_size - 1
        -- command = string.format(stmt_templates[key], table_id, start_id, end_id)
        -- connection:query(command)
        connection:bind_params_range_select(table_sum, key, start_id, end_id)
        -- connection:query_prepare(table_sum, key)
    end
end

-- execute all simple range queries (number set by sysbench.opt.simple_range)
function execute_simple_ranges(table_id)
    execute_range("simple_ranges", table_id)
end

function execute_sum_ranges(table_id)
    execute_range("sum_ranges", table_id)
end

function execute_order_ranges(table_id)
    execute_range("order_ranges", table_id)
end

function execute_distinct_ranges(table_id)
    execute_range("distinct_ranges", table_id)
end

function execute_index_updates(table_id)
    local command
    for i = 1, sysbench.opt.index_updates do
        command = string.format(stmt_templates.index_updates, table_id, get_id())
        connection:query(command)
    end
end

function execute_non_index_updates(table_id)
    local command
    for i = 1, sysbench.opt.non_index_updates do
        command = string.format(stmt_templates.non_index_updates, table_id, get_c_value(), get_id())
        connection:query(command)
    end
end

function execute_delete_inserts(table_id)
    for i = 1, sysbench.opt.delete_inserts do
        local id = get_id()
        local k = get_id()
        local delete_cmd = string.format(stmt_templates.deletes, table_id, id)
        local insert_cmd = string.format(stmt_templates.inserts, table_id, id, k, get_c_value(), get_pad_value())
        connection:query(delete_cmd)
        connection:query(insert_cmd)
    end
end
