-- https://github.com/Hammerspoon/hammerspoon/issues/2943
hs.window.filter.ignoreAlways['Safari Web Content (Cached)'] = true

-- Subscribe to windows being closed. If the app has no visible windows, hide the app.
hs.window.filter.new():subscribe(hs.window.filter.hasNoWindows, function(win)
    -- Some apps with a window leftover still sometimes trigger the hasNoWindows
    -- event. We'll need to check if there are windows instead of just hiding.
    local app = win:application()
    if #app:allWindows() == 0 then app:hide() end
end)

-- Subscribe to windows being created in order to automatically place them in the correct layout.
hs.window.filter.new():subscribe(hs.window.filter.windowCreated, function(win)
    -- Avoid moving dialogs, etc.
    -- Also avoid when dragging a tab out of the browser into a new window, etc.
    -- (But not Safari, womp womp)
    if win:isStandard() and not hs.mouse.getButtons().left then
        addWindowToLayoutCell(win)
    end
end)

-- If a window is only dragged a little bit, don't move it.
-- This is to avoid accidentally moving windows when trying to click on them.
hs.window.filter.new():subscribe(hs.window.filter.windowMoved, function(win)
    local existing = currentLayout.windows[win:id()]
    if not existing then return end
    local current = win:frame()

    -- Don't adjust if it didn't move. This could happen if you resize the window.
    -- A resize still triggers a windowMoved event.
    if current.x == existing.x and current.y == existing.y then return end

    local tolerance = 50
    if math.abs(current.x - existing.x) < tolerance and math.abs(current.y - existing.y) < tolerance then
        win:setFrame(existing)
    end
end)

-- Automatically move windows to a configured position when showing them.
-- (Only works when assigning to a variablem)
appwatcher = hs.application.watcher.new(function(appName, event, app)
    local handlers = {
        [hs.application.watcher.launched] = handleAppVisible,
        [hs.application.watcher.unhidden] = handleAppVisible,
    }
    if handlers[event] then handlers[event](app, app:name()) end
end):start()

function handleAppVisible(app, appName)
    -- If in laptop mode, don't do anything.
    if onLaptop then return end

    local config = apps[appName]
    if not config then return end
    local windows = app:visibleWindows()

    -- Don't move windows if there are more than one. It's awkward.
    -- Maybe eventually check to see if all the windows are in the same position
    -- in which case it might make sense to reposition them all then.
    if #windows ~= 1 then return end

    for _, win in pairs(windows) do
        -- Position the window if it's not already in the layout.
        if not currentLayout.windows[win:id()] then
            local position = nil

            -- If the app should be in the layout, place it there.
            if currentLayout.preset.apps[appName] then
                local cell = currentLayout.preset.apps[appName].cell
                position = currentLayout.preset.cells[cell][currentLayoutConfiguration]
            elseif config.position then
                position = config.position
            end

            if position then positionWindowUsingGrid(win, position) end
        end
    end
end
