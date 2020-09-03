#!/usr/bin/env lua

local lu = require("luaunit")

-- Unit tests
require("utils")
require("camera_follow-tracker")
require("main")
require("tracker")
require("tracker-base")
require("tracker-player")
require("tracker-rocket")

-- Integration tests
require("camera")

os.exit(lu.LuaUnit:run())
