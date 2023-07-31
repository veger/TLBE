#!/usr/bin/env lua

local lu = require("luaunit")

-- Unit tests
require("utils")
require("camera_follow-tracker")
require("main")
require("surface")
require("tracker")
require("tracker-base")
require("tracker-player")
require("tracker-rocket")
require("tracker-cityblock")

-- Integration tests
require("camera")

os.exit(lu.LuaUnit:run())
