; extends
(function_definition
  name: (identifier) @function.builtin
  (#match? @function.builtin "^__[a-z_]+__$"))

(call
  function: (attribute 
    attribute: (identifier) @function.builtin)
  (#match? @function.builtin "^__[a-z_]+__$"))

(call
  function: (identifier) @function.builtin
  (#match? @function.builtin "^__[a-z_]+__$"))

(attribute
  attribute: (identifier) @constant.builtin
  (#match? @constant.builtin "^__[a-z_]+__$"))
