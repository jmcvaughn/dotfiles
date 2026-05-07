return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Bash
        "bash-language-server",
        "shellcheck",

        -- Markdown
        "rumdl",
      },
    },
  },
}
