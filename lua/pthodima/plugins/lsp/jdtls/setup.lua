local M = {}

function M.setup()
  local jdtls = require("jdtls")
  local jdtls_dap = require("jdtls.dap")
  local jdtls_setup = require("jdtls.setup")
  local home = os.getenv("HOME")

  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".project", ".classpath" }
  local root_dir = jdtls_setup.find_root(root_markers)

  if not root_dir then
    vim.notify("No Java project root found. Make sure you're in a Java project directory.", vim.log.levels.WARN)
    return
  end

  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

  local path_to_mason_packages = home .. "/.local/share/nvim/mason/packages"
  local path_to_jdtls = path_to_mason_packages .. "/jdtls"
  local path_to_jdebug = path_to_mason_packages .. "/java-debug-adapter"
  local path_to_jtest = path_to_mason_packages .. "/java-test"
  local path_to_config = path_to_jdtls .. "/config_mac"
  local lombok_path = path_to_jdtls .. "/lombok.jar"
  local path_to_jar = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar")

  if not vim.loop.fs_stat(path_to_jdtls) then
    vim.notify("JDTLS not found. Please install it via Mason: :Mason", vim.log.levels.ERROR)
    return
  end

  if path_to_jar == "" or not vim.loop.fs_stat(path_to_jar) then
    vim.notify("JDTLS launcher jar not found at: " .. path_to_jdtls .. "/plugins/", vim.log.levels.ERROR)
    return
  end

  local java_cmd = "/opt/homebrew/Cellar/openjdk@21/21.0.7/bin/java"
  if not vim.loop.fs_stat(java_cmd) then
    java_cmd = vim.fn.exepath("java")
    if java_cmd == "" then
      vim.notify("Java executable not found. Please ensure Java is installed.", vim.log.levels.ERROR)
      return
    end
  end

  local bundles = {}
  
  if vim.loop.fs_stat(path_to_jdebug) then
    local debug_jar = vim.fn.glob(path_to_jdebug .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
    if debug_jar ~= "" then
      table.insert(bundles, debug_jar)
    end
  end

  if vim.loop.fs_stat(path_to_jtest) then
    local test_jars = vim.split(vim.fn.glob(path_to_jtest .. "/extension/server/*.jar", true), "\n")
    for _, jar in ipairs(test_jars) do
      if jar ~= "" and jar ~= vim.NIL then
        table.insert(bundles, jar)
      end
    end
  end

  local on_attach = function(client, bufnr)
    
    jdtls.setup_dap({ hotcodereplace = "auto" })
    jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    local nmap = function(keys, func, desc)
      if desc then
        desc = "LSP: " .. desc
      end
      vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end

    nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
    nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
    nmap("<leader>e", vim.diagnostic.open_float, "Show line diagnostics")
    nmap("<leader>hh", vim.lsp.buf.signature_help, "Signature [H][H]elp Documentation")
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
    nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
    nmap("<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[W]orkspace [L]ist Folders")

    -- Common LSP keymaps that should be available in Java files
    nmap("gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references")
    nmap("gd", vim.lsp.buf.definition, "Show LSP definitions")
    nmap("gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations")
    nmap("gt", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions")
    nmap("<leader>ca", vim.lsp.buf.code_action, "See available code actions")
    nmap("<leader>rn", vim.lsp.buf.rename, "Smart rename")
    nmap("K", vim.lsp.buf.hover, "Show documentation for what is under cursor")
    nmap("[d", vim.diagnostic.goto_prev, "Go to previous diagnostic")
    nmap("]d", vim.diagnostic.goto_next, "Go to next diagnostic")

    vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
      vim.lsp.buf.format()
    end, { desc = "Format current buffer with LSP" })

    local lsp_sig_ok, lsp_signature = pcall(require, "lsp_signature")
    if lsp_sig_ok then
      lsp_signature.on_attach({
        bind = true,
        padding = "",
        handler_opts = {
          border = "rounded",
        },
        hint_prefix = "󱄑 ",
      }, bufnr)
    end

    local saga_ok, lspsaga = pcall(require, "lspsaga")
    if saga_ok then
      lspsaga.setup()
    end

    require("pthodima.plugins.lsp.jdtls.keymaps")
    vim.notify("JDTLS attached successfully to buffer " .. bufnr, vim.log.levels.INFO)
  end

  local capabilities
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = cmp_nvim_lsp.default_capabilities()
  else
    capabilities = {
      workspace = {
        configuration = true
      },
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true
          }
        }
      }
    }
  end

  local config = {
    flags = {
      allow_incremental_sync = true,
    },
    root_dir = root_dir,
    handlers = {
      ["textDocument/definition"] = require("jdtls").definition,
    },
  }

  config.cmd = {
    java_cmd,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx2g",
    "-javaagent:" .. lombok_path,
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", path_to_jar,
    "-configuration", path_to_config,
    "-data", workspace_dir,
  }

  config.settings = {
          java = {
        references = {
          includeDecompiledSources = true,
        },
        format = {
          enabled = true,
          settings = {
            url = vim.fn.stdpath("config") .. "/format_style/eclipse-cs300-style.xml",
            profile = "CS300Style",
          },
        },
        eclipse = {
          downloadSources = true,
        },
        maven = {
          downloadSources = true,
        },
        project = {
          referencedLibraries = {
            root_dir .. "/*.jar",
            root_dir .. "/p2core.jar"
          }
        },
        autobuild = {
          enabled = false
        },
        cleanup = {
          actionsOnSave = {}
        },
      configuration = {
        updateBuildConfiguration = "automatic",
        runtimes = {
          {
            name = "JavaSE-17",
            path = "/opt/homebrew/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home/",
          },
          {
            name = "JavaSE-21", 
            path = "/opt/homebrew/Cellar/openjdk@21/21.0.7/libexec/openjdk.jdk/Contents/Home/",
          },
        }
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
        importOrder = {
          "java",
          "javax",
          "com",
          "org",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
    },
  }

  config.on_attach = on_attach
  config.capabilities = capabilities
  config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
    vim.defer_fn(function()
      if client.server_capabilities then
        client.request('java/projectConfigurationUpdate', { uri = vim.uri_from_fname(workspace_dir) }, function() end)
      end
    end, 1000)
  end

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  }

  vim.fn.mkdir(workspace_dir, "p")
  vim.notify("Starting JDTLS for project: " .. project_name, vim.log.levels.INFO)
  
  local ok, result = pcall(jdtls.start_or_attach, config)
  if ok then
    vim.defer_fn(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients and vim.lsp.get_clients({ name = "jdtls" }) or vim.lsp.get_active_clients({ name = "jdtls" })
      
      if #clients > 0 then
        local client = clients[1]
        if not vim.lsp.buf_is_attached(bufnr, client.id) then
          vim.lsp.buf_attach_client(bufnr, client.id)
        end
      end
    end, 3000)
  else
    vim.notify("JDTLS failed to start: " .. tostring(result), vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command("JdtlsStart", M.setup, {})

return M
