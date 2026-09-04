-- Everforest colorscheme.
-- The user asked for an *everforest background*, so the real everforest bg is on
-- by default. Their old init.vim forced transparency, so that is kept as a
-- toggle: <leader>ub or :TransparentToggle.
return {
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local function build(transparent)
        require("everforest").setup({
          background = "hard", -- "hard" | "medium" | "soft"
          transparent_background_level = transparent and 2 or 0,
          italics = true,
          ui_contrast = "high",
          on_highlights = function(hl, palette)
            if transparent then
              for _, g in ipairs({
                "Normal",
                "NormalNC",
                "NormalFloat",
                "SignColumn",
                "NonText",
                "TabLine",
                "TabLineFill",
              }) do
                hl[g] = vim.tbl_extend("force", hl[g] or {}, { bg = "NONE" })
              end
              hl.FloatBorder = { bg = "NONE", fg = palette.green }
            end
          end,
        })
      end

      vim.g.everforest_transparent = false
      build(false)
      vim.cmd.colorscheme("everforest")

      local function toggle()
        vim.g.everforest_transparent = not vim.g.everforest_transparent
        build(vim.g.everforest_transparent)
        vim.cmd.colorscheme("everforest")
        vim.notify("Transparency " .. (vim.g.everforest_transparent and "on" or "off"))
      end

      vim.api.nvim_create_user_command("TransparentToggle", toggle, {})
      vim.keymap.set("n", "<leader>ub", toggle, { desc = "Toggle transparent background" })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
