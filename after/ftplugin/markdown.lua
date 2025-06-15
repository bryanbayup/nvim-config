-- Activate Quarto LSP features for Markdown
require("quarto").activate()

-- Optionally: Activate Otter for Python code cells, with completion and diagnostics
require("otter").activate({ "python" }, true, true, nil)

-- Keymaps for Quarto/Molten (customize to taste)
local runner = require("quarto.runner")
vim.keymap.set("n", "<localleader>rc", runner.run_cell,  { desc = "Run cell", silent = true })
vim.keymap.set("n", "<localleader>ra", runner.run_above, { desc = "Run cell and above", silent = true })
vim.keymap.set("n", "<localleader>rA", runner.run_all,   { desc = "Run all cells", silent = true })
vim.keymap.set("n", "<localleader>rl", runner.run_line,  { desc = "Run line", silent = true })
vim.keymap.set("v", "<localleader>r",  runner.run_range, { desc = "Run visual range", silent = true })

vim.keymap.set("n", "<localleader>mi", ":MoltenInit<CR>",     { desc = "Molten Init Kernel", silent = true })
vim.keymap.set("n", "<localleader>ml", ":MoltenEvaluateLine<CR>", { desc = "Molten Evaluate Line", silent = true })
vim.keymap.set("v", "<localleader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv<ESC>", { desc = "Molten Evaluate Visual", silent = true })
vim.keymap.set("n", "<localleader>mh", ":MoltenHideOutput<CR>", { desc = "Molten Hide Output", silent = true })
vim.keymap.set("n", "<localleader>mo", ":noautocmd MoltenEnterOutput<CR>", { desc = "Molten Enter Output", silent = true })
vim.keymap.set("n", "<localleader>rr", ":MoltenReevaluateCell<CR>", { desc = "Re-evaluate cell", silent = true })

-- [Optional] Enable render-markdown.nvim on demand
vim.api.nvim_create_user_command("RenderMarkdownToggle", function()
  require("render-markdown").toggle()
end, {})

