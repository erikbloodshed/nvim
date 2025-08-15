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
    inactive = utils.with_alpha_blend("#409FFF", 0.05, "#242936"),
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

local terminal = {
  black = "#171B24",
  red = "#ED8274",
  green = "#87D96C",
  yellow = "#FACC6E",
  blue = "#6DCBFA",
  magenta = "#DABAFA",
  cyan = "#90E1C6",
  white = "#C7C7C7",
  bright_black = "#686868",
  bright_red = "#F28779",
  bright_green = "#D5FF80",
  bright_yellow = "#FFD173",
  bright_blue = "#73D0FF",
  bright_magenta = "#DFBFFF",
  bright_cyan = "#95E6CB",
  bright_white = "#FFFFFF",
}

-- New colors derived from Ayu Mirage JSON but not in original palette
local extra = {
  border = utils.with_alpha_blend("#409FFF", 0.5, "#242936"),
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
