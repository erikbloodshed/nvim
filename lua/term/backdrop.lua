local api = vim.api

local M = {}
local backdrop_instances = {}

local BACKDROP_OPACITY = 60
local BACKDROP_ZINDEX = 49
local BACKDROP_COLOR = "#000000"

local backdrop_events_setup = false

local function setup_global_events()
  if backdrop_events_setup then return end

  api.nvim_create_autocmd("ColorScheme", {
    group = api.nvim_create_augroup("BackdropColorScheme", { clear = true }),
    callback = function()
      for _, backdrop in pairs(backdrop_instances) do
        if M.is_backdrop_valid(backdrop) then
          M.destroy_backdrop(backdrop)
          local new_backdrop = M.create_backdrop(backdrop.id)
          backdrop_instances[backdrop.id] = new_backdrop
        end
      end
    end,
    desc = "Update backdrops on colorscheme change"
  })

  api.nvim_create_autocmd("VimLeavePre", {
    group = api.nvim_create_augroup("BackdropCleanup", { clear = true }),
    callback = M.cleanup_all,
    desc = "Cleanup all backdrops on exit"
  })

  backdrop_events_setup = true
end

local function get_normal_bg()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  return normal.bg
end

local function should_create_backdrop()
  return get_normal_bg() ~= nil and BACKDROP_OPACITY < 100
end

local function is_backdrop_valid(backdrop)
  return backdrop and backdrop.win and api.nvim_win_is_valid(backdrop.win) and
    backdrop.buf and api.nvim_buf_is_valid(backdrop.buf)
end

local function create_backdrop_window(backdrop)
  if not should_create_backdrop() then
    return false
  end

  -- Create buffer
  backdrop.buf = api.nvim_create_buf(false, true)
  if not backdrop.buf then
    return false
  end

  -- Set buffer options
  local buf_opts = {
    buftype = "nofile",
    filetype = "term_backdrop",
    bufhidden = "wipe"
  }

  for opt, value in pairs(buf_opts) do
    api.nvim_set_option_value(opt, value, { buf = backdrop.buf })
  end

  -- Create floating window
  backdrop.win = api.nvim_open_win(backdrop.buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = BACKDROP_ZINDEX,
  })

  if not backdrop.win then
    if api.nvim_buf_is_valid(backdrop.buf) then
      pcall(api.nvim_buf_delete, backdrop.buf, { force = true })
    end
    return false
  end

  -- Set highlight
  local hl_name = "Backdrop_" .. backdrop.id
  api.nvim_set_hl(0, hl_name, {
    bg = BACKDROP_COLOR,
    default = true
  })

  -- Set window options
  local win_opts = {
    winhighlight = "Normal:" .. hl_name,
    winblend = BACKDROP_OPACITY
  }

  for opt, value in pairs(win_opts) do
    api.nvim_set_option_value(opt, value, { win = backdrop.win })
  end

  -- Setup resize handling for this backdrop
  backdrop.resize_autocmd = api.nvim_create_autocmd("VimResized", {
    group = api.nvim_create_augroup("Backdrop_" .. backdrop.id, { clear = true }),
    callback = function()
      if is_backdrop_valid(backdrop) then
        pcall(api.nvim_win_set_config, backdrop.win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      else
        return true -- Remove this autocmd
      end
    end,
    desc = "Resize backdrop " .. backdrop.id,
  })

  return true
end

local function cleanup_backdrop_resources(backdrop)
  if not backdrop then return end

  -- Clean up autocmd group
  pcall(api.nvim_del_augroup_by_name, "Backdrop_" .. backdrop.id)

  -- Close window
  if backdrop.win and api.nvim_win_is_valid(backdrop.win) then
    pcall(api.nvim_win_close, backdrop.win, true)
  end

  -- Delete buffer
  if backdrop.buf and api.nvim_buf_is_valid(backdrop.buf) then
    pcall(api.nvim_buf_delete, backdrop.buf, { force = true })
  end
end

M.create_backdrop = function(terminal_name)
  setup_global_events()

  local existing = backdrop_instances[terminal_name]
  if existing then
    cleanup_backdrop_resources(existing)
  end

  local backdrop = {
    id = terminal_name,
    buf = nil,
    win = nil,
    resize_autocmd = nil,
  }

  local success = create_backdrop_window(backdrop)
  if success then
    backdrop_instances[terminal_name] = backdrop
    return backdrop
  end

  return nil
end

M.destroy_backdrop = function(backdrop)
  if not backdrop then return end

  cleanup_backdrop_resources(backdrop)
  backdrop_instances[backdrop.id] = nil
end

M.resize_backdrop = function(backdrop)
  if not is_backdrop_valid(backdrop) then return end

  pcall(api.nvim_win_set_config, backdrop.win, {
    width = vim.o.columns,
    height = vim.o.lines,
  })
end

M.is_backdrop_valid = function(backdrop)
  return is_backdrop_valid(backdrop)
end

M.cleanup_all = function()
  for _, backdrop in pairs(backdrop_instances) do
    cleanup_backdrop_resources(backdrop)
  end
  backdrop_instances = {}
end

M.get_backdrop = function(terminal_name)
  return backdrop_instances[terminal_name]
end

return M
