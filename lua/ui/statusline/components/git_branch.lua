local api = vim.api

return {
  cache_keys = { "git_branch" },
  events = { "BufWinEnter", "BufWritePost", "DirChanged" },
  render = function(ctx, apply_hl)
    local branch_name = ctx.cache:get("git_branch", function()
      local cwd = vim.fs.dirname(api.nvim_buf_get_name(ctx.bufnr))
      if not vim.uv.fs_stat(cwd) then return "" end
      local cached = ctx.win_data.git[cwd]
      if cached == "loading" then return "" end
      if cached then return cached end
      if not vim.fs.find(".git", { upward = true, path = cwd, type = "directory" })[1] then
        ctx.win_data.git[cwd] = ""
        return ""
      end
      ctx.win_data.git[cwd] = "loading"
      vim.system({ "git", "branch", "--show-current" },
        { cwd = cwd, text = true, timeout = 500 },
        vim.schedule_wrap(function(result)
          if not api.nvim_win_is_valid(ctx.winid) then return end
          local branch = result.code == 0 and result.stdout
            and result.stdout:gsub("%s*$", "") or ""
          ctx.win_data.git[cwd] = branch ~= "" and branch or false
          ctx.cache:reset("git_branch")
          ctx.refresh_win(ctx.winid)
        end))
      return ""
    end)
    if branch_name and branch_name ~= "" then
      local content = ctx.icons.git .. " " .. branch_name
      return ctx.hl_rule(content, "StatusLineGit", apply_hl)
    end
    return ""
  end,
}
