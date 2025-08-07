# OneDark Neovim Colorscheme Palette

## Core Background Colors
```
bg0          = "#282c34"    -- Main background (OneDark signature)
bg1          = "#2c323c"    -- Slightly lighter background (sidebars, popups)
bg2          = "#3e4451"    -- Even lighter (visual selection, current line)  
bg3          = "#5c6370"    -- Lightest background (borders, inactive elements)
bg_d         = "#21252b"    -- Darker background variant
```

## Core Foreground Colors
```
fg          = "#abb2bf"     -- Main foreground text
light_grey  = "#abb2bf"     -- Primary text
grey        = "#5c6370"     -- Secondary text (comments, less important)
dark_grey   = "#3e4451"     -- Tertiary text (line numbers, borders)
```

## OneDark Signature Colors

### Primary Syntax Colors
```
red         = "#e06c75"     -- Keywords, errors, delete operations
dark_red    = "#be5046"     -- Darker red variant
green       = "#98c379"     -- Strings, comments, additions, success
dark_green  = "#7a9f60"     -- Darker green variant
yellow      = "#e5c07b"     -- Classes, warnings, constants
dark_yellow = "#d19a66"     -- Darker yellow/orange variant
blue        = "#61afef"     -- Functions, methods, links
dark_blue   = "#4e88c7"     -- Darker blue variant
purple      = "#c678dd"     -- Keywords, types, special
dark_purple = "#a05eb5"     -- Darker purple variant
cyan        = "#56b6c2"     -- Operators, escape characters, info
dark_cyan   = "#449dab"     -- Darker cyan variant
```

### Extended OneDark Colors
```
orange      = "#d19a66"     -- Numbers, constants, attributes
pink        = "#e06c75"     -- Alternative for red (some variants)
teal        = "#56b6c2"     -- Alternative for cyan
lavender    = "#c678dd"     -- Alternative for purple
```

## UI and Special Colors

### Interface Elements
```
cursor_grey = "#2c323c"     -- Cursor line background
visual_grey = "#3e4451"     -- Visual selection background
menu_grey   = "#3e4451"     -- Menu/popup backgrounds
special_grey= "#3b4048"     -- Special backgrounds
gutter_grey = "#4b5263"     -- Gutter, line numbers
comment_grey= "#5c6370"     -- Comments, inactive text
```

### Git Colors (OneDark Style)
```
diff_add    = "#109868"     -- Git additions
diff_delete = "#9a353d"     -- Git deletions  
diff_change = "#948c36"     -- Git modifications
diff_text   = "#948c36"     -- Git diff text highlighting
```

### Diagnostic Colors
```
error       = "#e06c75"     -- Error messages and highlights
warning     = "#e5c07b"     -- Warning messages and highlights
info        = "#61afef"     -- Info messages and highlights
hint        = "#56b6c2"     -- Hint messages and highlights
```

## OneDark Style Variants

### Dark Variant
```
bg0_dark    = "#1e2227"     -- Darker main background
bg1_dark    = "#252931"     -- Darker sidebar background
fg_dark     = "#a0a8b7"     -- Slightly dimmer foreground
```

### Darker Variant  
```
bg0_darker  = "#1b1f27"     -- Even darker background
bg1_darker  = "#21252b"     -- Even darker sidebar
```

### Cool Variant
```
bg0_cool    = "#282d3a"     -- Cool-toned background
blue_cool   = "#6db3f2"     -- Cooler blue
cyan_cool   = "#4fb3d9"     -- Cooler cyan
```

### Warm Variant
```
bg0_warm    = "#2d2a28"     -- Warm-toned background
red_warm    = "#e86671"     -- Warmer red
orange_warm = "#d99a5e"     -- Warmer orange
```

## Terminal Colors (OneDark 16-color palette)
```
-- Dark colors (0-7)
term_black   = "#282c34"    -- 0: background
term_red     = "#e06c75"    -- 1: red
term_green   = "#98c379"    -- 2: green  
term_yellow  = "#e5c07b"    -- 3: yellow
term_blue    = "#61afef"    -- 4: blue
term_magenta = "#c678dd"    -- 5: purple/magenta
term_cyan    = "#56b6c2"    -- 6: cyan
term_white   = "#abb2bf"    -- 7: foreground

-- Bright colors (8-15)
term_br_black   = "#5c6370"    -- 8: grey
term_br_red     = "#e06c75"    -- 9: bright red
term_br_green   = "#98c379"    -- 10: bright green
term_br_yellow  = "#e5c07b"    -- 11: bright yellow  
term_br_blue    = "#61afef"    -- 12: bright blue
term_br_magenta = "#c678dd"    -- 13: bright magenta
term_br_cyan    = "#56b6c2"    -- 14: bright cyan
term_br_white   = "#ffffff"    -- 15: bright white
```

## OneDark Highlight Group Examples

```lua
-- Core groups
Normal       = { fg = fg, bg = bg0 }
NormalFloat  = { fg = fg, bg = bg1 }
Cursor       = { fg = bg0, bg = fg }
CursorLine   = { bg = cursor_grey }
Visual       = { bg = visual_grey }
Search       = { fg = bg0, bg = yellow }

-- Syntax highlighting (OneDark style)
Comment      = { fg = comment_grey, italic = true }
Constant     = { fg = cyan }
String       = { fg = green }
Character    = { fg = green }
Number       = { fg = orange }
Boolean      = { fg = orange }
Float        = { fg = orange }

Identifier   = { fg = red }
Function     = { fg = blue }
Statement    = { fg = purple }
Conditional  = { fg = purple }
Repeat       = { fg = purple }
Label        = { fg = purple }
Operator     = { fg = cyan }
Keyword      = { fg = red }
Exception    = { fg = purple }

PreProc      = { fg = yellow }
Include      = { fg = blue }
Define       = { fg = purple }
Macro        = { fg = purple }
PreCondit    = { fg = yellow }

Type         = { fg = yellow }
StorageClass = { fg = yellow }
Structure    = { fg = yellow }
Typedef      = { fg = yellow }

Special      = { fg = blue }
SpecialChar  = { fg = orange }
Tag          = { fg = red }
Delimiter    = { fg = fg }
SpecialComment = { fg = comment_grey }
Debug        = { fg = red }

-- UI Elements
LineNr       = { fg = gutter_grey }
CursorLineNr = { fg = fg }
SignColumn   = { bg = bg0 }
StatusLine   = { fg = fg, bg = cursor_grey }
TabLine      = { fg = comment_grey, bg = cursor_grey }
WinSeparator = { fg = special_grey }
Pmenu        = { fg = fg, bg = menu_grey }
PmenuSel     = { fg = cursor_grey, bg = blue }

-- Tree-sitter groups (OneDark mappings)
["@variable"]     = { fg = fg }
["@variable.builtin"] = { fg = yellow }
["@function"]     = { fg = blue }
["@function.builtin"] = { fg = cyan }
["@keyword"]      = { fg = purple }
["@keyword.function"] = { fg = purple }
["@string"]       = { fg = green }
["@number"]       = { fg = orange }
["@boolean"]      = { fg = orange }
["@type"]         = { fg = yellow }
["@type.builtin"] = { fg = yellow }
["@property"]     = { fg = red }
["@method"]       = { fg = blue }
["@constructor"]  = { fg = yellow }
["@tag"]          = { fg = red }
["@tag.attribute"] = { fg = orange }
["@operator"]     = { fg = cyan }
["@punctuation"]  = { fg = fg }
["@comment"]      = { fg = comment_grey, italic = true }

-- Diagnostics (OneDark style)
DiagnosticError = { fg = red }
DiagnosticWarn  = { fg = yellow }
DiagnosticInfo  = { fg = blue }
DiagnosticHint  = { fg = cyan }
```

## OneDark Theme Characteristics

1. **Background**: The signature `#282c34` dark blue-grey background
2. **Syntax Priority**: 
   - **Red** (`#e06c75`) for keywords and identifiers
   - **Blue** (`#61afef`) for functions and methods
   - **Green** (`#98c379`) for strings and comments
   - **Purple** (`#c678dd`) for control flow and types
   - **Yellow** (`#e5c07b`) for classes and built-ins
   - **Cyan** (`#56b6c2`) for operators and constants
   - **Orange** (`#d19a66`) for numbers and attributes

3. **Design Philosophy**: 
   - Balanced contrast for long coding sessions
   - Semantic color consistency across file types
   - Atom editor heritage with modern refinements
   - Tree-sitter and LSP optimized highlighting

4. **Accessibility**: 
   - WCAG AA compliant contrast ratios
   - Distinguishable colors for colorblind users
   - Consistent semantic meaning across contexts

This palette represents the authentic OneDark colorscheme as popularized by Atom
and widely adopted in Neovim, maintaining the original color relationships and
visual hierarchy that make OneDark distinctive.
