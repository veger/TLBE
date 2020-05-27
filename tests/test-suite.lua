#!/usr/bin/env lua

local lu = require("luaunit")

require("follow-player")
require("follow-base")

os.exit(lu.LuaUnit:run())
