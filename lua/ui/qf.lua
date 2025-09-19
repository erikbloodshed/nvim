local icons = require("ui.icons")
local M = {}

local signs = {
  error = { text = icons.error, hl = 'DiagnosticSignError' },
  warn = { text = icons.warn, hl = 'DiagnosticSignWarn' },
  info = { text = icons.info, hl = 'DiagnosticSignInfo' },
  hint = { text = icons.hint, hl = 'DiagnosticSignHint' },
}

local namespace = vim.api.nvim_create_namespace('custom_qf')
local show_multiple_lines = true
local max_filename_length = 30
local filename_truncate_prefix = '...'

local function pad_right(string, pad_to)
  local new = string

  if pad_to == 0 then
    return string
  end

  for _ = vim.fn.strwidth(string), pad_to do
    new = new .. ' '
  end

  return new
end

local function trim_path(path)
  local fname = vim.fn.fnamemodify(path, ':p:.')
  local len = vim.fn.strchars(fname)

  if max_filename_length > 0 and len > max_filename_length then
    fname = filename_truncate_prefix
      .. vim.fn.strpart(fname, len - max_filename_length, max_filename_length, 1)
  end

  return fname
end

local function list_items(info)
  if info.quickfix == 1 then
    return vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1 })
  else
    return vim.fn.getloclist(info.winid, { id = info.id, items = 1, qfbufnr = 1 })
  end
end

local function apply_highlights(bufnr, highlights)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, hl in ipairs(highlights) do
    if hl == nil or type(hl) ~= 'table' or hl.line == nil or hl.col == nil or hl.end_col == nil or hl.group == nil then
      goto continue
    end

    local line_length = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, hl.line, hl.line + 1, false)

    if #lines > 0 then
      line_length = lines[1]:len()
    else
      goto continue
    end

    local end_col = hl.end_col
    if end_col < hl.col or end_col > line_length then
      goto continue
    end

    vim.api.nvim_buf_set_extmark(
      bufnr,
      namespace,
      hl.line,
      hl.col,
      {
        end_col = end_col,
        hl_group = hl.group,
        priority = 100,
      }
    )
    ::continue::
  end
end

function M.format(info)
  local list = list_items(info)
  local qf_bufnr = list.qfbufnr
  local raw_items = list.items
  local lines = {}
  local pad_to = 0

  local type_mapping = {
    E = signs.error,
    W = signs.warn,
    I = signs.info,
    N = signs.hint,
  }

  local items = {}
  local show_sign = false

  if info.start_idx == 1 then
    vim.api.nvim_buf_clear_namespace(qf_bufnr, namespace, 0, -1)
  end

  for i = info.start_idx, info.end_idx do
    local raw = raw_items[i]

    if raw then
      local item = {
        type = raw.type,
        text = raw.text,
        location = '',
        path_size = 0,
        line_col_size = 0,
        index = i,
      }

      if type_mapping[item.type] then
        show_sign = true
      end

      if raw.bufnr > 0 then
        item.location = trim_path(vim.fn.bufname(raw.bufnr))
        item.path_size = #item.location
      end

      if raw.lnum and raw.lnum > 0 then
        local lnum = raw.lnum

        if raw.end_lnum and raw.end_lnum > 0 and raw.end_lnum ~= lnum then
          lnum = lnum .. '-' .. raw.end_lnum
        end

        if #item.location > 0 then
          item.location = item.location .. ' ' .. lnum
        else
          item.location = tostring(lnum)
        end

        if raw.col and raw.col > 0 then
          local col = raw.col

          if raw.end_col and raw.end_col > 0 and raw.end_col ~= col then
            col = col .. '-' .. raw.end_col
          end

          item.location = item.location .. ':' .. col
        end

        item.line_col_size = #item.location - item.path_size
      end

      local size = vim.fn.strwidth(item.location)
      if size > pad_to then
        pad_to = size
      end

      table.insert(items, item)
    end
  end

  local highlights = {}

  for _, item in ipairs(items) do
    local line_idx = item.index - 1
    local text = vim.split(item.text, '\n')[1]
    local location = item.location

    if show_multiple_lines then
      text = vim.fn.substitute(item.text, '\n\\s*', ' ', 'g')
    end

    text = vim.fn.trim(text)

    if text ~= '' then
      location = pad_right(location, pad_to)
    end

    local sign_conf = type_mapping[item.type]
    local sign = ' '
    local sign_hl = nil

    if sign_conf then
      sign = sign_conf.text
      sign_hl = sign_conf.hl
    end

    local prefix = show_sign and sign .. ' ' or ''
    local line = prefix .. location .. text

    if line == '' then
      line = ' '
    end

    if show_sign and sign_hl then
      table.insert(
        highlights,
        { group = sign_hl, line = line_idx, col = 0, end_col = #sign }
      )

      if text ~= '' then
        local text_start = #prefix + #location
        table.insert(
          highlights,
          { group = sign_hl, line = line_idx, col = text_start, end_col = #line }
        )
      end
    end

    if item.path_size > 0 then
      table.insert(highlights, {
        group = 'Directory',
        line = line_idx,
        col = #prefix,
        end_col = #prefix + item.path_size,
      })
    end

    if item.line_col_size > 0 then
      local col_start = #prefix + item.path_size

      table.insert(highlights, {
        group = 'Number',
        line = line_idx,
        col = col_start,
        end_col = col_start + item.line_col_size,
      })
    end

    local fix_annotation_start = text:find("%([^)]*fix[^)]*%)")

    if fix_annotation_start then
      local fix_annotation_end = text:find("%)", fix_annotation_start)
      if fix_annotation_end then
        local text_start = #prefix + #location
        table.insert(highlights, {
          group = 'Comment',
          line = line_idx,
          col = text_start + fix_annotation_start - 1,
          end_col = text_start + fix_annotation_end,
        })
      end
    end

    table.insert(lines, line)
  end

  vim.schedule(function()
    apply_highlights(qf_bufnr, highlights)
  end)

  return lines
end

vim.opt.quickfixtextfunc = "v:lua.require'ui.qf'.format"

return M
