```lua
-- Plugin Structure for TermSwitch
-- 
-- termswitch.nvim/
-- ├── lua/
-- │   └── termswitch/
-- │       ├── init.lua          (Main entry point)
-- │       ├── terminal.lua      (Terminal class)
-- │       ├── config.lua        (Configuration handling)
-- │       ├── commands.lua      (User commands)
-- │       ├── keymaps.lua       (Default keymaps)
-- │       └── utils.lua         (Utility functions)
-- ├── plugin/
-- │   └── termswitch.lua        (Plugin initialization)
-- ├── doc/
-- │   └── termswitch.txt        (Documentation)
-- └── README.md

-- =============================================================================
-- lua/termswitch/init.lua
-- =============================================================================

local config = require('termswitch.config')
local Terminal = require('termswitch.terminal')
local commands = require('termswitch.commands')
local keymaps = require('termswitch.keymaps')

local M = {}

-- Store all terminal instances
local terminals = {}

--- Create a new terminal instance
---@param name string Unique name for the terminal
---@param terminal_config table|nil Configuration for the terminal
---@return Terminal
function M.create_terminal(name, terminal_config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end

    -- Merge with global defaults
    local merged_config = vim.tbl_extend('force', config.get_config(), terminal_config or {})
    terminals[name] = Terminal:new(name, merged_config)
    return terminals[name]
end

--- Get an existing terminal by name
---@param name string Name of the terminal
---@return Terminal|nil
function M.get_terminal(name)
    return terminals[name]
end

--- Remove a terminal instance
---@param name string Name of the terminal to remove
function M.remove_terminal(name)
    if terminals[name] then
        terminals[name]:hide()
        terminals[name] = nil
    end
end

--- List all terminal names
---@return string[]
function M.list_terminals()
    local names = {}
    for name, _ in pairs(terminals) do
        table.insert(names, name)
    end
    return names
end

--- Get all terminals
---@return table<string, Terminal>
function M.get_all_terminals()
    return terminals
end

--- Setup the plugin
---@param user_config table|nil User configuration
function M.setup(user_config)
    -- Initialize configuration
    config.setup(user_config or {})
    
    -- Create default terminals
    M.create_terminal('terminal', { shell = nil })
    M.create_terminal('python', { shell = 'python3' })
    
    -- Setup commands
    commands.setup(M)
    
    -- Setup default keymaps if enabled
    if config.get_config().default_keymaps then
        keymaps.setup(M)
    end
end

-- Expose Terminal class for advanced usage
M.Terminal = Terminal

return M

-- =============================================================================
-- lua/termswitch/terminal.lua
-- =============================================================================

local api = vim.api

---@class Terminal
---@field config table
---@field buf number|nil
---@field win number|nil
---@field name string
local Terminal = {}
Terminal.__index = Terminal

--- Creates a new Terminal instance
---@param name string Unique name for this terminal
---@param config table Configuration for the terminal
---@return Terminal
function Terminal:new(name, config)
    local obj = {
        name = name,
        config = config,
        buf = nil,
        win = nil,
    }

    -- Set default title if not provided
    if not obj.config.title then
        obj.config.title = ' ' .. name:gsub("^%l", string.upper) .. ' '
    end

    setmetatable(obj, self)
    return obj
end

--- Get float configuration for the terminal window
---@private
---@return table
function Terminal:get_float_config()
    local ui = api.nvim_list_uis()[1]
    local width = math.floor(ui.width * self.config.width)
    local height = math.floor(ui.height * self.config.height)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)

    return {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = self.config.border,
        title = self.config.title,
        title_pos = 'center',
    }
end

--- Ensures the terminal buffer exists and is valid
---@private
function Terminal:ensure_buffer()
    if self.buf == nil or not api.nvim_buf_is_valid(self.buf) then
        self.buf = api.nvim_create_buf(false, true)
        api.nvim_set_option_value('buflisted', false, { buf = self.buf })
        api.nvim_set_option_value('bufhidden', 'hide', { buf = self.buf })
        api.nvim_set_option_value('filetype', self.config.filetype, { buf = self.buf })
    end
end

--- Setup window options
---@private
function Terminal:setup_window_options()
    if self.win and api.nvim_win_is_valid(self.win) then
        local win_opts = {
            number = false,
            relativenumber = false,
            signcolumn = 'no',
            wrap = false,
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        }
        
        for opt, value in pairs(win_opts) do
            api.nvim_set_option_value(opt, value, { win = self.win })
        end
    end
end

--- Start the terminal process
---@private
function Terminal:start_process()
    if api.nvim_get_option_value('buftype', { buf = self.buf }) ~= 'terminal' then
        api.nvim_set_current_buf(self.buf)

        local term_cmd = 'terminal'
        if self.config.shell then
            term_cmd = string.format("terminal %s", vim.fn.shellescape(self.config.shell))
        end

        vim.cmd(term_cmd)
        self.buf = api.nvim_get_current_buf()
    end
end

--- Check if we're currently in this terminal window
---@return boolean
function Terminal:is_current_window()
    local current_win = api.nvim_get_current_win()
    return self.win ~= nil
        and api.nvim_win_is_valid(self.win)
        and current_win == self.win
end

--- Check if the terminal window exists and is valid
---@return boolean
function Terminal:is_window_valid()
    return self.win ~= nil and api.nvim_win_is_valid(self.win)
end

--- Open the terminal window
function Terminal:open()
    self:ensure_buffer()

    if not self:is_window_valid() then
        local float_config = self:get_float_config()
        self.win = api.nvim_open_win(self.buf, true, float_config)
        self:setup_window_options()
        self:start_process()

        -- Set up autocmd to clean up when window is closed
        local group_name = 'TermSwitch_' .. self.name .. '_Closed'
        api.nvim_create_autocmd('WinClosed', {
            group = api.nvim_create_augroup(group_name, { clear = true }),
            pattern = tostring(self.win),
            callback = function()
                self.win = nil
            end,
            once = true,
        })
    else
        api.nvim_set_current_win(self.win)
    end

    api.nvim_command('startinsert')
end

--- Hide the terminal window
function Terminal:hide()
    if self:is_window_valid() then
        api.nvim_win_close(self.win, false)
        self.win = nil
        -- Clear the autocmd since the window is now closed
        local group_name = 'TermSwitch_' .. self.name .. '_Closed'
        pcall(api.nvim_clear_autocmds, { group = group_name })
    end
end

--- Focus the terminal window if it exists
function Terminal:focus()
    if self:is_window_valid() then
        api.nvim_set_current_win(self.win)
        api.nvim_command('startinsert')
        return true
    end
    return false
end

--- Toggle the terminal window (open/hide/focus)
function Terminal:toggle()
    if self:is_current_window() then
        self:hide()
    elseif self:is_window_valid() then
        self:focus()
    else
        self:open()
    end
end

--- Send text to the terminal
---@param text string Text to send to the terminal
function Terminal:send(text)
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        if api.nvim_get_option_value('buftype', { buf = self.buf }) == 'terminal' then
            local job_id = api.nvim_buf_get_var(self.buf, 'terminal_job_id')
            if job_id then
                api.nvim_chan_send(job_id, text)
            end
        end
    end
end

--- Check if the terminal process is running
---@return boolean
function Terminal:is_running()
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        local success, job_id = pcall(api.nvim_buf_get_var, self.buf, 'terminal_job_id')
        return success and job_id and job_id > 0
    end
    return false
end

--- Get terminal buffer
---@return number|nil
function Terminal:get_buffer()
    return self.buf
end

--- Get terminal window
---@return number|nil
function Terminal:get_window()
    return self.win
end

return Terminal

-- =============================================================================
-- lua/termswitch/config.lua
-- =============================================================================

local M = {}

local default_config = {
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    shell = nil,
    title = nil,
    filetype = 'terminal',
    default_keymaps = true,
    default_terminals = {
        terminal = { shell = nil },
        python = { shell = 'python3' },
    },
}

local config = {}

--- Validate configuration values
---@param user_config table
---@return table
local function validate_config(user_config)
    local validated = vim.deepcopy(user_config)
    
    -- Validate width
    if validated.width and (validated.width <= 0 or validated.width > 1) then
        vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        validated.width = default_config.width
    end
    
    -- Validate height
    if validated.height and (validated.height <= 0 or validated.height > 1) then
        vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        validated.height = default_config.height
    end
    
    -- Validate border
    local valid_borders = { 'none', 'single', 'double', 'rounded', 'solid', 'shadow' }
    if validated.border and not vim.tbl_contains(valid_borders, validated.border) then
        vim.notify(
            string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", validated.border),
            vim.log.levels.WARN
        )
        validated.border = default_config.border
    end
    
    return validated
end

--- Setup configuration
---@param user_config table
function M.setup(user_config)
    local validated_config = validate_config(user_config)
    config = vim.tbl_extend('force', default_config, validated_config)
end

--- Get current configuration
---@return table
function M.get_config()
    return config
end

--- Get default configuration
---@return table
function M.get_default_config()
    return vim.deepcopy(default_config)
end

return M

-- =============================================================================
-- lua/termswitch/commands.lua
-- =============================================================================

local api = vim.api

local M = {}

--- Setup user commands
---@param termswitch table The main termswitch module
function M.setup(termswitch)
    -- Create commands for default terminals
    api.nvim_create_user_command('ToggleTerm', function()
        local terminal = termswitch.get_terminal('terminal')
        if terminal then
            terminal:toggle()
        end
    end, { desc = 'Toggle default terminal window' })

    api.nvim_create_user_command('TogglePython', function()
        local terminal = termswitch.get_terminal('python')
        if terminal then
            terminal:toggle()
        end
    end, { desc = 'Toggle Python interpreter' })

    -- Generic command to toggle any terminal
    api.nvim_create_user_command('ToggleTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end

        local terminal = termswitch.get_terminal(name)
        if not terminal then
            vim.notify(
                string.format("Terminal '%s' not found. Available terminals: %s", 
                    name, table.concat(termswitch.list_terminals(), ', ')),
                vim.log.levels.ERROR
            )
            return
        end

        terminal:toggle()
    end, {
        nargs = 1,
        complete = function()
            return termswitch.list_terminals()
        end,
        desc = 'Toggle any terminal by name'
    })

    -- Command to create new terminal
    api.nvim_create_user_command('CreateTerminal', function(opts)
        local args = vim.split(opts.args, ' ', { trimempty = true })
        local name = args[1]
        local shell = args[2]
        
        if not name or name == '' then
            vim.notify("Usage: :CreateTerminal <name> [shell]", vim.log.levels.ERROR)
            return
        end

        local config = shell and { shell = shell } or {}
        termswitch.create_terminal(name, config)
        vim.notify(string.format("Created terminal '%s'", name), vim.log.levels.INFO)
    end, {
        nargs = '+',
        desc = 'Create a new terminal with optional shell'
    })

    -- Command to list all terminals
    api.nvim_create_user_command('ListTerminals', function()
        local terminals = termswitch.list_terminals()
        if #terminals == 0 then
            vim.notify("No terminals created", vim.log.levels.INFO)
        else
            vim.notify("Available terminals: " .. table.concat(terminals, ', '), vim.log.levels.INFO)
        end
    end, { desc = 'List all available terminals' })

    -- Command to remove terminal
    api.nvim_create_user_command('RemoveTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :RemoveTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end

        termswitch.remove_terminal(name)
        vim.notify(string.format("Removed terminal '%s'", name), vim.log.levels.INFO)
    end, {
        nargs = 1,
        complete = function()
            return termswitch.list_terminals()
        end,
        desc = 'Remove a terminal by name'
    })
end

return M

-- =============================================================================
-- lua/termswitch/keymaps.lua
-- =============================================================================

local M = {}

--- Setup default keymaps
---@param termswitch table The main termswitch module
function M.setup(termswitch)
    -- Default terminal keymaps
    vim.keymap.set('n', '<leader>tt', function()
        local terminal = termswitch.get_terminal('terminal')
        if terminal then terminal:toggle() end
    end, { noremap = true, silent = true, desc = 'Toggle Terminal (Normal mode)' })
    
    vim.keymap.set('t', '<leader>tt', function()
        vim.cmd('stopinsert')
        local terminal = termswitch.get_terminal('terminal')
        if terminal then terminal:toggle() end
    end, { noremap = true, silent = true, desc = 'Toggle Terminal (Terminal mode)' })

    -- Python terminal keymaps
    vim.keymap.set('n', '<leader>tp', function()
        local terminal = termswitch.get_terminal('python')
        if terminal then terminal:toggle() end
    end, { noremap = true, silent = true, desc = 'Toggle Python interpreter (Normal mode)' })
    
    vim.keymap.set('t', '<leader>tp', function()
        vim.cmd('stopinsert')
        local terminal = termswitch.get_terminal('python')
        if terminal then terminal:toggle() end
    end, { noremap = true, silent = true, desc = 'Toggle Python interpreter (Terminal mode)' })

    -- Generic terminal escape
    vim.keymap.set('t', '<C-\\><C-n>', '<C-\\><C-n>', 
        { noremap = true, silent = true, desc = 'Exit terminal mode' })
end

return M

-- =============================================================================
-- lua/termswitch/utils.lua
-- =============================================================================

local M = {}

--- Check if a command exists in the system
---@param cmd string Command to check
---@return boolean
function M.command_exists(cmd)
    return vim.fn.executable(cmd) == 1
end

--- Get available shells
---@return string[]
function M.get_available_shells()
    local shells = {}
    local common_shells = { 'bash', 'zsh', 'fish', 'sh', 'python3', 'python', 'node', 'ipython' }
    
    for _, shell in ipairs(common_shells) do
        if M.command_exists(shell) then
            table.insert(shells, shell)
        end
    end
    
    return shells
end

--- Sanitize terminal name
---@param name string
---@return string
function M.sanitize_name(name)
    return name:gsub('[^%w_-]', '_')
end

--- Get terminal info
---@param terminal Terminal
---@return table
function M.get_terminal_info(terminal)
    return {
        name = terminal.name,
        is_running = terminal:is_running(),
        is_window_valid = terminal:is_window_valid(),
        is_current = terminal:is_current_window(),
        buffer = terminal:get_buffer(),
        window = terminal:get_window(),
    }
end

return M

-- =============================================================================
-- plugin/termswitch.lua
-- =============================================================================

-- Prevent loading the plugin twice
if vim.g.loaded_termswitch then
    return
end
vim.g.loaded_termswitch = 1
```

-- Plugin initialization will be handled by user calling require('termswitch').setup()
-- This file serves as the entry point for lazy loading

-- =============================================================================
-- doc/termswitch.txt
-- =============================================================================

--[[
*termswitch.txt*                                    Terminal switcher for Neovim

Author: Your Name
License: MIT

CONTENTS                                                    *termswitch-contents*

1. Introduction                    |termswitch-introduction|
2. Setup                          |termswitch-setup|
3. Configuration                  |termswitch-configuration|
4. Commands                       |termswitch-commands|
5. API                           |termswitch-api|
6. Examples                      |termswitch-examples|

==============================================================================
1. INTRODUCTION                                        *termswitch-introduction*

TermSwitch is a Neovim plugin that provides floating terminal windows with
easy switching between multiple named terminal instances.

Features:
- Multiple named terminal instances
- Floating window terminals
- Configurable size and appearance
- Default keymaps for quick access
- Support for different shells per terminal
- Easy terminal management commands

==============================================================================
2. SETUP                                                    *termswitch-setup*

Add the plugin to your plugin manager and call setup:

Using lazy.nvim: >
    {
        "your-username/termswitch.nvim",
        config = function()
            require("termswitch").setup()
        end
    }
<

Using packer.nvim: >
    use {
        "your-username/termswitch.nvim",
        config = function()
            require("termswitch").setup()
        end
    }
<

==============================================================================
3. CONFIGURATION                                    *termswitch-configuration*

Default configuration: >
    require("termswitch").setup({
        width = 0.8,              -- Terminal width as fraction of screen
        height = 0.8,             -- Terminal height as fraction of screen
        border = "rounded",       -- Border style
        shell = nil,              -- Default shell (nil uses system default)
        title = nil,              -- Default title (nil uses terminal name)
        filetype = "terminal",    -- Buffer filetype
        default_keymaps = true,   -- Enable default keymaps
        default_terminals = {     -- Default terminals to create
            terminal = { shell = nil },
            python = { shell = "python3" },
        },
    })
<

Border options: "none", "single", "double", "rounded", "solid", "shadow"

==============================================================================
4. COMMANDS                                              *termswitch-commands*

:ToggleTerm                     Toggle the default terminal
:TogglePython                   Toggle the Python terminal
:ToggleTerminal {name}          Toggle any terminal by name
:CreateTerminal {name} [shell]  Create a new terminal
:ListTerminals                  List all available terminals
:RemoveTerminal {name}          Remove a terminal

==============================================================================
5. API                                                        *termswitch-api*

require("termswitch").create_terminal({name}, {config})    *termswitch.create_terminal()*
    Create a new terminal instance.
    
    Parameters: ~
        {name}    (string) Unique name for the terminal
        {config}  (table) Configuration for the terminal
    
    Example: >
        local termswitch = require("termswitch")
        termswitch.create_terminal("node", { shell = "node" })
<

require("termswitch").get_terminal({name})                 *termswitch.get_terminal()*
    Get an existing terminal by name.
    
    Parameters: ~
        {name} (string) Name of the terminal
    
    Returns: ~
        Terminal instance or nil

require("termswitch").remove_terminal({name})              *termswitch.remove_terminal()*
    Remove a terminal instance.
    
    Parameters: ~
        {name} (string) Name of the terminal to remove

require("termswitch").list_terminals()                     *termswitch.list_terminals()*
    List all terminal names.
    
    Returns: ~
        (table) Array of terminal names

Terminal methods:                                          *termswitch-terminal-methods*

terminal:toggle()               Toggle the terminal (open/hide/focus)
terminal:open()                 Open the terminal
terminal:hide()                 Hide the terminal
terminal:focus()                Focus the terminal
terminal:send({text})           Send text to the terminal
terminal:is_running()           Check if terminal process is running
terminal:is_window_valid()      Check if terminal window is valid
terminal:is_current_window()    Check if currently in this terminal

==============================================================================
6. EXAMPLES                                              *termswitch-examples*

Basic usage: >
    require("termswitch").setup()
    
    -- Use default keymaps
    -- <leader>tt for terminal
    -- <leader>tp for python
<

Custom configuration: >
    require("termswitch").setup({
        width = 0.9,
        height = 0.7,
        border = "double",
        default_keymaps = false,  -- Disable default keymaps
    })
<

Creating custom terminals: >
    local termswitch = require("termswitch")
    
    -- Create terminals
    termswitch.create_terminal("node", { shell = "node" })
    termswitch.create_terminal("mysql", { shell = "mysql -u root -p" })
    
    -- Set custom keymaps
    vim.keymap.set("n", "<leader>tn", function()
        termswitch.get_terminal("node"):toggle()
    end)
<

Advanced terminal usage: >
    local terminal = require("termswitch").get_terminal("python")
    
    -- Send code to Python terminal
    terminal:send("print('Hello, World!')\n")
    
    -- Check if terminal is running
    if terminal:is_running() then
        terminal:send("import numpy as np\n")
    end
<

vim:tw=78:ts=8:ft=help:norl:
]]--

-- =============================================================================
-- README.md
-- =============================================================================

--[[
# TermSwitch.nvim

A powerful terminal switcher plugin for Neovim that provides floating terminal windows with easy switching between multiple named terminal instances.

## ✨ Features

- 🪟 **Floating Terminal Windows** - Beautiful floating terminals with customizable borders
- 🔄 **Multiple Terminal Instances** - Create and manage multiple named terminals
- 🐍 **Shell Support** - Use different shells for different terminals
- ⌨️ **Easy Keymaps** - Default keymaps for quick access (customizable)
- 🎨 **Highly Configurable** - Customize size, appearance, and behavior
- 📋 **Rich API** - Programmatic control over terminals

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "your-username/termswitch.nvim",
    config = function()
        require("termswitch").setup()
    end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "your-username/termswitch.nvim",
    config = function()
        require("termswitch").setup()
    end
}
```

## 🚀 Quick Start

```lua
-- Basic setup with defaults
require("termswitch").setup()

-- Now you can use:
-- <leader>tt to toggle the default terminal
-- <leader>tp to toggle Python interpreter
```

## ⚙️ Configuration

```lua
require("termswitch").setup({
    width = 0.8,              -- Terminal width as fraction of screen
    height = 0.8,             -- Terminal height as fraction of screen
    border = "rounded",       -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    shell = nil,              -- Default shell (nil uses system default)
    title = nil,              -- Default title (nil uses terminal name)
    filetype = "terminal",    -- Buffer filetype
    default_keymaps = true,   -- Enable default keymaps
    default_terminals = {     -- Default terminals to create
        terminal = { shell = nil },
        python = { shell = "python3" },
    },
})
```

## 🎯 Usage

### Default Keymaps

| Mode | Keymap | Action |
|------|--------|--------|
| Normal | `<leader>tt` | Toggle default terminal |
| Terminal | `<leader>tt` | Toggle default terminal |
| Normal | `<leader>tp` | Toggle Python interpreter |
| Terminal | `<leader>tp` | Toggle Python interpreter |

### Commands

| Command | Description |
|---------|-------------|
| `:ToggleTerm` | Toggle the default terminal |
| `:TogglePython` | Toggle the Python terminal |
| `:ToggleTerminal <name>` | Toggle any terminal by name |
| `:CreateTerminal <name> [shell]` | Create a new terminal |
| `:ListTerminals` | List all available terminals |
| `:RemoveTerminal <name>` | Remove a terminal |

## 🔧 API Reference

### Creating Terminals

```lua
local termswitch = require("termswitch")

-- Create a Node.js terminal
termswitch.create_terminal("node", { shell = "node" })

-- Create a MySQL terminal
termswitch.create_terminal("mysql", { 
    shell = "mysql -u root -p",
    title = " Database " 
})

-- Create a custom sized terminal
termswitch.create_terminal("small", {
    width = 0.5,
    height = 0.3,
    border = "single"
})
```

### Managing Terminals

```lua
-- Get a terminal instance
local terminal = termswitch.get_terminal("python")

-- Control the terminal
terminal:toggle()  -- Toggle visibility
terminal:open()    -- Open terminal
terminal:hide()    -- Hide terminal
terminal:focus()   -- Focus terminal

-- Send commands
terminal:send("print('Hello, World!')\n")
terminal:send("import pandas as pd\n")

-- Check status
if terminal:is_running() then
    print("Terminal is active")
end

-- List all terminals
local names = termswitch.list_terminals()
print("Available terminals:", table.concat(names, ", "))
```

## 📚 Examples

### Custom Setup with Multiple Terminals

```lua
require("termswitch").setup({
    width = 0.9,
    height = 0.7,
    border = "double",
    default_keymaps = false,  -- We'll set our own
})

local termswitch = require("termswitch")

-- Create specialized terminals
termswitch.create_terminal("dev", { shell = "zsh" })
termswitch.create_terminal("test", { shell = "bash" })
termswitch.create_terminal("db", { shell = "psql -d mydb" })

-- Custom keymaps
local function map(mode, key, action, desc)
    vim.keymap.set(mode, key, action, { desc = desc, silent = true })
end

map("n", "<leader>td", function() termswitch.get_terminal("dev"):toggle() end, "Toggle Dev Terminal")
map("n", "<leader>tt", function() termswitch.get_terminal("test"):toggle() end, "Toggle Test Terminal")
map("n", "<leader>tb", function() termswitch.get_terminal("db"):toggle() end, "Toggle DB Terminal")
```

### Interactive Python Development

```lua
local termswitch = require("termswitch")

-- Create Python terminal with IPython
termswitch.create_terminal("ipython", { 
    shell = "ipython",
    title = " IPython " 
})

-- Function to send current line to Python
local function send_line_to_python()
    local line = vim.api.nvim_get_current_line()
    local terminal = termswitch.get_terminal("ipython")
    if terminal then
        terminal:send(line .. "\n")
    end
end

-- Function to send visual selection to Python
local function send_selection_to_python()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
    
    local terminal = termswitch.get_terminal("ipython")
    if terminal then
        for _, line in ipairs(lines) do
            terminal:send(line .. "\n")
        end
    end
end

vim.keymap.set("n", "<leader>sl", send_line_to_python, { desc = "Send line to Python" })
vim.keymap.set("v", "<leader>s", send_selection_to_python, { desc = "Send selection to Python" })
```

### Project-Specific Terminals

```lua
-- Create terminals based on project type
local function setup_project_terminals()
    local cwd = vim.fn.getcwd()
    local project_name = vim.fn.fnamemodify(cwd, ":t")
    
    if vim.fn.filereadable("package.json") == 1 then
        -- Node.js project
        termswitch.create_terminal("npm", { shell = "npm run dev" })
        termswitch.create_terminal("node", { shell = "node" })
    elseif vim.fn.filereadable("requirements.txt") == 1 then
        -- Python project
        termswitch.create_terminal("python", { shell = "python" })
        termswitch.create_terminal("pytest", { shell = "pytest --watch" })
    elseif vim.fn.filereadable("Cargo.toml") == 1 then
        -- Rust project
        termswitch.create_terminal("cargo", { shell = "cargo run" })
        termswitch.create_terminal("test", { shell = "cargo test" })
    end
end

-- Auto-setup on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
    callback = setup_project_terminals
})
```

## 🎨 Customization

### Custom Border Styles

```lua
-- Using different border styles for different terminals
termswitch.create_terminal("main", { border = "rounded" })
termswitch.create_terminal("debug", { border = "double" })
termswitch.create_terminal("logs", { border = "single" })
```

### Dynamic Terminal Sizing

```lua
-- Create terminals with different sizes
termswitch.create_terminal("fullscreen", { width = 0.95, height = 0.95 })
termswitch.create_terminal("sidebar", { width = 0.3, height = 0.8 })
termswitch.create_terminal("bottom", { width = 0.8, height = 0.3 })
```

### Custom Terminal Titles

```lua
termswitch.create_terminal("api", { 
    shell = "curl -s https://api.example.com",
    title = " 🌐 API Terminal " 
})

termswitch.create_terminal("logs", { 
    shell = "tail -f /var/log/app.log",
    title = " 📋 Application Logs " 
})
```

## 🔍 Advanced Features

### Terminal State Management

```lua
-- Check terminal status and manage accordingly
local function manage_terminals()
    local terminals = termswitch.get_all_terminals()
    
    for name, terminal in pairs(terminals) do
        if not terminal:is_running() then
            print("Terminal " .. name .. " is not running")
            -- Optionally restart or remove inactive terminals
        end
    end
end

-- Run every 30 seconds
vim.fn.timer_start(30000, manage_terminals, { ["repeat"] = -1 })
```

### Integration with Other Plugins

```lua
-- Integration with nvim-tree
local function toggle_terminal_in_tree_dir()
    local tree_api = require("nvim-tree.api")
    local node = tree_api.tree.get_node_under_cursor()
    
    if node and node.type == "directory" then
        -- Create terminal in the selected directory
        local term_name = "tree_" .. vim.fn.fnamemodify(node.absolute_path, ":t")
        termswitch.create_terminal(term_name, {
            shell = "cd " .. node.absolute_path .. " && $SHELL"
        })
        termswitch.get_terminal(term_name):toggle()
    end
end
```

## 🛠️ Troubleshooting

### Common Issues

1. **Terminal not starting**: Check if the specified shell exists and is executable
2. **Keymaps not working**: Ensure `default_keymaps = true` or set custom keymaps
3. **Window not appearing**: Check terminal dimensions and border settings

### Debug Information

```lua
-- Get debug info for a terminal
local terminal = termswitch.get_terminal("python")
local utils = require("termswitch.utils")
local info = utils.get_terminal_info(terminal)
print(vim.inspect(info))
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Inspired by toggleterm.nvim and other terminal plugins
- Built with ❤️ for the Neovim community

---

**Happy terminal switching! 🚀**
]]--

-- =============================================================================
-- Additional Plugin Files
-- =============================================================================

-- stylua.toml (for code formatting)
--[[
indent_type = "Spaces"
indent_width = 4
column_width = 100
line_endings = "Unix"
quote_style = "AutoPreferSingle"
call_parentheses = "Always"
collapse_simple_statement = "Never"
]]--

-- .github/workflows/ci.yml (for CI/CD)
--[[
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        neovim_version: ['v0.8.0', 'v0.9.0', 'nightly']

    steps:
    - uses: actions/checkout@v3
    
    - name: Install Neovim
      uses: rhysd/action-setup-vim@v1
      with:
        neovim: true
        version: ${{ matrix.neovim_version }}
    
    - name: Run tests
      run: |
        nvim --version
        nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Lint with luacheck
      uses: lunarmodules/luacheck@v1
      with:
        args: lua/
    
    - name: Check formatting with stylua
      uses: JohnnyMorganz/stylua-action@v3
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        version: latest
        args: --check lua/
]]--

-- tests/minimal_init.lua (for testing)
--[[
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/plenary.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', 'https://github.com/nvim-lua/plenary.nvim', install_path})
end

vim.opt.rtp:prepend(install_path)
vim.opt.rtp:prepend('.')

require('plenary.busted')
]]--

-- tests/termswitch_spec.lua (basic tests)
--[[
local termswitch = require('termswitch')

describe('TermSwitch', function()
    before_each(function()
        -- Reset state before each test
        for _, name in ipairs(termswitch.list_terminals()) do
            termswitch.remove_terminal(name)
        end
    end)

    it('can create a terminal', function()
        local terminal = termswitch.create_terminal('test', {})
        assert.is_not_nil(terminal)
        assert.equals('test', terminal.name)
    end)

    it('can list terminals', function()
        termswitch.create_terminal('test1', {})
        termswitch.create_terminal('test2', {})
        
        local terminals = termswitch.list_terminals()
        assert.equals(2, #terminals)
        assert.is_true(vim.tbl_contains(terminals, 'test1'))
        assert.is_true(vim.tbl_contains(terminals, 'test2'))
    end)

    it('can get terminal by name', function()
        local created = termswitch.create_terminal('test', {})
        local retrieved = termswitch.get_terminal('test')
        
        assert.equals(created, retrieved)
    end)

    it('can remove terminal', function()
        termswitch.create_terminal('test', {})
        assert.is_not_nil(termswitch.get_terminal('test'))
        
        termswitch.remove_terminal('test')
        assert.is_nil(termswitch.get_terminal('test'))
    end)
end)
]]--

-- Makefile (for development)
--[[
.PHONY: test lint format install

test:
	nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

lint:
	luacheck lua/

format:
	stylua lua/

install:
	@echo "Installing development dependencies..."
	@echo "Make sure you have luacheck and stylua installed"

clean:
	rm -rf tests/data

help:
	@echo "Available targets:"
	@echo "  test    - Run tests"
	@echo "  lint    - Run linter"
	@echo "  format  - Format code"
	@echo "  install - Install dev dependencies"
	@echo "  clean   - Clean test data"
]]--
