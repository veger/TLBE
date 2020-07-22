#!/usr/bin/env lua

local lu = require("luaunit")

require("camera_follow-tracker")
require("camera_follow-player")
require("tracker-base")
require("tracker-rocket")

os.exit(lu.LuaUnit:run())
