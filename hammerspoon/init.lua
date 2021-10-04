----------------------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------------------

require('helpers')
require('modals')
require('windows')
hyper = require('hyper'):setHyperKey('F19')

hs.window.animationDuration = 0.2

hs.loadSpoon('ReloadConfiguration'):start()
local notification = hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loading...'}):send()



----------------------------------------------------------------------------------------------------
-- Summon
----------------------------------------------------------------------------------------------------

local summon = require('summon')
summon.start('space', {
  c = 'Visual Studio Code',
  b = 'Safari', -- browser
  s = 'Slack',
  m = 'Spotify', -- music
  i = 'iTerm',
  g = 'Tower',
  r = 'Ray',
  e = 'Mimestream', -- email
  f = 'Finder',
  t = 'Tinkerwell',
  d = 'TablePlus', -- database
})


----------------------------------------------------------------------------------------------------
-- Grid
----------------------------------------------------------------------------------------------------

hs.grid.setGrid('30x20')
hs.grid.setMargins('15x15') -- id like 30x30, but https://github.com/Hammerspoon/hammerspoon/issues/2955

positions = {
  full     = '0,0 30x20',

  center = {
    large  = '4,1 22x18',
    medium = '6,1 18x18',
    small  = '8,2 14x16',
    tiny   = '9,3 12x12',
    mini   = '11,4 8x10',
  },

  sixths = {
    left  = '0,0 5x20',
    right  = '25,0 5x20',
  },

  thirds = {
    left   = '0,0 10x20',
    center = '10,0 10x20',
    right  = '20,0 10x20',
  },

  halves = {
    left   = '0,0 15x20',
    right  = '15,0 15x20',
  },

  twoThirds = {
    left   = '0,0 20x20',
    right  = '10,0 20x20',
  },

  fiveSixths = {
    left   = '0,0 25x20',
    right  = '5,0 25x20',
  },
}

--------------------------------------------------------------------------------
-- Grid Movements
--------------------------------------------------------------------------------

local chain = require('chain')
local chainX = { 'thirds', 'halves', 'twoThirds', 'fiveSixths', 'sixths', }
local chainY = { 'thirds', 'full' }
local centers = positions.center
hyper:bind({}, 'up', chain({positions.full, centers.large, centers.medium, centers.small, centers.tiny}))
hyper:bind({}, 'left', chain(getPositions(chainX, 'left')))
hyper:bind({}, 'right', chain(getPositions(chainX, 'right')))
hyper:bind({}, 'down', chain(getPositions(chainY, 'center')))


--------------------------------------------------------------------------------
-- Multi Window Layouts
--------------------------------------------------------------------------------

layouts = {
  {
    name = 'Browser',
    description = 'Focused in the center',
    apps = {
      Safari = positions.center.medium,
    }
  },
  {
    name = 'Code',
    description = 'Focused in the center',
    apps = {
      Code = positions.center.medium,
    }
  },
  {
    name = 'Code and Browser',
    description = 'Code 50%, Browser 50%',
    apps = {
      Safari = positions.halves.left,
      Code = positions.halves.right
    }
  },
  {
    name = 'Code and Browser (narrow)',
    description = 'Code 66%, Browser 33%',
    apps = {
      Safari = positions.thirds.left,
      Code = positions.twoThirds.right
    }
  },
  {
    name = 'Code and Ray',
    description = 'Code 83%, Ray 17%',
    apps = {
      Ray = positions.sixths.left,
      Code = positions.fiveSixths.right
    }
  },
  {
    name = 'Code, Ray, Browser',
    description = 'Code 50%, Browser 33%, Ray 17%',
    apps = {
      Ray = positions.sixths.left,
      Safari = '5,0 10x20',
      Code = positions.halves.right
    }
  }
}

bindLayoutSelector('l', layouts)
hyper:bind({}, 'r', resetLayout)
hyper:bind({}, 'm', toggleMaximized)
hyper:bind({}, 'f', function() toggleZenFocus(positions.center.medium) end)
require('autosizes')

--------------------------------------------------------------------------------
-- Done!
--------------------------------------------------------------------------------

notification:withdraw()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded', withdrawAfter = 1}):send()
