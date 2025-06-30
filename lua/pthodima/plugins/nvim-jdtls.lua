return {
  "mfussenegger/nvim-jdtls",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    { "folke/neodev.nvim", opts = {} },
    "mfussenegger/nvim-dap",
  },
  lazy = true,
  init = function()
    vim.api.nvim_create_autocmd("BufReadCmd", {
      pattern = "jdt://*",
      callback = function(args)
        local uri = args.file or args.match
        local clients = vim.lsp.get_clients and vim.lsp.get_clients({ name = "jdtls" }) or vim.lsp.get_active_clients({ name = "jdtls" })
        
        if #clients > 0 then
          local client = clients[1]
          local bufnr = vim.api.nvim_get_current_buf()
          
          if not vim.lsp.buf_is_attached(bufnr, client.id) then
            vim.lsp.buf_attach_client(bufnr, client.id)
          end
          
          require("jdtls").open_classfile(uri)
        else
          vim.notify("No JDTLS client available for jdt:// URI: " .. uri, vim.log.levels.WARN)
        end
      end,
    })
  end,
  config = false, -- Disable plugin's config entirely
}
