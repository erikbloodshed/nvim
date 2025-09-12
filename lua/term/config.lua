local M = {}

M.borders = {
  none = true,
  single = true,
  double = true,
  rounded = true,
  solid = true,
  shadow = true
}

M.defaults = {
  width = 0.8,
  height = 0.8,
  border = 'rounded',
  shell = nil,
  filetype = 'terminal',
  auto_delete_on_close = false,
  open_in_file_dir = false,
  open = true,
}

function M.validate_config(cfg)
  local validated = vim.deepcopy(cfg)

  if validated.width and (validated.width <= 0 or validated.width > 1) then
    vim.notify("Term: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
    validated.width = M.defaults.width
  end

  if validated.height and (validated.height <= 0 or validated.height > 1) then
    vim.notify("Term: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
    validated.height = M.defaults.height
  end

  if validated.border and not M.borders[validated.border] then
    vim.notify(string.format("Term: Invalid 'border' style '%s'. Using 'rounded'.", validated.border),
      vim.log.levels.WARN)
    validated.border = M.defaults.border
  end

  return validated
end

return M
