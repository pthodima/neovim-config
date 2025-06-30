-- This file is automatically loaded when opening Java files
-- It sets up nvim-jdtls for the current buffer

-- Java-specific settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

-- JDTLS setup
require("pthodima.plugins.lsp.jdtls.setup").setup()

-- Set some Java-specific options
vim.opt_local.cmdheight = 2 -- more space in the neovim command line for displaying messages 