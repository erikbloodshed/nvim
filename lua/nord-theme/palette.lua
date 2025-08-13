local palette = {
  none = 'NONE', -- Placeholder for transparency or system defaults

  -- Blacks (New, for dark UI elements)
  black0 = '#191D24', -- Derived: Darkened Nord0 by reducing lightness to ~12%
  black1 = '#1E222A', -- Derived: Lightness ~15%, same hue as Nord0
  black2 = '#222630', -- Derived: Matches provided palette, lightness ~18%

  -- Grays
  gray0 = '#242933', -- Derived: Matches provided palette, slightly lighter than Nord0
  gray1 = '#2E3440', -- Original: Nord0 (Polar Night)
  gray2 = '#3B4252', -- Original: Nord1 (Polar Night)
  gray3 = '#434C5E', -- Original: Nord2 (Polar Night)
  gray4 = '#4C566A', -- Original: Nord3 (Polar Night)
  gray5 = '#60728A', -- Derived: Adjusted from provided #60728A, less blue, lightness ~45%

  -- Whites
  white0_normal = '#C0C8D8',      -- Derived: Adjusted Nord4, reduced lightness (~78%) and blue tint
  white0_reduce_blue = '#BBC3D4', -- Derived: Further adjusted white0_normal, neutral hue
  white1 = '#D8DEE9',             -- Original: Nord4 (Snow Storm)
  white2 = '#E5E9F0',             -- Original: Nord5 (Snow Storm)
  white3 = '#ECEFF4',             -- Original: Nord6 (Snow Storm)

  -- Frost
  cyan = {
    base = '#8FBCBB',   -- Original: Nord7 (Frost)
    bright = '#9FC6C5', -- Derived: Lightness increased ~10% for hover/active states
    dim = '#80B3B2',    -- Derived: Lightness decreased ~10% for subtle accents
  },
  blue0 = '#5E81AC',    -- Original: Nord10 (Frost)
  blue1 = '#81A1C1',    -- Original: Nord9 (Frost)
  blue2 = '#88C0D0',    -- Original: Nord8 (Frost)

  -- Aurora
  red = {
    base = '#BF616A',   -- Original: Nord11 (Aurora)
    bright = '#C5727A', -- Derived: Lightness ~62%, reduced saturation for comfort
    dim = '#B74E58',    -- Derived: Lightness ~50% for subtle errors
  },
  orange = {
    base = '#D08770',   -- Original: Nord12 (Aurora)
    bright = '#D79784', -- Derived: Lightness ~70%, reduced saturation for warnings
    dim = '#CB775D',    -- Derived: Lightness ~58% for subtle warnings
  },
  yellow = {
    base = '#EBCB8B',   -- Original: Nord13 (Aurora)
    bright = '#EFD49F', -- Derived: Lightness ~80%, reduced saturation for highlights
    dim = '#E7C173',    -- Derived: Lightness ~66% for subtle highlights
  },
  green = {
    base = '#A3BE8C',   -- Original: Nord14 (Aurora)
    bright = '#B1C89D', -- Derived: Lightness ~72%, reduced saturation for success states
    dim = '#97B67C',    -- Derived: Lightness ~58% for subtle success
  },
  magenta = {
    base = '#B48EAD',   -- Original: Nord15 (Aurora)
    bright = '#BE9DB8', -- Derived: Lightness ~71%, reduced saturation for annotations
    dim = '#A97EA1',    -- Derived: Lightness ~57% for subtle annotations
  },
}

return palette
