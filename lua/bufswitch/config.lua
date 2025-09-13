local M = {}

-- Default configuration
local default_config = {
  hide_timeout = 800,
  show_tabline = true,
  next_key = '<Right>',
  prev_key = '<Left>',
  hide_in_special = true,
  disable_in_special = true,
  passthrough_keys_in_special = false,
  special_buftypes = { "quickfix", "help", "nofile", "prompt" },
  special_filetypes = { "qf", "help", "netrw", "neo-tree" },
  special_bufname_patterns = { "^term://", "^neo%-tree " },
  exclude_buftypes = { "quickfix", "nofile", "help", "prompt", "terminal" },
  exclude_filetypes = { "qf", "netrw", "NvimTree" },
  periodic_cleanup = true,
  debug = false,
}

-- Validate configuration types
local function validate_config(config)
  local type_checks = {
    hide_timeout = "number",
    show_tabline = "boolean",
    next_key = "string",
    prev_key = "string",
    hide_in_special = "boolean",
    disable_in_special = "boolean",
    passthrough_keys_in_special = "boolean",
    special_buftypes = "table",
    special_filetypes = "table",
    special_bufname_patterns = "table",
    exclude_buftypes = "table",
    exclude_filetypes = "table",
    periodic_cleanup = "boolean",
    debug = "boolean",
  }

  for key, expected_type in pairs(type_checks) do
    if config[key] and type(config[key]) ~= expected_type then
      error(string.format("Configuration error: '%s' must be of type '%s', got '%s'", key, expected_type,
        type(config[key])))
    end
  end

  if config.hide_timeout and config.hide_timeout <= 0 then
    error("Configuration error: 'hide_timeout' must be a positive number")
  end
end

function M.create(user_config)
  if user_config and type(user_config) ~= "table" then
    error("Configuration error: user_config must be a table")
  end

  local config = vim.tbl_deep_extend('force', default_config, user_config or {})
  validate_config(config)
  return config
end

return M
