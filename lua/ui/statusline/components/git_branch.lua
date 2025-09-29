local api, fn = vim.api, vim.fn

local function get_branch(cwd, callback)
  if not vim.fs.find(".git", { upward = true, path = cwd })[1] then
    vim.schedule(function() callback("") end)
    return
  end
  vim.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" },
    { cwd = cwd, text = true, timeout = 1000 },
    vim.schedule_wrap(function(result)
      local branch = result.code == 0 and result.stdout
        and result.stdout:gsub("%s*$", "") or ""
      callback(branch)
    end))
end

return {
  cache_keys = { "git_branch" },
  events = { "BufWinEnter", "BufWritePost", "DirChanged" },
  render = function(ctx, apply_hl)
    local branch_name = ctx.cache:get("git_branch", function()
      local buf_path = api.nvim_buf_get_name(ctx.bufnr)
      local cwd = buf_path and buf_path ~= ""
        and fn.fnamemodify(buf_path, ":h") or fn.getcwd()
      local cached = ctx.win_data.git[cwd]
      if cached == "loading" then return "" end
      if cached then return cached end
      ctx.win_data.git[cwd] = "loading"
      get_branch(cwd, function(branch)
        if not api.nvim_win_is_valid(ctx.winid) then return end
        ctx.win_data.git[cwd] = branch
        ctx.cache:reset("git_branch")
        ctx.refresh_win(ctx.winid)
      end)
      return ""
    end)

    if branch_name and branch_name ~= "" then
      return ctx.hl_rule(ctx.icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
    end
    return ""
  end,
}
