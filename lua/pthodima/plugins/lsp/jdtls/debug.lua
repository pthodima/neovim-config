local M = {}

-- Debug function to check JDTLS setup
function M.check_jdtls()
  local home = os.getenv("HOME")
  local path_to_mason_packages = home .. "/.local/share/nvim/mason/packages"
  local path_to_jdtls = path_to_mason_packages .. "/jdtls"
  
  print("=== JDTLS Debug Information ===")
  print("Home directory: " .. home)
  print("Mason packages path: " .. path_to_mason_packages)
  print("JDTLS path: " .. path_to_jdtls)
  
  -- Check if JDTLS is installed
  if vim.loop.fs_stat(path_to_jdtls) then
    print("✓ JDTLS directory exists")
    
    -- Check launcher jar
    local launcher_jar = path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_1.7.0.v20250331-1702.jar"
    if vim.loop.fs_stat(launcher_jar) then
      print("✓ Launcher jar exists: " .. launcher_jar)
    else
      print("✗ Launcher jar NOT found: " .. launcher_jar)
      print("Available launcher jars:")
      local launcher_glob = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher*.jar", false, true)
      for _, jar in ipairs(launcher_glob) do
        print("  - " .. jar)
      end
    end
    
    -- Check config directory
    local config_path = path_to_jdtls .. "/config_mac_arm"
    if vim.loop.fs_stat(config_path) then
      print("✓ Config directory exists: " .. config_path)
    else
      print("✗ Config directory NOT found: " .. config_path)
      print("Available config directories:")
      local config_glob = vim.fn.glob(path_to_jdtls .. "/config*", false, true)
      for _, config in ipairs(config_glob) do
        print("  - " .. config)
      end
    end
  else
    print("✗ JDTLS directory NOT found")
    print("Mason packages directory contents:")
    local packages = vim.fn.glob(path_to_mason_packages .. "/*", false, true)
    for _, pkg in ipairs(packages) do
      if vim.loop.fs_stat(pkg).type == "directory" then
        print("  - " .. vim.fn.fnamemodify(pkg, ":t"))
      end
    end
  end
  
  -- Check Java executable resolution
  print("\n--- Java Executable Check ---")
  local java_cmd = vim.fn.exepath("java")
  if java_cmd ~= "" then
    print("✓ Java found in PATH: " .. java_cmd)
  else
    print("✗ Java NOT found in PATH")
    print("Checking common Java locations:")
    local java_paths = {
      "/opt/homebrew/Cellar/openjdk@21/21.0.7/bin/java",
      "/opt/homebrew/bin/java",
      "/usr/local/bin/java",
      "/usr/bin/java",
    }
    for _, path in ipairs(java_paths) do
      if vim.loop.fs_stat(path) then
        print("  ✓ Found: " .. path)
        java_cmd = path
        break
      else
        print("  ✗ Not found: " .. path)
      end
    end
  end
  
  if java_cmd ~= "" then
    print("Will use Java: " .. java_cmd)
    -- Test Java execution
    local java_version = vim.fn.system(java_cmd .. " --version 2>&1")
    if vim.v.shell_error == 0 then
      print("✓ Java executable works:")
      print("  " .. vim.split(java_version, "\n")[1])
    else
      print("✗ Java executable failed to run")
    end
  else
    print("✗ No Java executable found")
  end
  
  -- Check current buffer
  print("\n--- Current Context ---")
  local current_file = vim.fn.expand("%:p")
  print("Current file: " .. current_file)
  
  -- Check if we're in a Java project
  local jdtls_setup = require("jdtls.setup")
  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
  local root_dir = jdtls_setup.find_root(root_markers)
  
  if root_dir then
    print("✓ Java project root found: " .. root_dir)
    print("Project markers found:")
    for _, marker in ipairs(root_markers) do
      local marker_path = root_dir .. "/" .. marker
      if vim.loop.fs_stat(marker_path) then
        print("  ✓ " .. marker)
      end
    end
  else
    print("✗ Java project root NOT found")
    print("Looking for markers: " .. table.concat(root_markers, ", "))
    print("Current directory: " .. vim.fn.getcwd())
  end
  
  -- Check workspace directory
  if root_dir then
    local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
    local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
    print("Workspace directory: " .. workspace_dir)
    if vim.loop.fs_stat(workspace_dir) then
      print("✓ Workspace directory exists")
    else
      print("! Workspace directory will be created")
    end
  end
  
  -- Check LSP clients
  print("\n--- LSP Status ---")
  local clients = vim.lsp.get_active_clients()
  if #clients == 0 then
    print("No active LSP clients")
  else
    print("Active LSP clients:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name .. " (id: " .. client.id .. ")")
    end
  end
  
  print("=== End Debug Information ===")
end

-- Command to manually start JDTLS
function M.start_jdtls()
  print("Manually starting JDTLS...")
  local jdtls_setup = require("pthodima.plugins.lsp.jdtls.setup")
  jdtls_setup.setup()
end

-- Test minimal JDTLS setup
function M.test_minimal_jdtls()
  print("Testing minimal JDTLS setup...")
  local minimal_setup = require("pthodima.plugins.lsp.jdtls.minimal-setup")
  minimal_setup.setup()
end

-- Setup debug commands
vim.api.nvim_create_user_command("JdtlsDebug", M.check_jdtls, { desc = "Debug JDTLS setup" })
vim.api.nvim_create_user_command("JdtlsStart", M.start_jdtls, { desc = "Manually start JDTLS" })
vim.api.nvim_create_user_command("JdtlsMinimal", M.test_minimal_jdtls, { desc = "Test minimal JDTLS setup" })

return M 