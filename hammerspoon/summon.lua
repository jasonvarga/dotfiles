local summon = {}

summon.via = function(modalKey)
  local modal = modal('Summon', modalKey, {timeout=1})

  hs.fnutils.map(apps, function(app)
    if app.key then
      modal:bind(modalKey, app.key, function()
        hs.application.launchOrFocusByBundleID(app.id)
      end)
    end
  end)
end

return summon
