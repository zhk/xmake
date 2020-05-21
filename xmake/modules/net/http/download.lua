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
-- @file        download.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- get user agent
function _get_user_agent()

    -- init user agent
    if _g._USER_AGENT == nil then

        -- init systems
        local systems = {macosx = "Macintosh", linux = "Linux", windows = "Windows", msys = "MSYS", cygwin = "Cygwin"}

        -- os user agent
        local os_user_agent = ""
        if is_host("macosx") then
            local osver = try { function() return os.iorun("/usr/bin/sw_vers -productVersion") end }
            if osver then
                os_user_agent = ("Intel Mac OS X " .. (osver or "")):trim()
            end
        elseif is_host("linux", "msys", "cygwin") then
            local osver = try { function () return os.iorun("uname -r") end }
            if osver then
                os_user_agent = (os_user_agent .. " " .. (osver or "")):trim()
            end
        end

        -- make user agent
        _g._USER_AGENT = string.format("Xmake/%s (%s;%s)", xmake.version(), systems[os.subhost()] or os.subhost(), os_user_agent)
    end
    return _g._USER_AGENT
end

-- download url using curl
function _curl_download(tool, url, outputfile)

    -- set basic arguments
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-SL")
    else
        table.insert(argv, "-fsSL")
    end

    -- set user-agent
    local user_agent = _get_user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " curl/" .. tool.version
        end
        table.insert(argv, "-A")
        table.insert(argv, user_agent)
    end

    -- set url
    table.insert(argv, url)

    -- ensure output directory
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputfile
    table.insert(argv, "-o")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url using wget
function _wget_download(tool, url, outputfile)

    -- ensure output directory
    local argv = {url}
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set user-agent
    local user_agent = _get_user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " wget/" .. tool.version
        end
        table.insert(argv, "-U")
        table.insert(argv, user_agent)
    end

    -- set outputfile
    table.insert(argv, "-O")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url
--
-- @param url           the input url
-- @param outputfile    the output file
--
--
function main(url, outputfile)

    -- init output file
    outputfile = outputfile or path.filename(url):gsub("%?.+$", "")
    
    -- attempt to download url using curl first
    local tool = find_tool("curl", {version = true})
    if tool then
        return _curl_download(tool, url, outputfile)
    end

    -- download url using wget
    tool = find_tool("wget", {version = true})
    if tool then
        return _wget_download(tool, url, outputfile)
    end
end
