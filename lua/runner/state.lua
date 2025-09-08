local api, fn = vim.api, vim.fn
local utils = require("runner.utils")

local M = {}

local State = {}
State.__index = State

function State:init(config)
  local lang_type = config.type

  self = setmetatable({
    src_file = api.nvim_buf_get_name(0),
    type = lang_type,
    compiler = config.compiler,
    compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags,
    data_path = utils.get_data_path(config.data_dir_name),
    hash_tbl = {},
    buffer_cache = {},
    command_cache = {},
  }, State)

  if lang_type ~= "interpreted" then
    self.src_basename = fn.fnamemodify(self.src_file, ":t:r")
    self.output_directory = config.output_directory or ""
    self.exe_file = vim.fn.join({ self.output_directory, self.src_basename }, "/")
  end

  if lang_type == "assembled" then
    self.linker = config.linker
    self.linker_flags = config.linker_flags or {}
    self.obj_file = self.exe_file .. ".o"
  end

  if lang_type == "compiled" then
    self.asm_file = self.exe_file .. ".s"
  end

  return self
end

function State:invalidate_cmd_cache()
  self.command_cache.run_cmd = nil
  self.buffer_cache.hash = nil
  self.hash_tbl = {}

  local lang_type = self.type
  if lang_type == "interpreted" then return end

  self.command_cache.compile_cmd = nil
  self.command_cache.link_cmd = nil

  if lang_type == "compiled" then
    self.command_cache.show_assembly_cmd = nil
  end
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

  self.buffer_cache.hash = fn.sha256(table.concat(api.nvim_buf_get_lines(0, 0, -1, true), "\n"))
  self.buffer_cache.changedtick = changedtick

  return self.buffer_cache.hash
end

M.init = function(config)
  return State:init(config)
end

return M
