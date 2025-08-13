;; extends
((identifier) @constant
  (#match? @constant "^k[A-Z]+")
  (#set! "priority" 130))
