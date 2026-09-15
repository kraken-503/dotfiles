return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    lazy = false,       
    init = function()
      vim.opt.wrap = false
      vim.opt.sidescrolloff = 36

      vim.g.neominimap = {
        auto_enable = true,
        log_level = vim.log.levels.OFF,
        notification_level = vim.log.levels.INFO,
        
        layout = "float", 
        float = {
          minimap_width = 20,
          window_border = "none",
        },
        search = {
          enabled = true,  
          mode = "icon",    
          priority = 200,   
          -- 🌟 Icon line removed entirely to force native string fallback!
        },

        exclude_filetypes = { 
          "NvimTree", "lazy", "mason", "help", "notify", "toggleterm" 
        },
      }

      -- Highlight configuration fallback mapping
      local function apply_transparent_minimap_highlights()
        vim.api.nvim_set_hl(0, "NeominimapSearchIcon", { fg = "#FF5555", bold = true, default = false })
        vim.api.nvim_set_hl(0, "NeominimapBackground", { bg = "NONE", default = false })
      end

      apply_transparent_minimap_highlights() 

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_transparent_minimap_highlights,
      })
    end, 
  },
}

