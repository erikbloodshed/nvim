-- LSP semantic token highlights for Ayu Mirage theme
local M = {}

function M.get_highlights(p)
  return {
    -- Basic semantic tokens
    ["@lsp.type.boolean"] = { link = "@boolean" },
    ["@lsp.type.builtinType"] = { link = "@type.builtin" },
    ["@lsp.type.comment"] = { link = "@comment" },
    ["@lsp.type.enum"] = { link = "@type" },
    ["@lsp.type.enumMember"] = { link = "@constant" },
    ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"] = { link = "@punctuation.special" },
    ["@lsp.type.interface"] = { link = "@type" },
    ["@lsp.type.keyword"] = { link = "@keyword" },
    ["@lsp.type.namespace"] = { link = "@namespace" },
    ["@lsp.type.number"] = { link = "@number" },
    ["@lsp.type.operator"] = { link = "@operator" },
    ["@lsp.type.parameter"] = { link = "@parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.string"] = { link = "@string" },
    ["@lsp.type.typeAlias"] = { link = "@type.definition" },
    ["@lsp.type.variable"] = { link = "@variable" },

    -- Language-specific tokens
    ["@lsp.type.decorator"] = { fg = p.syntax.special },
    ["@lsp.type.deriveHelper"] = { link = "@attribute" },
    ["@lsp.type.generic"] = { fg = p.syntax.operator },
    ["@lsp.type.lifetime"] = { fg = p.syntax.operator },
    ["@lsp.type.macro"] = {},
    ["@lsp.type.selfKeyword"] = { fg = p.syntax.keyword },
    ["@lsp.type.selfTypeKeyword"] = { fg = p.syntax.keyword },
    ["@lsp.type.selfTypeParameter"] = { fg = p.syntax.keyword },
    ["@lsp.type.unresolvedReference"] = { fg = p.common.error, undercurl = true },

    -- Type modifiers (empty tables indicate using default highlighting)
    ["@lsp.typemod.class.defaultLibrary"] = {},
    ["@lsp.typemod.enum.defaultLibrary"] = {},
    ["@lsp.typemod.enumMember.defaultLibrary"] = {},
    ["@lsp.typemod.function.defaultLibrary"] = {},
    ["@lsp.typemod.keyword.async"] = {},
    ["@lsp.typemod.keyword.injected"] = {},
    ["@lsp.typemod.macro.defaultLibrary"] = {},
    ["@lsp.typemod.method.defaultLibrary"] = {},
    ["@lsp.typemod.operator.injected"] = {},
    ["@lsp.typemod.string.injected"] = {},
    ["@lsp.typemod.struct.defaultLibrary"] = {},
    ["@lsp.typemod.type.defaultLibrary"] = {},
    ["@lsp.typemod.typeAlias.defaultLibrary"] = {},
    ["@lsp.typemod.variable.callable"] = {},
    ["@lsp.typemod.variable.defaultLibrary"] = {},
    ["@lsp.typemod.variable.injected"] = {},
    ["@lsp.typemod.variable.static"] = {},
    ["@lsp.typemod.variable.readonly"] = {},
  }
end

return M
