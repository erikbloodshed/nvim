local M = {}

-- Simple defaults - let Neovim handle validation
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
    validated.width = M.defaults.width
  end

  if validated.height and (validated.height <= 0 or validated.height > 1) then
    validated.height = M.defaults.height
  end

  return validated
end

return M
