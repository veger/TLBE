#!/usr/bin/env lua

local lu = require("luaunit")

package.path = package.path .. ";../?.lua"
require("scripts.main")

require("follow-player")
require("follow-base")

local runner = lu.LuaUnit.new()
os.exit(runner:runSuite())
