-- Everforest colorscheme (dark, transparent background to match kitty opacity)
return {
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("everforest").setup({
        background = "hard", -- "hard" | "medium" | "soft"
        transparent_background_level = 2,
        italics = true,
        ui_contrast = "high",
        on_highlights = function(hl, palette)
          hl.Normal = { bg = "NONE" }
          hl.NormalNC = { bg = "NONE" }
          hl.NormalFloat = { bg = "NONE" }
          hl.FloatBorder = { bg = "NONE", fg = palette.green }
          hl.SignColumn = { bg = "NONE" }
          hl.NonText = { bg = "NONE" }
          hl.TabLine = { bg = "NONE" }
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
