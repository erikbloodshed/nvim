; extends
(call
  function: (identifier) @type
  (#match? @type "^[A-Z]"))

; Dunder method definitions
(function_definition
  name: (identifier) @function.builtin
  (#match? @function.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

; Dunder method calls
(call
  function: (attribute 
    attribute: (identifier) @function.builtin)
  (#match? @function.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

(call
  function: (identifier) @function.builtin
  (#match? @function.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

; Dunder attribute access (for things like __name__, __doc__)
(attribute
  attribute: (identifier) @constant.builtin
  (#match? @constant.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

; Specific common dunder attributes that should be highlighted as constants
((identifier) @constant.builtin
 (#match? @constant.builtin "^__(name|doc|file|package|path|version|author|dict|class|module|qualname|annotations__)__$"))

; Class-level dunder attributes in assignments
(assignment
  left: (identifier) @constant.builtin
  (#match? @constant.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

; Dunder methods in decorators (less common but possible)
(decorator
  (identifier) @function.builtin
  (#match? @function.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))

(decorator
  (attribute
    attribute: (identifier) @function.builtin)
  (#match? @function.builtin "^__[a-zA-Z_][a-zA-Z0-9_]*__$"))
