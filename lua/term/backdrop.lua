local api = vim.api

local M = {}
local backdrop_instances = {}

local BACKDROP_OPACITY = 60
local BACKDROP_ZINDEX = 49
local BACKDROP_COLOR = "#000000"

-- A single shared highlight group is used for all backdrop windows.
-- Per-terminal HL groups are wasteful because every terminal uses identical
-- color and opacity, and nvim_set_hl has no delete counterpart — per-instance
-- names would leak into the global HL namespace permanently.
local BACKDROP_HL_GROUP = "TermSwitchBackdrop"
local backdrop_hl_initialized = false

local function ensure_backdrop_hl()
  if not backdrop_hl_initialized then
    api.nvim_set_hl(0, BACKDROP_HL_GROUP, { bg = BACKDROP_COLOR, default = true })
    backdrop_hl_initialized = true
  end
end

local function should_create_backdrop()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  return normal.bg ~= nil and BACKDROP_OPACITY < 100
end

local function is_valid(bd)
  return bd and bd.win and api.nvim_win_is_valid(bd.win)
end

local function cleanup_backdrop(bd)
  if not bd then return end

  if bd.augroup then
    pcall(api.nvim_del_augroup_by_id, bd.augroup)
    bd.augroup = nil
  end

  if bd.win and api.nvim_win_is_valid(bd.win) then
    pcall(api.nvim_win_close, bd.win, true)
    bd.win = nil
  end

  backdrop_instances[bd.id] = nil
end

local function create_backdrop_window(id)
  if not should_create_backdrop() then
    return nil
  end

  -- Clean up any pre-existing backdrop for this id before creating a new one.
  local existing = backdrop_instances[id]
  if existing then
    cleanup_backdrop(existing)
  end

  local buf = api.nvim_create_buf(false, true)
  if not buf then return nil end

  vim.bo[buf].buftype   = "nofile"
  vim.bo[buf].filetype  = "termswitch_backdrop"
  vim.bo[buf].bufhidden = "wipe"

  local win = api.nvim_open_win(buf, false, {
    relative  = "editor",
    width     = vim.o.columns,
    height    = vim.o.lines,
    row       = 0,
    col       = 0,
    style     = "minimal",
    focusable = false,
    zindex    = BACKDROP_ZINDEX,
  })

  if not win then
    pcall(api.nvim_buf_delete, buf, { force = true })
    return nil
  end

  ensure_backdrop_hl()
  vim.wo[win].winhighlight = "Normal:" .. BACKDROP_HL_GROUP
  vim.wo[win].winblend     = BACKDROP_OPACITY

  local bd = {
    id     = id,
    buf    = buf,
    win    = win,
    augroup = nil,
  }

  bd.augroup = api.nvim_create_augroup("TermBackdrop_" .. id, { clear = true })
  api.nvim_create_autocmd("VimResized", {
    group    = bd.augroup,
    callback = function()
      if is_valid(bd) then
        pcall(api.nvim_win_set_config, bd.win, {
          width  = vim.o.columns,
          height = vim.o.lines,
        })
      else
        return true -- Removes this autocmd
      end
    end,
    desc = "Resize backdrop " .. id,
  })

  backdrop_instances[id] = bd
  return bd
end

function M.create_backdrop(terminal_name)
  return create_backdrop_window(terminal_name)
end

function M.destroy_backdrop(bd)
  cleanup_backdrop(bd)
end

-- Registered inside M so it only exists once and is clearly scoped.
-- Using an augroup prevents duplicate registration if the module is
-- re-required during development (e.g. with :luafile).
local vimleave_group = api.nvim_create_augroup("TermSwitchBackdropVimLeave", { clear = true })
api.nvim_create_autocmd("VimLeave", {
  group    = vimleave_group,
  callback = function()
    for _, bd in pairs(backdrop_instances) do
      cleanup_backdrop(bd)
    end
    backdrop_instances = {}
  end,
  desc = "Cleanup floating terminal backdrops on exit",
})

return M
