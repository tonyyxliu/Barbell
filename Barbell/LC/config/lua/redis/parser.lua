local parser = require("lua-parser.lua-parser.parser")
local pp = require("lua-parser.lua-parser.pp")
local validator = require("lua-parser.lua-parser.validator")

if #arg ~= 1 then
    print("Usage: parse.lua <string>")
    os.exit(1)
end

print("arg[1]: " .. arg[1])

local function file_to_string(file_path)
    local file = io.open(file_path, "r") -- 以只读模式打开文件
    if not file then
        error("无法打开文件: " .. file_path)
    end
    local content = file:read("*all") -- 读取文件的所有内容
    file:close() -- 关闭文件
    return content
end

local ast, error_msg = parser.parse(file_to_string(arg[1]), "example.lua")
if not ast then
    print(error_msg)
    os.exit(1)
end

print(error_msg)
pp.print(ast)   --- print the AST in text

--- eCBMG Generation
---@param ast any
---@param errorinfo any
local function gen_eCBMG(ast, errorinfo)
    validator.validate(ast, errorinfo)
end

gen_eCBMG(ast, error_msg)
os.exit(0)
