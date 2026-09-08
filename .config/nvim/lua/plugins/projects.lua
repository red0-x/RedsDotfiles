-- Make repos under ~/Documents/GitHub show up in the project picker (<leader>fp)
-- and in the dashboard's Projects entry. Snacks only scans ~/dev and ~/projects
-- by default, which is not where these live.
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        projects = {
          dev = { "~/Documents/GitHub", "~/dev", "~/projects" },
        },
      },
    },
  },
}
