----------------------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------------------

hs.loadSpoon('ReloadConfiguration'):start()
local notification = hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loading...'}):send()

hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.radius = 6

require('helpers')
require('modals')
positions = require('positions')
layouts = require('layouts')
apps = require('apps')
hyper = require('hyper'):setHyperKey('F19')

----------------------------------------------------------------------------------------------------
-- Window Management
----------------------------------------------------------------------------------------------------

if hs.screen.allScreens()[1]:name() == 'Built-in Retina Display' then onLaptop = true end
windowMargin = 20
if onLaptop then windowMargin = 0 end

hs.window.animationDuration = 0
hs.grid.setGrid('30x20')
hs.grid.setMargins(string.format('%sx%s', windowMargin, windowMargin))

require('windows')

-- Grid Movements
local chain = require('chain')
local chainX = { 'thirds', 'halves', 'twoThirds', 'fiveSixths', 'sixths', }
local chainY = { 'thirds', 'full' }
local centers = positions.center
bindHyper('up', chain({positions.full, centers.large, centers.medium, centers.small, centers.tiny}))
bindHyper('left', chain(getPositions(chainX, 'left')))
bindHyper('right', chain(getPositions(chainX, 'right')))
bindHyper('down', chain(getPositions(chainY, 'center')))

-- Multi-window layouts
bindLayoutSelector('l')
bindPositionSelector('return')
bindHyper('r', resetLayout)
bindHyper('h', hideFloatingWindows)
bindHyper('s', function ()
    saveLayoutSnapshot()
    hs.alert.show('Layout snapshotted')
end)
bindHyper('delete', function ()
    removeWindowFromLayout(hs.window.focusedWindow())
    hs.alert.show("Window removed from layout")
end)
bindHyper('m', toggleMaximized)
bindHyper('d', setToDefaultPosition)
bindHyper('t', toggleLayout)
bindHyper('c', centerWindow)
bindWarp('w')
bindHyper('n', focusNextCellWindow)
bindHyper('p', focusPreviousCellWindow)
bindHyper('f', toggleFocusMode)


----------------------------------------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------------------------------------

-- Summon apps using hyper+o then key defined in apps.lua
require('summon').via('o')

bindHyper('`', hs.toggleConsole)
hyper:bind('cmd', '`', function() hs.console.clearConsole() end)
bindHyper('f1', function() hs.osascript.applescript('tell app "System Events" to tell appearance preferences to set dark mode to not dark mode') end)

-- Quick entry in Things.app
hyper:bind('cmd', '=', function() hs.eventtap.keyStroke({'cmd', 'alt', 'shift', 'ctrl'}, '=') end)

--------------------------------------------------------------------------------
-- Done!
--------------------------------------------------------------------------------

notification:withdraw()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded', withdrawAfter = 1}):send()
