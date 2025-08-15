-- termswitch/backdrop.lua
local api = vim.api

local M = {}

-- Track backdrop windows globally to avoid conflicts
local backdrop_instances = {}

---@class BackdropOptions
---@field opacity? number Backdrop opacity (0-100, default: 60)
---@field zindex? number Z-index for backdrop (default: 45)
---@field color? string Background color (default: "#000000")

---@class Backdrop
---@field buf number Backdrop buffer
---@field win number Backdrop window
---@field opts BackdropOptions
---@field id string Unique identifier
local Backdrop = {}
Backdrop.__index = Backdrop

--- Creates a new backdrop instance
---@param id string Unique identifier for this backdrop
---@param opts? BackdropOptions Options for backdrop configuration
---@return Backdrop
function Backdrop:new(id, opts)
  opts = opts or {}

  local obj = {
    id = id,
    buf = nil,
    win = nil,
    opts = vim.tbl_extend('force', {
      opacity = 100,
      zindex = 45,
      color = "#000000"
    }, opts)
  }

  setmetatable(obj, self)
  return obj
end

--- Checks if backdrop should be created based on environment
---@return boolean
function Backdrop:should_create()
  -- Only create backdrop if termguicolors is enabled
  if not vim.o.termguicolors then
    return false
  end

  -- Check if Normal highlight has background color
  local normal, has_bg
  if vim.fn.has("nvim-0.9.0") == 0 then
    normal = api.nvim_get_hl_by_name("Normal", true)
    has_bg = normal and normal.background ~= nil
  else
    normal = api.nvim_get_hl(0, { name = "Normal" })
    has_bg = normal and normal.bg ~= nil
  end

  -- Only create if we have a background and opacity is less than 100
  return has_bg and self.opts.opacity and self.opts.opacity < 100
end

--- Creates the backdrop window
function Backdrop:create()
  if not self:should_create() then
    return false
  end

  -- Clean up existing backdrop if it exists
  self:destroy()

  -- Create backdrop buffer
  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    return false
  end

  -- Set buffer options
  vim.bo[self.buf].buftype = "nofile"
  vim.bo[self.buf].filetype = "termswitch_backdrop"
  vim.bo[self.buf].bufhidden = "wipe"

  -- Create fullscreen backdrop window
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
    -- Clean up buffer if window creation failed
    if api.nvim_buf_is_valid(self.buf) then
      api.nvim_buf_delete(self.buf, { force = true })
    end
    return false
  end

  -- Set up backdrop highlight
  local hl_name = "TermSwitchBackdrop_" .. self.id
  api.nvim_set_hl(0, hl_name, {
    bg = self.opts.color,
    default = true
  })

  -- Apply backdrop styling
  vim.wo[self.win].winhighlight = "Normal:" .. hl_name
  vim.wo[self.win].winblend = self.opts.opacity

  -- Set up auto-resize for backdrop
  self:setup_resize_handler()

  -- Register this backdrop instance
  backdrop_instances[self.id] = self

  return true
end

--- Sets up automatic resizing of backdrop on VimResized
function Backdrop:setup_resize_handler()
  if not self:is_valid() then
    return
  end

  api.nvim_create_autocmd("VimResized", {
    callback = function()
      if self:is_valid() then
        api.nvim_win_set_config(self.win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      else
        -- Clean up invalid backdrop
        self:destroy()
        return true -- Remove this autocmd
      end
    end,
    desc = "Resize TermSwitch backdrop " .. self.id,
    group = api.nvim_create_augroup("TermSwitchBackdrop_" .. self.id, { clear = true })
  })
end

--- Checks if backdrop is valid
---@return boolean
function Backdrop:is_valid()
  return self.win and api.nvim_win_is_valid(self.win) and
    self.buf and api.nvim_buf_is_valid(self.buf)
end

--- Destroys the backdrop
function Backdrop:destroy()
  -- Clean up autocmd group
  pcall(api.nvim_del_augroup_by_name, "TermSwitchBackdrop_" .. self.id)

  -- Close window
  if self.win and api.nvim_win_is_valid(self.win) then
    api.nvim_win_close(self.win, true)
  end

  -- Delete buffer
  if self.buf and api.nvim_buf_is_valid(self.buf) then
    api.nvim_buf_delete(self.buf, { force = true })
  end

  -- Clear references
  self.win = nil
  self.buf = nil

  -- Unregister instance
  backdrop_instances[self.id] = nil
end

--- Module functions

--- Creates a backdrop for a terminal
---@param terminal_name string Name of the terminal
---@param opts? BackdropOptions Backdrop options
---@return Backdrop
function M.create_backdrop(terminal_name, opts)
  local backdrop = Backdrop:new(terminal_name, opts)
  return backdrop
end

--- Destroys all backdrop instances
function M.cleanup_all()
  for _, backdrop in pairs(backdrop_instances) do
    backdrop:destroy()
  end
  backdrop_instances = {}
end

--- Gets backdrop instance by terminal name
---@param terminal_name string
---@return Backdrop|nil
function M.get_backdrop(terminal_name)
  return backdrop_instances[terminal_name]
end

--- Auto-cleanup on VimLeave
api.nvim_create_autocmd("VimLeave", {
  callback = function()
    M.cleanup_all()
  end,
  desc = "Cleanup TermSwitch backdrops on exit"
})

return M
