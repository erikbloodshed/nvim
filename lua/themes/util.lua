local M = {}

M.bg = "#000000"
M.fg = "#ffffff"
M.day_brightness = 0.3

---@param c  string
local function rgb(c)
  c = string.lower(c)
  return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) }
end

---@param foreground string foreground color
---@param background string background color
---@param alpha number|string number between 0 and 1. 0 results in bg, 1 results in fg
function M.blend(foreground, alpha, background)
  alpha = type(alpha) == "string" and (tonumber(alpha, 16) / 0xff) or alpha
  local bg = rgb(background)
  local fg = rgb(foreground)

  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02x%02x%02x", blendChannel(1), blendChannel(2), blendChannel(3))
end

function M.blend_bg(hex, amount, bg)
  return M.blend(hex, amount, bg or M.bg)
end

M.darken = M.blend_bg

function M.blend_fg(hex, amount, fg)
  return M.blend(hex, amount, fg or M.fg)
end

function M.brighten(color, lightness_amount, saturation_amount)
  lightness_amount = lightness_amount or 0.05
  saturation_amount = saturation_amount or 0.2
  local hsluv = require("themes.hsluv")

  -- Convert the hex color to HSLuv
  local hsl = hsluv.hex_to_hsluv(color)

  -- Increase lightness slightly
  hsl[3] = math.min(hsl[3] + (lightness_amount * 100), 100)

  -- Increase saturation a bit more to make the color more vivid
  hsl[2] = math.min(hsl[2] + (saturation_amount * 100), 100)

  -- Convert the HSLuv back to hex and return
  return hsluv.hsluv_to_hex(hsl)
end

return M
