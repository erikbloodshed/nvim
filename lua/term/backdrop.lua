local api = vim.api

local M = {}
local backdrop_instances = {}

local Backdrop = {}
Backdrop.__index = Backdrop

function Backdrop:new(id, opts)
  opts = opts or {}

  local obj = {
    id = id,
    buf = nil,
    win = nil,
    opts = vim.tbl_extend('force', {
      opacity = 80,
      zindex = 45,
      color = "#000000"
    }, opts)
  }

  setmetatable(obj, self)
  return obj
end

function Backdrop:should_create()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  return normal.bg ~= nil and self.opts.opacity < 100
end

function Backdrop:create()
  if not self:should_create() then
    return false
  end

  self:destroy()

  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    return false
  end

  vim.bo[self.buf].buftype = "nofile"
  vim.bo[self.buf].filetype = "termswitch_backdrop"
  vim.bo[self.buf].bufhidden = "wipe"

  self.win = api.nvim_open_win(self.buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = self.opts.zindex,
  })

  if not self.win then
    if api.nvim_buf_is_valid(self.buf) then
      api.nvim_buf_delete(self.buf, { force = true })
    end
    return false
  end

  local hl_name = "TermSwitchBackdrop_" .. self.id
  api.nvim_set_hl(0, hl_name, {
    bg = self.opts.color,
    default = true
  })

  vim.wo[self.win].winhighlight = "Normal:" .. hl_name
  vim.wo[self.win].winblend = self.opts.opacity

  self:setup_resize_handler()

  backdrop_instances[self.id] = self

  return true
end

function Backdrop:setup_resize_handler()
  if not self:is_valid() then
    return
  end

  api.nvim_create_autocmd("VimResized", {
    group = api.nvim_create_augroup("TermSwitchBackdrop_" .. self.id, { clear = true }),
    callback = function()
      if self:is_valid() then
        api.nvim_win_set_config(self.win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      else
        return true -- Remove this autocmd
      end
    end,
    desc = "Resize TermSwitch backdrop " .. self.id,
  })
end

function Backdrop:is_valid()
  return self.win and api.nvim_win_is_valid(self.win) and
    self.buf and api.nvim_buf_is_valid(self.buf)
end

--- Destroys the backdrop
function Backdrop:destroy()
  pcall(api.nvim_del_augroup_by_name, "TermSwitchBackdrop_" .. self.id)

  if self.win and api.nvim_win_is_valid(self.win) then
    api.nvim_win_close(self.win, true)
  end

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    api.nvim_buf_delete(self.buf, { force = true })
  end

  self.win = nil
  self.buf = nil

  backdrop_instances[self.id] = nil
end

function M.create_backdrop(terminal_name, opts)
  local backdrop = Backdrop:new(terminal_name, opts)
  return backdrop
end

function M.cleanup_all()
  for _, backdrop in pairs(backdrop_instances) do
    backdrop:destroy()
  end
  backdrop_instances = {}
end

function M.get_backdrop(terminal_name)
  return backdrop_instances[terminal_name]
end

api.nvim_create_autocmd("VimLeave", {
  callback = function()
    M.cleanup_all()
  end,
  desc = "Cleanup TermSwitch backdrops on exit"
})

return M
