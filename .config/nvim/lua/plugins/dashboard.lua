return {
  "folke/snacks.nvim",
  init = function()
    local function hl()
      vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#a7c080" })
      vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { fg = "#d3e8b0" })
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
