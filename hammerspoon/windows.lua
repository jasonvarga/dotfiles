require('autosizes')

settingLayout = false
currentLayout = nil
maximizedWindows = {}
zenWindow = nil
layoutBeforeZen = nil

function moveApp(application, cell)
  local app = getOrOpenApp(application)
  app:unhide()
  for _, window in pairs(app:allWindows()) do
    positionWindow(window, cell)
  end
end

function positionWindow(window, cell, saveToLayout)
  hs.grid.set(window, cell)
  if saveToLayout == false then
    currentLayout.windows[window:id()] = nil
  else
    currentLayout.windows[window:id()] = asGridCellString(cell)
  end
end

function asGridCellString(cell)
  if type(cell) == 'string' then return cell end
  return string.format("%d,%d %dx%d", cell.x, cell.y, cell.w, cell.h)
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
  local layout = hs.fnutils.find(layouts, function(l) return l.name == name end)
  applyLayout(layout)
end

function applyLayout(layout)
  settingLayout = true
  currentLayout = layout
  currentLayout.windows = {}
  for app,cell in pairs(layout.apps) do
    moveApp(app, cell)
  end
  hideWindowsExcept(layout.apps)
  hs.timer.doAfter(hs.window.animationDuration, function() settingLayout = false end)
end

function resetLayout()
  if currentLayout then setLayout(currentLayout.name) end
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
function toggleZenFocus(cell)
  local win = hs.window.focusedWindow()

  if zenWindow == win.id then
    zenWindow = nil
    if layoutBeforeZen then
      applyLayout(layoutBeforeZen)
      win:focus()
    end
  else
    hs.grid.set(win, cell)
    hideWindowsExcept({[win:application():name()] = true})
    layoutBeforeZen = currentLayout
    zenWindow = win.id
  end
end

-- Moves a window to its default position as defined in apps.lua
function setToDefaultPosition()
  local win = hs.window.focusedWindow()
  local app = win:application()
  local config = hs.fnutils.find(apps, function(config) return config.id == app:bundleID() end)
  if config.position then
    positionWindow(win, config.position, false)
  else
    openPositionSelector()
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

function toggleLayout()
  local layout = hs.fnutils.find(layouts, function(l) return l.name == currentLayout.name end)
  if layout == nil then return end
  local toggle = layout.toggle
  if toggle == nil then return end
  setLayout(toggle)
end

function bindWarp(key)
  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    local cell = hs.grid.get(choice.window)
    positionWindow(hs.window.focusedWindow(), cell)
  end)

  hyper:bind({}, key, function()
    local windows = hs.fnutils.filter(hs.window.visibleWindows(), function(win)
      local focusedWin = hs.window.focusedWindow()
      return win:id() ~= focusedWin:id() and win:frame() ~= focusedWin:frame()
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
  end)
end

function hideFloatingWindows()
  for _,window in pairs(hs.window.visibleWindows()) do
    if currentLayout.windows[window:id()] == nil then
      window:minimize()
    end
  end
end

function focusNextCellWindow()
  local windows = getWindowsInFocusedCell()
  if #windows == 0 then return end
  local focusedIndex = hs.fnutils.indexOf(windows, hs.window.focusedWindow())
  local nextWindow = windows[focusedIndex+1]
  if nextWindow then
    nextWindow:focus()
  else
    local prevWindow = windows[1]
    prevWindow:focus()
  end
end

function focusPreviousCellWindow()
  local windows = getWindowsInFocusedCell()
  if #windows == 0 then return end
  local focusedIndex = hs.fnutils.indexOf(windows, hs.window.focusedWindow())
  local nextWindow = windows[focusedIndex-1]
  if nextWindow then
    nextWindow:focus()
  else
    local prevWindow = windows[#windows]
    prevWindow:focus()
  end
end

function getWindowsInFocusedCell()
  local window = hs.window.focusedWindow()
  local windows = hs.window.visibleWindows()
  windows = hs.fnutils.filter(windows, function(w) return w:frame() == window:frame() end)
  table.sort(windows, function(a, b) return a:id() < b:id() end)
  return windows
end

function applyNextLayout()
  local currentLayoutIndex = hs.fnutils.indexOf(layouts, currentLayout)
  local nextLayoutIndex = currentLayoutIndex + 1
  local nextLayout = layouts[nextLayoutIndex]
  if nextLayout == nil then nextLayout = layouts[1] end
  setLayout(nextLayout.name)
end

function openPositionSelector()
    local chooser = hs.chooser.new(function(choice)
        positionWindow(hs.window.frontmostWindow(), choice.position)
    end)

    chooser:choices({
        { text = "L", position = positions.center.large },
        { text = "M", position = positions.center.medium },
        { text = "S", position = positions.center.small },
        { text = "XS", position = positions.center.tiny },
        { text = "XXS", position = positions.center.mini },
    }):query(''):show()
end

function bindPositionSelector(key)
    hyper:bind({}, key, function()
        openPositionSelector()
    end)
end
