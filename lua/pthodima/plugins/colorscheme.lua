return {
  'projekt0n/github-nvim-theme',
  name = 'github-theme',
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('github-theme').setup({
      options = {
        transparent = true,
        hide_nc_statusline = true,
        darken = {
          floats = true,
          sidebars = {
            enable = true,
            list = { "qf", "vista_kind", "terminal", "packer" }
          }
        }
      }
    })

    vim.cmd('colorscheme github_dark')
  end,
}
