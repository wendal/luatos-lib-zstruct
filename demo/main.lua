--[[
wifi定位演示
]]

-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "zstructdemo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- 一定要添加sys.lua !!!!
sys = require("sys")
zstruct = require("zstruct")

-- 用户代码已开始---------------------------------------------

sys.taskInit(function()

    -- 方式1逐段生成结构体
    local mytd = zstruct.typedef()
    log.info(">>", mytd.add)
    mytd:add("int32_t", "id")
    mytd:add("int8_t flags")
    mytd:add("uint8_t data[10]")
    -- 生成不变变的结构体声明, 可用于后续操作
    local myst = mytd:build()

    -- 打印总大小
    log.info("myst", "结构体总大小", zstruct.sizeof(myst))
    log.info("myst", "结构体形式表达", "\n" .. zstruct.metastr(myst))

    myst.id = 0x11A3A5A7
    myst.flags = 0x02
    myst.data[0] = 0x30
    myst.data[8] = 0x38


    local raw = zstruct.raw(myst):toStr() -- raw的返回值是zbuff对象

    log.info("myst", string.format("id 0x%08X flags 0x%02X", myst.id, myst.flags))
    log.info("myst", raw:toHex())

    myst = mytd:build(raw)
    log.info("myst", string.format("id 0x%08X flags 0x%02X", myst.id, myst.flags))
    log.info("myst", "data[0]", myst.data[0], "data[8]", myst.data[8])

end)

-- 用户代码已结束---------------------------------------------

-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
