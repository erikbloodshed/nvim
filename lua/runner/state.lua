local M = {}

local State = {}
State.__index = State

function State:init(config)
  local api, fn = vim.api, vim.fn
  local utils = require("runner.utils")

  self = setmetatable({
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

    api = api,
    fn = fn,
    utils = utils,

    hash_tbl = {},
    buffer_cache = {},
    command_cache = {},
  }, self)

  self.src_basename = fn.fnamemodify(self.src_file, ":t:r")
  self.exe_file = self.output_directory .. self.src_basename
  self.asm_file = self.exe_file .. ".s"
  self.obj_file = self.exe_file .. ".o"

  return self
end

function State:has_type(type_name)
  return self.type == type_name
end

function State:invalidate_cache()
  self.command_cache.run_cmd = nil

  if self:has_type("interpreted") then
    return "interpreted"
  end

  self.command_cache.compile_cmd = nil
  self.command_cache.link_cmd = nil

  if self:has_type("compiled") then
    self.command_cache.show_assembly_cmd = nil
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

function State:get_buffer_hash()
  local changedtick = vim.b.changedtick

  if self.buffer_cache.hash and self.buffer_cache.changedtick == changedtick then
    return self.buffer_cache.hash
  end

  local lines = self.api.nvim_buf_get_lines(0, 0, -1, true)
  self.buffer_cache.hash = self.fn.sha256(table.concat(lines, "\n"))
  self.buffer_cache.changedtick = changedtick

  return self.buffer_cache.hash
end

M.init = function(config)
  return State:init(config)
end

return M
