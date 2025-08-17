local utils = require("themes.auren.utils") -- Adjust path as needed

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
  red = "#e06c75",
  orange = "#d19a66",
  yellow = "#e5c07b",
  green = "#98c379",
  cyan = "#56b6c2",
  blue = "#61afef",
  purple = "#c678dd",
  deepRed = "#be5046",
  white = "#FFFFFF",
  teal = "#5eaba0",
}

local colors = {
  -- Editor core colors
  editor = {
    bg = base.base00,
    fg = base.base06,
    line = utils.with_alpha_blend(base.base01, 0.7, base.base00), -- Current line / cursor line background
    selection = {
      active = base.base02,
      inactive = base.base03,
    }
  },

  -- UI elements
  ui = {
    bg = utils.lighten(base.base00, 0.02), -- UI background
    fg = base.base06,                      -- UI foreground
    line = base.base02,                    -- Separator lines
    panel = {
      bg = base.base01,                    -- Panel background
      fg = base.base04,                    -- Panel foreground
    }
  },

  -- Syntax highlighting colors (One Dark Pro accents)
  syntax = {
    tag = accent.cyan,        -- Blue - tags, modules
    func = accent.blue,       -- Blue - functions, methods
    entity = accent.yellow,   -- Cyan - types, classes, interfaces
    string = accent.green,    -- Green - strings, characters
    regexp = accent.teal,     -- Green - regular expressions
    markup = accent.red,      -- Red - markup, todos
    keyword = accent.purple,  -- Purple - keywords, storage
    special = accent.orange,  -- Orange - special characters, macros
    comment = base.base03,    -- Gray - comments
    constant = accent.orange, -- Orange - constants, numbers
    operator = accent.cyan,   -- Yellow - operators, variables
  },

  -- Common semantic colors
  common = {
    error = accent.red,      -- Red - errors
    warning = accent.orange, -- Orange - warnings
    info = accent.blue,      -- Blue - information
    hint = accent.cyan,      -- Cyan - hints
    success = accent.green,  -- Green - success
    white = accent.white,
    none = "NONE",
  },

  vcs = {
    added = base.green,
    modified = base.yellow,
    removed = base.red,
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
