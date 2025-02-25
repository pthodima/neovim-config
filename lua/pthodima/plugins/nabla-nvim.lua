return {
  "jbyuki/nabla.nvim",
  config = function()
    -- Ensure 'nabla' is available after loading
    require('nabla')

    -- Set up the key mapping for opening the popup with <leader>p
    vim.api.nvim_set_keymap('n', '<leader>p', ':lua require("nabla").popup({border = "single"})<CR>', { noremap = true, silent = true })
    
    -- Optional: Add any other customizations you want for 'nabla'
  end
}
