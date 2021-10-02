local summon = function(app)
  hs.application.open(app)
end
  
local sm = hs.hotkey.modal.new()

sm.start = function(key, bindings)
  local timer

  hyper:bind({}, 'space', function() sm:enter() end)
  sm:bind({}, 'escape', function() sm:exit() end)

  function sm:entered()
    timer = hs.timer.doAfter(1, function() sm:exit() end)
  end

  function sm:exited()
    if timer then timer:stop() end
  end

  for key,app in pairs(bindings) do
      sm:bind({}, key, function()
        summon(app)
        sm:exit()
      end)
  end

end

return sm
