local M = {}

function M.get(c)
  return {
    ["@lsp.type.boolean"] = { link = "Constant" },
    ["@lsp.type.builtinType"] = { link = "Type" },
    ["@lsp.type.comment"] = { link = "Comment" },
    ["@lsp.type.class"] = { link = "StorageClass" },
    ["@lsp.type.enum"] = { link = "StorageClass" },
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.escapeSequence"] = { link = "Special" },
    ["@lsp.type.formatSpecifier"] = { link = "Special" },
    ["@lsp.type.interface"] = { link = "Identifier" },
    ["@lsp.type.keyword"] = { link = "Statement" },
    ["@lsp.type.namespace"] = { link = "@module" },
    ["@lsp.type.number"] = { link = "Constant" },
    ["@lsp.type.operator"] = { link = "Operator" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@variable.member" },
    ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
    ["@lsp.type.typeAlias"] = { link = "@type.definition" },
    ["@lsp.type.unresolvedReference"] = { link = "Error" },
    ["@lsp.type.variable"] = {},
    ["@lsp.typemod.class.defaultLibrary"] = { link = "StorageClass" },
    ["@lsp.typemod.enum.defaultLibrary"] = { link = "StorageClass" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
    ["@lsp.typemod.macro.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.method.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.operator.injected"] = { link = "Operator" },
    ["@lsp.typemod.string.injected"] = { link = "String" },
    ["@lsp.typemod.type.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"] = { link = "@variable" },
  }
end

return M
