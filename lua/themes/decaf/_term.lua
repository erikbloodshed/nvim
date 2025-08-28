local M = {}

function M.get(c)
  return {
    terminal_color_0 = c.overlay0,
    terminal_color_1 = c.red,
    terminal_color_2 = c.green,
    terminal_color_3 = c.yellow,
    terminal_color_4 = c.blue,
    terminal_color_5 = c.pink,
    terminal_color_6 = c.sky,
    terminal_color_7 = c.text,
    terminal_color_8 = c.overlay1,
    terminal_color_9 = c.red,
    terminal_color_10 = c.green,
    terminal_color_11 = c.yellow,
    terminal_color_12 = c.blue,
    terminal_color_13 = c.pink,
    terminal_color_14 = c.sky,
    terminal_color_15 = c.text,
  }
end

return M
