-- Discord Rich Presence via cord.nvim
--
-- Icons: per-language Minecraft icons are the large image (so it changes with
-- the file you're in), and the red ruby block is the small badge, giving every
-- state a red hue without freezing on one icon.
--
-- The app title ("LazyVim") comes from the Discord application behind
-- `editor.client` and cannot be renamed from here. To make it say "larpvim",
-- create an app named larpvim at https://discord.com/developers/applications
-- and set `client = "<that application id>"` below.

local MC_RED = "ruby" -- accent background sampled at rgb(80, 21, 29)

return {
  {
    "vyfor/cord.nvim",
    build = ":Cord update",
    event = "VeryLazy",
    ---@type CordConfig
    opts = function()
      -- required lazily: cord is not on the rtp while specs are being read
      local red = require("cord.api.icon").get(MC_RED, "minecraft", "accent")
      return {
        editor = {
          client = "lazyvim",
          tooltip = "larpvim      red0xx ont",
          icon = red,
        },
        display = {
          theme = "minecraft",
          flavor = "accent",
          view = "full",
          swap_fields = false,
          -- language icon large, red editor block as the small badge
          swap_icons = false,
        },
        idle = {
          enabled = true,
          timeout = 300000,
          details = "AFK in the Nether",
          tooltip = "💤",
          icon = red,
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
      }
    end,
  },
}
