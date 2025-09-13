local M = {}

-- Configuration validation helpers
local function validate_config_types(config)
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
    if config[key] ~= nil and type(config[key]) ~= expected_type then
      error(string.format("Configuration error: '%s' must be of type '%s', got '%s'",
        key, expected_type, type(config[key])))
    end
  end

  -- Validate positive numbers
  if config.hide_timeout and config.hide_timeout <= 0 then
    error("Configuration error: 'hide_timeout' must be a positive number")
  end
end

local function validate_key_bindings(config)
  if config.orig_next_key and not config.passthrough_keys_in_special then
    vim.notify("Warning: 'orig_next_key' is set but 'passthrough_keys_in_special' is false",
      vim.log.levels.WARN)
  end

  if config.orig_prev_key and not config.passthrough_keys_in_special then
    vim.notify("Warning: 'orig_prev_key' is set but 'passthrough_keys_in_special' is false",
      vim.log.levels.WARN)
  end
end

function M.create(user_config)
  local default_config = {
    hide_timeout = 800,
    show_tabline = true,
    next_key = '<Right>',
    prev_key = '<Left>',
    orig_next_key = nil,
    orig_prev_key = nil,
    hide_in_special = true,
    disable_in_special = true,
    passthrough_keys_in_special = false,
    special_buftypes = {
      "quickfix", "help", "nofile", "prompt",
    },
    special_filetypes = {
      "qf", "help", "netrw", "neo-tree",
    },
    special_bufname_patterns = {
      "^term://", "^neo%-tree "
    },
    exclude_buftypes = {
      "quickfix", "nofile", "help", "prompt", "terminal"
    },
    exclude_filetypes = {
      "qf", "netrw", "NvimTree"
    },
    periodic_cleanup = true,
    debug = false,
  }

  if user_config then
    -- Validate user configuration before merging
    if type(user_config) ~= "table" then
      error("Configuration error: user_config must be a table")
    end

    local merged_config = vim.tbl_deep_extend('force', default_config, user_config)

    -- Validate the merged configuration
    validate_config_types(merged_config)
    validate_key_bindings(merged_config)

    return merged_config
  end

  return default_config
end

return M
