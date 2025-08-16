local utils = require("themes.ayu-dark.utils")

-- local u = "#1F2430"
-- local e = "#242936"

local syntax = {
  tag = "#39BAE6",
  func = "#FFB454",
  entity = "#59C2FF",
  string = "#AAD94C",
  regexp = "#95E6CB",
  markup = "#F07178",
  keyword = "#FF8F40",
  special = "#E6B673",
  comment = utils.with_alpha_blend("#0B0E14", 0.5, "#BFBDB6"),
  constant = "#D2A6FF",
  operator = "#F29668",
}

local vcs = {
  added = "#7FD962",
  modified = "#FFCC66",
  removed = "#F26D78",
}

local editor = {
  fg = "#BFBDB6",
  bg = "#1b2b34",
  line = "#131721",
  selection = {
    active = utils.with_alpha_blend("#6C5980", 0.25, "#0D1017"),
    inactive = utils.with_alpha_blend("#6C5980", 0.05, "#242936"),
  },
  find_match = {
    active = "#6C5980",
    inactive = utils.with_alpha_blend("#6C5980", 0.4, "#0D1017")
  },
  gutter = {
    active = utils.with_alpha_blend("#6C7380", 0.8, "#0D1017"),
    normal = utils.with_alpha_blend("#6C7380", 0.4, "#0D1017"),
  },
  indent_guide = {
    active = utils.with_alpha_blend("#6C7380", 0.35, "#0D1017"),
    normal = utils.with_alpha_blend("#6C7380", 0.18, "#0D1017"),
  }
}

local ui = {
  fg = "#565B66",
  bg = "#0B0E14",
  line = "#11151C",
  selection = {
    active = utils.with_alpha_blend("#475266", 0.15, "#0B0E14"),
    normal = utils.with_alpha_blend("#475266", 0.12, "#0B0E14"),
  },
  panel = {
    bg = "#0F131A",
    shadow = utils.with_alpha_blend("#000000", 0.5, "#0B0E14"),
  }
}

local common = {
  accent = "#E6B450",
  error = "#D95757",
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

local extra = {
  border1 = utils.with_alpha_blend("#409FFF", 0.6, "#242936"),
  border2 = utils.with_alpha_blend("#FFAD66", 0.8, "#242936"),
  line_number_fg = "#8A9199",
  fold_fg = "#707A8C",
  fold_bg = "#1C212B",
  float_title_fg = "#FFD173",
  pmenu_thumb_bg = "#707A8C",
  pmenu_sbar_bg = "#242936",
  visual_bg = ui.selection.active,
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
