local M = {}

local cache_listeners_initialized = false

M.setup_listeners = function(state, commands)
    if cache_listeners_initialized then return end
    cache_listeners_initialized = true

    local api = state.api
    local group = api.nvim_create_augroup("CodeforgeCommandCacheInvalidation", { clear = true })

    api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*",
        callback = function()
            local current_buf_name = api.nvim_buf_get_name(0)
            if current_buf_name == state.src_file then
                commands.clear_caches()
            end
        end,
    })
end

return M
