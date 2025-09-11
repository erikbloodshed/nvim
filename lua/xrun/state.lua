local api, fn = vim.api, vim.fn
local utils = require("xrun.utils")

local M = {}

local State = {}
State.__index = State

function State:init(config)
  local lang_type = config.type

  local obj = setmetatable({
    src_file = api.nvim_buf_get_name(0),
    type = lang_type,
    compiler = config.compiler,
    compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags,
    data_path = utils.get_data_path(config.data_dir_name),
    hash_tbl = {},
    buffer_cache = { dep_mtimes = {} },
    command_cache = {},
    dependencies = {}
  }, State)

  obj.default_cflags = vim.deepcopy(obj.compiler_flags)

  if lang_type ~= "interpreted" then
    obj.basename = fn.fnamemodify(obj.src_file, ":t:r")
    obj.outdir = config.output_directory or ""
    obj.exe = vim.fs.joinpath(obj.outdir, obj.basename)
  end

  if lang_type == "assembled" then
    obj.linker = config.linker
    obj.linker_flags = config.linker_flags or {}
    obj.obj_file = obj.exe .. ".o"
  end

  if lang_type == "compiled" then
    obj.asm_file = obj.exe .. ".s"
    obj.dep_file = obj.exe .. ".d"
  end

  return obj
end

function State:invalidate_run_cache()
  self.command_cache.run_cmd = nil
end

function State:invalidate_build_cache()
  self:invalidate_run_cache()
  self.hash_tbl = {}
  self.buffer_cache.hash = nil
  self.command_cache.compile_cmd = nil
  if self.type == "compiled" then
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
  local dep_changed = false

  if self.type == "compiled" then
    for _, dep in ipairs(self.dependencies) do
      local current_mtime = utils.get_date_modified(dep)
      if current_mtime ~= self.buffer_cache.dep_mtimes[dep] then
        dep_changed = true
        self.buffer_cache.dep_mtimes[dep] = current_mtime
      end
    end
  end

  if dep_changed or not self.buffer_cache.hash or self.buffer_cache.changedtick ~= changedtick then
    local content = api.nvim_buf_get_lines(0, 0, -1, true)
    local hash_input = table.concat(content, "\n")
    if self.type == "compiled" then
      for _, dep in ipairs(self.dependencies) do
        local dep_content = utils.read_file(dep)
        if dep_content then
          hash_input = hash_input .. table.concat(dep_content, "\n")
        end
      end
    end

    self.buffer_cache.hash = fn.sha256(hash_input)
    self.buffer_cache.changedtick = changedtick
  end

  return self.buffer_cache.hash
end

function State:set_compiler_flags(flags_str)
  self.compiler_flags = flags_str ~= "" and vim.split(flags_str, "%s+", { trimempty = true })
    or self.default_cflags
  self:invalidate_build_cache()
end

function State:set_cmd_args(args)
  self.cmd_args = args ~= "" and args or nil
  self:invalidate_run_cache()
end

function State:set_data_file(filepath)
  self.data_file = filepath
  self:invalidate_run_cache()
end

function State:update_dependencies()
  if self.type == "compiled" then
    local new_deps = utils.parse_dependency_file(self.dep_file)

    if not vim.deep_equal(self.dependencies, new_deps) then
      self.dependencies = new_deps
      self.buffer_cache.dep_mtimes = {}

      for _, dep in ipairs(self.dependencies) do
        self.buffer_cache.dep_mtimes[dep] = utils.get_date_modified(dep)
      end

      self.buffer_cache.hash = nil

      vim.notify("Dependencies updated from build output.", vim.log.levels.INFO)
    end
  end
end

M.init = function(config)
  return State:init(config)
end

return M
