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
-- @file        msbuild.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_file")

-- detect build-system and configuration file
function detect()
    if is_subhost("windows") then
        return find_file("*.sln", os.curdir())
    end
end

-- do clean
function clean()
    os.vexec("msbuild \"%s\" -nologo -t:Clean -p:Configuration=Release -p:Platform=%s", configfile, is_arch("x64") and "x64" or "Win32")
end

-- do build
function build()

    -- only support the current subsystem host platform now!
    assert(is_subhost(config.plat()), "msbuild: %s not supported!", config.plat())

    -- do build
    os.vexec("msbuild \"%s\" -nologo -t:Build -p:Configuration=Release -p:Platform=%s", configfile, is_arch("x64") and "x64" or "Win32")
    cprint("${color.success}build ok!")
end
