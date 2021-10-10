require('autosizes')

settingLayout = false

local wm = {
  currentLayout = nil,
  maximizedWindows = {},
  zenWindow = nil,
  layoutBeforeZen = nil
}

function moveApp(application, cell)
  local app = getOrOpenApp(application)
  app:unhide()
  for _, window in pairs(app:allWindows()) do
    positionWindow(window, cell)
  end
end

function positionWindow(window, cell)
  hs.grid.set(window, cell)
end

function getOrOpenApp(application)
  return hs.application.open(apps[application].id, 10)
end

function hideApp(application)
  local app = hs.application.get(application)
  if app == nil then
    return false
  end
  app:hide()
end

function bindLayoutSelector(key)
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
  settingLayout = true
  local layout = hs.fnutils.find(layouts, function(l)
    return l.name == name
  end)
  for app,cell in pairs(layout.apps) do
    moveApp(app, cell)
  end
  hideWindowsExcept(layout.apps)
  wm.currentLayout = name
  hs.timer.doAfter(hs.window.animationDuration, function() settingLayout = false end)
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
    if wm.layoutBeforeZen then
      setLayout(wm.layoutBeforeZen)
      win:focus()
    end
  else
    hs.grid.set(win, cell)
    hideWindowsExcept({[win:application():name()] = true})
    wm.layoutBeforeZen = wm.currentLayout
    wm.zenWindow = win.id
  end
end

-- Moves a window to its default position as defined in apps.lua
function setToDefaultPosition()
  local win = hs.window.focusedWindow()
  local app = win:application()
  local config = hs.fnutils.find(apps, function(config) return config.id == app:bundleID() end)
  if config.position then
    positionWindow(win, config.position)
  else
    hs.alert(app:name() .. ' has no default position')
  end
end

function setInferredLayout()
  local layout = getInferredLayout()
  if layout then
    setLayout(layout)
    hs.alert('Layout "' .. layout .. '"')
  else
    hs.alert('No inferred layout')
  end
end

-- Guesses what the current layout should be based on the current window layout.
function getInferredLayout()
  -- Get the apps across all layouts
  local managedApps = {}
  for _,layout in pairs(layouts) do
    for app,_ in pairs(layout.apps) do managedApps[app] = true end
  end

  -- Get the visible windows, but only onces that are managed apps
  local visibleApps = {}
  for _,window in pairs(hs.window.visibleWindows()) do
    local app = window:application()
    if managedApps[app:name()] then visibleApps[app:name()] = true end
  end

  -- Get potential layouts for the current visible apps.
  -- There may be more than one layout with matching apps.
  local inferrableLayouts = {}
  for _,layout in pairs(layouts) do
    if hasMatchingApps(visibleApps, layout.apps) then
      inferrableLayouts[#inferrableLayouts+1] = layout
    end
  end

  if #inferrableLayouts == 0 then return nil end

  -- Check if there's a layout that matches the positions of all visible windows.
  local inferredLayout = nil
  for _,layout in pairs(inferrableLayouts) do
    if isMatchingLayout(visibleApps, layout.apps) then
      inferredLayout = layout.name
    end
  end

  -- Use the exact layout match, or just the first with matching apps.
  if inferredLayout then return inferredLayout end
  return inferrableLayouts[1].name
end

-- Check if the given apps are all in the given layout.
function hasMatchingApps(visibleApps, layoutApps)
  if size(visibleApps) ~= size(layoutApps) then return false end
  for app,_ in pairs(layoutApps) do
    if not visibleApps[app] then return false end
  end
  return true
end

-- Check if the given apps are all in the layout defined positions.
function isMatchingLayout(visibleApps, apps)
  for appName,_ in pairs(visibleApps) do
    local app = getApp(appName)
    local window = app:mainWindow()
    local windowCell = hs.grid.get(window)
    local windowRect = hs.grid.getCell(windowCell, hs.screen.mainScreen())
    local layoutRect = hs.grid.getCell(apps[appName], hs.screen.mainScreen())
    if hs.geometry.equals(windowRect, layoutRect) then return true end
  end
  return false
end

return wm
