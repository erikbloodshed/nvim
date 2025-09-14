local api = vim.api

local M = {}
local backdrop_instances = {}

local BACKDROP_OPACITY = 60
local BACKDROP_ZINDEX = 49
local BACKDROP_COLOR = "#000000"

-- Simplified background check - no need for caching
local function should_create_backdrop()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  return normal.bg ~= nil and BACKDROP_OPACITY < 100
end

local function is_valid(backdrop)
  return backdrop and backdrop.win and api.nvim_win_is_valid(backdrop.win)
end

local function cleanup_backdrop(backdrop)
  if not backdrop then return end

  if backdrop.augroup then
    pcall(api.nvim_del_augroup_by_id, backdrop.augroup)
  end

  if backdrop.win and api.nvim_win_is_valid(backdrop.win) then
    pcall(api.nvim_win_close, backdrop.win, true)
  end

  backdrop_instances[backdrop.id] = nil
end

local function create_backdrop_window(id)
  if not should_create_backdrop() then
    return nil
  end

  local existing = backdrop_instances[id]
  if existing then
    cleanup_backdrop(existing)
  end

  local buf = api.nvim_create_buf(false, true)
  if not buf then return nil end

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "termswitch_backdrop"
  vim.bo[buf].bufhidden = "wipe"

  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = BACKDROP_ZINDEX,
  })

  if not win then
    pcall(api.nvim_buf_delete, buf, { force = true })
    return nil
  end

  local backdrop = {
    id = id,
    buf = buf,
    win = win,
    augroup = nil,
  }

  -- Set window appearance
  local hl_name = "Backdrop_" .. id
  api.nvim_set_hl(0, hl_name, { bg = BACKDROP_COLOR, default = true })
  vim.wo[win].winhighlight = "Normal:" .. hl_name
  vim.wo[win].winblend = BACKDROP_OPACITY

  backdrop.augroup = api.nvim_create_augroup("TermBackdrop_" .. id, { clear = true })
  api.nvim_create_autocmd("VimResized", {
    group = backdrop.augroup,
    callback = function()
      if is_valid(backdrop) then
        pcall(api.nvim_win_set_config, backdrop.win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      else
        return true -- Remove autocmd
      end
    end,
    desc = "Resize backdrop " .. id,
  })

  backdrop_instances[id] = backdrop
  return backdrop
end

function M.create_backdrop(terminal_name)
  return create_backdrop_window(terminal_name)
end

function M.destroy_backdrop(backdrop)
  cleanup_backdrop(backdrop)
end

api.nvim_create_autocmd("VimLeave", {
  callback = function()
    for _, backdrop in pairs(backdrop_instances) do
      cleanup_backdrop(backdrop)
    end
    backdrop_instances = {}
  end,
  desc = "Cleanup floating terminal backdrops on exit"
})

return M
