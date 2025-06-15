return {
  "quarto-dev/quarto-nvim",
  lazy = false,
  ft = { "quarto", "markdown" },
  config = function()
    require("quarto").setup({
      lspFeatures = {
        enabled = true,
        chunks = "all",
        languages = { "r", "python", "julia", "bash", "html" },
        diagnostics = {
          enabled = true,
          triggers = { "BufWritePost" },
        },
        completion = {
          enabled = true,
        },
      },
      codeRunner = {
        enabled = true,
        default_method = "molten",
      },
    })
  end,
  dependencies = {
    "jmbuhr/otter.nvim",
    opts = {},
  },
}

