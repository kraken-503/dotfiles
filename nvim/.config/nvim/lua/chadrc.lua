-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

-- The Quickshell theme switcher writes the active NvChad theme name to this file
-- (tools/export_apps.py). If it is missing or invalid, the default below is used.
local function qs_theme(default)
  local f = io.open((os.getenv "HOME" or "") .. "/.cache/quickshell-bar/nvchad-theme", "r")
  if not f then return default end
  local name = (f:read "*l" or ""):match "^%s*([%w_%-]+)%s*$"
  f:close()
  return name or default
end

M.base46 = {
	theme = qs_theme "tokyonight",
  transparency = false,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
