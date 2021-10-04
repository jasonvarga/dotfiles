-- Subscribe to windows being closed. If the app has no visible windows, hide the app.
-- The automatic layouts rely on app hiding events, not window closing events.
wf = hs.window.filter.new()
wf:subscribe(hs.window.filter.hasNoWindows, function(win) win:application():hide() end)

-- When apps are opened/quit/hidden/unhidden, apply various rules.
appwatcher = hs.application.watcher.new(function(appName, event, app)
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
  if apps[appName].position then
    hs.grid.set(app:mainWindow(), apps[appName].position)
  end

  local rule = apps[appName].onShow
  if rule then hs.timer.doAfter(0.5, rule) end
end

function handleAppHidden(app, appName)
  local rule = apps[appName].onHide
  if rule then hs.timer.doAfter(0.5, rule) end
end
