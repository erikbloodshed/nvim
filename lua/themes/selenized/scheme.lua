local utils = require("themes.selenized.utils") -- Adjust path as needed
local transparency = false

return {
  -- base colors (foreground/background)
  bg_0 = transparency or "#103c48",
  bg_1 = "#184956",
  bg_2 = "#2d5b69",
  dim_0 = "#72898f",
  fg_0 = "#adbcbc",
  fg_1 = "#cad8d9",

  -- accent colors
  red = "#fa5750",
  green = "#75b938",
  yellow = "#dbb32d",
  blue = "#4695f7",
  magenta = "#f275be",
  cyan = "#41c7b9",

  -- bright accent
  br_red = "#ff665c",
  br_green = "#84c747",
  br_yellow = "#ebc13d",
  br_blue = "#58a3ff",
  br_magenta = "#ff84cd",
  br_cyan = "#53d6c7",

  -- additional colors for gui/truecolor supported apps
  orange = "#ed8649",
  violet = "#af4b8a",
  br_orange = "#fd9456",
  br_violet = "#bd96fa",
}

