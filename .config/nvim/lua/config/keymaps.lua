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

-- jcode as a plain listed buffer in the current window (shows up in Shift-h/l cycling)
map("n", "<leader>tj", function()
  vim.cmd("enew")
  vim.fn.termopen("jcode", { cwd = LazyVim.root() })
  vim.cmd("startinsert")
end, { desc = "jcode (current window, listed buffer)" })

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

-- ── new nvim instance in a tmux split (mirrors jcode's <A-j> behavior) ─
map({ "n", "t" }, "<A-n>", function()
  if vim.env.TMUX then
    vim.fn.jobstart({ "tmux", "split-window", "-h", "-c", LazyVim.root(), "nvim" }, { detach = true })
  else
    vim.notify("Not inside tmux — open a new tmux pane manually, or use :tabnew | terminal nvim", vim.log.levels.WARN)
  end
end, { desc = "New nvim instance (tmux split)" })

-- ── empty bash pane in tmux ────────────────────────────────────────────
map({ "n", "t" }, "<A-b>", function()
  if vim.env.TMUX then
    vim.fn.jobstart({ "tmux", "split-window", "-h", "-c", LazyVim.root(), "bash" }, { detach = true })
  else
    vim.notify("Not inside tmux — open a new tmux pane manually, or use :terminal", vim.log.levels.WARN)
  end
end, { desc = "New bash pane (tmux split)" })

-- ── dev server preview (npm run dev) in a bottom split ───────────────
map({ "n", "t" }, "<A-d>", function()
  Snacks.terminal.toggle("bun run dev", {
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
