M = {}

-- Convert hex color to RGB components
local function hex_to_rgb(hex)
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
local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x",
    math.floor(r + 0.5),
    math.floor(g + 0.5),
    math.floor(b + 0.5)
  )
end

-- Linear interpolation between two values
local function lerp(a, b, t)
  return a + (b - a) * t
end

-- Blend two colors with a given ratio
-- @param color1: First color in hex format (e.g., "#ff0000")
-- @param color2: Second color in hex format (e.g., "#0000ff")
-- @param ratio: Blend ratio (0.0 = full color1, 1.0 = full color2)
-- @return: Blended color in hex format
function M.blend_colors(color1, color2, ratio)
  -- Clamp ratio between 0 and 1
  ratio = math.max(0, math.min(1, ratio))

  local r1, g1, b1 = hex_to_rgb(color1)
  local r2, g2, b2 = hex_to_rgb(color2)

  local r = lerp(r1, r2, ratio)
  local g = lerp(g1, g2, ratio)
  local b = lerp(b1, b2, ratio)

  return rgb_to_hex(r, g, b)
end

return M
