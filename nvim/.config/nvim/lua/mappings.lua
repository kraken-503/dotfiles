require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")



local map = vim.keymap.set

-- Official Neominimap command bindings
map("n", "<leader>mm", "<cmd>Neominimap Toggle<cr>", { desc = "Toggle global minimap" })
map("n", "<leader>mo", "<cmd>Neominimap Enable<cr>", { desc = "Enable global minimap" })
map("n", "<leader>mc", "<cmd>Neominimap Disable<cr>", { desc = "Disable global minimap" })
map("n", "<leader>mf", "<cmd>Neominimap Focus<cr>", { desc = "Focus on minimap" })

vim.api.nvim_set_hl(0, "NeominimapSearchLine", { link = "Search", default = false })
