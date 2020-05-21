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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.config")
import("core.platform.environment")
import("make.makefile")
import("make.xmakefile")
import("cmake.cmakelists")
import("ninja.build_ninja")
import("vstudio.vs")
import("vsxmake.vsxmake")
import("clang.compile_flags")
import("clang.compile_commands")

function makers()

    -- the maps
    return
    {   
        make             = makefile.make
    ,   makefile         = makefile.make
    ,   xmakefile        = xmakefile.make
    ,   cmake            = cmakelists.make
    ,   cmakelists       = cmakelists.make
    ,   ninja            = build_ninja.make
    ,   vs2002           = vs.make(2002)
    ,   vs2003           = vs.make(2003)
    ,   vs2005           = vs.make(2005)
    ,   vs2008           = vs.make(2008)
    ,   vs2010           = vs.make(2010)
    ,   vs2012           = vs.make(2012)
    ,   vs2013           = vs.make(2013)
    ,   vs2015           = vs.make(2015)
    ,   vs2017           = vs.make(2017)
    ,   vs2019           = vs.make(2019)
    ,   vs               = vs.make()
    ,   vsxmake2010      = vsxmake.make(2010)
    ,   vsxmake2012      = vsxmake.make(2012)
    ,   vsxmake2013      = vsxmake.make(2013)
    ,   vsxmake2015      = vsxmake.make(2015)
    ,   vsxmake2017      = vsxmake.make(2017)
    ,   vsxmake2019      = vsxmake.make(2019)
    ,   vsxmake          = vsxmake.make()
    ,   compile_flags    = compile_flags.make
    ,   compile_commands = compile_commands.make
    }
end

-- make project
function _make(kind)

    local maps = makers()
    assert(maps[kind], "the project kind(%s) is not supported!", kind)

    -- make it
    maps[kind](option.get("outputdir"))
end

-- main
function main()

    -- config it first
    task.run("config")

    -- enter toolchains environment
    environment.enter("toolchains")

    -- make project
    _make(option.get("kind"))

    -- leave toolchains environment
    environment.leave("toolchains")

    -- trace
    cprint("${color.success}create ok!")
end
