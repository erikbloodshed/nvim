local utils = require("themes.oneocean.utils") -- Adjust path as needed

-- Base palette (Oceanic Next foundation)
local base = {
  base00 = "#1b2b34", -- Background
  base01 = "#343d46", -- Line highlight
  base02 = "#4f5b66", -- Selection
  base03 = "#65737e", -- Comments
  base04 = "#a7adba", -- Dark foreground
  base05 = "#c0c5ce", -- Default foreground
  base06 = "#cdd3de", -- Light foreground
  base07 = "#d8dee9", -- Light background
}

local accent = {
  red = "#e06c75",     -- Errors / keywords
  orange = "#d19a66",  -- Constants / numbers
  yellow = "#e5c07b",  -- Identifiers / variables
  green = "#98c379",   -- Strings
  cyan = "#56b6c2",    -- Classes / types
  blue = "#61afef",    -- Functions
  purple = "#c678dd",  -- Keywords / storage
  deepRed = "#be5046", -- Alternative red (operators/errors)
  white = "#FFFFFF"
}

local colors = {
  -- Editor core colors
  editor = {
    bg = base.base00,
    fg = base.base05,
    line = utils.with_alpha_blend(base.base01, 0.7, base.base00), -- Current line / cursor line background
    selection = {
      active = base.base02,
      inactive = base.base03,
    }
  },
  -- Syntax highlighting colors (One Dark Pro accents)
  syntax = {
    tag = accent.blue,                         -- Blue - tags, modules
    func = accent.blue,                        -- Blue - functions, methods
    entity = accent.yellow,                    -- Cyan - types, classes, interfaces
    string = accent.green,                     -- Green - strings, characters
    regexp = utils.darken(accent.green, 0.05), -- Green - regular expressions
    markup = accent.red,                       -- Red - markup, todos
    keyword = accent.purple,                   -- Purple - keywords, storage
    special = accent.orange,                   -- Orange - special characters, macros
    comment = base.base03,                     -- Gray - comments
    constant = accent.orange,                  -- Orange - constants, numbers
    operator = accent.cyan,                    -- Yellow - operators, variables
  },

  -- Common semantic colors
  common = {
    error = accent.red,      -- Red - errors
    warning = accent.orange, -- Orange - warnings
    info = accent.blue,      -- Blue - information
    hint = accent.cyan,      -- Cyan - hints
    success = accent.green,  -- Green - success
    none = "NONE",
    white = accent.white,
  },

  -- UI elements
  ui = {
    bg = utils.darken(base.base00, 0.02), -- UI background
    fg = utils.darken(base.base05, 0.05), -- UI foreground
    line = base.base01,                   -- Separator lines
    panel = {
      bg = base.base01,                   -- Panel background
      fg = base.base04,                   -- Panel foreground
    }
  },

  -- Version control colors
  vcs = {
    added = base.green,    -- Green - added lines
    modified = base.yellow, -- Yellow - modified lines
    removed = base.red,  -- Red - removed lines
  },

  -- Extended colors for various UI elements
  extra = {
    border1 = base.base02,
    border2 = base.base03,
    fold_fg = base.base04,
    fold_bg = base.base01,
    line_number_fg = base.base03,
    pmenu_sbar_bg = base.base02,
    pmenu_thumb_bg = base.base03,
  },

  -- Terminal colors (16-color palette)
  terminal = {
    black = "#1b2b34",
    red = "#e06c75",
    green = "#98c379",
    yellow = "#e5c07b",
    blue = "#61afef",
    magenta = "#c678dd",
    cyan = "#56b6c2",
    white = "#c0c5ce",
    bright_black = "#65737e",
    bright_red = "#be5046",
    bright_green = "#98c379",
    bright_yellow = "#e5c07b",
    bright_blue = "#61afef",
    bright_magenta = "#c678dd",
    bright_cyan = "#56b6c2",
    bright_white = "#d8dee9",
  },
}

return colors
