return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"lua_ls",
				"jdtls", -- Java LSP server (installed but not auto-configured)
			},
			-- auto-install configured servers (with lspconfig)
			automatic_installation = true,
			-- Exclude jdtls from automatic setup since we handle it manually
			handlers = {
				-- Default handler for most servers
				function(server_name)
					require("lspconfig")[server_name].setup({})
				end,
				-- Explicitly disable jdtls auto-setup
				["jdtls"] = function() end,
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				-- Formatters
				"stylua", -- lua formatter
				"isort", -- import formatter
				"black", -- python formatter
				
				-- Linters
				"pylint", -- python linter
				
				-- Java tools
				"java-debug-adapter", -- Java debugger
				"java-test", -- Java test runner
				
				-- Debug Adapters for other languages
				"debugpy", -- Python debugger
				"js-debug-adapter", -- JavaScript/TypeScript debugger
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
