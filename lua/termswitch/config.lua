local M = {}

M.VALID_BORDERS = {
  none = true,
  single = true,
  double = true,
  rounded = true,
  solid = true,
  shadow = true
}

M.DEFAULT_CONFIG = {
  width = 0.8,
  height = 0.8,
  border = 'rounded',
  shell = nil,
  filetype = 'terminal',
  auto_delete_on_close = false,
  -- Backdrop configuration
  backdrop = {
    enabled = true,   -- Enable/disable backdrop
    opacity = 80,      -- Backdrop opacity (0-100)
    color = "#000000", -- Backdrop color
  }
}

function M.validate_config(cfg)
  local validated = vim.deepcopy(cfg)

  if validated.width and (validated.width <= 0 or validated.width > 1) then
    vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
    validated.width = M.DEFAULT_CONFIG.width
  end

  if validated.height and (validated.height <= 0 or validated.height > 1) then
    vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
    validated.height = M.DEFAULT_CONFIG.height
  end

  if validated.border and not M.VALID_BORDERS[validated.border] then
    vim.notify(string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", validated.border),
      vim.log.levels.WARN)
    validated.border = M.DEFAULT_CONFIG.border
  end

  -- Validate backdrop configuration
  if validated.backdrop then
    if validated.backdrop.opacity and
      (type(validated.backdrop.opacity) ~= 'number' or
        validated.backdrop.opacity < 0 or validated.backdrop.opacity > 100) then
      vim.notify("TermSwitch: 'backdrop.opacity' must be between 0 and 100. Using default.", vim.log.levels.WARN)
      validated.backdrop.opacity = M.DEFAULT_CONFIG.backdrop.opacity
    end

    if validated.backdrop.color and type(validated.backdrop.color) ~= 'string' then
      vim.notify("TermSwitch: 'backdrop.color' must be a string. Using default.", vim.log.levels.WARN)
      validated.backdrop.color = M.DEFAULT_CONFIG.backdrop.color
    end
  else
    -- Ensure backdrop config exists
    validated.backdrop = vim.deepcopy(M.DEFAULT_CONFIG.backdrop)
  end

  return validated
end

return M
