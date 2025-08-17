--- Color manipulation utilities for Lua.
--- This module provides functions for converting between color formats (hex, RGB, HSL),
--- manipulating colors (lightness, saturation, blending), and calculating luminance and contrast.
--- All hex color inputs support 3-digit (e.g., "#FFF") or 6-digit (e.g., "#FFFFFF") formats,
--- with or without the "#" prefix.
local M = {}

--- Convert hex color to RGB components.
--- Takes a hex color string and converts it to RGB values. Supports 6-digit (e.g., "#FF0000") and
--- 3-digit (e.g., "#FFF") hex formats, with or without the "#" prefix.
--- Effect: Converts a hex string to its red, green, and blue components for further manipulation.
--- Example: to_rgb("#FF0000") returns 255, 0, 0 (pure red).
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
local function to_rgb(hex)
  hex = hex:gsub("#", "")
  if #hex == 3 then
    -- Expand 3-digit hex to 6-digit
    hex = hex:gsub("(%x)", "%1%1")
  end

  local r = tonumber(hex:sub(1, 2), 16)
  local def = 0
  local g = tonumber(hex:sub(3, 4), 16) or def
  local b = tonumber(hex:sub(5, 6), 16) or def

  return r, g, b
end

--- Convert RGB components to hex color.
--- Converts RGB values to a lowercase hex color string with a "#" prefix.
--- Effect: Produces a hex string for use in CSS, Neovim highlights, or other color contexts.
--- Example: to_hex(255, 0, 0) returns "#ff0000" (pure red).
local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x",
    math.floor(r + 0.5),
    math.floor(g + 0.5),
    math.floor(b + 0.5)
  )
end

--- Convert RGB to HSL.
--- Converts RGB values to HSL (Hue, Saturation, Lightness) for easier color manipulation.
--- Effect: Enables adjustments in HSL space, where hue defines color type, saturation defines
--- intensity, and lightness defines brightness.
--- Example: rgb_to_hsl(255, 0, 0) returns approximately 0, 1, 0.5 (red hue, fully saturated,
--- 50% lightness).
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

--- Convert HSL to RGB.
--- Converts HSL values back to RGB for rendering or further processing.
--- Effect: Transforms hue, saturation, and lightness into RGB values suitable for display.
--- Example: hsl_to_rgb(0, 1, 0.5) returns approximately 255, 0, 0 (pure red).
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

--- Linear interpolation between two values.
--- Interpolates between two values based on a factor, useful for smooth transitions.
--- Effect: Produces a value between `a` and `b` based on the interpolation factor `t`.
--- Example: lerp(0, 100, 0.5) returns 50 (halfway between 0 and 100).
local function lerp(a, b, t)
  return a + (b - a) * t
end

--- Clamp value between min and max.
--- Ensures a value stays within a specified range, preventing invalid inputs.
--- Effect: Restricts `value` to be no less than `min_val` and no more than `max_val`.
--- Example: clamp(150, 0, 100) returns 100.
local function clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end

--- Blend two colors with a given ratio.
--- Interpolates between two colors to create a new color based on a ratio.
--- Effect: Creates a smooth transition from `color1` to `color2` (e.g., blending red and blue creates
--- purple at 0.5).
--- Example: blend_colors("#FF0000", "#0000FF", 0.5) returns approximately "#800080" (purple).
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
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

--- Lighten a color by a given amount.
--- Increases the lightness of a color in HSL space, making it brighter.
--- Effect: Moves the color toward white without changing hue or saturation.
--- Example: lighten("#FF0000", 0.2) returns a lighter red (e.g., "#ff3333").
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.lighten(color, amount)
  amount = clamp(amount, 0, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Increase lightness
  l = clamp(l + amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

--- Darken a color by a given amount.
--- Decreases the lightness of a color in HSL space, making it darker.
--- Effect: Moves the color toward black without changing hue or saturation.
--- Example: darken("#FF0000", 0.2) returns a darker red (e.g., "#cc0000").
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.darken(color, amount)
  amount = clamp(amount, 0, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Decrease lightness
  l = clamp(l - amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

--- Add alpha channel to a color (returns rgba format for CSS-like usage).
--- Converts a hex color to an rgba string with a specified alpha (transparency) value.
--- Note: Primarily for CSS or documentation, as Neovim doesn't support alpha in highlights.
--- Effect: Adds transparency to a color for use in environments supporting rgba.
--- Example: with_alpha("#FF0000", 0.5) returns "rgba(255, 0, 0, 0.50)" (semi-transparent red).
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.with_alpha(color, alpha)
  alpha = clamp(alpha, 0, 1)
  local r, g, b = to_rgb(color)

  -- Return in rgba format
  return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, alpha)
end

--- Blend a color with a background to simulate alpha.
--- Blends a foreground color with a background color based on an alpha value, simulating
--- transparency.
--- Effect: Produces a solid color that mimics the appearance of a transparent color over a
--- background.
--- Example: with_alpha_blend("#FF0000", 0.5, "#000000") blends red with black, returning a darker
--- red (e.g., "#800000").
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.with_alpha_blend(color, alpha, background)
  background = background or "#000000"
  alpha = clamp(alpha, 0, 1)

  -- Blend the color with background based on alpha
  return M.blend_colors(background, color, alpha)
end

--- Adjust saturation of a color.
--- Increases or decreases the saturation of a color in HSL space.
--- Effect: Positive amounts make the color more vibrant; negative amounts make it more grayscale.
--- Example: saturate("#FF0000", -0.5) returns a less saturated red (e.g., "#ff4040").
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.saturate(color, amount)
  amount = clamp(amount, -1, 1)
  local r, g, b = to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)

  -- Adjust saturation
  s = clamp(s + amount, 0, 1)

  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return to_hex(new_r, new_g, new_b)
end

--- Get the relative luminance of a color (useful for contrast calculations).
--- Calculates the relative luminance using ITU-R BT.709 coefficients.
--- Effect: Provides a value indicating perceived brightness, useful for accessibility (e.g., WCAG
--- contrast ratios).
--- Example: get_luminance("#FFFFFF") returns 1 (maximum luminance for white).
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.get_luminance(color)
  local r, g, b = to_rgb(color)

  local function to_linear(c)
    c = c / 255
    return c <= 0.03928 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end

  local lr, lg, lb = to_linear(r), to_linear(g), to_linear(b)

  return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb
end

--- Calculate contrast ratio between two colors.
--- Computes the contrast ratio between two colors, useful for ensuring text readability (e.g., WCAG
--- compliance).
--- Effect: Returns a ratio where higher values indicate better contrast (e.g., 21 for black vs. white).
--- Example: get_contrast_ratio("#FFFFFF", "#000000") returns 21 (maximum contrast).
--- Note: Invalid hex strings may cause errors; ensure valid 3-digit or 6-digit hex input.
function M.get_contrast_ratio(color1, color2)
  local lum1 = M.get_luminance(color1)
  local lum2 = M.get_luminance(color2)

  local lighter = math.max(lum1, lum2)
  local darker = math.min(lum1, lum2)

  return (lighter + 0.05) / (darker + 0.05)
end

return M
