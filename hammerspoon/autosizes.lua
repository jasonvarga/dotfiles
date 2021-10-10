-- todo: don't apply rules when in focus or maximized modes

-- Subscribe to windows being closed. If the app has no visible windows, hide the app.
-- The automatic layouts rely on app hiding events, not window closing events.
wf = hs.window.filter.new()
wf:subscribe(hs.window.filter.hasNoWindows, function(win)
  -- Some apps with a window leftover still sometimes trigger the hasNoWindows
  -- event. We'll need to check if there are windows instead of just hiding.
  local app = win:application()
  if #app:allWindows() == 0 then app:hide() end
end)

-- When apps are opened/quit/hidden/unhidden, apply various rules.
appwatcher = hs.application.watcher.new(function(appName, event, app)
  -- dont apply automatic rules if a layout is causing windows to be manipulated.
  if settingLayout then return end

  local handlers = {
    [hs.application.watcher.launched] = handleAppVisible,
    [hs.application.watcher.unhidden] = handleAppVisible,
    [hs.application.watcher.terminated] = handleAppHidden,
    [hs.application.watcher.hidden] = handleAppHidden,
  }
  -- pass app:name() because when terminated, the appName is nil.
  if handlers[event] then handlers[event](app, app:name()) end
end):start()

function handleAppVisible(app, appName)
  local config = apps[appName]
  if not config then return end
  if config.position then
    positionWindow(app:mainWindow(), config.position)
  end
  local rule = config.onShow
  if rule then rule() end
end

function handleAppHidden(app, appName)
  local config = apps[appName]
  if not config then return end
  local rule = config.onHide
  if rule then rule() end
end
