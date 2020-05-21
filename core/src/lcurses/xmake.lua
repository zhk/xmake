-- add target
target("lcurses")

    -- enable this target?
    if not has_config("curses") and not has_config("pdcurses") then
        set_default(false)
    end

    -- make as a static library
    set_kind("static")

    -- add deps
    add_deps("luajit")
    if is_plat("windows") and has_config("pdcurses") then
        add_deps("pdcurses")
    end

    -- add the common source files
    add_files("lcurses.c")
  
    -- add options
    if is_plat("windows") then
        add_options("pdcurses")
    else
        add_options("curses")
    end
