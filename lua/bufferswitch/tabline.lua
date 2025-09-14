local M = {}
local utils = require("bufferswitch.utils")
local icons = require("ui.icons")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local config = {
  hide_in_special = true, -- hide tabline in special buffers
  hide_timeout = 2000,    -- ms before hiding tabline
}

local git_branch_cache = {}

local function get_git_branch(bufnr, callback)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    callback("")
    return
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    callback("")
    return
  end

  -- Run git from the file's directory
  local file_dir = vim.fn.fnamemodify(filepath, ":h")

  if git_branch_cache[file_dir] then
    callback(git_branch_cache[file_dir])
    return
  end

  vim.system({ "git", "-C", file_dir, "symbolic-ref", "--short", "HEAD" }, {}, function(obj)
    local branch = ""
    if obj.code == 0 and obj.stdout then
      branch = obj.stdout:gsub("\n", "")
    end

    git_branch_cache[file_dir] = branch
    callback(branch)
  end)
end

function M.format_bufname(bufnr, is_current)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "[Invalid]"
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ":t")

  if vim.bo[bufnr].buftype == "help" then
    return "[Help] " .. (display_name ~= "" and display_name or "help")
  elseif vim.bo[bufnr].buftype == "terminal" then
    return "[Term] " .. (display_name ~= "" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "" then
    display_name = "[No Name]"
  end

  if #display_name > 25 then
    display_name = display_name:sub(1, 22) .. "..."
  end

  local base_hl = is_current and "BufferSwitchSelected" or "BufferSwitchInactive"

  local modified_marker = ""
  if vim.bo[bufnr].modified then
    modified_marker = "%#BufferSwitchModified#●%#" .. base_hl .. "#"
  end

  local get_devicon = function()
    if has_devicons then
      local ext = vim.fn.fnamemodify(name, ":e") or ""
      local devicon, icon_color = devicons.get_icon_color(display_name, ext)
      local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel"})
      if devicon then
        vim.api.nvim_set_hl(0, "BufferSwitchDevicon", { fg = icon_color, bg = hl.bg })
        local icon_hl = is_current and "BufferSwitchDevicon" or "BufferSwitchInactive"
        return string.format("%%#%s#%s%%#%s# ", icon_hl, devicon, base_hl)
      end
    end
    return ""
  end

  return string.format("%s%s%s", get_devicon(), display_name, modified_marker)
end

function M.update_tabline(buffer_list)
  local current_buf = vim.api.nvim_get_current_buf()
  local parts = {}

  for i, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = bufnr == current_buf
      local hl = is_current and "%#BufferSwitchSelected#" or "%#BufferSwitchInactive#"
      local entry = table.concat({ hl, "  ", M.format_bufname(bufnr, is_current), "  ", })

      table.insert(parts, entry)

      if i < #buffer_list then
        table.insert(parts, "%#BufferSwitchSeparator#|")
      else
        table.insert(parts, "%#BufferSwitchFill#")
      end
    end
  end

  local left = table.concat(parts, "")
  local cwd = vim.fs.basename(vim.fs.dirname(vim.api.nvim_buf_get_name(current_buf)))

  get_git_branch(current_buf, function(branch)
    local git_branch = branch ~= "" and (" " .. branch .. " ") or ""
    local right = string.format(
      "%%=%s%%#BufferSwitchRight# %s%s ",
      "%#BufferSwitchFill#",
      git_branch ~= "" and (icons.git .. git_branch .. "📁 ") or "📁 ",
      cwd
    )

    vim.schedule(function()
      vim.o.tabline = "%#BufferSwitchFill#" .. left .. right .. "%T"
    end)
  end)
end

function M.show_tabline_temporarily(_, buffer_order)
  if config.hide_in_special and utils.is_special_buffer(config) then
    return
  end
  utils.stop_hide_timer()

  vim.o.showtabline = 2
  M.update_tabline(buffer_order)

  utils.start_hide_timer(config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.stop_hide_timer()
end

return M
