local api = vim.api
local blend_bg = require("themes.util").blend_bg
local blend_fg = require("themes.util").blend_fg
local M = {}

M.get = function(c)
  local s = {
    ["@lsp.type.boolean"]                      = { link = "Boolean" },
    ["@lsp.type.builtinType"]                  = { link = "@type.builtin" },
    ["@lsp.type.comment"]                      = { link = "Comment" },
    ["@lsp.type.decorator"]                    = { link = "@attribute" },
    ["@lsp.type.deriveHelper"]                 = { link = "@attribute" },
    ["@lsp.type.enum"]                         = { link = "@type" },
    ["@lsp.type.enumMember"]                   = { link = "Constant" },
    ["@lsp.type.escapeSequence"]               = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"]              = { link = "@markup.list" },
    ["@lsp.type.generic"]                      = { link = "@variable" },
    ["@lsp.type.interface"]                    = { fg = blend_fg(c.blue1, 0.7, c.fg) },
    ["@lsp.type.keyword"]                      = { link = "@keyword" },
    ["@lsp.type.lifetime"]                     = { link = "@keyword.storage" },
    ["@lsp.type.namespace"]                    = { link = "@module" },
    ["@lsp.type.namespace.python"]             = { link = "@variable" },
    ["@lsp.type.number"]                       = { link = "Constant" },
    ["@lsp.type.operator"]                     = { link = "@operator" },
    ["@lsp.type.parameter"]                    = { link = "@variable.parameter" },
    ["@lsp.type.property"]                     = { link = "@property" },
    ["@lsp.type.selfKeyword"]                  = { link = "@variable.builtin" },
    ["@lsp.type.selfTypeKeyword"]              = { link = "@variable.builtin" },
    ["@lsp.type.string"]                       = { link = "String" },
    ["@lsp.type.typeAlias"]                    = { link = "@type.definition" },
    ["@lsp.type.unresolvedReference"]          = { undercurl = true, sp = c.error },
    ["@lsp.type.variable"]                     = {},
    ["@lsp.typemod.class.defaultLibrary"]      = { link = "@type.builtin" },
    ["@lsp.typemod.enum.defaultLibrary"]       = { link = "@type.builtin" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.function.defaultLibrary"]   = { link = "Special" },
    ["@lsp.typemod.keyword.async"]             = { link = "@keyword.coroutine" },
    ["@lsp.typemod.keyword.injected"]          = { link = "@keyword" },
    ["@lsp.typemod.macro.defaultLibrary"]      = { link = "Special" },
    ["@lsp.typemod.method.defaultLibrary"]     = { link = "Special" },
    ["@lsp.typemod.operator.injected"]         = { link = "Operator" },
    ["@lsp.typemod.string.injected"]           = { link = "String" },
    ["@lsp.typemod.struct.defaultLibrary"]     = { link = "@type.builtin" },
    ["@lsp.typemod.type.defaultLibrary"]       = { fg = blend_bg(c.blue1, 0.8, c.bg) },
    ["@lsp.typemod.typeAlias.defaultLibrary"]  = { link = "@lsp.typemod.typeAlias.defaultLibrary" },
    ["@lsp.typemod.variable.callable"]         = { link = "Function" },
    ["@lsp.typemod.variable.defaultLibrary"]   = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"]         = { link = "@variable" },
    ["@lsp.typemod.variable.static"]           = { link = "Constant" },

  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for key, val in pairs(s) do hl(0, key, val) end
end

return M
