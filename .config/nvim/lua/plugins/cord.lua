-- Discord Rich Presence via cord.nvim
-- Theme: Minecraft icons. Flavor set to "accent" for the warmer/red-tinted blocks.
-- Switch flavor with "dark" | "light" | "accent" if you want a different look.
return {
  {
    "vyfor/cord.nvim",
    build = ":Cord update",
    event = "VeryLazy",
    ---@type CordConfig
    opts = {
      editor = {
        client = "lazyvim",
        tooltip = "LazyVim - red's forge",
      },
      display = {
        theme = "minecraft",
        flavor = "accent",
        view = "full",
        swap_fields = false,
        swap_icons = false,
      },
      idle = {
        enabled = true,
        timeout = 300000,
        details = "AFK in the Nether",
        tooltip = "💤",
      },
      text = {
        workspace = function(opts)
          return "Mining in " .. opts.workspace
        end,
        viewing = function(opts)
          return "Peeking at " .. opts.filename
        end,
        editing = function(opts)
          return "Crafting " .. opts.filename
        end,
        terminal = function(opts)
          return "Running commands in " .. opts.name
        end,
        dashboard = "Respawning",
      },
      buttons = {
        {
          label = function(opts)
            return opts.repo_url and "View Repository" or "Get LazyVim"
          end,
          url = function(opts)
            return opts.repo_url or "https://lazyvim.org"
          end,
        },
      },
      advanced = {
        discord = {
          reconnect = {
            enabled = true,
            interval = 5000,
            initial = true,
          },
        },
      },
    },
  },
}
