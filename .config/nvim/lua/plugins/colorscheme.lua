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
      -- Wallpaper-following palette, written by ~/.config/hypr/scripts/wallcolors.py.
      -- Missing / unreadable file -> stock everforest.
      local palette_file = vim.fn.expand("~/.cache/rice/nvim-palette.json")
      local function rice_palette()
        local ok, lines = pcall(vim.fn.readfile, palette_file)
        if not ok or #lines == 0 then return nil end
        local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
        return ok2 and type(data) == "table" and data.palette or nil
      end

      local function build(transparent)
        local rp = rice_palette()
        require("everforest").setup({
          background = "hard", -- "hard" | "medium" | "soft"
          transparent_background_level = transparent and 2 or 0,
          italics = true,
          ui_contrast = "high",
          colours_override = function(palette)
            if rp then
              for k, v in pairs(rp) do
                if palette[k] ~= nil then palette[k] = v end
              end
            end
          end,
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

      vim.g.everforest_transparent = true
      build(true)
      vim.cmd.colorscheme("everforest")

      local function toggle()
        vim.g.everforest_transparent = not vim.g.everforest_transparent
        build(vim.g.everforest_transparent)
        vim.cmd.colorscheme("everforest")
        vim.notify("Transparency " .. (vim.g.everforest_transparent and "on" or "off"))
      end

      vim.api.nvim_create_user_command("TransparentToggle", toggle, {})
      vim.keymap.set("n", "<leader>ub", toggle, { desc = "Toggle transparent background" })

      -- Live recolor when the wallpaper changes (file is replaced atomically).
      local function reload()
        build(vim.g.everforest_transparent)
        if vim.g.colors_name == "everforest" then vim.cmd.colorscheme("everforest") end
      end
      vim.api.nvim_create_user_command("RiceReload", reload, {})
      local dir = vim.fn.fnamemodify(palette_file, ":h")
      vim.fn.mkdir(dir, "p")
      local w = vim.uv.new_fs_event()
      if w then
        local pending = false
        w:start(dir, {}, function(_, fname)
          if fname ~= "nvim-palette.json" or pending then return end
          pending = true
          vim.defer_fn(function() pending = false; reload() end, 150)
        end)
      end
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
