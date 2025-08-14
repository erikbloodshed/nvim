local utils = require("themes.ayu-mirage.utils")

-- local u = "#1F2430"
-- local e = "#242936"

local syntax = {
  tag = "#5CCFE6",
  func = "#FFD173",
  entity = "#73D0FF",
  string = "#D5FF80",
  regexp = "#95E6CB",
  markup = "#F28779",
  keyword = "#FFAD66",
  special = "#FFDFB3",
  comment = utils.with_alpha_blend("#B8CFE6", 0.5, "#242936"),
  constant = "#DFBFFF",
  operator = "#F29E74",
}

local vcs = {
  added = "#87D96C",
  modified = "#FFCC66",
  removed = "#F27983",
}

local editor = {
  fg = "#CCCAC2",
  bg = "#242936",
  line = "#1A1F29",
  selection = {
    active = utils.with_alpha_blend("#409FFF", 0.25, "#242936"),
    inactive = utils.with_alpha_blend("#409FFF", 0.13, "#242936"),
  },
  find_match = {
    active = "#695380",
    inactive = utils.with_alpha_blend("#695380", 0.4, "#242936")
  },
  gutter = {
    active = utils.with_alpha_blend("#8A9199", 0.8, "#242936"),
    normal = utils.with_alpha_blend("#8A9199", 0.4, "#242936"),
  },
  indent_guide = {
    active = utils.with_alpha_blend("#8A9199", 0.35, "#242936"),
    normal = utils.with_alpha_blend("#8A9199", 0.18, "#242936"),
  }
}

local ui = {
  fg = "#707A8C",
  bg = "#1F2430",
  line = "#171B24",
  selection = {
    active = utils.with_alpha_blend("#637599", 0.15, "#1F2430"),
    normal = utils.with_alpha_blend("#69758C", 0.12, "#1F2430"),
  },
  panel = {
    bg = "#1C212B",
    shadow = utils.with_alpha_blend("#12151C", 0.7, "#1F2430"),
  }
}

local common = {
  accent = "#FFCC66",
  error = "#FF6666",
}

-- Terminal colors for :terminal
local terminal = {
  black = "#212733",
  red = "#FF3333",
  green = "#B8CC52",
  yellow = "#FFCC66",
  blue = "#8FCDF1",
  magenta = "#D484FF",
  cyan = "#90E0FF",
  white = "#D0D0D0",        -- Default text - made brighter
  bright_black = "#5C6370", -- Made brighter than comment color
  bright_red = "#FF6666",
  bright_green = "#CCFF66",
  bright_yellow = "#FFDD66",
  bright_blue = "#409FFF", -- Made brighter for directories
  bright_magenta = "#E066FF",
  bright_cyan = "#66FFFF",
  bright_white = "#FFFFFF", -- Made very bright for high contrast
}

-- New colors derived from Ayu Mirage JSON but not in original palette
local extra = {
  line_number_fg = "#8A9199",
  fold_fg = "#707A8C",
  fold_bg = "#1C212B",
  float_title_fg = "#FFD173",
  pmenu_thumb_bg = "#707A8C",
  pmenu_sbar_bg = "#242936",
  visual_bg = ui.selection.active, -- resolved from alpha blend
}

return {
  syntax = syntax,
  vcs = vcs,
  editor = editor,
  ui = ui,
  common = common,
  terminal = terminal,
  extra = extra
}
