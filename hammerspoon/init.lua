----------------------------------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------------------------------

hyper = "cmd alt ctrl"
require('helpers')
require('summon')


----------------------------------------------------------------------------------------------------
-- Configuration File Auto-Reload
----------------------------------------------------------------------------------------------------

hs.loadSpoon('ReloadConfiguration')
spoon.ReloadConfiguration:start()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded'}):send()


----------------------------------------------------------------------------------------------------
-- Misc Keybindings
----------------------------------------------------------------------------------------------------

hs.hotkey.bind(hyper, 'f1', function()
  hs.execute('osascript -e \'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode\'')
end)

hs.hotkey.bind(hyper, 'h', function()
  hs.execute('/opt/homebrew/bin/php /Users/jason/.dotfiles/yabai/hide-floating-windows.php')
end)

--------------------------------------------------------------------------------
-- Summon Specific Apps
--------------------------------------------------------------------------------

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

registerModalBindings(hyper, 'space', hs.fnutils.map(summonModalBindings, function(app)
  return function() summon(app) end
end), true)


--------------------------------------------------------------------------------
-- Yabai Window Management
--------------------------------------------------------------------------------

local yabaiKeyBindings = {
  ['left'] = 'window --focus west',
  ['down'] = 'window --focus south',
  ['up'] = 'window --focus north',
  ['right'] = 'window --focus east',
  ['n'] = 'window --focus stack.next OR window --focus stack.first',
  ['p'] = 'window --focus stack.prev OR window --focus stack.last',
  ['o'] = 'window --toggle zoom-parent',
  ['m'] = 'window --toggle zoom-fullscreen',
  ['0'] = 'space --balance',
  ['-'] = 'window --resize left:50:0 AND window --resize right:-50:0',
  ['='] = 'window --resize left:-50:0 AND window --resize right:50:0',
  ['i'] = function() stackline.config:toggle('appearance.showIcons') end,
}

local yabaiShiftKeyBindings = {
  ['-'] = 'window --resize left:200:0 AND window --resize right:-200:0',
  ['='] = 'window --resize left:-200:0 AND window --resize right:200:0',
}

local yabaiModalBindings = {
  ['left'] = 'window --warp west',
  ['down'] = 'window --warp south',
  ['up'] = 'window --warp north',
  ['right'] = 'window --warp east',
  ['h'] = 'window --warp west',
  ['j'] = 'window --warp south',
  ['k'] = 'window --warp north',
  ['l'] = 'window --warp east',
  ['n'] = 'window --stack next',
  ['p'] = 'window --stack prev',
  ['f'] = 'window --toggle float',
  ['s'] = 'window --toggle split',
  ['o'] = 'window --toggle zoom-parent',
  ['m'] = 'window --toggle zoom-fullscreen',
  [']'] = 'space --focus next',
  ['['] = 'space --focus prev',
  ['x'] = 'space --mirror x-axis',
  ['0'] = 'space --balance',
  ['i'] = function() stackline.config:toggle('appearance.showIcons') end,
  ['c'] = 'window --grid 12:6:1:1:4:10',
  ['r'] = function() hs.execute('launchctl kickstart -k "gui/${UID}/homebrew.mxcl.yabai"') end,
}

registerKeyBindings(hyper, hs.fnutils.map(yabaiKeyBindings, function(cmd)
  return function() yabai(cmd) end
end))

registerKeyBindings(hyper..'shift', hs.fnutils.map(yabaiShiftKeyBindings, function(cmd)
  return function() yabai(cmd) end
end))

local yabaiModal = registerModalBindings(hyper, 'y', hs.fnutils.map(yabaiModalBindings, function(cmd)
  return function() yabai(cmd) end
end))

function yabaiModal:entered()
  hs.window.highlight.ui.overlay = true
  hs.window.highlight.ui.overlayColor = {0.5,0.25,0.75,0.25}
  hs.window.highlight.start()
end

function yabaiModal:exited()
  hs.window.highlight.stop()
end


--------------------------------------------------------------------------------
-- Yabai Stack Icons
--------------------------------------------------------------------------------

stackline = require('stackline')

stackline:init()
stackline.config:set('paths.yabai', '/opt/homebrew/bin/yabai')
stackline.config:set('appearance.size', 23)
stackline.config:set('appearance.iconPadding', 1)
stackline.config:set('appearance.offset.x', 5)
stackline.config:set('appearance.offset.y', 12)
stackline.config:set('appearance.pillThinness', 4)
stackline.config:set('appearance.showIcons', false)
