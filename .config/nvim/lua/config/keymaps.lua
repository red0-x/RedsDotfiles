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

-- ── jcode: one key to toggle, works from terminal mode too ───────────
local function jcode()
  Snacks.terminal.toggle("jcode", {
    cwd = LazyVim.root(),
    win = { position = "right", width = 0.4, wo = { winbar = "" } },
    start_insert = true,
    auto_insert = true,
    auto_close = false,
  })
end
map({ "n", "t" }, "<A-j>", jcode, { desc = "Toggle jcode (right split)" })

-- ── dev server preview (npm run dev) in a bottom split ───────────────
map({ "n", "t" }, "<A-d>", function()
  Snacks.terminal.toggle("npm run dev", {
    cwd = LazyVim.root(),
    win = { position = "bottom", height = 0.3 },
    auto_close = false,
  })
end, { desc = "Toggle dev server" })

-- ── window movement: works in terminal mode as well ──────────────────
for _, k in ipairs({ "h", "j", "k", "l" }) do
  map("t", "<C-" .. k .. ">", "<C-\\><C-n><C-w>" .. k, { desc = "Go to window " .. k })
end
map("t", "<A-1>", "<C-\\><C-n>1gt")

-- resize / move windows
map("n", "<C-A-h>", "<C-w>H", { desc = "Move window far left" })
map("n", "<C-A-j>", "<C-w>J", { desc = "Move window far down" })
map("n", "<C-A-k>", "<C-w>K", { desc = "Move window far up" })
map("n", "<C-A-l>", "<C-w>L", { desc = "Move window far right" })
map("n", "<leader>wz", "<C-w>|<C-w>_", { desc = "Zoom window (max)" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows" })

-- ── tab moving ───────────────────────────────────────────────────────
map("n", "<A-S-Left>", "<cmd>-tabmove<cr>", { desc = "Move tab left" })
map("n", "<A-S-Right>", "<cmd>+tabmove<cr>", { desc = "Move tab right" })

-- ── open the running app in a browser ────────────────────────────────
map("n", "<leader>op", function()
  vim.ui.input({ prompt = "Open URL: ", default = "http://localhost:3000" }, function(url)
    if url then
      vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    end
  end)
end, { desc = "Open app preview in browser" })
