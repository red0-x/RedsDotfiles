-- Discord Rich Presence via cord.nvim
--
-- Theme is Minecraft. Note on "red": cord's Minecraft theme only ships three
-- flavors (dark = #101010, light = #f0f0f0, accent = per-language color), and
-- none of them is globally red -- I verified this by sampling the actual PNGs.
-- So red is applied explicitly here instead:
--   * flavor = "accent" so icons keep their colored Minecraft block backing
--   * the editor icon is pinned to a red Minecraft block (accent ruby, #501d1d)
--   * the idle icon matches
-- Set MC_RED to any icon name below to change the red block used.

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
          tooltip = "LazyVim - red's forge",
          icon = red,
        },
        display = {
          theme = "minecraft",
          flavor = "accent",
          view = "full",
          swap_fields = false,
          -- red block becomes the large/prominent image; language icon moves
          -- to the small badge. Set false to put the language icon back on top.
          swap_icons = true,
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
