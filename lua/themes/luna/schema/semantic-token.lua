local M = {}

M.get = function(c)
  return {
    -- Basic Types
    ["@lsp.type.boolean"] = { link = "Boolean" },
    ["@lsp.type.number"] = { link = "Constant" },
    ["@lsp.type.string"] = { link = "String" },
    ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"] = { link = "@markup.list" },
    -- Classes & Types
    ["@lsp.type.class"] = { link = "Type" },
    ["@lsp.type.builtinType"] = { link = "@type.builtin" },
    ["@lsp.type.enum"] = { link = "Type" },
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.interface"] = { fg = c.interface },
    ["@lsp.type.generic"] = { link = "@variable" },
    ["@lsp.type.typeAlias"] = { link = "Typedef" },
    -- Variables & Parameters
    ["@lsp.type.variable"] = {},
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
    ["@lsp.type.selfTypeKeyword"] = { link = "@variable.builtin" },
    -- Functions & Methods
    ["@lsp.type.method"] = {},
    -- Keywords & Operators
    ["@lsp.type.keyword"] = { link = "@keyword" },
    ["@lsp.type.operator"] = { link = "Operator" },
    ["@lsp.type.lifetime"] = { link = "StorageClass" },
    -- Modules & Namespaces
    ["@lsp.type.namespace"] = { link = "Directory" },
    ["@lsp.type.namespace.python"] = { link = "@variable" },
    ["@lsp.type.namespace.cpp"] = { link = "PreProc" },
    -- Attributes & Decorators
    ["@lsp.type.decorator"] = { link = "@attribute" },
    ["@lsp.type.deriveHelper"] = { link = "@attribute" },
    -- Comments & Errors
    ["@lsp.type.comment"] = { link = "Comment" },
    ["@lsp.type.unresolvedReference"] = { undercurl = true, sp = c.error },
    -- Default Library Overrides
    ["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.enum.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.function.defaultLibrary.cpp"] = { link = "@function.method" },
    ["@lsp.typemod.macro.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.method.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.struct.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.type.defaultLibrary"] = { link = "Special" },
    ["@lsp.typemod.typeAlias.defaultLibrary"] = { link = "@lsp.typemod.type.defaultLibrary" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.defaultLibrary.cpp"] = { link = "@variable.builtin.c" },
    -- Keyword Modifiers
    ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
    ["@lsp.typemod.keyword.injected"] = { link = "@keyword" },
    -- Variable Modifiers
    ["@lsp.typemod.variable.callable"] = { link = "Function" },
    ["@lsp.typemod.variable.injected"] = { link = "@variable" },
    ["@lsp.typemod.variable.static"] = { link = "Constant" },
    -- Injected Tokens
    ["@lsp.typemod.operator.injected"] = { link = "Operator" },
    ["@lsp.typemod.string.injected"] = { link = "String" },
  }
end

return M
