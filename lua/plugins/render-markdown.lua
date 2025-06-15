return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "echasnovski/mini.nvim", -- or "nvim-tree/nvim-web-devicons"
  },
  ft = { "markdown", "vimwiki" }, -- add "quarto" if desired
  opts = {
    -- Any options you want to override
  },
  config = function(_, opts)
    require("render-markdown").setup(opts or {})
    vim.opt.conceallevel = 2
  end,
}

