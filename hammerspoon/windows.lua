local wm = {
  currentLayout = nil,
  maximizedWindows = {},
  zenWindow = nil,
  layoutBeforeZen = nil
}

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

function bindLayoutSelector(key, layouts)
  local chooser = hs.chooser.new(function(choice)
    local layout = choice.text
    if layout then
      setLayout(layout)
    end
  end)

  hyper:bind({}, key, function()
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
  wm.currentLayout = name
end

function resetLayout()
  if wm.currentLayout then setLayout(wm.currentLayout) end
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
function toggleMaximized()
  local win = hs.window.focusedWindow()
  local id = win:id()

  if wm.maximizedWindows[id] then
    hs.grid.set(win, wm.maximizedWindows[id])
    wm.maximizedWindows[id] = nil
  else
    local cell = hs.grid.get(win)
    wm.maximizedWindows[id] = cell
    hs.grid.maximizeWindow(win)
  end
end

-- Moves a window into the center of the screen, with every other app hidden.
-- Running a second time will return to the previous layout.
function toggleZenFocus(cell)
  local win = hs.window.focusedWindow()

  if wm.zenWindow == win.id then
    wm.zenWindow = nil
    if wm.layoutBeforeZen then setLayout(wm.layoutBeforeZen) end
  else
    hs.grid.set(win, cell)
    hideWindowsExcept({[win:application():name()] = true})
    wm.layoutBeforeZen = wm.currentLayout
    wm.zenWindow = win.id
  end
end

return wm