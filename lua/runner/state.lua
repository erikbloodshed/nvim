local M = {}

local State = {}
State.__index = State

function State.new(config)
  local api, fn = vim.api, vim.fn
  local utils = require("runner.utils")

  local self = setmetatable({
    src_file = api.nvim_buf_get_name(0),
    type = config.type,
    compiler = config.compiler,
    compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags,
    linker = config.linker,
    linker_flags = config.linker_flags or {},
    output_directory = config.output_directory or "",
    data_path = utils.get_data_path(config.data_dir_name),
    data_file = nil,
    cmd_args = nil,

    -- Internal dependencies
    api = api,
    fn = fn,
    utils = utils,

    -- Caching structures
    hash_tbl = {
      compile = nil,
      assemble = nil,
      link = nil,
    },

    buffer_cache = {
      hash = nil,
      changedtick = nil,
    },

    command_cache = {
      compile_cmd = nil,
      link_cmd = nil,
      show_assembly_cmd = nil,
      run_cmd = nil,
    },
  }, State)

  -- Computed properties
  self.src_basename = fn.fnamemodify(self.src_file, ":t:r")
  self.exe_file = self.output_directory .. self.src_basename
  self.asm_file = self.exe_file .. ".s"
  self.obj_file = self.exe_file .. ".o"

  return self
end

-- Type checking method
function State:has_type(type_name)
  return self.type == type_name
end

function State:clear_cache(cache_key)
  if cache_key then
    self.command_cache[cache_key] = nil
  end
end

-- Cache management methods
function State:invalidate_cache()
  self:clear_cache("run_cmd")

  if self:has_type("interpreted") then
    return "interpreted"
  end

  self:clear_cache("compile_cmd")
  self:clear_cache("link_cmd")

  if self:has_type("compiled") then
    self:clear_cache("show_assembly_cmd")
  end

  return "compiled"
end

function State:get_cached_command(key, builder)
  local val = self.command_cache[key]
  if val ~= nil then return val end
  val = builder()
  self.command_cache[key] = val
  return val
end

function State:make_cmd(tool, flags, args)
  return {
    compiler = tool,
    arg = vim.list_extend(vim.list_extend({}, flags or {}), args or {}),
  }
end

function State:get_buffer_hash()
  local changedtick = self.api.nvim_buf_get_changedtick(0)

  if self.buffer_cache.hash and self.buffer_cache.changedtick == changedtick then
    return self.buffer_cache.hash
  end

  local lines = self.api.nvim_buf_get_lines(0, 0, -1, true)
  self.buffer_cache.hash = self.fn.sha256(table.concat(lines, "\n"))
  self.buffer_cache.changedtick = changedtick

  return self.buffer_cache.hash
end

function State:get_hash(key)
  return self.hash_tbl[key]
end

function State:set_hash(key, value)
  self.hash_tbl[key] = value
end

-- Configuration methods
function State:set_compiler_flags(flags)
  self.compiler_flags = flags
  local cache_type = self:invalidate_cache()
  return cache_type
end

function State:set_cmd_args(args)
  self.cmd_args = args
  self:clear_cache("run_cmd")
end

function State:set_data_file(filepath)
  self.data_file = filepath
  self:clear_cache("run_cmd")
end

function State:remove_data_file()
  self.data_file = nil
  self:clear_cache("run_cmd")
end

-- File information methods
function State:get_src_filename()
  return self.fn.fnamemodify(self.src_file, ':t')
end

function State:get_data_filename()
  return self.data_file and self.fn.fnamemodify(self.data_file, ':t') or nil
end

function State:get_date_modified()
  return self.utils.get_date_modified(self.src_file)
end

-- Build information method
function State:get_build_info()
  local flags = table.concat(self.compiler_flags or {}, " ")
  local lines = {
    "Filename          : " .. self:get_src_filename(),
    "Filetype          : " .. vim.bo.filetype,
    "Language Type     : " .. self.type,
  }

  if self:has_type("compiled") or self:has_type("assembled") then
    lines[#lines + 1] = "Compiler          : " .. (self.compiler or "None")
    lines[#lines + 1] = "Compile Flags     : " .. (flags == "" and "None" or flags)
    lines[#lines + 1] = "Output Directory  : " .. (self.output_directory == "" and "None" or self.output_directory)
  end

  if self:has_type("assembled") then
    lines[#lines + 1] = "Linker            : " .. (self.linker or "None")
    lines[#lines + 1] = "Linker Flags      : " .. table.concat(self.linker_flags or {}, " ")
  end

  if self:has_type("interpreted") then
    lines[#lines + 1] = "Run Command       : " .. (self.compiler or "None")
  end

  vim.list_extend(lines, {
    "Data Directory    : " .. (self.data_path or "Not Found"),
    "Data File In Use  : " .. (self:get_data_filename() or "None"),
    "Command Arguments : " .. (self.cmd_args or "None"),
    "Date Modified     : " .. self:get_date_modified(),
  })

  return lines
end

-- Public interface
M.init = function(config)
  return State.new(config)
end

return M
