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

hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.radius = 6

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
bindHyper('up', chain({positions.full, centers.large, centers.medium, centers.small, centers.tiny}))
bindHyper('left', chain(getPositions(chainX, 'left')))
bindHyper('right', chain(getPositions(chainX, 'right')))
bindHyper('down', chain(getPositions(chainY, 'center')))

-- Multi-window layouts
bindLayoutSelector('l')
bindHyper('r', resetLayout)
bindHyper('m', toggleMaximized)
bindHyper('d', setToDefaultPosition)
bindHyper('f', function() toggleZenFocus(positions.center.medium) end)
setInferredLayout()

----------------------------------------------------------------------------------------------------
-- Misc Keybindings
----------------------------------------------------------------------------------------------------

bindHyper('`', hs.toggleConsole)
bindHyper('f1', function() hs.execute('osascript -e \'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode\'') end)

--------------------------------------------------------------------------------
-- Done!
--------------------------------------------------------------------------------

notification:withdraw()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded', withdrawAfter = 1}):send()
