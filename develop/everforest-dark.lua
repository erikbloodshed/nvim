-- everforest_hard_dark.lua
-- Refactored to use only hard dark palette
-- Author: sainnhe (original), refactored by Grok
-- Description: Comfortable & Pleasant Color Scheme for Neovim
-- Website: https://github.com/sainnhe/everforest
-- License: MIT

local everforest = {}

-- Default configuration (some options remain, but background is fixed)
local default_config = {
  transparent_background = 0, -- 0: none, 1: transparent, 2: statusline/tabline transparent
  dim_inactive_windows = false,
  enable_italic = true,
  disable_italic_comment = false,
  show_eob = true,
  float_style = 'bright', -- 'dim' or 'bright'
  diagnostic_text_highlight = false,
  diagnostic_line_highlight = false,
  diagnostic_virtual_text = 'colored', -- 'grey', 'colored', 'highlighted'
  spell_foreground = 'none',
  current_word = 'grey background',    -- 'grey background', 'high contrast background', 'bold', 'underline', etc.
  cursor = 'auto',                     -- 'red', 'orange', etc. or 'auto'
  ui_contrast = 'high',                -- 'low' or 'high'
  sign_column_background = 'grey',     -- 'grey' or 'none'
  colors_override = {},                -- table to override colors
  better_performance = false,
  inlay_hints_background = 'dimmed',   -- 'none' or 'dimmed'
  disable_terminal_colors = false,
  -- Add more config options as needed from the original, but ignore background selection
}

-- Hard dark palette fixed
local hard_dark_palette = {
  bg_dim = '#1e2326',
  bg0 = '#272e33',
  bg1 = '#2e383c',
  bg2 = '#374145',
  bg3 = '#414b50',
  bg4 = '#495156',
  bg5 = '#4f5b58',
  bg_visual = '#4c3743',
  bg_red = '#493b40',
  bg_green = '#3d484d',
  bg_blue = '#384b55',
  bg_yellow = '#45443c',
  fg = '#d3c6aa',
  red = '#e67e80',
  orange = '#e39b7b',
  yellow = '#d9bb80',
  green = '#83c092',
  aqua = '#87c095',
  blue = '#7fbbb3',
  purple = '#d699b6',
  grey0 = '#7a8478',
  grey1 = '#859289',
  grey2 = '#9da9a0',
  none = 'NONE',
  statusline1 = '#a7c080',
  statusline2 = '#d3c6aa',
  statusline3 = '#e67e80',
}

-- Function to get palette with overrides
local function get_palette(config)
  local override = config.colors_override or {}
  local pal = vim.tbl_deep_extend('force', hard_dark_palette, override)
  return pal
end

-- Helper function to set highlight
local function highlight(group, fg, bg, attr, sp)
  local opts = {}
  if fg and fg ~= 'NONE' then opts.fg = fg end
  if bg and bg ~= 'NONE' then opts.bg = bg end
  if attr then
    local attrs = vim.split(attr, ',')
    for _, a in ipairs(attrs) do
      if a == 'bold' or a == 'italic' or a == 'underline' or a == 'undercurl' or a == 'reverse' then
        opts[a] = true
      end
    end
  end
  if sp and sp ~= 'NONE' then opts.sp = sp end
  vim.api.nvim_set_hl(0, group, opts)
end

-- Link helper
local function link(from, to)
  vim.api.nvim_set_hl(0, from, { link = to })
end

-- Main setup function
function everforest.setup(user_config)
  user_config = user_config or {}
  local config = vim.tbl_deep_extend('force', default_config, user_config)
  local palette = get_palette(config)

  vim.cmd('highlight clear')
  if vim.fn.exists('syntax_on') then
    vim.cmd('syntax reset')
  end
  vim.g.colors_name = 'everforest_hard_dark'

  if not (vim.fn.has('termguicolors') == 1 and vim.o.termguicolors) and not vim.fn.has('gui_running') == 1 and vim.o.t_Co ~= '256' then
    return
  end

  -- Apply highlights
  -- UI Highlights
  if config.transparent_background >= 1 then
    highlight('Normal', palette.fg, palette.none)
    highlight('NormalNC', palette.fg, palette.none)
    highlight('Terminal', palette.fg, palette.none)
    if config.show_eob then
      highlight('EndOfBuffer', palette.bg4, palette.none)
    else
      highlight('EndOfBuffer', palette.bg0, palette.none)
    end
    if config.ui_contrast == 'low' then
      highlight('FoldColumn', palette.bg5, palette.none)
    else
      highlight('FoldColumn', palette.grey0, palette.none)
    end
    highlight('Folded', palette.grey1, palette.none)
    highlight('SignColumn', palette.fg, palette.none)
    highlight('ToolbarLine', palette.fg, palette.none)
  else
    highlight('Normal', palette.fg, palette.bg0)
    if config.dim_inactive_windows then
      highlight('NormalNC', palette.fg, palette.bg_dim)
    else
      highlight('NormalNC', palette.fg, palette.bg0)
    end
    highlight('Terminal', palette.fg, palette.bg0)
    if config.show_eob then
      highlight('EndOfBuffer', palette.bg4, palette.none)
    else
      highlight('EndOfBuffer', palette.bg0, palette.none)
    end
    highlight('Folded', palette.grey1, palette.bg1)
    highlight('ToolbarLine', palette.fg, palette.bg2)
    if config.sign_column_background == 'grey' then
      highlight('SignColumn', palette.fg, palette.bg1)
      highlight('FoldColumn', palette.grey2, palette.bg1)
    else
      highlight('SignColumn', palette.fg, palette.none)
      if config.ui_contrast == 'low' then
        highlight('FoldColumn', palette.bg5, palette.none)
      else
        highlight('FoldColumn', palette.grey0, palette.none)
      end
    end
  end

  if vim.fn.has('nvim') == 1 then
    highlight('IncSearch', palette.bg0, palette.red)
    highlight('Search', palette.bg0, palette.green)
  else
    highlight('IncSearch', palette.red, palette.bg0, 'reverse')
    highlight('Search', palette.green, palette.bg0, 'reverse')
  end
  link('CurSearch', 'IncSearch')

  highlight('ColorColumn', palette.none, palette.bg1)
  if config.ui_contrast == 'low' then
    highlight('Conceal', palette.bg5, palette.none)
  else
    highlight('Conceal', palette.grey0, palette.none)
  end
  if config.cursor == 'auto' then
    highlight('Cursor', palette.none, palette.none, 'reverse')
  else
    highlight('Cursor', palette.bg0, palette[config.cursor])
  end
  link('vCursor', 'Cursor')
  link('iCursor', 'Cursor')
  link('lCursor', 'Cursor')
  link('CursorIM', 'Cursor')

  if vim.o.diff then
    highlight('CursorLine', palette.none, palette.none, 'underline')
    highlight('CursorColumn', palette.none, palette.none, 'bold')
  else
    highlight('CursorLine', palette.none, palette.bg1)
    highlight('CursorColumn', palette.none, palette.bg1)
  end

  if config.ui_contrast == 'low' then
    highlight('LineNr', palette.bg5, palette.none)
    if vim.o.diff then
      highlight('CursorLineNr', palette.grey1, palette.none, 'underline')
    elseif (vim.o.relativenumber == 1 and vim.o.cursorline == 0) or config.sign_column_background == 'none' then
      highlight('CursorLineNr', palette.grey1, palette.none)
    else
      highlight('CursorLineNr', palette.grey1, palette.bg1)
    end
  else
    highlight('LineNr', palette.grey0, palette.none)
    if vim.o.diff then
      highlight('CursorLineNr', palette.grey2, palette.none, 'underline')
    elseif (vim.o.relativenumber == 1 and vim.o.cursorline == 0) or config.sign_column_background == 'none' then
      highlight('CursorLineNr', palette.grey2, palette.none)
    else
      highlight('CursorLineNr', palette.grey2, palette.bg1)
    end
  end

  highlight('DiffAdd', palette.none, palette.bg_green)
  highlight('DiffChange', palette.none, palette.bg_blue)
  highlight('DiffDelete', palette.none, palette.bg_red)
  if vim.fn.has('nvim') == 1 then
    highlight('DiffText', palette.bg0, palette.blue)
  else
    highlight('DiffText', palette.blue, palette.bg0, 'reverse')
  end

  highlight('Directory', palette.green, palette.none)
  highlight('ErrorMsg', palette.red, palette.none, 'bold,underline')
  highlight('WarningMsg', palette.yellow, palette.none, 'bold')
  highlight('ModeMsg', palette.fg, palette.none, 'bold')
  highlight('MoreMsg', palette.yellow, palette.none, 'bold')
  highlight('MatchParen', palette.none, palette.bg4)
  highlight('NonText', palette.bg4, palette.none)
  if vim.fn.has('nvim') == 1 then
    highlight('Whitespace', palette.bg4, palette.none)
    highlight('SpecialKey', palette.yellow, palette.none)
  else
    highlight('SpecialKey', palette.bg3, palette.none)
  end
  highlight('Pmenu', palette.fg, palette.bg2)
  highlight('PmenuSbar', palette.none, palette.bg2)
  highlight('PmenuSel', palette.bg0, palette.statusline1)
  highlight('PmenuKind', palette.green, palette.bg2)
  highlight('PmenuExtra', palette.grey2, palette.bg2)
  link('WildMenu', 'PmenuSel')
  highlight('PmenuThumb', palette.none, palette.grey0)
  if config.float_style == 'dim' then
    highlight('NormalFloat', palette.fg, palette.bg_dim)
    highlight('FloatBorder', palette.grey1, palette.bg_dim)
    highlight('FloatTitle', palette.fg, palette.bg_dim, 'bold')
  else
    highlight('NormalFloat', palette.fg, palette.bg2)
    highlight('FloatBorder', palette.grey1, palette.bg2)
    highlight('FloatTitle', palette.fg, palette.bg2, 'bold')
  end
  highlight('Question', palette.yellow, palette.none)
  if config.spell_foreground == 'none' then
    highlight('SpellBad', palette.none, palette.none, 'undercurl', palette.red)
    highlight('SpellCap', palette.none, palette.none, 'undercurl', palette.blue)
    highlight('SpellLocal', palette.none, palette.none, 'undercurl', palette.aqua)
    highlight('SpellRare', palette.none, palette.none, 'undercurl', palette.purple)
  else
    highlight('SpellBad', palette.red, palette.none, 'undercurl', palette.red)
    highlight('SpellCap', palette.blue, palette.none, 'undercurl', palette.blue)
    highlight('SpellLocal', palette.aqua, palette.none, 'undercurl', palette.aqua)
    highlight('SpellRare', palette.purple, palette.none, 'undercurl', palette.purple)
  end
  if config.transparent_background == 2 then
    highlight('StatusLine', palette.grey1, palette.none)
    highlight('StatusLineTerm', palette.grey1, palette.none)
    highlight('StatusLineNC', palette.grey0, palette.none)
    highlight('StatusLineTermNC', palette.grey0, palette.none)
    highlight('TabLine', palette.grey2, palette.bg3)
    highlight('TabLineFill', palette.grey1, palette.none)
    highlight('TabLineSel', palette.bg0, palette.statusline1)
    if vim.fn.has('nvim') == 1 then
      highlight('WinBar', palette.grey1, palette.none, 'bold')
      highlight('WinBarNC', palette.grey0, palette.none)
    end
  else
    highlight('StatusLine', palette.grey1, palette.bg2)
    highlight('StatusLineTerm', palette.grey1, palette.bg1)
    highlight('StatusLineNC', palette.grey1, palette.bg1)
    highlight('StatusLineTermNC', palette.grey1, palette.bg0)
    highlight('TabLine', palette.grey2, palette.bg3)
    highlight('TabLineFill', palette.grey1, palette.bg1)
    highlight('TabLineSel', palette.bg0, palette.statusline1)
    if vim.fn.has('nvim') == 1 then
      highlight('WinBar', palette.grey1, palette.bg2, 'bold')
      highlight('WinBarNC', palette.grey1, palette.bg1)
    end
  end
  if config.dim_inactive_windows then
    highlight('VertSplit', palette.bg4, palette.bg_dim)
  else
    highlight('VertSplit', palette.bg4, palette.none)
  end
  link('WinSeparator', 'VertSplit')
  highlight('Visual', palette.none, palette.bg_visual)
  highlight('VisualNOS', palette.none, palette.bg_visual)
  highlight('QuickFixLine', palette.purple, palette.none, 'bold')
  highlight('Debug', palette.orange, palette.none)
  highlight('debugPC', palette.bg0, palette.green)
  highlight('debugBreakpoint', palette.bg0, palette.red)
  highlight('ToolbarButton', palette.bg0, palette.green)
  if vim.fn.has('nvim') == 1 then
    highlight('Substitute', palette.bg0, palette.yellow)
    if config.diagnostic_text_highlight then
      highlight('DiagnosticError', palette.red, palette.bg_red)
      highlight('DiagnosticUnderlineError', palette.none, palette.bg_red, 'undercurl', palette.red)
      highlight('DiagnosticWarn', palette.yellow, palette.bg_yellow)
      highlight('DiagnosticUnderlineWarn', palette.none, palette.bg_yellow, 'undercurl', palette.yellow)
      highlight('DiagnosticInfo', palette.blue, palette.bg_blue)
      highlight('DiagnosticUnderlineInfo', palette.none, palette.bg_blue, 'undercurl', palette.blue)
      highlight('DiagnosticHint', palette.purple, palette.bg_purple)
      highlight('DiagnosticUnderlineHint', palette.none, palette.bg_purple, 'undercurl', palette.purple)
      highlight('DiagnosticOk', palette.green, palette.bg_green)
      highlight('DiagnosticUnderlineOk', palette.none, palette.bg_green, 'undercurl', palette.green)
    else
      highlight('DiagnosticError', palette.red, palette.none)
      highlight('DiagnosticUnderlineError', palette.none, palette.none, 'undercurl', palette.red)
      highlight('DiagnosticWarn', palette.yellow, palette.none)
      highlight('DiagnosticUnderlineWarn', palette.none, palette.none, 'undercurl', palette.yellow)
      highlight('DiagnosticInfo', palette.blue, palette.none)
      highlight('DiagnosticUnderlineInfo', palette.none, palette.none, 'undercurl', palette.blue)
      highlight('DiagnosticHint', palette.purple, palette.none)
      highlight('DiagnosticUnderlineHint', palette.none, palette.none, 'undercurl', palette.purple)
      highlight('DiagnosticOk', palette.green, palette.none)
      highlight('DiagnosticUnderlineOk', palette.none, palette.none, 'undercurl', palette.green)
    end
    link('DiagnosticFloatingError', 'ErrorFloat')
    link('DiagnosticFloatingWarn', 'WarningFloat')
    link('DiagnosticFloatingInfo', 'InfoFloat')
    link('DiagnosticFloatingHint', 'HintFloat')
    link('DiagnosticFloatingOk', 'OkFloat')
    link('DiagnosticVirtualTextError', 'VirtualTextError')
    link('DiagnosticVirtualTextWarn', 'VirtualTextWarning')
    link('DiagnosticVirtualTextInfo', 'VirtualTextInfo')
    link('DiagnosticVirtualTextHint', 'VirtualTextHint')
    link('DiagnosticVirtualTextOk', 'VirtualTextOk')
    link('DiagnosticSignError', 'RedSign')
    link('DiagnosticSignWarn', 'YellowSign')
    link('DiagnosticSignInfo', 'BlueSign')
    link('DiagnosticSignHint', 'PurpleSign')
    link('DiagnosticSignOk', 'GreenSign')
    -- Additional LSP links as in original
  end

  -- Syntax Highlights
  highlight('Boolean', palette.purple, palette.none)
  highlight('Number', palette.purple, palette.none)
  highlight('Float', palette.purple, palette.none)
  if config.enable_italic then
    highlight('PreProc', palette.purple, palette.none, 'italic')
    highlight('PreCondit', palette.purple, palette.none, 'italic')
    highlight('Include', palette.purple, palette.none, 'italic')
    highlight('Define', palette.purple, palette.none, 'italic')
    highlight('Conditional', palette.red, palette.none, 'italic')
    highlight('Repeat', palette.red, palette.none, 'italic')
    highlight('Keyword', palette.red, palette.none, 'italic')
    highlight('Typedef', palette.red, palette.none, 'italic')
    highlight('Exception', palette.red, palette.none, 'italic')
    highlight('Statement', palette.red, palette.none, 'italic')
  else
    highlight('PreProc', palette.purple, palette.none)
    highlight('PreCondit', palette.purple, palette.none)
    highlight('Include', palette.purple, palette.none)
    highlight('Define', palette.purple, palette.none)
    highlight('Conditional', palette.red, palette.none)
    highlight('Repeat', palette.red, palette.none)
    highlight('Keyword', palette.red, palette.none)
    highlight('Typedef', palette.red, palette.none)
    highlight('Exception', palette.red, palette.none)
    highlight('Statement', palette.red, palette.none)
  end
  highlight('Error', palette.red, palette.none)
  highlight('StorageClass', palette.orange, palette.none)
  highlight('Tag', palette.orange, palette.none)
  highlight('Label', palette.orange, palette.none)
  highlight('Structure', palette.orange, palette.none)
  highlight('Operator', palette.orange, palette.none)
  highlight('Title', palette.orange, palette.none, 'bold')
  highlight('Special', palette.yellow, palette.none)
  highlight('SpecialChar', palette.yellow, palette.none)
  highlight('Type', palette.yellow, palette.none)
  highlight('Function', palette.green, palette.none)
  highlight('String', palette.green, palette.none)
  highlight('Character', palette.green, palette.none)
  highlight('Constant', palette.aqua, palette.none)
  highlight('Macro', palette.aqua, palette.none)
  highlight('Identifier', palette.blue, palette.none)
  highlight('Todo', palette.bg0, palette.blue, 'bold')
  if config.disable_italic_comment then
    highlight('Comment', palette.grey1, palette.none)
    highlight('SpecialComment', palette.grey1, palette.none)
  else
    highlight('Comment', palette.grey1, palette.none, 'italic')
    highlight('SpecialComment', palette.grey1, palette.none, 'italic')
  end
  highlight('Delimiter', palette.fg, palette.none)
  highlight('Ignore', palette.grey1, palette.none)
  highlight('Underlined', palette.none, palette.none, 'underline')

  -- Predefined
  highlight('Fg', palette.fg, palette.none)
  highlight('Grey', palette.grey1, palette.none)
  highlight('Red', palette.red, palette.none)
  highlight('Orange', palette.orange, palette.none)
  highlight('Yellow', palette.yellow, palette.none)
  highlight('Green', palette.green, palette.none)
  highlight('Aqua', palette.aqua, palette.none)
  highlight('Blue', palette.blue, palette.none)
  highlight('Purple', palette.purple, palette.none)
  if config.enable_italic then
    highlight('RedItalic', palette.red, palette.none, 'italic')
    highlight('OrangeItalic', palette.orange, palette.none, 'italic')
    highlight('YellowItalic', palette.yellow, palette.none, 'italic')
    highlight('GreenItalic', palette.green, palette.none, 'italic')
    highlight('AquaItalic', palette.aqua, palette.none, 'italic')
    highlight('BlueItalic', palette.blue, palette.none, 'italic')
    highlight('PurpleItalic', palette.purple, palette.none, 'italic')
  else
    highlight('RedItalic', palette.red, palette.none)
    highlight('OrangeItalic', palette.orange, palette.none)
    highlight('YellowItalic', palette.yellow, palette.none)
    highlight('GreenItalic', palette.green, palette.none)
    highlight('AquaItalic', palette.aqua, palette.none)
    highlight('BlueItalic', palette.blue, palette.none)
    highlight('PurpleItalic', palette.purple, palette.none)
  end
  if config.transparent_background == 1 or config.sign_column_background == 'none' then
    highlight('RedSign', palette.red, palette.none)
    highlight('OrangeSign', palette.orange, palette.none)
    highlight('YellowSign', palette.yellow, palette.none)
    highlight('GreenSign', palette.green, palette.none)
    highlight('AquaSign', palette.aqua, palette.none)
    highlight('BlueSign', palette.blue, palette.none)
    highlight('PurpleSign', palette.purple, palette.none)
  else
    highlight('RedSign', palette.red, palette.bg1)
    highlight('OrangeSign', palette.orange, palette.bg1)
    highlight('YellowSign', palette.yellow, palette.bg1)
    highlight('GreenSign', palette.green, palette.bg1)
    highlight('AquaSign', palette.aqua, palette.bg1)
    highlight('BlueSign', palette.blue, palette.bg1)
    highlight('PurpleSign', palette.purple, palette.bg1)
  end
  link('Added', 'Green')
  link('Removed', 'Red')
  link('Changed', 'Blue')
  if config.diagnostic_text_highlight then
    highlight('ErrorText', palette.none, palette.bg_red, 'undercurl', palette.red)
    highlight('WarningText', palette.none, palette.bg_yellow, 'undercurl', palette.yellow)
    highlight('InfoText', palette.none, palette.bg_blue, 'undercurl', palette.blue)
    highlight('HintText', palette.none, palette.bg_purple, 'undercurl', palette.purple)
  else
    highlight('ErrorText', palette.none, palette.none, 'undercurl', palette.red)
    highlight('WarningText', palette.none, palette.none, 'undercurl', palette.yellow)
    highlight('InfoText', palette.none, palette.none, 'undercurl', palette.blue)
    highlight('HintText', palette.none, palette.none, 'undercurl', palette.purple)
  end
  if config.diagnostic_line_highlight then
    highlight('ErrorLine', palette.none, palette.bg_red)
    highlight('WarningLine', palette.none, palette.bg_yellow)
    highlight('InfoLine', palette.none, palette.bg_blue)
    highlight('HintLine', palette.none, palette.bg_purple)
  else
    vim.cmd('highlight clear ErrorLine')
    vim.cmd('highlight clear WarningLine')
    vim.cmd('highlight clear InfoLine')
    vim.cmd('highlight clear HintLine')
  end
  if config.diagnostic_virtual_text == 'grey' then
    link('VirtualTextWarning', 'Grey')
    link('VirtualTextError', 'Grey')
    link('VirtualTextInfo', 'Grey')
    link('VirtualTextHint', 'Grey')
    link('VirtualTextOk', 'Grey')
  elseif config.diagnostic_virtual_text == 'colored' then
    link('VirtualTextWarning', 'Yellow')
    link('VirtualTextError', 'Red')
    link('VirtualTextInfo', 'Blue')
    link('VirtualTextHint', 'Purple')
    link('VirtualTextOk', 'Green')
  else
    highlight('VirtualTextWarning', palette.yellow, palette.bg_yellow)
    highlight('VirtualTextError', palette.red, palette.bg_red)
    highlight('VirtualTextInfo', palette.blue, palette.bg_blue)
    highlight('VirtualTextHint', palette.purple, palette.bg_purple)
    highlight('VirtualTextOk', palette.green, palette.bg_green)
  end
  highlight('ErrorFloat', palette.red, palette.none)
  highlight('WarningFloat', palette.yellow, palette.none)
  highlight('InfoFloat', palette.blue, palette.none)
  highlight('HintFloat', palette.purple, palette.none)
  highlight('OkFloat', palette.green, palette.none)
  if vim.o.diff then
    highlight('CurrentWord', palette.bg0, palette.green)
  elseif config.current_word == 'grey background' then
    highlight('CurrentWord', palette.none, palette.bg2)
  elseif config.current_word == 'high contrast background' then
    highlight('CurrentWord', palette.none, palette.bg3)
  else
    highlight('CurrentWord', palette.none, palette.none, config.current_word)
  end
  if config.inlay_hints_background == 'none' then
    link('InlayHints', 'LineNr')
  else
    highlight('InlayHints', palette.grey1, palette.bg_dim)
  end

  -- Terminal colors (fixed to dark)
  if (vim.fn.has('termguicolors') == 1 and vim.o.termguicolors) or vim.fn.has('gui_running') == 1 and not config.disable_terminal_colors then
    local terminal = {
      black = palette.bg3,
      red = palette.red,
      green = palette.green,
      yellow = palette.yellow,
      blue = palette.blue,
      purple = palette.purple,
      cyan = palette.aqua,
      white = palette.fg,
    }
    if not vim.fn.has('nvim') then
      vim.g.terminal_ansi_colors = {
        terminal.black, terminal.red, terminal.green, terminal.yellow,
        terminal.blue, terminal.purple, terminal.cyan, terminal.white,
        terminal.black, terminal.red, terminal.green, terminal.yellow,
        terminal.blue, terminal.purple, terminal.cyan, terminal.white,
      }
    else
      vim.g.terminal_color_0 = terminal.black
      vim.g.terminal_color_1 = terminal.red
      vim.g.terminal_color_2 = terminal.green
      vim.g.terminal_color_3 = terminal.yellow
      vim.g.terminal_color_4 = terminal.blue
      vim.g.terminal_color_5 = terminal.purple
      vim.g.terminal_color_6 = terminal.cyan
      vim.g.terminal_color_7 = terminal.white
      vim.g.terminal_color_8 = terminal.black
      vim.g.terminal_color_9 = terminal.red
      vim.g.terminal_color_10 = terminal.green
      vim.g.terminal_color_11 = terminal.yellow
      vim.g.terminal_color_12 = terminal.blue
      vim.g.terminal_color_13 = terminal.purple
      vim.g.terminal_color_14 = terminal.cyan
      vim.g.terminal_color_15 = terminal.white
    end
  end

  -- Plugin highlights (Treesitter, etc.)
  highlight('TSStrong', palette.none, palette.none, 'bold')
  highlight('TSEmphasis', palette.none, palette.none, 'italic')
  highlight('TSUnderline', palette.none, palette.none, 'underline')
  highlight('TSNote', palette.bg0, palette.green, 'bold')
  highlight('TSWarning', palette.bg0, palette.yellow, 'bold')
  highlight('TSDanger', palette.bg0, palette.red, 'bold')
  link('TSAnnotation', 'Purple')
  -- ... continue with all TS links as in original

  -- Other plugins and filetypes can be added similarly, but since fixed palette, no changes needed.

  -- Return for potential chaining
  return everforest
end

return everforest
