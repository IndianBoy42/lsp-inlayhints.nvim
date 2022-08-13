local utils = {}

function utils.cancel_requests(client, ids)
  for _, id in ipairs(ids or {}) do
    client.cancel_request(id)
  end
end

function utils.cancel_pending_requests(client, bufnr, method)
  for id, r in pairs(client.requests) do
    if r.method == method and r.bufnr == bufnr then
      client.cancel_request(id)
    end
  end
end

local function cleanup_timer(timer)
  if timer then
    if timer:has_ref() then
      timer:stop()
      if not timer:is_closing() then
        timer:close()
      end
    end
    timer = nil
  end
end

local scheduler = {}

function scheduler:new()
  local t = {
    timer = vim.loop.new_timer(),
  }

  setmetatable(t, self)
  self.__index = self

  return t
end

function scheduler:schedule(fn, delay)
  delay = delay or 0
  self.timer:start(delay, 0, function()
    self:run(fn)
  end)
end

function scheduler:run(fn)
  vim.schedule_wrap(fn)()
end

function scheduler:clear()
  cleanup_timer(self.timer)
  self = nil
end

utils.scheduler = scheduler

local cancellationTokenSource = {}

function cancellationTokenSource:new()
  local t = {
    token = {},
  }

  function self:cancel()
    t.token.isCancellationRequested = true
  end

  setmetatable(t, self)
  self.__index = self

  return t
end

utils.cancellationTokenSource = cancellationTokenSource

utils.tbl_map = function(fn, t)
  local ret = {}
  for k, v in pairs(t) do
    ret[k] = fn(v)
  end
  return ret
end

return utils
