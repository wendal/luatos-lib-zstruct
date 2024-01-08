# luatos-lib-zstruct

C风格的struct库, 用于解析和合成二进制数据

## 介绍

本库属于工具库,不依赖其他库, 纯lua编写, 可以直接拷贝到项目中使用

## 安装

本协议库使用纯lua编写, 所以不需要编译, 直接将源码拷贝到项目即可

## 使用

```lua
-- 结构体的声明
local zstruct = require("zstruct")

-- 方式1逐段生成结构体
local mytd = zstruct.typedef()
mytd:add("int32_t", "id")
mytd:add("int8_t flags")
mytd:add("uint8_t data[10]")

-- 方式2一次性生成结构体
local mytd = zstruct.typedef([[
int32_t id;
int8_t flags;
uint8_t data[10];
]])

-- 生成不变变的结构体声明, 可用于后续操作
local myst = mytd:build()

-- 打印总大小
log.info("myst", zstruct.sizeof(myst))

-- 生成结构体数据
local mydata = myst:new()
mydata.id = 10
mydata.flags = 0x12
mydata.data[1] = 0x34

log.info("mydata", zstruct.toraw(mydata):toHex())

-- 解析数据
local str = string.fromHex("0a1234000000000000000000000000") -- 待解析的数据, 也可以是zbuff
local mydata = myst:new(str)
if mydata then -- 如果数据不足, 解析失败, 所以要判断
    log.info("mydata", mydata.id, mydata.flags)
end
```

## 支持的数据类型声明

* 带符号的整数: int8_t, int16_t, int32_t, int64_t
* 无符号的整数: uint8_t, uint16_t, uint32_t, uint64_t
* 浮点数: float, double, 分别是32bit和64bit
* char是int8_t的别名
* 支持数组声明, 例如 `char data[10]`/`uint8_t data[8]`

暂不支持指针类型, 如果是指针可以设置成 `int32_t`

## 变更日志

[changelog](changelog.md)

## LIcense

[MIT License](https://opensource.org/licenses/MIT)
