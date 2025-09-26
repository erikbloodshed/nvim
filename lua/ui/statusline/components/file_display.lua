local api, fn = vim.api, vim.fn
local core = require("ui.statusline.core")
local lazy_dep = require("ui.statusline.lazy_dep")

local devicons = nil
local devicons_failed = false

local function ensure_devicons_loaded()
  if devicons or devicons_failed then
    return devicons
  end

  lazy_dep.require("nvim-web-devicons", {
    on_success = function(mod)
      devicons = mod
      -- refresh all windows that might need icon updates
      for _, winid in ipairs(api.nvim_list_wins()) do
        if api.nvim_win_is_valid(winid) and core.win_data[winid] then
          core.get_win_cache(winid):reset("file_data")
          core.refresh_win(winid)
        end
      end
    end,
    on_failure = function()
      devicons_failed = true
    end,
  })

  return devicons
end

return {
  cache_keys = { "file_data" },
  render = function(ctx, apply_hl)
    local windat = ctx.windat
    local file_data = ctx.cache:get("file_data", function()
      local name = api.nvim_buf_get_name(ctx.bufnr)
      local display_name = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
      local ext = (name == "") and "" or fn.fnamemodify(name, ":e")

      local result = {
        name = display_name,
        icon = "",
        hl = "Normal",
        has_devicons = devicons ~= nil,
      }

      if windat.icons[display_name] then
        local icon_info = windat.icons[display_name]
        result.icon = icon_info.icon or ""
        result.hl = icon_info.hl or "Normal"
        result.has_devicons = true
      else
        -- Init icon cache
        windat.icons[display_name] = { icon = "", hl = "Normal" }

        -- Ensure devicons is loaded
        local icons_mod = ensure_devicons_loaded()

        if icons_mod then
          -- Got devicons, try fetching icon
          local icon, hl = icons_mod.get_icon(display_name, ext)
          if icon then
            windat.icons[display_name] = { icon = icon, hl = hl or "Normal" }
            result.icon = icon
            result.hl = hl or "Normal"
            result.has_devicons = true
          end
        elseif devicons_failed then
          local fallback_icon = "󰈔"
          windat.icons[display_name] = { icon = fallback_icon, hl = "Normal" }
          result.icon = fallback_icon
          result.hl = "Normal"
        end
      end

      return result
    end)

    local parts = {}

    if file_data.icon and file_data.icon ~= "" then
      parts[#parts + 1] = core.hl_rule(file_data.icon, file_data.hl, apply_hl)
      parts[#parts + 1] = " "
    elseif not file_data.has_devicons and not devicons_failed then
      parts[#parts + 1] = core.hl_rule("󰔟", "Comment", apply_hl)
      parts[#parts + 1] = " "
    end

    parts[#parts + 1] = core.hl_rule(file_data.name, "StatusLine", apply_hl)

    return table.concat(parts, "")
  end,
}

