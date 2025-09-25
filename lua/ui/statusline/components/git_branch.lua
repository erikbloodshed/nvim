-- ===================================================================
-- ui/statusline/components/git_branch.lua
local api, fn = vim.api, vim.fn
local icons = require("ui.icons")

local M = {
  enabled = true,
  priority = 3,
  cache_keys = { "git_branch" },
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl
  local refresh_win = require('ui.statusline').refresh_win

  local branch_name = ctx.cache:get("git_branch", function()
    local cwd = fn.fnamemodify(api.nvim_buf_get_name(ctx.bufnr), ":h") or fn.getcwd()
    if ctx.wdata.git[cwd] == nil then
      ctx.wdata.git[cwd] = false
      vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true, timeout = 1000 },
        vim.schedule_wrap(function(result)
          if not api.nvim_win_is_valid(ctx.winid) then return end
          local branch = (result.code == 0 and result.stdout) and result.stdout:gsub("%s*$", "") or ""
          ctx.wdata.git[cwd] = branch
          ctx.cache:invalidate("git_branch")
          refresh_win(ctx.winid)
        end))
    end
    return ctx.wdata.git[cwd] or ""
  end)

  if branch_name and branch_name ~= "" then
    return conditional_hl(icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
  end
  return ""
end

return M

