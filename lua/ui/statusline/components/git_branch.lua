local api, fn = vim.api, vim.fn

return {
  cache_keys = { "git_branch" },
  events = { "BufWinEnter", "BufWritePost", "DirChanged" },
  render = function(ctx, apply_hl)
    local branch_name = ctx.cache:get("git_branch", function()
      -- === FIX STARTS HERE ===
      local buf_path = api.nvim_buf_get_name(ctx.bufnr)
      local cwd
      if buf_path and buf_path ~= "" then
        cwd = fn.fnamemodify(buf_path, ":h")
      else
        cwd = fn.getcwd()
      end
      local cached = ctx.win_data.git[cwd]
      if cached == "loading" then return "" end
      if cached then return cached end
      if not vim.fs.find(".git", { upward = true, path = cwd })[1] then
        ctx.win_data.git[cwd] = ""
        return ""
      end
      ctx.win_data.git[cwd] = "loading"
      vim.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, {
        cwd = cwd,
        text = true,
        timeout = 1000,
      }, vim.schedule_wrap(function(result)
        if not api.nvim_win_is_valid(ctx.winid) then return end
        local branch = ""
        if result.code == 0 and result.stdout then
          branch = result.stdout:gsub("%s*$", "")
        end
        ctx.win_data.git[cwd] = branch
        ctx.cache:reset("git_branch")
        ctx.refresh_win(ctx.winid)
      end))
      return ""
    end)
    if branch_name and branch_name ~= "" then
      return ctx.hl_rule(ctx.icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
    end
    return ""
  end,
}
