local M = {}

M.data = {
  buf_order = {},
  tabline_order = {},
  cycle = { active = false, index = 0 },
}

function M.reset_cycle()
  M.data.cycle.active = false
  M.data.cycle.index = 0
end

function M.set_cycle(index)
  M.data.cycle.active = true
  M.data.cycle.index = index
end

function M.is_cycling()
  return M.data.cycle.active
end

return M
