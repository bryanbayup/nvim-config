return {
  {
    "rebelot/kanagawa.nvim",
    config = function()
      require("kanagawa").setup()
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    config = function()
      require("nightfox").setup()
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup()
    end,
  },
}

