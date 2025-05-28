local M = {}

M.init = function(opts)
    opts = opts or {}
    local lang = {
        cpp = {
            compiler = "g++",
            fallback_flags = { "-std=c++20", "-O2" },
            output_dir = "/tmp",
            compiled = true,
            link = false,
        }
    }

    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    local config = vim.tbl_deep_extend('force', lang[ft], opts)

    return config
end

return M
