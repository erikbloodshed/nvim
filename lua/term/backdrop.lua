local api = vim.api

local M = {}
local backdrop_instances = {}

local BACKDROP_OPACITY = 60
local BACKDROP_ZINDEX = 49
local BACKDROP_COLOR = "#000000"

-- Cache Normal highlight check result temporarily
local normal_bg_cache = nil
local normal_bg_cache_time = 0
local CACHE_DURATION = 1000 -- 1 second in milliseconds

local get_normal_bg = function()
  local current_time = vim.loop.hrtime() / 1000000

  if normal_bg_cache and (current_time - normal_bg_cache_time) < CACHE_DURATION then
    return normal_bg_cache
  end

  local normal = api.nvim_get_hl(0, { name = "Normal" })
  normal_bg_cache = normal.bg
  normal_bg_cache_time = current_time

  return normal_bg_cache
end

local should_create_backdrop = function()
  return get_normal_bg() ~= nil and BACKDROP_OPACITY < 100
end

local function is_backdrop_valid(backdrop)
  return backdrop and backdrop.win and api.nvim_win_is_valid(backdrop.win) and
    backdrop.buf and api.nvim_buf_is_valid(backdrop.buf)
end

local create_resize_autocmd = function(backdrop)
  return api.nvim_create_autocmd("VimResized", {
    group = api.nvim_create_augroup("TermBackdrop_" .. backdrop.id, { clear = true }),
    callback = function()
      if is_backdrop_valid(backdrop) then
        -- Use pcall to avoid errors if window is closed during resize
        pcall(api.nvim_win_set_config, backdrop.win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      else
        return true -- Remove this autocmd
      end
    end,
    desc = "Resize TermSwitch backdrop " .. backdrop.id,
  })
end

local cleanup_backdrop_resources = function(backdrop)
  if not backdrop then return end

  -- Clean up autocmd group
  pcall(api.nvim_del_augroup_by_name, "TermBackdrop_" .. backdrop.id)

  -- Close window
  if backdrop.win and api.nvim_win_is_valid(backdrop.win) then
    pcall(api.nvim_win_close, backdrop.win, true)
  end

  -- Delete buffer
  if backdrop.buf and api.nvim_buf_is_valid(backdrop.buf) then
    pcall(api.nvim_buf_delete, backdrop.buf, { force = true })
  end
end

local create_backdrop_window = function(backdrop)
  if not should_create_backdrop() then
    return false
  end

  -- Destroy existing backdrop first
  local existing = backdrop_instances[backdrop.id]
  if existing then
    cleanup_backdrop_resources(existing)
  end

  -- Create buffer
  backdrop.buf = api.nvim_create_buf(false, true)
  if not backdrop.buf then
    return false
  end

  -- Set buffer options in batch
  local buf_opts = {
    buftype = "nofile",
    filetype = "termswitch_backdrop",
    bufhidden = "wipe"
  }

  for opt, value in pairs(buf_opts) do
    vim.bo[backdrop.buf][opt] = value
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

  local hl_name = "Backdrop_" .. backdrop.id
  api.nvim_set_hl(0, hl_name, {
    bg = BACKDROP_COLOR,
    default = true
  })

  local win_opts = {
    winhighlight = "Normal:" .. hl_name,
    winblend = BACKDROP_OPACITY
  }

  for opt, value in pairs(win_opts) do
    vim.wo[backdrop.win][opt] = value
  end

  create_resize_autocmd(backdrop)

  backdrop_instances[backdrop.id] = backdrop
  return true
end

local cleanup_all = function()
  for _, backdrop in pairs(backdrop_instances) do
    cleanup_backdrop_resources(backdrop)
  end
  backdrop_instances = {}
end

M.create_backdrop = function(terminal_name)
  local backdrop = {
    id = terminal_name,
    buf = nil,
    win = nil,
  }

  local success = create_backdrop_window(backdrop)
  return success and backdrop or nil
end

M.destroy_backdrop = function(backdrop)
  if not backdrop then return end

  cleanup_backdrop_resources(backdrop)

  backdrop.win, backdrop.buf = nil, nil
  backdrop_instances[backdrop.id] = nil
end

api.nvim_create_autocmd("VimLeave", {
  callback = cleanup_all,
  desc = "Cleanup floating terminal backdrops on exit"
})

return M
