currentLayout = nil
previousLayout = nil

function startRegularMode()
    if (previousLayout == nil) then
        printi('starting regular mode and theres no previousLayout')
        currentLayout = { windows = {} }
    else
        currentLayout = previousLayout
        printi(currentLayout)
        positionWindows(currentLayout.windows)
    end

    previousLayout = nil
end

function stopRegularMode()
    previousLayout = currentLayout
    currentLayout = nil
end

function hideFloatingWindows()
    for _,window in pairs(hs.window.visibleWindows()) do
        if currentLayout.windows[window:id()] == nil then
            window:minimize()
        end
    end
end

function saveLayoutSnapshot()
    for _,window in pairs(hs.window.visibleWindows()) do
        if window:isStandard() then -- Avoid moving dialogs, etc.
            currentLayout.windows[window:id()] = window:frame()
        end
    end
end

function resetLayout()
    if (currentMode == 'focus') then
        setWindowMode('regular')
    end

    if not currentLayout.windows then
        return
    end

    positionWindows(currentLayout.windows)
    hideFloatingWindows()
end

function positionWindows(windows)
    for id,frame in pairs(windows) do
        local window = hs.window.find(id)
        if window then
            positionWindowUsingRect(window, frame)
        end
    end
end

function removeWindowFromLayout(win)
    if currentLayout.windows[win:id()] then
        currentLayout.windows[win:id()] = nil
    end
end


function bindLayoutSelector(key)
    local chooser = hs.chooser.new(function(choice)
        setWindowMode('regular')
        applyPresetLayout(choice.layout)
    end)

    hyper:bind({}, key, function()
        local choices = map(function(layout)
        return {
            ["text"] = layout.name,
            ["subText"] = layout.description,
            ["layout"] = layout
        }
        end, layouts)
        chooser:searchSubText(true):choices(choices):query(''):show()
    end)
end

function applyPresetLayout(layout)
    currentLayout = { windows = {} }
    currentLayoutConfiguration = 1
    for app,cells in pairs(layout.apps) do
        positionAppUsingGrid(app, cells[1])
    end
    currentLayout.preset = layout
    printi(layout.apps)
    hideWindowsExcept(layout.apps)
    saveLayoutSnapshot()
end

function toggleLayout()
    if currentLayout == nil then return end
    currentLayoutConfiguration = currentLayoutConfiguration + 1
    printi(currentLayout)
    for app,cells in pairs(currentLayout.preset.apps) do
        if cells[currentLayoutConfiguration] == nil then currentLayoutConfiguration = 1 end
        positionAppUsingGrid(app, cells[currentLayoutConfiguration])
    end
    saveLayoutSnapshot()
end

function cycleLayouts()
    local nextLayoutIndex = getNextLayoutIndex()
    local nextLayout = layouts[nextLayoutIndex]
    applyPresetLayout(nextLayout)
    lastCycledLayoutIndex = nextLayoutIndex
end

function getNextLayoutIndex()
    if lastCycledLayoutIndex == nil then return 1 end
    local nextIndex = lastCycledLayoutIndex + 1
    if nextIndex > #layouts then nextIndex = 1 end
    return nextIndex
end
