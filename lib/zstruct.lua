
--[[
@module zstruct
@summary C风格的struct库
@version 1.0.0
@date    2024.01.08
@author  wendal
@tag LUAT_USE_GPIO
@usage
-- 具体用法请查阅demo
]]

local zstruct = {}

-- 类型定义, key = {字节宽度, 是否是无符号, 数组大小, 当前值}
zstruct.types = {
    -- 有符号整数
    int8_t = {8, "c"},
    int16_t = {16, "h"},
    int32_t = {32, "i"},
    int64_t = {64, "l"},
    -- 无符号整数
    uint8_t = {8, "b"},
    uint16_t = {16, "H"},
    uint32_t = {32, "I"},
    uint64_t = {64, "L"},
    -- 浮点数
    float = {32, "f"},
    double = {64, "d"},
}
-- 定义别名
zstruct.types.int = zstruct.types.int32_t
zstruct.types.char = zstruct.types.int8_t
zstruct.types.short = zstruct.types.int16_t
-- zstruct.types.long = zstruct.types.int32_t
-- zstruct.types.long_long = zstruct.types.int64_t
-- zstruct.types.unsigned = zstruct.types.uint32_t
-- zstruct.types.unsigned_char = zstruct.types.uint8_t
-- zstruct.types.unsigned_short = zstruct.types.uint16_t
-- zstruct.types.unsigned_long = zstruct.types.uint32_t
-- zstruct.types.unsigned_long_long = zstruct.types.uint64_t
zstruct.types.bool = zstruct.types.uint8_t
zstruct.types.boolean = zstruct.types.uint8_t
zstruct.types.byte = zstruct.types.uint8_t
zstruct.types.u8 = zstruct.types.uint8_t
zstruct.types.u16 = zstruct.types.uint16_t
zstruct.types.u32 = zstruct.types.uint32_t
zstruct.types.u64 = zstruct.types.uint64_t
zstruct.types.i8 = zstruct.types.int8_t
zstruct.types.i16 = zstruct.types.int16_t
zstruct.types.i32 = zstruct.types.int32_t
zstruct.types.i64 = zstruct.types.int64_t

--[[
获取结构体大小
@api zstruct.sizeof(df)
@table 结构体定义
@return 结构体大小(字节)
]]
function zstruct.sizeof(df)
    if df and df.__size then
        return df.__size // 8
    end
    return 0
end

--[[
__fields的定义格式为:
1. 字段名
2. 字段类型
3. 字段类型信息
4. 字段值
5. 数组大小(若是数组, 则为数组大小,否则为nil)
]]

-- local builder_opts = {}
local function builder_add(meta, typename, key, default_value, bitsize, arraysize)
    if not key then
        local tmp = typename:trim():split(" ")
        if #tmp < 2 then
            log.error("zstruct", "非法的类型定义", typename)
            return
        end
        typename = tmp[1]:trim()
        key = tmp[2]:trim()
    end
    -- log.info("key分析", key, key:find("%["), key:endsWith("]"))
    if key:find("%[") and key:endsWith("]") then
        local tmp = key:split("[")
        key = tmp[1]:trim()
        arraysize = tonumber(tmp[2]:trim():sub(1, -2))
        if not default_value then
            default_value = {}
        end
    end
    -- log.info("新增key", key, arraysize, json.encode(default_value or 0))

    local typeinfo = zstruct.types[typename]
    if not typeinfo then
        log.error("zstruct", "非法的类型定义", typename, key)
        return
    end
    table.insert(meta.__fields, {key, typename, typeinfo, default_value or 0, arraysize})
    meta.__size = meta.__size + typeinfo[1] * (arraysize or 1)
    return true
end

local function struct_set(struct, key, value)
    -- log.info("设置字段", key, value)
    for _, v in pairs(struct.__fields) do
        if v[1] == key then
            v[4] = value
            return true
        end
    end
    log.error("zstruct", "没有该字段定义", key)
end

local function struct_load(struct, buff)
    if type(buff) == "string" then
        buff = zbuff.create(zstruct.sizeof(struct), buff)
        buff:seek(0)
    end
    -- log.info("待解析数据", buff:query(0, zstruct.sizeof(struct)):toHex(), buff:used())
    local cnt = 0
    for k, v in pairs(struct.__fields) do
        local bit_order = struct.__bit_order == "big" and ">" or "<"
        if v[5] then
            for i = 0, v[5] - 1 do
                cnt, v[4][i] = buff:unpack(bit_order .. v[3][2], v[4][i])
            end
        else
            cnt, v[4] = buff:unpack(bit_order .. v[3][2])
            -- log.info("非数组数据", cnt, v[3][2], v[4])
        end
    end
    return true
end

local function struct_get(struct, key)
    for _, v in pairs(struct.__fields) do
        if v[1] == key then
            return v[4]
        end
        -- log.info("不匹配", key, v[1])
    end
    log.error("zstruct", "没有该字段定义", key)
end

--[[
构建结构体数据
@api builder:new(data)
@string/zbuff 数据,可选
@return table 结构体数据
]]
local function builder_new(meta, data)
    local struct = {
        __newindex = struct_set,
        __load = struct_load,
        __index = struct_get
    }
    struct.__fields = {}
    struct.__size = meta.__size
    struct.__bit_order = meta.__bit_order
    for k, v in pairs(meta.__fields) do
        -- log.info("构建结构体对象", "字段", v[1])
        struct.__fields[k] = {}
        for k2, v2 in pairs(v) do
            struct.__fields[k][k2] = v2
        end
    end
    setmetatable(struct, struct)
    if data then
        if not struct:__load(data) then
            return
        end
    end
    return struct
end

--[[
创建结构体定义构建器对象
@api zstruct.typedef(df, bit_order)
@string 结构体定义字符串,可选
@string 字节序,可选,默认"big",即大端字节序
@return table 结构体定义构建器对象
]]
function zstruct.typedef(df, bit_order)
    local builder = {}
    builder.__size = 0
    builder.__fields = {}
    builder.__bit_order = bit_order or "big"
    builder.add = builder_add
    builder.build = builder_new
    -- setmetatable(builder, builder_opts)
    if df then
        for k, v in pairs(df:split(";")) do
            v = v:trim()
            if #v > 0 then
                builder.add(builder, v)
            end
        end
    end
    return builder
end

--[[
获取结构体的C语言表达字符串
@api zstruct.metastr(df)
@table 结构体定义
@return string C语言结构体定义字符串
]]
function zstruct.metastr(df)
    -- if not df then
    --     return
    -- end
    local tmp = ""
    for k, v in pairs(df.__fields) do
        -- log.info("zstruct", v[2], v[1])
        tmp = tmp .. v[2] .. " " .. v[1]
        if v[5] then
            tmp = tmp .. string.format("[%d]", v[5])
        end
        tmp = tmp .. ";\n"
    end
    return tmp
end

--[[
获取结构体数据字符串
@api zstruct.raw(df)
@table 结构体数据
@return zbuff 结构体数据
@usage
-- 返回值是zbuff, 可以通过 buff:toStr() 获取字符串

]]
function zstruct.raw(df)
    if not df then
        return
    end
    local buff = zbuff.create(zstruct.sizeof(df))
    for k, v in pairs(df.__fields) do
        local bit_order = df.__bit_order == "big" and ">" or "<"
        if v[5] then
            for i = 0, v[5] - 1 do
                buff:pack(bit_order .. v[3][2], v[4][i] or 0)
            end
        else
            -- log.info("非数组数据", v[3][2], v[4])
            buff:pack(bit_order .. v[3][2], v[4])
        end
    end
    return buff
end

return zstruct
