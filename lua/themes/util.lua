local m = {
  { 3.240969941904521, -1.537383177570093, -0.498610760293 },
  { -0.96924363628087, 1.87596750150772, 0.041555057407175 },
  { 0.055630079696993, -0.20397695888897, 1.056971514242878 },
}
local minv = {
  { 0.41239079926595, 0.35758433938387, 0.18048078840183 },
  { 0.21263900587151, 0.71516867876775, 0.072192315360733 },
  { 0.019330818715591, 0.11919477979462, 0.95053215224966 },
}

local refY = 1.0
local refU = 0.19783000664283
local refV = 0.46831999493879
local kappa = 903.2962962
local epsilon = 0.0088564516
local hexChars = "0123456789abcdef"

local length_of_ray_until_intersect = function(theta, line)
  return line.intercept / (math.sin(theta) - line.slope * math.cos(theta))
end

local dot_product = function(a, b)
  return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local from_linear = function(c)
  if c <= 0.0031308 then
    return 12.92 * c
  else
    return 1.055 * (c ^ 0.416666666666666685) - 0.055
  end
end

local to_linear = function(c)
  if c > 0.04045 then
    return ((c + 0.055) / 1.055) ^ 2.4
  else
    return c / 12.92
  end
end

-- Core conversion functions
local get_bounds = function(l)
  local result = {}
  local sub2
  local sub1 = ((l + 16) ^ 3) / 1560896
  if sub1 > epsilon then
    sub2 = sub1
  else
    sub2 = l / kappa
  end

  for i = 1, 3 do
    local m1 = m[i][1]
    local m2 = m[i][2]
    local m3 = m[i][3]

    for t = 0, 1 do
      local top1 = (284517 * m1 - 94839 * m3) * sub2
      local top2 = (838422 * m3 + 769860 * m2 + 731718 * m1) * l * sub2 - 769860 * t * l
      local bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t
      table.insert(result, { slope = top1 / bottom, intercept = top2 / bottom })
    end
  end
  return result
end

local max_safe_chroma_for_lh = function(l, h)
  local hrad = h / 360 * math.pi * 2
  local bounds = get_bounds(l)
  local min = math.huge

  for i = 1, 6 do
    local bound = bounds[i]
    local length = length_of_ray_until_intersect(hrad, bound)
    if length >= 0 then
      min = math.min(min, length)
    end
  end
  return min
end

local xyz_to_rgb = function(tuple)
  return {
    from_linear(dot_product(m[1], tuple)),
    from_linear(dot_product(m[2], tuple)),
    from_linear(dot_product(m[3], tuple)),
  }
end

local rgb_to_xyz = function(tuple)
  local rgbl = { to_linear(tuple[1]), to_linear(tuple[2]), to_linear(tuple[3]) }
  return {
    dot_product(minv[1], rgbl),
    dot_product(minv[2], rgbl),
    dot_product(minv[3], rgbl),
  }
end

local y_to_l = function(Y)
  if Y <= epsilon then
    return Y / refY * kappa
  else
    return 116 * ((Y / refY) ^ 0.333333333333333315) - 16
  end
end

local l_to_y = function(L)
  if L <= 8 then
    return refY * L / kappa
  else
    return refY * (((L + 16) / 116) ^ 3)
  end
end

local xyz_to_luv = function(tuple)
  local X = tuple[1]
  local Y = tuple[2]
  local divider = X + 15 * Y + 3 * tuple[3]
  local varU = 4 * X
  local varV = 9 * Y
  if divider ~= 0 then
    varU = varU / divider
    varV = varV / divider
  else
    varU = 0
    varV = 0
  end
  local L = y_to_l(Y)
  if L == 0 then
    return { 0, 0, 0 }
  end
  return { L, 13 * L * (varU - refU), 13 * L * (varV - refV) }
end

local luv_to_xyz = function(tuple)
  local L = tuple[1]
  local U = tuple[2]
  local V = tuple[3]
  if L == 0 then
    return { 0, 0, 0 }
  end
  local varU = U / (13 * L) + refU
  local varV = V / (13 * L) + refV
  local Y = l_to_y(L)
  local X = 0 - (9 * Y * varU) / (((varU - 4) * varV) - varU * varV)
  return { X, Y, (9 * Y - 15 * varV * Y - varV * X) / (3 * varV) }
end

local luv_to_lch = function(tuple)
  local L = tuple[1]
  local U = tuple[2]
  local V = tuple[3]
  local C = math.sqrt(U * U + V * V)
  local H
  if C < 0.00000001 then
    H = 0
  else
    H = math.atan2(V, U) * 180.0 / 3.1415926535897932
    if H < 0 then
      H = 360 + H
    end
  end
  return { L, C, H }
end

local lch_to_luv = function(tuple)
  local L = tuple[1]
  local C = tuple[2]
  local Hrad = tuple[3] / 360.0 * 2 * math.pi
  return { L, math.cos(Hrad) * C, math.sin(Hrad) * C }
end

local hsluv_to_lch = function(tuple)
  local H = tuple[1]
  local S = tuple[2]
  local L = tuple[3]
  if L > 99.9999999 then
    return { 100, 0, H }
  end
  if L < 0.00000001 then
    return { 0, 0, H }
  end
  return { L, max_safe_chroma_for_lh(L, H) / 100 * S, H }
end

local lch_to_hsluv = function(tuple)
  local L = tuple[1]
  local C = tuple[2]
  local H = tuple[3]
  local max_chroma = max_safe_chroma_for_lh(L, H)
  if L > 99.9999999 then
    return { H, 0, 100 }
  end
  if L < 0.00000001 then
    return { H, 0, 0 }
  end
  return { H, C / max_chroma * 100, L }
end

local rgb_to_hex = function(tuple)
  local h = "#"
  for i = 1, 3 do
    local c = math.floor(tuple[i] * 255 + 0.5)
    local digit2 = math.fmod(c, 16)
    local x = (c - digit2) / 16
    local digit1 = math.floor(x)
    h = h .. string.sub(hexChars, digit1 + 1, digit1 + 1)
    h = h .. string.sub(hexChars, digit2 + 1, digit2 + 1)
  end
  return h
end

local hex_to_rgb = function(hex)
  hex = string.lower(hex)
  local ret = {}
  for i = 0, 2 do
    local char1 = string.sub(hex, i * 2 + 2, i * 2 + 2)
    local char2 = string.sub(hex, i * 2 + 3, i * 2 + 3)
    local digit1 = string.find(hexChars, char1) - 1
    local digit2 = string.find(hexChars, char2) - 1
    ret[i + 1] = (digit1 * 16 + digit2) / 255.0
  end
  return ret
end

local lch_to_rgb = function(tuple)
  return xyz_to_rgb(luv_to_xyz(lch_to_luv(tuple)))
end

local rgb_to_lch = function(tuple)
  return luv_to_lch(xyz_to_luv(rgb_to_xyz(tuple)))
end

local hsluv_to_rgb = function(tuple)
  return lch_to_rgb(hsluv_to_lch(tuple))
end

local rgb_to_hsluv = function(tuple)
  return lch_to_hsluv(rgb_to_lch(tuple))
end

local function rgb(c)
  c = string.lower(c)
  return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) }
end

local hsluv_to_hex = function(tuple)
  return rgb_to_hex(hsluv_to_rgb(tuple))
end

local hex_to_hsluv = function(s)
  return rgb_to_hsluv(hex_to_rgb(s))
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
