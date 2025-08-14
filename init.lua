--[[
   ▄▄▄▄    ██▓     ▒█████   ▒█████  ▓█████▄   ██████  ██░ ██ ▓█████ ▓█████▄
  ▓█████▄ ▓██▒    ▒██▒  ██▒▒██▒  ██▒▒██▀ ██▌▒██    ▒ ▓██░ ██▒▓█   ▀ ▒██▀ ██▌
  ▒██▒ ▄██▒██░    ▒██░  ██▒▒██░  ██▒░██   █▌░ ▓██▄   ▒██▀▀██░▒███   ░██   █▌
  ▒██░█▀  ▒██░    ▒██   ██░▒██   ██░░▓█▄   ▌  ▒   ██▒░▓█ ░██ ▒▓█  ▄ ░▓█▄   ▌
  ░▓█  ▀█▓░██████▒░ ████▓▒░░ ████▓▒░░▒████▓ ▒██████▒▒░▓█▒░██▓░▒████▒░▒████▓
  ░▒▓███▀▒░ ▒░▓  ░░ ▒░▒░▒░ ░ ▒░▒░▒░  ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░░ ▒░ ░ ▒▒▓  ▒
▒░▒   ░ ░ ░ ▒  ░  ░ ▒ ▒░   ░ ▒ ▒░  ░ ▒  ▒ ░ ░▒  ░ ░ ▒ ░▒░ ░ ░ ░  ░ ░ ▒  ▒
 ░    ░   ░ ░   ░ ░ ░ ▒  ░ ░ ░ ▒   ░ ░  ░ ░  ░  ░   ░  ░░ ░   ░    ░ ░  ░
 ░          ░  ░    ░ ░      ░ ░     ░          ░   ░  ░  ░   ░  ░   ░
      ░                            ░                               ░
--]]

require("core.options")
require("core.lazy")
require("core.lsp")
require("core.autocmds")

vim.cmd.colorscheme("ayu-mirage")

-- Rainbow highlight groups for each nesting level
local rainbow_hls = {
  "RainbowParen1",
  "RainbowParen2",
  "RainbowParen3",
  "RainbowParen4",
  "RainbowParen5",
  "RainbowParen6",
}

-- Define default rainbow colors (override in colorscheme if desired)
vim.api.nvim_set_hl(0, "RainbowParen1", { fg = "#FFB454", bold = true }) -- Gold
vim.api.nvim_set_hl(0, "RainbowParen2", { fg = "#59C2C1", bold = true }) -- Green
vim.api.nvim_set_hl(0, "RainbowParen3", { fg = "#FF73B9", bold = true }) -- Pink
vim.api.nvim_set_hl(0, "RainbowParen4", { fg = "#C2A8E7", bold = true }) -- Purple
vim.api.nvim_set_hl(0, "RainbowParen5", { fg = "#6CB6FF", bold = true }) -- Blue
vim.api.nvim_set_hl(0, "RainbowParen6", { fg = "#FF9F43", bold = true }) -- Orange
vim.api.nvim_set_hl(0, "RainbowParen7", { fg = "#FF6666", bold = true }) -- Red

-- Highlight group for bracket under the cursor
local hl_on_cursor = "MatchParenOnCursor"
vim.api.nvim_set_hl(0, hl_on_cursor, { fg = "#FFFFFF", bg = "#444444", bold = true })

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace("RainbowMultiParenHighlight")

-- Helper: detect if a node is a bracket pair
local function is_bracket_pair(node, bufnr)
  local text = vim.treesitter.get_node_text(node, bufnr)
  if not text or #text < 2 then return false end
  local first = text:sub(1, 1)
  local last = text:sub(-1)
  return (first == "(" and last == ")")
    or (first == "{" and last == "}")
    or (first == "[" and last == "]")
end

local function highlight_pairs()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then return end

  local tree = parser:parse()[1]
  local root = tree:root()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- 0-based

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then return end

  local level = 0
  while node do
    if is_bracket_pair(node, 0) then
      level = level + 1
      local start_row, start_col, end_row, end_col = node:range()
      local hl_group = rainbow_hls[(level - 1) % #rainbow_hls + 1]

      -- Get the node's text to determine the bracket characters
      local text = vim.treesitter.get_node_text(node, 0)
      local is_empty_pair = #text == 2 -- e.g., "()", "{}", "[]"

      -- Cursor on opening bracket
      if row == start_row and col == start_col then
        vim.api.nvim_buf_add_highlight(0, ns, hl_on_cursor, start_row, start_col, start_col + 1)
        vim.api.nvim_buf_add_highlight(0, ns, hl_group, end_row, end_col - 1, end_col)

      -- Cursor on closing bracket (more robust check)
      elseif row == end_row and (col >= end_col - 1 or (is_empty_pair and col == start_col + 1)) then
        vim.api.nvim_buf_add_highlight(0, ns, hl_group, start_row, start_col, start_col + 1)
        vim.api.nvim_buf_add_highlight(0, ns, hl_on_cursor, end_row, end_col - 1, end_col)

      -- Cursor inside pair
      else
        vim.api.nvim_buf_add_highlight(0, ns, hl_group, start_row, start_col, start_col + 1)
        vim.api.nvim_buf_add_highlight(0, ns, hl_group, end_row, end_col - 1, end_col)
      end
    end
    node = node:parent()
  end
end

-- Autocommand to trigger highlighting on cursor movement
vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
  callback = function()
    pcall(highlight_pairs) -- Wrap in pcall to avoid breaking on errors
  end,
})
