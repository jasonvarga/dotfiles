----------------------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------------------

require('helpers')
require('modals')
require('windows')
positions = require('positions')
layouts = require('layouts')
apps = require('apps')
hyper = require('hyper'):setHyperKey('F19')

hs.loadSpoon('ReloadConfiguration'):start()
local notification = hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loading...'}):send()

----------------------------------------------------------------------------------------------------
-- Summon
----------------------------------------------------------------------------------------------------

require('summon').via('o')

----------------------------------------------------------------------------------------------------
-- Window Management
----------------------------------------------------------------------------------------------------

hs.window.animationDuration = 0.2
hs.grid.setGrid('30x20')
hs.grid.setMargins('15x15') -- id like 30x30, but https://github.com/Hammerspoon/hammerspoon/issues/2955

-- Grid Movements
local chain = require('chain')
local chainX = { 'thirds', 'halves', 'twoThirds', 'fiveSixths', 'sixths', }
local chainY = { 'thirds', 'full' }
local centers = positions.center
hyper:bind({}, 'up', chain({positions.full, centers.large, centers.medium, centers.small, centers.tiny}))
hyper:bind({}, 'left', chain(getPositions(chainX, 'left')))
hyper:bind({}, 'right', chain(getPositions(chainX, 'right')))
hyper:bind({}, 'down', chain(getPositions(chainY, 'center')))

-- Multi-window layouts
bindLayoutSelector('l')
hyper:bind({}, 'r', resetLayout)
hyper:bind({}, 'm', toggleMaximized)
hyper:bind({}, 'f', function() toggleZenFocus(positions.center.medium) end)

----------------------------------------------------------------------------------------------------
-- Misc Keybindings
----------------------------------------------------------------------------------------------------

hyper:bind({}, '`', hs.toggleConsole)
hyper:bind({}, 'f1', function() hs.execute('osascript -e \'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode\'') end)

--------------------------------------------------------------------------------
-- Done!
--------------------------------------------------------------------------------

notification:withdraw()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded', withdrawAfter = 1}):send()
