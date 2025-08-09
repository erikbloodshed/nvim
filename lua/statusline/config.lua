-- statusline/config.lua
local M = {}

--[[
  Default Configuration
--]]
local default_config = {
  components = {
    mode = true,
    file_info = true,
    git_branch = true,
    diagnostics = true,
    lsp_status = true,
    encoding = false,
    position = true,
    percentage = true,
  },
  separators = {
    left = '',
    right = '',
    section = ' | ',
  },
  icons = {
    modified = '',
    readonly = '',
    git = '',
    error = '',
    warn = '',
    info = '',
    hint = '',
    lsp = '',
  },
  center_filename = true,
  enable_profiling = false,
  exclude = {
    buftypes = { 'terminal', 'quickfix', 'help', 'nofile', 'prompt' },
    filetypes = {
      'NvimTree', 'neo-tree', 'aerial', 'Outline', 'packer', 'alpha', 'starter',
      'TelescopePrompt', 'TelescopeResults', 'TelescopePreview',
      'lazy', 'mason', 'lspinfo', 'null-ls-info',
      'checkhealth', 'help', 'man', 'qf', 'fugitive'
    },
    floating_windows = true,
    small_windows = { min_height = 3, min_width = 20 },
  },
  cache = {
    update_intervals = {
      mode = 50,
      file_info = 200,
      position = 100,
      percentage = 100,
      git_branch = 60000,
      diagnostics = 1000,
      lsp_status = 2000,
      encoding = 120000,
    }
  },
  throttle = {
    cursor_ms = 50,
    redraw_ms = 100,
  }
}

local config = vim.deepcopy(default_config)

--[[
  Setup configuration
--]]
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', default_config, user_config or {})
end

--[[
  Get current configuration
--]]
function M.get()
  return config
end

--[[
  Get specific configuration value
--]]
function M.get_value(key)
  return config[key]
end

--[[
  Update configuration at runtime
--]]
function M.update(new_config)
  config = vim.tbl_deep_extend('force', config, new_config)
end

return M
