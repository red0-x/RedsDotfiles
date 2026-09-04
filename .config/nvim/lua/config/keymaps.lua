-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- ── jcode ────────────────────────────────────────────────────────────
-- <leader>j opens jcode in a floating terminal inside Neovim.
map("n", "<leader>j", function()
  LazyVim.terminal({ "jcode" }, { cwd = LazyVim.root(), esc_esc = false, ctrl_hjkl = false })
end, { desc = "jcode (root dir)" })

map("n", "<leader>J", function()
  LazyVim.terminal({ "jcode" }, { cwd = vim.uv.cwd(), esc_esc = false, ctrl_hjkl = false })
end, { desc = "jcode (cwd)" })

-- ── tab switching (mirrors the kitty alt+N bindings) ─────────────────
for i = 1, 9 do
  map("n", "<A-" .. i .. ">", "<cmd>" .. i .. "tabnext<cr>", { desc = "Go to tab " .. i })
end
map("n", "<A-Left>", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
map("n", "<A-Right>", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<A-t>", "<cmd>tabnew<cr>", { desc = "New tab" })
