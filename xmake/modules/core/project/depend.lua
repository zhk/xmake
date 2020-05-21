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
-- @file        depend.lua
--

-- imports
import("private.tools.cl.parse_deps", {alias = "parse_deps_cl"})
import("private.tools.gcc.parse_deps", {alias = "parse_deps_gcc"})

-- load depfiles for gcc
function _load_depfiles_gcc(dependinfo)

    local depfiles = dependinfo.depfiles_gcc
    if depfiles then
        depfiles = parse_deps_gcc(depfiles)
        if depfiles then
            if dependinfo.files then
                table.join2(dependinfo.files, depfiles)
            else
                dependinfo.files = depfiles
            end
        end
        dependinfo.depfiles_gcc = nil
    end
end

-- load depfiles for cl
function _load_depfiles_cl(dependinfo)

    local depfiles = dependinfo.depfiles_cl
    if depfiles then
        depfiles = parse_deps_cl(depfiles)
        if depfiles then
            if dependinfo.files then
                table.join2(dependinfo.files, depfiles)
            else
                dependinfo.files = depfiles
            end
        end
        dependinfo.depfiles_cl = nil
    end
end

-- load dependent info from the given file (.d) 
function load(dependfile)

    if os.isfile(dependfile) then
        -- may be the depend file has been incomplete when if the compilation process is abnormally interrupted
        local dependinfo = try { function() return io.load(dependfile) end }
        if dependinfo then
            -- attempt to load depfiles from the compilers
            if is_plat("windows") then
                _load_depfiles_cl(dependinfo)
            else
                _load_depfiles_gcc(dependinfo)
            end
            return dependinfo
        end
    end
end

-- save dependent info to file
function save(dependinfo, dependfile)
    io.save(dependfile, dependinfo)
end

-- the dependent info is changed?
--
-- if not depend.is_changed(dependinfo, {filemtime = os.mtime(objectfile), values = {...}}) then
--      return 
-- end
--
function is_changed(dependinfo, opt)

    -- empty depend info? always be changed
    local files = dependinfo.files or {}
    local values = dependinfo.values or {}
    if #files == 0 and #values == 0 then
        return true
    end

    -- check the dependent files are changed?
    local lastmtime = opt.lastmtime or 0
    _g.files_mtime = _g.files_mtime or {}
    local files_mtime = _g.files_mtime
    for _, file in ipairs(files) do

        -- get and cache the file mtime
        local mtime = files_mtime[file] or os.mtime(file)
        files_mtime[file] = mtime

        -- source and header files have been changed or not exists?
        if mtime == 0 or mtime > lastmtime then
            return true
        end
    end

    -- check the dependent values are changed?
    local depvalues = values
    local optvalues = opt.values or {}
    if #depvalues ~= #optvalues then
        return true
    end
    for idx, depvalue in ipairs(depvalues) do
        local optvalue = optvalues[idx]
        local deptype = type(depvalue) 
        local opttype = type(optvalue)
        if deptype ~= opttype then
            return true
        elseif deptype == "string" and depvalue ~= optvalue then
            return true
        elseif deptype == "table" then
            for subidx, subvalue in ipairs(depvalue) do
                if subvalue ~= optvalue[subidx] then
                    return true
                end
            end
        end
    end

    -- check the dependent files list are changed?
    local optfiles = opt.files
    if optfiles then
        for idx, file in ipairs(files) do
            if file ~= optfiles[idx] then
                return true
            end
        end
    end
end
