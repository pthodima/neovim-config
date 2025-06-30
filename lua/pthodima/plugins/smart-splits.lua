return {
  "mrjones2014/smart-splits.nvim",
  -- build = "./kitty/install-kittens.bash", -- optional: only needed if using Kitty
  config = function()
    require("smart-splits").setup({
      -- explicitly set to 'wezterm' for multiplexer support
      multiplexer = "wezterm",
      at_edge = "stop", -- or "wrap"
    })

    -- Keymaps for moving between splits
    local ss = require("smart-splits")
    vim.keymap.set("n", "<C-h>", ss.move_cursor_left, { desc = "Move left" })
    vim.keymap.set("n", "<C-j>", ss.move_cursor_down, { desc = "Move down" })
    vim.keymap.set("n", "<C-k>", ss.move_cursor_up, { desc = "Move up" })
    vim.keymap.set("n", "<C-l>", ss.move_cursor_right, { desc = "Move right" })

    -- Optional: resizing splits
    vim.keymap.set("n", "<A-h>", ss.resize_left, { desc = "Resize left" })
    vim.keymap.set("n", "<A-j>", ss.resize_down, { desc = "Resize down" })
    vim.keymap.set("n", "<A-k>", ss.resize_up, { desc = "Resize up" })
    vim.keymap.set("n", "<A-l>", ss.resize_right, { desc = "Resize right" })
  end,
}
