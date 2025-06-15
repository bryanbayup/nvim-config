return {
  "benlubas/molten-nvim",
  version = "^1.0.0",
  lazy = false,
  build = ":UpdateRemotePlugins",
  init = function()
    vim.g.molten_image_provider = "image.nvim"
    vim.g.molten_output_win_max_height = 12
    vim.g.molten_virt_text_output = true
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_virt_text_max_lines = 12
    -- recommended: don't auto open output, open with <localleader>os instead
    vim.g.molten_auto_open_output = false
    vim.g.molten_wrap_output = true
  end,
}

