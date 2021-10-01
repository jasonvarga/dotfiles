----------------------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------------------

-- hyper = "cmd alt ctrl"
require('helpers')

local chain = require('chain')

hs.loadSpoon('Hyper')
hyper = spoon.Hyper:start({applications = {}}):setHyperKey('F19')

----------------------------------------------------------------------------------------------------
-- Configuration File Auto-Reload
----------------------------------------------------------------------------------------------------

hs.loadSpoon('ReloadConfiguration')
spoon.ReloadConfiguration:start()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded', withdrawAfter = 1}):send()


----------------------------------------------------------------------------------------------------
-- Summon
----------------------------------------------------------------------------------------------------
local summonModalBindings = {
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
}

local summon = function(app)
  hs.application.open(app)
end

local sm = hs.hotkey.modal.new()
sm.start = function()
  hyper:bind({}, 'space', function()
    print('entering sm modal')
    sm:enter()
  end)
  hyper:bind({}, 'escape', function()
    print('closing sm modal')
    sm:exit()
  end)
  for key,app in pairs(summonModalBindings) do
      sm:bind({}, key, function()
        summon(app)
        sm:exit()
      end)
  end
end
sm.start()


----------------------------------------------------------------------------------------------------
-- Grid
----------------------------------------------------------------------------------------------------

hs.window.animationDuration = 0.2
hs.grid.setGrid('30x20')
hs.grid.setMargins('15x15') -- id like 30x30, but https://github.com/Hammerspoon/hammerspoon/issues/2955

positions = {
  full     = '0,0 30x20',

  center = {
    large  = '4,1 22x18',
    medium = '6,1 18x18',
    small  = '8,2 14x16',
    tiny   = '9,3 12x12',
  },

  quarters = {
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

  threeQuarters = {
    left   = '0,0 25x20',
    right  = '5,0 25x20',
  },
}

--------------------------------------------------------------------------------
-- Grid Movements
--------------------------------------------------------------------------------

local chainX = { 'thirds', 'halves', 'twoThirds', 'quarters' }
local chainY = { 'thirds', 'full' }
local centers = positions.center
hyper:bind({}, 'up', chain({positions.full, centers.large, centers.medium, centers.small, centers.tiny}))
hyper:bind({}, 'left', chain(getPositions(chainX, 'left')))
hyper:bind({}, 'right', chain(getPositions(chainX, 'right')))
hyper:bind({}, 'down', chain(getPositions(chainY, 'center')))


--------------------------------------------------------------------------------
-- Multi Window Layouts
--------------------------------------------------------------------------------

currentLayout = nil

layouts = {
  {
    name = 'Browser',
    description = 'Focused in the center',
    apps = {
      Safari = positions.center.medium,
    }
  },
  {
    name = 'Code with Browser',
    description = '50/50',
    apps = {
      Safari = positions.halves.left,
      Code = positions.halves.right
    }
  },
  {
    name = 'Code with Browser',
    description = '70/30',
    apps = {
      Safari = positions.thirds.left,
      Code = positions.twoThirds.right
    }
  },
  {
    name = 'Code and Ray',
    description = '75/25',
    apps = {
      Ray = positions.quarters.left,
      Code = positions.threeQuarters.right
    }
  },
  {
    name = 'Code, Ray, Browser',
    description = 'Appropriately distributed',
    apps = {
      Ray = positions.quarters.left,
      Safari = '5,0 10x20',
      Code = positions.halves.right
    }
  }
}

bindLayouts(layouts)
hyper:bind({}, 'r', function () resetLayout() end)
hyper:bind({}, 'm', function () toggleMaximized() end)
hyper:bind({}, 'f', function () toggleZenFocus() end)
