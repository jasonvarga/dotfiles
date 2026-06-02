-- Snaps the source window to the target window's frame, and adds the source
-- to the layout if the target is already in it.
function warpWindowToWindow(source, target)
    positionWindowUsingRect(source, target:frame())
    if currentLayout.windows[target:id()] then
        currentLayout.windows[source:id()] = target:frame()
    end
end

local warpActive = false
local warpSource = nil
local warpTarget = nil
local warpTap = nil
local warpCanvas = nil
local warpAlert = nil
local warpCandidates = nil

local function warpHighlight(win)
    if not win then
        if warpCanvas then warpCanvas:hide() end
        return
    end
    if not warpCanvas then
        warpCanvas = hs.canvas.new({x = 0, y = 0, w = 0, h = 0})
        warpCanvas:level(hs.canvas.windowLevels.floating)
        warpCanvas:canvasMouseEvents(false, false, false, false)
        warpCanvas[1] = {
            type = 'rectangle',
            action = 'strokeAndFill',
            fillColor = {red = 0.2, green = 0.5, blue = 1, alpha = 0.18},
            strokeColor = {red = 0.2, green = 0.5, blue = 1, alpha = 0.9},
            strokeWidth = 5,
            roundedRectRadii = {xRadius = 8, yRadius = 8},
        }
    end
    local f = win:frame()
    warpCanvas:frame({x = f.x, y = f.y, w = f.w, h = f.h})
    warpCanvas:show()
end

-- Snapshots the standard windows (excluding the source) and their frames once,
-- front-to-back, so hit testing during the session is pure arithmetic with no
-- expensive Accessibility calls on every mouse move.
local function snapshotCandidates()
    warpCandidates = {}
    for _, win in ipairs(hs.window.orderedWindows()) do
        if win:isStandard() and win:id() ~= warpSource:id() then
            table.insert(warpCandidates, {win = win, frame = win:frame()})
        end
    end
end

local function windowUnderMouse()
    local p = hs.mouse.absolutePosition()
    for _, candidate in ipairs(warpCandidates) do
        local f = candidate.frame
        if p.x >= f.x and p.x <= f.x + f.w and p.y >= f.y and p.y <= f.y + f.h then
            return candidate.win
        end
    end
    return nil
end

local function endWarpSession()
    warpActive = false
    warpTarget = nil
    warpCandidates = nil
    if warpTap then warpTap:stop(); warpTap = nil end
    if warpCanvas then warpCanvas:delete(); warpCanvas = nil end
    if warpAlert then hs.alert.closeSpecific(warpAlert); warpAlert = nil end
end

local function startWarpSession()
    warpSource = hs.window.focusedWindow()
    if not warpSource then return end
    warpActive = true
    snapshotCandidates()
    warpAlert = hs.alert.show('Click a window to warp to…  (hyper+w for list, esc to cancel)', 10)

    warpTap = hs.eventtap.new({
        hs.eventtap.event.types.mouseMoved,
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.rightMouseDown,
        hs.eventtap.event.types.keyDown,
    }, function(e)
        local t = e:getType()
        if t == hs.eventtap.event.types.mouseMoved then
            local target = windowUnderMouse()
            if target ~= warpTarget then
                warpTarget = target
                warpHighlight(warpTarget)
            end
            return false
        elseif t == hs.eventtap.event.types.keyDown then
            if e:getKeyCode() == hs.keycodes.map.escape then
                endWarpSession()
                return true
            end
            return false
        elseif t == hs.eventtap.event.types.rightMouseDown then
            endWarpSession()
            return true
        elseif t == hs.eventtap.event.types.leftMouseDown then
            local target = windowUnderMouse()
            if target then warpWindowToWindow(warpSource, target) end
            endWarpSession()
            return true
        end
    end)
    warpTap:start()

    warpTarget = windowUnderMouse()
    warpHighlight(warpTarget)
end

local function showWarpChooser()
    local source = warpSource
    if not source then return end
    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        warpWindowToWindow(source, choice.window)
    end)
    local windows = hs.fnutils.filter(hs.window.visibleWindows(), function(win)
        return win:id() ~= source:id() and win:frame() ~= source:frame()
    end)
    local choices = map(function(window)
        local app = window:application()
        return {
            text = app:name(),
            subText = window:title() or '--',
            window = window,
            image = hs.image.imageFromAppBundle(window:application():bundleID()),
        }
    end, windows)
    chooser:searchSubText(true):choices(choices):query(''):show()
end

function bindWarp(key)
    hyper:bind({}, key, function()
        if warpActive then
            -- Second press: drop into the keyboard chooser using the same source.
            endWarpSession()
            showWarpChooser()
        else
            startWarpSession()
        end
    end)
end
