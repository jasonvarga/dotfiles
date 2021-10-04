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
  local code = hs.application.get(apps['Code'].id)
  local safari = hs.application.get(apps['Safari'].id)
  local ray = hs.application.get(apps['Ray'].id)
  local rayIsVisible = ray and not ray:isHidden()
  local safariIsVisible = safari and not safari:isHidden()
  local codeIsVisible = code and not code:isHidden()

  local rules = {
    Safari = function ()
      if codeIsVisible then
        if rayIsVisible then setLayout('Code, Ray, Browser')
        else setLayout('Code and Browser') end
      end
    end,
    Code = function ()
      if rayIsVisible and safariIsVisible then setLayout('Code, Ray, Browser')
      elseif safariIsVisible then setLayout('Code and Browser') end
    end,
    Ray = function ()
      if not code then getOrOpenApp('Code') end
      if safariIsVisible then setLayout('Code, Ray, Browser')
      else setLayout('Code and Ray') end
    end,
    Spotify = function () hs.grid.set(app:mainWindow(), positions.center.small) end,
    Slack = function () hs.grid.set(app:mainWindow(), positions.center.tiny) end,
    Tower = function () hs.grid.set(app:mainWindow(), positions.center.large) end,
    Messages = function () hs.grid.set(app:mainWindow(), positions.center.mini) end,
    iTerm2 = function () hs.grid.set(app:mainWindow(), positions.center.tiny) end,
  }

  if rules[appName] then
    hs.timer.doAfter(0.5, rules[appName])
  end
end

function handleAppHidden(app, appName)
  local code = hs.application.get(apps['Code'].id)
  local safari = hs.application.get(apps['Safari'].id)
  local ray = hs.application.get(apps['Ray'].id)
  local rayIsVisible = ray and not ray:isHidden()
  local safariIsVisible = safari and not safari:isHidden()
  local codeIsVisible = code and not code:isHidden()

  local rules = {
    Safari = function ()
      if codeIsVisible then
        if rayIsVisible then setLayout('Code and Ray')
        else setLayout('Code') end
      end
    end,
    Code = function ()
      if ray then
        if code then ray:hide() else ray:kill() end
      end
      if safariIsVisible then setLayout('Browser') end
    end,
    Ray = function ()
      if codeIsVisible then
        if safariIsVisible then setLayout('Code and Browser')
        else setLayout('Code') end
      end
    end,
  }

  if rules[appName] then
    hs.timer.doAfter(0.5, rules[appName])
  end
end
