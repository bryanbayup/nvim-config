local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.setup = {
  obsidian_dirs = {
    mainnotes = "/home/bayu/Documents/personal/vaults/notes",
    generalpath = "/home/bayu/Documents/personal/vaults",
  },
}

require("utils")
require("vim-options")
require("lazy").setup("plugins")

local schemes = { "kanagawa", "nightfox", "catppuccin-mocha" }
local current = 1

vim.keymap.set("n", "t", function()
  current = current % #schemes + 1
  local scheme = schemes[current]
  vim.cmd.colorscheme(scheme)
  print("Colorscheme switched to " .. scheme)
end, { desc = "Switch colorscheme" })

vim.g.python3_host_prog=vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
vim.g.loaded_python3_provider = nil
vim.cmd('runtime! plugin/rplugin.vim')
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"

local jupyter_ipynb_template = [[
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    ""
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "jupytext": {
   "main_language": "python",
   "text_representation": {
    "extension": ".md",
    "format_name": "markdown",
    "format_version": "1.3",
    "jupytext_version": "1.17.2"
   }
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
]]

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.ipynb",
  callback = function()
    if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(jupyter_ipynb_template, "\n"))
      -- Auto save supaya file sudah valid sebelum autocommand lain berjalan
      vim.cmd("write")
    end
  end,
})


-- Auto-import Jupyter output when opening *.ipynb
local imb = function(e)
  vim.schedule(function()
    -- Skip jika file kosong atau tidak valid JSON
    local f = io.open(e.file, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    if not content or content == "" then return end
    local ok_json, data = pcall(vim.json.decode, content)
    if not ok_json or not data or not data.metadata then return end

    local kernels = vim.fn.MoltenAvailableKernels()
    local kernel_name = data.metadata.kernelspec and data.metadata.kernelspec.name
    if not kernel_name or not vim.tbl_contains(kernels, kernel_name) then
      kernel_name = nil
      local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
      if venv ~= nil then
        kernel_name = string.match(venv, "/.+/(.+)")
      end
    end
    if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
      vim.cmd(("MoltenInit %s"):format(kernel_name))
    end
    vim.cmd("MoltenImportOutput")
  end)
end

vim.api.nvim_create_autocmd("BufAdd", {
  pattern = { "*.ipynb" },
  callback = imb,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.ipynb" },
  callback = function(e)
    if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
      imb(e)
    end
  end,
})
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.ipynb" },
  callback = function()
    if require("molten.status").initialized() == "Molten" then
      vim.cmd("MoltenExportOutput!")
    end
  end,
})
