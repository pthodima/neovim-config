return {
   "oclay1st/gradle.nvim",
   cmd = { "Gradle", "GradleExec", "GradleInit" },
   dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
   },
   opts = {
    gradle_executable = "./gradlew",
  }, -- options, see default configuration
   keys = { { "<Leader>G", "<cmd>Gradle<cr>", desc = "Gradle" } },
}
