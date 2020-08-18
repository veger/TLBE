#!/usr/bin/env lua

local lu = require("luaunit")

-- Unit tests
require("utils")
require("camera_follow-tracker")
require("camera_follow-player")
require("tracker")
require("tracker-base")
require("tracker-rocket")

-- Integration tests
require("camera")

os.exit(lu.LuaUnit:run())
