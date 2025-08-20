local hex_to_hsluv = require("themes.hsluv").hex_to_hsluv
local hsluv_to_hex = require("themes.hsluv").hsluv_to_hex

local function rgb(c)
  c = string.lower(c)
  return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) }
end

local M = {}

M.blend = function(foreground, alpha, background)
  alpha = type(alpha) == "string" and (tonumber(alpha, 16) / 0xff) or alpha
  local bg = rgb(background)
  local fg = rgb(foreground)

  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02x%02x%02x", blendChannel(1), blendChannel(2), blendChannel(3))
end

M.brighten = function(color, lightness_amount, saturation_amount)
  lightness_amount = lightness_amount or 0.05
  saturation_amount = saturation_amount or 0.2

  local hsl = hex_to_hsluv(color)

  hsl[3] = math.min(hsl[3] + (lightness_amount * 100), 100)
  hsl[2] = math.min(hsl[2] + (saturation_amount * 100), 100)

  return hsluv_to_hex(hsl)
end

return M
