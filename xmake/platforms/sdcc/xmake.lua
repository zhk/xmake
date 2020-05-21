--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("sdcc")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("stm8", "mcs51", "z80", "z180", "r2k", "r3ka", "s08", "hc08")

    -- set formats
    set_formats {static = "$(name).lib", object = "$(name).rel", binary = "$(name).bin", symbol = "$(name).sym"}

    -- on check project configuration
    on_config_check("config")

    -- on load
    on_load("load")


