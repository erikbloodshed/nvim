local utils = require("themes.ayu-mirage.utils")

local u = "#1F2430"
local e = "#242936"

local syntax = {
  tag = "#5CCFE6",
  func = "#FFD173",
  entity = "#73D0FF",
  string = "#D5FF80",
  regexp = "#95E6CB",
  markup = "#F28779",
  keyword = "#FFAD66",
  special = "#FFDFB3",
  comment = utils.blend_colors(e, "#B8CFE6", 0.5),
  constant = "#DFBFFF",
  operator = "#F29E74",
}

local vcs = {
  added = "#87D96C",
  modified = "#80BFFF",
  removed = "#F27983",
}

local editor = {
  fg = "#CCCAC2",
  bg = "#1F2430",
  line = "#1A1F29",
  selection = {
    active = utils.blend_colors(e, "#409FFF", 0.25),
    inactive = utils.blend_colors(e, "#409FFF", 0.13),
  },
  find_match = {
    active = "#695380",
    inactive = utils.blend_colors(e, "#695380", 0.4)
  },
  gutter = {
    active = utils.blend_colors(e, "#8A9199", 0.8),
    normal = utils.blend_colors(e, "#8A9199", 0.4),
  },
  indent_guide = {
    active = utils.blend_colors(e, "#8A9199", 0.15),
    normal = utils.blend_colors(e, "#8A9199", 0.12),
  }
}

local ui = {
  fg = "#707A8C",
  bg = "#152430",
  line = "#171B24",
  selection = {
    active = utils.blend_colors(u, "#637599", 0.15),
    normal = utils.blend_colors(u, "#637599", 0.12),
  },
  panel = {
    bg = "#1C212B",
    shadow = utils.blend_colors(u, "#12151C", 0.7),
  }
}

local common = {
  accent = "#FFCC66",
  error = "#FF6666",
}

-- New colors derived from Ayu Mirage JSON but not in original palette
local extra = {
  match_paren_bg = "#695380",
  match_paren_border = "#5C4672",
  line_number_fg = "#8A9199",
  fold_fg = "#707A8C",
  fold_bg = "#1C212B",
  float_title_fg = "#FFD173",
  pmenu_thumb_bg = "#707A8C",
  pmenu_sbar_bg = "#242936",
  visual_bg = "#409FFF", -- resolved from alpha blend
}

return { syntax = syntax, vcs = vcs, editor = editor, ui = ui, common = common, extra = extra }
