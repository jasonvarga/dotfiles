local summon = {}

summon.via = function(modalKey)
  local modal = modal('Summon', modalKey, {timeout=1, text='Summoning...'})

  hs.fnutils.map(apps, function(app)
    if app.key then
      modal:bind(modalKey, app.key, function()
        local currentApp = hs.window.focusedWindow():application()
        if (currentApp:bundleID() == app.id) then
          currentApp:hide()
        else
          hs.application.launchOrFocusByBundleID(app.id)
        end
        modal:exit()
      end)
    end
  end)
end

return summon
