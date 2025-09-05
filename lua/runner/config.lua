local M = {}

local defaults = {
  keymaps = {
    { key = "<leader>rr", action = "run", mode = "n", desc = "Runner: Run File" },
    { key = "<leader>rc", action = "compile", mode = "n", desc = "Runner: Compile File" },
    { key = "<leader>ra", action = "set_cmd_args", mode = "n", desc = "Runner: Set Arguments" },
    { key = "<leader>rf", action = "set_compiler_flags", mode = "n", desc = "Runner: Set Compiler Flags" },
    { key = "<leader>ri", action = "get_build_info", mode = "n", desc = "Runner: Show Build Info" },
    { key = "<leader>rd", action = "add_data_file", mode = "n", desc = "Runner: Add Data File" },
    { key = "<leader>rx", action = "remove_data_file", mode = "n", desc = "Runner: Remove Data File" },
    { key = "<leader>rs", action = "show_assembly", mode = "n", desc = "Runner: Show Assembly" },
    { key = "<leader>rq", action = "open_quickfix", mode = "n", desc = "Runner: Open Quickfix" },
  },

  filetype = {
    c = {
      type = "compiled",
      compiler = "gcc",
      fallback_flags = { "-std=c23", "-O2" },
      response_file = nil,
      data_dir_name = "dat",
      output_directory = "/tmp/",
    },

    cpp = {
      type = "compiled",
      compiler = "g++",
      fallback_flags = { "-std=c++20", "-O2" },
      response_file = nil,
      data_dir_name = "dat",
      output_directory = "/tmp/",
    },

    asm = {
      type = "assembled",
      compiler = "nasm",
      fallback_flags = { "-f", "elf64" },
      response_file = nil,
      linker = "ld",
      linker_flags = { "-m", "elf_x86_64" },
      data_dir_name = "dat",
      output_directory = "/tmp/",
    },

    python = {
      type = "interpreted",
      compiler = "python3",
      fallback_flags = {},
      response_file = nil,
      data_dir_name = "dat",
    },

    lua = {
      type = "interpreted",
      compiler = "lua",
      fallback_flags = {},
      response_file = nil,
      data_dir_name = "dat",
    },
  }
}

local function create_restricted_table(allowed_keys, initial_values)
  local restricted = initial_values or {}
  local allowed_set = {}

  -- Create a set for O(1) lookup
  for _, key in ipairs(allowed_keys) do
    allowed_set[key] = true
  end

  local mt = {
    __index = function(t, key)
      if not allowed_set[key] then
        error("Invalid key: " .. tostring(key) .. ". Allowed keys: " .. table.concat(allowed_keys, ", "))
      end
      return rawget(t, key)
    end,

    __newindex = function(t, key, value)
      if not allowed_set[key] then
        error("Invalid key: " .. tostring(key) .. ". Allowed keys: " .. table.concat(allowed_keys, ", "))
      end
      rawset(t, key, value)
    end
  }

  return setmetatable(restricted, mt)
end

local function validate_keymap(keymap)
  local allowed_keymap_keys = { "key", "action", "mode", "desc" }
  return create_restricted_table(allowed_keymap_keys, keymap)
end

local function validate_filetype_config(config)
  local allowed_filetype_keys = {
    "type", "compiler", "fallback_flags", "response_file",
    "data_dir_name", "output_directory", "linker", "linker_flags"
  }
  local restricted_config = create_restricted_table(allowed_filetype_keys, config)

  if restricted_config.type then
    local allowed_types = { "compiled", "assembled", "interpreted" }
    local valid_type = false
    for _, allowed_type in ipairs(allowed_types) do
      if restricted_config.type == allowed_type then
        valid_type = true
        break
      end
    end
    if not valid_type then
      error("Invalid type value: " ..
        tostring(restricted_config.type) .. ". Allowed values: " .. table.concat(allowed_types, ", "))
    end
  end

  return restricted_config
end

M.init = function(user_config)
  if user_config then
    local allowed_top_level_keys = { "keymaps", "filetype" }
    user_config = create_restricted_table(allowed_top_level_keys, user_config)

    if user_config.keymaps then
      for i, keymap in ipairs(user_config.keymaps) do
        user_config.keymaps[i] = validate_keymap(keymap)
      end
    end

    if user_config.filetype then
      for ft, config in pairs(user_config.filetype) do
        user_config.filetype[ft] = validate_filetype_config(config)
      end
    end
  end

  local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

  if not defaults.filetype[ft] then
    vim.notify("No default configuration found for filetype: " .. ft, vim.log.levels.ERROR)
    return nil
  end

  local lang_config = {}
  if user_config and user_config.filetype and user_config.filetype[ft] then
    lang_config = user_config.filetype[ft]
  end

  local config = vim.tbl_deep_extend('force', defaults.filetype[ft], lang_config)

  local keymaps = defaults.keymaps
  if user_config and user_config.keymaps then
    keymaps = vim.tbl_deep_extend("force", keymaps, user_config.keymaps)
  end

  local allowed_final_config_keys = {
    "type", "compiler", "fallback_flags", "response_file",
    "data_dir_name", "output_directory", "linker", "linker_flags",
    "keymaps", "filetype"
  }
  config = create_restricted_table(allowed_final_config_keys, config)

  config.keymaps = keymaps
  config.filetype = ft

  return config
end

return M
