# Standard Neovim Colorscheme Palette

## Core Background Colors
```
bg0          = "#1e1e1e"    -- Main background
bg1          = "#252525"    -- Slightly lighter background (sidebars, popups)
bg2          = "#2d2d2d"    -- Even lighter (visual selection, current line)
bg3          = "#3c3c3c"    -- Lightest background (borders, inactive elements)
```

## Core Foreground Colors
```
fg0          = "#d4d4d4"    -- Main foreground text
fg1          = "#b3b3b3"    -- Secondary text (comments, less important)
fg2          = "#808080"    -- Tertiary text (line numbers, fold text)
fg3          = "#4d4d4d"    -- Quaternary text (whitespace, very dim)
```

## Semantic Colors

### Syntax Highlighting
```
red          = "#f44747"    -- Keywords, errors, delete operations
orange       = "#ff8c00"    -- Numbers, constants, warnings
yellow       = "#ffff00"    -- Strings, search highlights
green        = "#4ec9b0"    -- Comments, additions, success
cyan         = "#4fc1ff"    -- Escape characters, info
blue         = "#569cd6"    -- Functions, methods, links
purple       = "#c586c0"    -- Types, classes, special keywords
magenta      = "#d16d9e"    -- Preprocessor, special characters
```

### UI Elements
```
accent       = "#007acc"    -- Primary accent (cursor, selection)
border       = "#3c3c3c"    -- Window borders, separators
cursor       = "#ffffff"    -- Cursor color
selection    = "#264f78"    -- Visual selection background
search       = "#613214"    -- Search match background
match        = "#515c6a"    -- Matching parentheses
```

### Git Colors
```
git_add      = "#587c0c"    -- Added lines
git_change   = "#895503"    -- Modified lines  
git_delete   = "#94151b"    -- Deleted lines
git_conflict = "#bb7a61"    -- Conflict markers
```

### Diagnostic Colors
```
error        = "#f44747"    -- Error messages and highlights
warning      = "#ff8c00"    -- Warning messages and highlights
info         = "#4fc1ff"    -- Info messages and highlights
hint         = "#4ec9b0"    -- Hint messages and highlights
```

## Usage Examples

### Highlight Group Mappings
```lua
-- Normal text
Normal       = { fg = fg0, bg = bg0 }
NormalFloat  = { fg = fg0, bg = bg1 }

-- Cursor and selection
Cursor       = { fg = bg0, bg = cursor }
Visual       = { bg = selection }
CursorLine   = { bg = bg2 }

-- Syntax highlighting
Comment      = { fg = green, italic = true }
Constant     = { fg = orange }
String       = { fg = yellow }
Function     = { fg = blue }
Keyword      = { fg = red }
Type         = { fg = purple }
Operator     = { fg = cyan }

-- UI elements
LineNr       = { fg = fg2 }
StatusLine   = { fg = fg0, bg = bg3 }
TabLine      = { fg = fg1, bg = bg1 }
WinSeparator = { fg = border }

-- Diagnostics
DiagnosticError = { fg = error }
DiagnosticWarn  = { fg = warning }
DiagnosticInfo  = { fg = info }
DiagnosticHint  = { fg = hint }
```

## Color Variants by Theme Style

### Dark Theme Variants
```
-- Darker variant
bg0_dark     = "#0d1117"
fg0_dark     = "#f0f6fc"

-- High contrast variant  
bg0_hc       = "#000000"
fg0_hc       = "#ffffff"
```

### Light Theme Variants
```
-- Light theme colors
bg0_light    = "#ffffff"
bg1_light    = "#f6f8fa"
fg0_light    = "#24292f"
fg1_light    = "#656d76"
```

## Additional Semantic Colors

### Terminal Colors (0-15)
```
terminal_black   = "#000000"    -- 0, 8
terminal_red     = "#cd3131"    -- 1, 9  
terminal_green   = "#0dbc79"    -- 2, 10
terminal_yellow  = "#e5e510"    -- 3, 11
terminal_blue    = "#2472c8"    -- 4, 12
terminal_magenta = "#bc3fbc"    -- 5, 13
terminal_cyan    = "#11a8cd"    -- 6, 14
terminal_white   = "#e5e5e5"    -- 7, 15
```

### Special Purpose
```
fold_bg      = "#202d39"    -- Code folding background
indent_guide = "#3b4048"    -- Indentation guides
whitespace   = "#3c3c3c"    -- Whitespace characters
nontext      = "#3c3c3c"    -- Non-text characters
conceal      = "#808080"    -- Concealed text
spell_bad    = "#f44747"    -- Spelling errors
spell_rare   = "#ff8c00"    -- Rare words
```

## Best Practices

1. **Contrast Ratios**: Ensure minimum 4.5:1 contrast ratio for readability
2. **Consistency**: Use the same color for similar semantic meanings
3. **Accessibility**: Test with colorblind-friendly tools
4. **Variants**: Provide light/dark variants when possible
5. **Terminal Support**: Include 256-color and true-color fallbacks
6. **Documentation**: Comment color purposes and accessibility notes

## Testing Colors

Use these highlight groups to test your palette:
- `@variable`, `@function`, `@keyword`, `@string`
- `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`  
- `DiffAdd`, `DiffChange`, `DiffDelete`
- `Search`, `IncSearch`, `Visual`
- `LineNr`, `CursorLineNr`, `StatusLine`
