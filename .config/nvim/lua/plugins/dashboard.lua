return {
  "folke/snacks.nvim",
  init = function()
    local function hl()
      -- follow the (wallpaper-driven) everforest palette
      local ok, p = pcall(function()
        local ef = require("everforest")
        return require("everforest.colours").generate_palette(ef.config, vim.o.background)
      end)
      local accent = ok and p.green or "#a7c080"
      local title = ok and p.aqua or "#d3e8b0"
      vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = accent })
      vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { fg = title })
    end
    hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
  end,
  opts = {
    dashboard = {
      preset = {
        -- lines padded to equal width so snacks' centering doesn't stagger them,
        -- and left-padded so the LARPVIM block (not the trailing L's) is centered
        header = [[
           ██╗      █████╗ ██████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗          L
           ██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██║████╗ ████║      L
           ██║     ███████║██████╔╝██████╔╝██║   ██║██║██╔████╔██║   l
           ██║     ██╔══██║██╔══██╗██╔═══╝ ╚██╗ ██╔╝██║██║╚██╔╝██║ l
           ███████╗██║  ██║██║  ██║██║      ╚████╔╝ ██║██║ ╚═╝ ██║
           ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝       ╚═══╝  ╚═╝╚═╝     ╚═╝           ]],
      },
      sections = {
        -- separate section: centered on its own, so header placement is untouched
        {
          align = "center",
          padding = 1,
          text = {
            { "        ▌▞▀▖             ▐  ", hl = "SnacksDashboardTitle" },
            { "\n" },
            { "▙▀▖▞▀▖▞▀▌▌▞▌▚▗▘▚▗▘ ▞▀▖▛▀▖▜▀ ", hl = "SnacksDashboardTitle" },
            { "\n" },
            { "▌  ▛▀ ▌ ▌▛ ▌▗▚ ▗▚  ▌ ▌▌ ▌▐ ▖", hl = "SnacksDashboardTitle" },
            { "\n" },
            { "▘  ▝▀▘▝▀▘▝▀ ▘ ▘▘ ▘ ▝▀ ▘ ▘ ▀ ", hl = "SnacksDashboardTitle" },
            { "\n" },
          },
        },
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
  },
}
