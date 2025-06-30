local M = {}

-- Get the current Java file name without extension
local function get_java_class_name()
  local filename = vim.fn.expand("%:t")
  if not filename:match("%.java$") then
    vim.notify("Current file is not a Java file", vim.log.levels.WARN)
    return nil
  end
  return filename:gsub("%.java$", "")
end

-- Get the project root directory
local function get_project_root()
  local jdtls_setup = require("jdtls.setup")
  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".project", ".classpath" }
  return jdtls_setup.find_root(root_markers) or vim.fn.getcwd()
end

-- Build classpath including external JARs
local function build_classpath(root_dir)
  local classpath = { "." }
  
  -- Add all JARs in the root directory
  local jar_files = vim.fn.glob(root_dir .. "/*.jar", false, true)
  for _, jar in ipairs(jar_files) do
    table.insert(classpath, jar)
  end
  
  -- Add common JAR locations
  local common_jars = {
    root_dir .. "/lib/*.jar",
    root_dir .. "/libs/*.jar",
    root_dir .. "/target/dependency/*.jar"
  }
  
  for _, pattern in ipairs(common_jars) do
    local jars = vim.fn.glob(pattern, false, true)
    for _, jar in ipairs(jars) do
      table.insert(classpath, jar)
    end
  end
  
  return table.concat(classpath, ":")
end

-- Run the current Java file
function M.run_current_file()
  local class_name = get_java_class_name()
  if not class_name then
    return
  end
  
  local root_dir = get_project_root()
  local classpath = build_classpath(root_dir)
  local current_file = vim.fn.expand("%:p")
  
  -- Save the file first
  vim.cmd("write")
  
  -- Create a terminal command
  local cmd = string.format(
    "cd '%s' && javac -cp '%s' '%s' && java -cp '%s' %s",
    root_dir,
    classpath,
    current_file,
    classpath,
    class_name
  )
  
  -- Open a terminal and run the command
  vim.cmd("botright split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

-- Find and run a main class in the project
function M.run_main_class()
  local root_dir = get_project_root()
  local classpath = build_classpath(root_dir)
  
  -- Look for Java files with main methods
  local java_files = vim.fn.glob(root_dir .. "/**/*.java", false, true)
  local main_classes = {}
  
  for _, file in ipairs(java_files) do
    local content = vim.fn.readfile(file)
    for _, line in ipairs(content) do
      if line:match("public%s+static%s+void%s+main%s*%(") then
        local relative_path = file:sub(#root_dir + 2)  -- Remove root_dir prefix
        local class_name = relative_path:gsub("%.java$", ""):gsub("/", ".")
        table.insert(main_classes, { file = file, class = class_name })
        break
      end
    end
  end
  
  if #main_classes == 0 then
    vim.notify("No main classes found in project", vim.log.levels.WARN)
    return
  elseif #main_classes == 1 then
    local main_class = main_classes[1].class
    local cmd = string.format("cd '%s' && java -cp '%s' %s", root_dir, classpath, main_class)
    vim.cmd("botright split")
    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")
  else
    -- Multiple main classes, let user choose
    local choices = {}
    for i, main_class in ipairs(main_classes) do
      table.insert(choices, string.format("%d. %s", i, main_class.class))
    end
    
    vim.ui.select(choices, {
      prompt = "Select main class to run:",
    }, function(choice, idx)
      if choice and idx then
        local main_class = main_classes[idx].class
        local cmd = string.format("cd '%s' && java -cp '%s' %s", root_dir, classpath, main_class)
        vim.cmd("botright split")
        vim.cmd("terminal " .. cmd)
        vim.cmd("startinsert")
      end
    end)
  end
end

-- Compile all Java files and run the current class
function M.compile_and_run()
  local class_name = get_java_class_name()
  if not class_name then
    return
  end
  
  local root_dir = get_project_root()
  local classpath = build_classpath(root_dir)
  
  -- Save all modified buffers
  vim.cmd("wall")
  
  -- Compile all Java files in the project
  local java_files = vim.fn.glob(root_dir .. "/**/*.java", false, true)
  local files_str = table.concat(java_files, " ")
  
  local cmd = string.format(
    "cd '%s' && javac -cp '%s' %s && java -cp '%s' %s",
    root_dir,
    classpath,
    files_str,
    classpath,
    class_name
  )
  
  vim.cmd("botright split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

-- Quick run command for the current file (without terminal split)
function M.quick_run()
  local class_name = get_java_class_name()
  if not class_name then
    return
  end
  
  local root_dir = get_project_root()
  local classpath = build_classpath(root_dir)
  local current_file = vim.fn.expand("%:p")
  
  vim.cmd("write")
  
  local cmd = string.format(
    "cd '%s' && javac -cp '%s' '%s' && java -cp '%s' %s",
    root_dir,
    classpath,
    current_file,
    classpath,
    class_name
  )
  
  -- Run in background and show output in quickfix
  vim.fn.system(cmd)
  local output = vim.v.shell_error == 0 and "Compilation and execution successful" or "Error occurred"
  vim.notify(output, vim.v.shell_error == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
end

return M 