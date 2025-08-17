local M = {}

-- Convert hex color to RGB components
local function to_rgb(hex)
  hex = hex:gsub("#", "")
  if #hex == 3 then
    -- Expand 3-digit hex to 6-digit
    hex = hex:gsub("(%x)", "%1%1")
  end

  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  return r, g, b
end

-- Convert RGB components to hex color
local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x",
    math.floor(r + 0.5),
    math.floor(g + 0.5),
    math.floor(b + 0.5)
  )
end

-- Convert RGB to HSL
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2

  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, l
end

-- Convert HSL to RGB
local function hsl_to_rgb(h, s, l)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1 / 6 then return p + (q - p) * 6 * t end
      if t < 1 / 2 then return q end
      if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
      return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1 / 3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1 / 3)
  end

  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

-- Linear interpolation between two values
local function lerp(a, b, t)
  return a + (b - a) * t
end

-- Clamp value between min and max
local function clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end

-- Blend two colors with a given ratio
function M.blend_colors(color1, color2, ratio)
  -- Clamp ratio between 0 and 1
  ratio = clamp(ratio, 0, 1)

  local r1, g1, b1 = to_rgb(color1)
  local r2, g2, b2 = to_rgb(color2)

  local r = lerp(r1, r2, ratio)
  local g = lerp(g1, g2, ratio)
  local b = lerp(b1, b2, ratio)

  return to_hex(r, g, b)
end

-- Lighten a color by a given amount (0.0 to 1.0)
function M.lighten(color, amount)
  amount = clamp(amount, 0, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Increase lightness
  l = clamp(l + amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

-- Darken a color by a given amount (0.0 to 1.0)
function M.darken(color, amount)
  amount = clamp(amount, 0, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Decrease lightness
  l = clamp(l - amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

-- Add alpha channel to a color (returns rgba format for CSS-like usage)
-- For Neovim, this is mainly for documentation as Neovim doesn't support alpha in highlights
function M.with_alpha(color, alpha)
  alpha = clamp(alpha, 0, 1)
  local r, g, b = to_rgb(color)

  -- Return in rgba format
  return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, alpha)
end

-- Alternative: blend with background to simulate alpha
function M.with_alpha_blend(color, alpha, background)
  background = background or "#000000"
  alpha = clamp(alpha, 0, 1)

  -- Blend the color with background based on alpha
  return M.blend_colors(background, color, alpha)
end

-- Adjust saturation of a color
function M.saturate(color, amount)
  amount = clamp(amount, -1, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Adjust saturation
  s = clamp(s + amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

-- Get the relative luminance of a color (useful for contrast calculations)
function M.get_luminance(color)
  local r, g, b = to_rgb(color)

  -- Convert to linear RGB
  local function to_linear(c)
    c = c / 255
    return c <= 0.03928 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end

  local lr, lg, lb = to_linear(r), to_linear(g), to_linear(b)

  -- Calculate luminance using ITU-R BT.709 coefficients
  return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb
end

-- Calculate contrast ratio between two colors
function M.get_contrast_ratio(color1, color2)
  local lum1 = M.get_luminance(color1)
  local lum2 = M.get_luminance(color2)

  local lighter = math.max(lum1, lum2)
  local darker = math.min(lum1, lum2)

  return (lighter + 0.05) / (darker + 0.05)
end

return M
