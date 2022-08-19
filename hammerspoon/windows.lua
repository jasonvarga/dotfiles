initialMode = 'regular'
currentMode = nil
previousMode = initialMode
lastCycledLayoutIndex = nil
currentLayoutConfiguration = nil

require('windows.regular')
require('windows.focus')
require('windows.common')
require('windows.subscriptions')
require('windows.resizer')

function setWindowMode(mode)
    if (mode == currentMode) then
        return
    end

    previousMode = currentMode
    currentMode = mode

    if mode == "focus" then
        startFocusMode()
    elseif mode == "regular" then
        startRegularMode()
    end

    if previousMode == "focus" then
        stopFocusMode()
    elseif previousMode == "regular" then
        stopRegularMode()
    end
end

function toggleFocusMode()
    if currentMode == "focus" then
        setWindowMode(previousMode)
    elseif currentMode == "regular" then
        setWindowMode("focus")
    end
end

setWindowMode(initialMode);
