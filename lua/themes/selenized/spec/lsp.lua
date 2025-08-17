local p = require("themes.selenized.scheme")

return {
  -- Basic semantic tokens
  ["@lsp.type.boolean"] = {},
  ["@lsp.type.builtinType"] = {},
  ["@lsp.type.comment"] = {},
  ["@lsp.type.enum"] = {},
  ["@lsp.type.enumMember"] = {},
  ["@lsp.type.escapeSequence"] = {},
  ["@lsp.type.formatSpecifier"] = {},
  ["@lsp.type.interface"] = {},
  ["@lsp.type.keyword"] = {},
  ["@lsp.type.namespace"] = {},
  ["@lsp.type.number"] = {},
  ["@lsp.type.operator"] = {},
  ["@lsp.type.parameter"] = {},
  ["@lsp.type.property"] = {},
  ["@lsp.type.string"] = {},
  ["@lsp.type.typeAlias"] = {},
  ["@lsp.type.variable"] = {},

  -- Language-specific tokens
  ["@lsp.type.decorator"] = {},
  ["@lsp.type.deriveHelper"] = {},
  ["@lsp.type.generic"] = {},
  ["@lsp.type.lifetime"] = {},
  ["@lsp.type.macro"] = {},
  ["@lsp.type.selfKeyword"] = {},
  ["@lsp.type.selfTypeKeyword"] = {},
  ["@lsp.type.selfTypeParameter"] = {},
  ["@lsp.type.unresolvedReference"] = {},

  -- Type modifiers
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

  ["@lsp.mod.builtin"] = {}
}
