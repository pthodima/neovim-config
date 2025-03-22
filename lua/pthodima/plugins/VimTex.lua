return {
	"lervag/vimtex",
	lazy = false, -- we don't want to lazy load VimTeX
	-- tag = "v2.15", -- uncomment to pin to a specific release
	init = function()
		-- VimTeX configuration goes here, e.g.
		vim.g.vimtex_view_method = "skim"
    vim.g.vimtex_context_pdf_viewer = "skim"

    -- Indentation settings
    vim.g.vimtex_indent_enabled = false            -- Disable auto-indent from Vimtex
    vim.g.tex_indent_items = false                 -- Disable indent for enumerate
    vim.g.tex_indent_brace = false                 -- Disable brace indent

    -- Suppression settings
    vim.g.vimtex_quickfix_mode = 0                 -- Suppress quickfix on save/build
    vim.g.vimtex_log_ignore = {                    -- Suppress specific log messages
      'Underfull',
      'Overfull',
      'specifier changed to',
      'Token not allowed in a PDF string',
    }

    -- Other settings
    vim.g.vimtex_mappings_enabled = false          -- Disable default mappings
    vim.g.tex_flavor = 'latex'                     -- Set file type for TeX files

    vim.g.vimtex_compiler_latexmk = {
        aux_dir = 'aux_dir',
        out_dir = 'out_dir',
        callback = 1,
        continuous = 1,
        executable = 'latexmk',
        hooks = {},
        options = {
            '-verbose',
            '-file-line-error',
            '-synctex=1',
            '-interaction=nonstopmode',
        },
    }
	end,
}
