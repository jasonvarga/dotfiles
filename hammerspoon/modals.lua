function modal(name, key, opts)
  local log = hs.logger.new('modal', 'debug')
  local modal = hs.hotkey.modal.new()
  local mods = opts.mods or {}
  local timeout = opts.timeout or false
  local timer

  hyper:bind(mods, key, function() modal:enter() end)
  modal:bind('', 'escape', nil, function() modal:exit() end)

  function modal:entered()
    log.d('modal ' .. name .. ' entered')
    if timeout then
      timer = hs.timer.doAfter(1, function() modal:exit() end)
    end
  end

  function modal:exited()
    log.d('modal ' .. name .. ' exited')
    if timer then timer:stop() end
  end

  return modal
end
