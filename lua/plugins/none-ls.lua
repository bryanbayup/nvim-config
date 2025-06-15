return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        -- Hanya tinggalkan sumber yang tidak berhubungan dengan Python
        null_ls.builtins.formatting.stylua,
      }
    })
    -- Pemetaan kunci untuk format sudah diatur oleh lspconfig,
    -- jadi baris ini bisa tetap ada atau dipindahkan ke sana.
    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
