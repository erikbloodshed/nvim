local core = require("ui.statusline.core")

return {
  render = function(_, apply_hl)
    return core.hl_rule("%l:%v", "StatusLineValue", apply_hl)
  end
}
