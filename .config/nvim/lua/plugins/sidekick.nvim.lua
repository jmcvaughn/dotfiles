return {
  "folke/sidekick.nvim",
  keys = {
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle({ name = "codex", focus = true })
      end,
      desc = "Sidekick Toggle Codex",
    },
  },
}
