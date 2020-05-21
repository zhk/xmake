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
-- @file        runjobs.lua
--

-- imports
import("core.base.scheduler")

-- print back characters
function _print_backchars(backnum)
    if backnum > 0 then
        local str = ""
        for i = 1, backnum do
            str = str .. '\b'
        end
        for i = 1, backnum do
            str = str .. ' '
        end
        for i = 1, backnum do
            str = str .. '\b'
        end
        if #str > 0 then
            printf(str)
        end
    end
end

-- asynchronous run jobs 
--
-- e.g. 
-- runjobs("test", function (index) print("hello") end, {total = 100, comax = 6, timeout = 1000, timer = function (running_jobs_indices) end})
-- runjobs("test", function () os.sleep(10000) end, {showtips = true})
--
-- local jobs = jobpool.new()
-- local root = jobs:addjob("job/root", function (idx, total)
--   print(idx, total)
-- end)
-- for i = 1, 3 do
--     local job = jobs:addjob("job/" .. i, function (idx, total)
--         print(idx, total)
--     end, root)
-- end
-- runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices) end})
-- 
--
function main(name, jobs, opt)

    -- init options
    op = opt or {}
    local total = opt.total or (type(jobs) == "table" and jobs:size()) or 1
    local comax = opt.comax or total
    local timeout = opt.timeout or 500
    local group_name = name
    local jobs_cb = type(jobs) == "function" and jobs or nil
    assert(timeout < 60000, "runjobs: invalid timeout!")
    assert(jobs, "runjobs: no jobs!")

    -- show waiting tips?
    local waitindex = 0
    local waitchars = opt.waitchars or {'\\', '-', '/', '|'}
    local backnum = 0
    local showtips = io.isatty() and opt.showtips -- we need hide wait characters if is not a tty

    -- run timer
    local stop = false
    local running_jobs_indices
    if opt.timer then
        scheduler.co_start_named(name .. "/timer", function ()
            while not stop do
                os.sleep(timeout)
                if not stop then
                    opt.timer(running_jobs_indices)
                end
            end
        end)
    elseif showtips then
        scheduler.co_start_named(name .. "/tips", function ()
            while not stop do
                os.sleep(timeout)
                if not stop then

                    -- print back characters
                    _print_backchars(backnum)

                    -- show waitchars
                    waitindex = ((waitindex + 1) % #waitchars)
                    local tips = nil
                    local waitobjs = scheduler.co_group_waitobjs(group_name)
                    if waitobjs:size() > 0 then
                        local names = {}
                        for _, obj in waitobjs:keys() do
                            if obj:otype() == scheduler.OT_PROC then
                                table.insert(names, obj:name())
                            elseif obj:otype() == scheduler.OT_SOCK then
                                table.insert(names, "sock")
                            elseif obj:otype() == scheduler.OT_PIPE then
                                table.insert(names, "pipe")
                            end
                        end
                        names = table.unique(names)
                        if #names > 0 then
                            names = table.concat(names, ",")
                            if #names > 16 then
                                names = names:sub(1, 16) .. ".."
                            end
                            tips = string.format("(%d/%s)", waitobjs:size(), names)
                        end
                    end
                    if tips then
                        cprintf("${dim}%s${clear} %s", tips, waitchars[waitindex + 1])
                        backnum = #tips + 2
                    else
                        printf(waitchars[waitindex + 1])
                        backnum = 1
                    end
                    io.flush()
                end
            end
        end)
    end

    -- run jobs
    local index = 0
    local priority_prev = 0
    local priority_curr = 0
    local job_pending = nil
    while index < total do
        running_jobs_indices = {}
        scheduler.co_group_begin(group_name, function (co_group)
            local freemax = comax - #co_group
            local max = math.min(index + freemax, total)
            local jobfunc = jobs_cb
            while index < max do
                
                -- uses job pool?
                local jobname
                if not jobs_cb then
                    
                    -- get job priority 
                    local job, priority
                    if job_pending then
                        job = job_pending
                        priority = priority_prev
                    else
                        job, priority = jobs:pop()
                    end
                    if not job then
                        break
                    end

                    -- priority changed? we need wait all running jobs exited
                    priority_curr = priority or priority_prev
                    assert(priority_curr >= priority_prev, "runjobs: invalid priority(%d < %d)!", priority_curr, priority_prev)
                    if priority_curr > priority_prev then
                        job_pending = job
                        break
                    end
                    job_pending = nil

                    -- get run function
                    jobfunc = job.run
                    jobname = job.name
                else
                    jobname = tostring(index)
                end

                -- start this job
                index = index + 1
                table.insert(running_jobs_indices, index)
                scheduler.co_start_named(name .. '/' .. jobname, function(i)
                    try
                    { 
                        function()
                            if jobfunc then
                                jobfunc(i, total)
                            end
                        end,
                        catch
                        {
                            function (errors)

                                -- stop timer and disable show waitchars first
                                stop = true

                                -- remove wait charactor
                                if showtips then
                                    _print_backchars(backnum)
                                    print("")
                                    io.flush()
                                end

                                -- do exit callback
                                if opt.exit then
                                    opt.exit(errors)
                                end

                                -- re-throw this errors and abort scheduler
                                raise(errors)
                            end
                        }
                    }
                end, index)
            end
        end)
    
        -- need only one jobs exited if be same priority
        if priority_curr == priority_prev then
            scheduler.co_group_wait(group_name, {limit = 1})
        else
            -- need to wait all running jobs exited first if be different priority
            scheduler.co_group_wait(group_name)
            priority_prev = priority_curr
        end
    end

    -- wait all jobs exited
    scheduler.co_group_wait(group_name)

    -- stop timer
    stop = true

    -- remove wait charactor
    if showtips then
        _print_backchars(backnum)
        io.flush()
    end

    -- do exit callback
    if opt.exit then
        opt.exit()
    end
end
