local summon = {}

summon.via = function(modalKey)
  local modal = modal('Summon', modalKey, {timeout=1, text='Summoning...'})

  hs.fnutils.map(apps, function(app)
    if app.key then
      modal:bind(modalKey, app.key, function()
        hs.application.launchOrFocusByBundleID(app.id)
        modal:exit()
      end)
    end
  end)
end

return summon
