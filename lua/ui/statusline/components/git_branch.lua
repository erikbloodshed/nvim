local api, fn = vim.api, vim.fn
local core = require("ui.statusline.core")

return {
  cache_keys = { "git_branch" },
  render = function(ctx, apply_hl)
    local branch_name = ctx.cache:get("git_branch", function()
      local windat = ctx.windat
      local cwd = fn.fnamemodify(api.nvim_buf_get_name(ctx.bufnr), ":h") or fn.getcwd()
      if windat.git[cwd] == nil then
        windat.git[cwd] = false
        vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true, timeout = 1000 },
          vim.schedule_wrap(function(result)
            if not api.nvim_win_is_valid(ctx.winid) then return end
            local branch = (result.code == 0 and result.stdout) and result.stdout:gsub("%s*$", "") or ""
            windat.git[cwd] = branch
            ctx.cache:reset("git_branch")
            core.refresh_win(ctx.winid)
          end))
      end
      return windat.git[cwd] or ""
    end)
    if branch_name and branch_name ~= "" then
      return core.hl_rule(ctx.icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
    end
    return ""
  end,
}
