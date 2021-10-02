--------------------------------------------------------------------------------
-- Language Helpers
--------------------------------------------------------------------------------

function map(f, t)
  n = {}

  for k,v in pairs(t) do
    n[k] = f(v);
  end

  return n;
end

function printi(...)
  return print(hs.inspect(...))
end

--------------------------------------------------------------------------------
-- Modal Helpers
--------------------------------------------------------------------------------

function modal(name, key, opts)
  local log = hs.logger.new('modal', 'debug')
  local modal = hs.hotkey.modal.new()
  local mods = opts.mods or {}
  local timeout = opts.timeout or false
  local timer

  hyper:bind(mods, key, function() modal:enter() end)
  modal:bind('', 'escape', nil, function() modal:exit() end)

  function modal:entered()
    log.d('modal ' .. name .. ' entered')
    if timeout then
      timer = hs.timer.doAfter(1, function() modal:exit() end)
    end
  end

  function modal:exited()
    log.d('modal ' .. name .. ' exited')
    if timer then timer:stop() end
  end

  return modal
end


--------------------------------------------------------------------------------
-- Grid Helpers
--------------------------------------------------------------------------------

function moveApp(application, cell)
  local app = getOrOpenApp(application)
  
  -- until the app open issue is fixed, we'll just
  -- bail here and you can re-run the command
  if app == nil then return end 
  
  app:unhide()
  local window = app:mainWindow()
  if window then
    hs.grid.set(window, cell, hs.screen.mainScreen())
  end
end

function getOrOpenApp(application)
  local app = hs.application.get(application)
  if not app then
    -- this should wait for the app to open. the app *does* open 
    -- but it always returns nil. even when increasing the time.
    app = hs.application.open(application, 0, true)
  end
  return app
end

function hideApp(application)
  local app = hs.application.get(application)
  if app == nil then
    return false
  end
  app:hide()
end

function getPositions(sizes, leftOrRight, topOrBottom)
  local applyLeftOrRight = function (size)
    if type(positions[size]) == 'string' then
      return positions[size]
    end
    return positions[size][leftOrRight]
  end

  local applyTopOrBottom = function (position)
    local h = math.floor(string.match(position, 'x([0-9]+)') / 2)
    position = string.gsub(position, 'x[0-9]+', 'x'..h)
    if topOrBottom == 'bottom' then
      local y = math.floor(string.match(position, ',([0-9]+)') + h)
      position = string.gsub(position, ',[0-9]+', ','..y)
    end
    return position
  end

  if (topOrBottom) then
    return map(applyTopOrBottom, map(applyLeftOrRight, sizes))
  end

  return map(applyLeftOrRight, sizes)
end

--------------------------------------------------------------------------------
-- Layout Helpers
--------------------------------------------------------------------------------

currentLayout = nil

function bindLayouts(layouts)
  local chooser = hs.chooser.new(function(choice)
    local layout = choice.text
    if layout then
      currentLayout = layout
      setLayout(layout)
    end
  end)

  hyper:bind({}, 'l', function()
    local choices = map(function(layout)
      return {
        ["text"] = layout.name,
        ["subText"] = layout.description,
      }
    end, layouts)
    chooser:searchSubText(true):choices(choices):query(''):show()
  end)
end

function setLayout(name)
  local layout = hs.fnutils.find(layouts, function(l)
    return l.name == name
  end)
  for app,cell in pairs(layout.apps) do
    moveApp(app, cell)
  end
  hideWindowsExcept(layout.apps)
end

function resetLayout()
  if currentLayout then setLayout(currentLayout) end
end

function hideWindowsExcept(allowed)
  local windows = hs.window.visibleWindows()
  for _,window in pairs(windows) do
    local app = window:application()
    local appName = app:name()
    if not allowed[appName] then
      app:hide()
    end
  end
end


-- Maximizes a window, remembering the previous size.
-- When run a second time, it will restore the window to its previous size.
--
-- Stores window sizes in a table keyed by window ID.
-- { ["123"] = "10,20 3x3", ["456"] = "10,20 3x3" }
maximizedWindows = {}
function toggleMaximized()
  local win = hs.window.focusedWindow()
  local id = win:id()

  if maximizedWindows[id] then
    hs.grid.set(win, maximizedWindows[id])
    maximizedWindows[id] = nil
  else
    local cell = hs.grid.get(win)
    maximizedWindows[id] = cell
    hs.grid.maximizeWindow(win)
  end
end


-- Moves a window into the center of the screen, with every other app hidden.
-- Running a second time will return to the previous layout.
zenWindow = nil
layoutBeforeZen = nil
function toggleZenFocus()
  local zenPosition = positions.center.medium
  local win = hs.window.focusedWindow()

  if zenWindow == win.id then
    zenWindow = nil
    if layoutBeforeZen then setLayout(layoutBeforeZen) end
  else
    local app = win:application()
    hs.grid.set(win, zenPosition)
    hideWindowsExcept({[win:application():name()] = true})
    layoutBeforeZen = currentLayout
    zenWindow = win.id
  end
end
