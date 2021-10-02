local summon = {}

summon.start = function(modalKey, bindings)
  local modal = modal('Summon', modalKey, {timeout=1})

  for key,app in pairs(bindings) do
      modal:bind({}, key, function()
        hs.application.open(app)
        modal:exit()
      end)
  end
end

return summon
