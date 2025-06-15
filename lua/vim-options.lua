vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set relativenumber")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

-- global keymaps
vim.keymap.set({"n", "v"}, "<C-s>", ":w<CR>", {silent = true}) -- save file with Ctrl+S
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>", {silent = true}) -- save file with Ctrl+S in insert mode
vim.keymap.set("n", "<leader>x", ":bd<CR>", {silent = true}) -- close current buffer
vim.keymap.set("i", "<C-h>", "<Left>", {silent = true}) -- move left in insert mode
vim.keymap.set("i", "<C-j>", "<Down>", {silent = true}) -- move down in insert mode
vim.keymap.set("i", "<C-k>", "<Up>", {silent = true}) -- move up in insert mode
vim.keymap.set("i", "<C-l>", "<Right>", {silent = true}) -- move right in insert mode

-- Fungsi untuk generate random ID
local function generate_id()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    math.randomseed(os.time())
    for i = 1, 12 do
        local rand = math.random(#chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id
end

-- Shortcut 1: HTML/Markdown region comment dengan auto-generated ID
vim.keymap.set('n', '<leader>hr', function()
    local id = generate_id()
    local lines = {
        '<!-- #region id="' .. id .. '" -->',
        '',
        '<!-- #endregion -->'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke baris kedua (kosong) dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
    vim.cmd('startinsert!')
end, { desc = 'Insert HTML region dengan auto ID' })

-- Shortcut 2: Python code block dengan auto-generated ID
vim.keymap.set('n', '<leader>py', function()
    local id = generate_id()
    local lines = {
        '```python id="' .. id .. '"',
        '',
        '```'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke baris kedua (kosong) dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python code block dengan auto ID' })

-- Optional: Shortcut untuk generate ID generic
vim.keymap.set('n', '<leader>id', function()
    local id = generate_id()
    vim.api.nvim_put({id}, 'c', false, true)
end, { desc = 'Generate dan insert random ID' })

-- Python Code Block Visual Selection Shortcuts
-- Tambahkan ke vim-options.lua atau buat file terpisah

-- Fungsi untuk mencari boundaries Python code block
local function find_python_block_boundaries()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    local python_start = nil
    local python_end = nil
    local in_python_block = false
    
    -- Cari dari atas ke bawah
    for i, line in ipairs(lines) do
        if line:match("^```python") then
            if i <= current_line then
                python_start = i
                in_python_block = true
            elseif python_start then
                -- Jika sudah ketemu start dan ini python block baru, stop
                break
            end
        elseif line:match("^```$") and python_start then
            if i > current_line and in_python_block then
                python_end = i
                break
            elseif i <= current_line then
                -- Reset jika closing block sebelum current line
                python_start = nil
                in_python_block = false
            end
        end
    end
    
    if python_start and python_end then
        return python_start, python_end
    else
        return nil, nil
    end
end

-- Fungsi untuk mencari boundaries kode (skip baris kosong di awal dan akhir)
local function find_code_boundaries(start_line, end_line)
    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line - 1, false)
    
    local code_start = start_line
    local code_end = end_line - 1
    
    -- Cari baris pertama yang ada kode (skip baris kosong di awal)
    for i, line in ipairs(lines) do
        if line:match("%S") then -- Ada non-whitespace character
            code_start = start_line + i - 1
            break
        end
    end
    
    -- Cari baris terakhir yang ada kode (skip baris kosong di akhir)
    for i = #lines, 1, -1 do
        if lines[i]:match("%S") then -- Ada non-whitespace character
            code_end = start_line + i - 1
            break
        end
    end
    
    return code_start, code_end
end

-- Shortcut 1: Visual select semua kode di Python block (tanpa baris kosong)
vim.keymap.set('n', '<leader>vp', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local code_start, code_end = find_code_boundaries(python_start, python_end)
    
    if code_start >= code_end then
        vim.notify("Tidak ada kode di dalam Python block", vim.log.levels.WARN)
        return
    end
    
    -- Pindah ke baris pertama kode
    vim.api.nvim_win_set_cursor(0, {code_start, 0})
    
    -- Masuk visual line mode dan select sampai baris terakhir
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {code_end, 0})
    
end, { desc = 'Visual select semua kode di Python block' })

-- Shortcut 2: Visual select semua konten Python block (termasuk baris kosong)
vim.keymap.set('n', '<leader>vP', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    -- Select dari baris setelah ```python sampai sebelum ```
    local content_start = python_start + 1
    local content_end = python_end - 1
    
    if content_start > content_end then
        vim.notify("Python block kosong", vim.log.levels.WARN)
        return
    end
    
    -- Pindah ke baris pertama konten
    vim.api.nvim_win_set_cursor(0, {content_start, 0})
    
    -- Masuk visual line mode dan select sampai baris terakhir konten
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {content_end, 0})
    
end, { desc = 'Visual select semua konten Python block (termasuk baris kosong)' })

-- Shortcut 3: Visual select Python block beserta boundaries (```python dan ```)
vim.keymap.set('n', '<leader>vB', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    -- Select dari ```python sampai ```
    vim.api.nvim_win_set_cursor(0, {python_start, 0})
    
    -- Masuk visual line mode dan select sampai closing ```
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {python_end, 0})
    
end, { desc = 'Visual select Python block beserta boundaries' })

-- Shortcut 4: Visual select current function/class di dalam Python block
vim.keymap.set('n', '<leader>vf', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, python_start, python_end - 1, false)
    
    local func_start = nil
    local func_end = nil
    local current_indent = nil
    
    -- Cari function/class definition sebelum current line
    for i = current_line - python_start, 1, -1 do
        local line = lines[i]
        if line:match("^%s*def ") or line:match("^%s*class ") then
            func_start = python_start + i - 1
            current_indent = #line:match("^%s*")
            break
        end
    end
    
    if not func_start then
        vim.notify("Tidak ditemukan function/class di atas kursor", vim.log.levels.WARN)
        return
    end
    
    -- Cari akhir function/class (baris dengan indent yang sama atau lebih kecil)
    for i = current_line - python_start + 1, #lines do
        local line = lines[i]
        if line:match("%S") then -- Ada non-whitespace
            local line_indent = #line:match("^%s*")
            if line_indent <= current_indent then
                func_end = python_start + i - 2 -- Baris sebelumnya
                break
            end
        end
    end
    
    -- Jika tidak ketemu, pakai sampai akhir block
    if not func_end then
        func_end = python_end - 1
    end
    
    -- Visual select function/class
    vim.api.nvim_win_set_cursor(0, {func_start, 0})
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {func_end, 0})
    
end, { desc = 'Visual select current function/class di Python block' })

-- Shortcut 5: Visual select current cell (antara # %%)
vim.keymap.set('n', '<leader>vc', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, python_start, python_end - 1, false)
    
    local cell_start = python_start + 1 -- Default ke awal block
    local cell_end = python_end - 1     -- Default ke akhir block
    
    -- Cari # %% sebelum current line
    for i = current_line - python_start, 1, -1 do
        local line = lines[i]
        if line:match("^%s*# %%") then
            cell_start = python_start + i
            break
        end
    end
    
    -- Cari # %% sesudah current line
    for i = current_line - python_start + 1, #lines do
        local line = lines[i]
        if line:match("^%s*# %%") then
            cell_end = python_start + i - 2
            break
        end
    end
    
    -- Cari boundaries kode dalam cell (skip baris kosong)
    local code_start, code_end = find_code_boundaries(cell_start, cell_end + 1)
    
    if code_start >= code_end then
        vim.notify("Tidak ada kode di cell ini", vim.log.levels.WARN)
        return
    end
    
    -- Visual select cell
    vim.api.nvim_win_set_cursor(0, {code_start, 0})
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {code_end, 0})
    
end, { desc = 'Visual select current Jupyter cell' })

-- Shortcut 6: Copy semua kode Python block ke clipboard
vim.keymap.set('n', '<leader>yp', function()
    local python_start, python_end = find_python_block_boundaries()
    
    if not python_start or not python_end then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local code_start, code_end = find_code_boundaries(python_start, python_end)
    
    if code_start >= code_end then
        vim.notify("Tidak ada kode di dalam Python block", vim.log.levels.WARN)
        return
    end
    
    -- Copy ke clipboard
    local lines = vim.api.nvim_buf_get_lines(0, code_start - 1, code_end, false)
    local content = table.concat(lines, '\n')
    vim.fn.setreg('+', content)
    
    vim.notify("Kode Python block telah disalin ke clipboard", vim.log.levels.INFO)
    
end, { desc = 'Copy semua kode Python block ke clipboard' })

-- Python Code Block Shortcuts
-- Tambahkan ke vim-options.lua atau buat file terpisah

-- Fungsi untuk cek apakah kursor berada di dalam python code block
local function is_in_python_block()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    local in_python_block = false
    local python_start = nil
    
    for i, line in ipairs(lines) do
        if line:match("^```python") then
            python_start = i
            if i < current_line then
                in_python_block = true
            end
        elseif line:match("^```$") and python_start then
            if i > current_line and in_python_block then
                return true, python_start
            end
            in_python_block = false
            python_start = nil
        end
    end
    
    return false, nil
end

-- Shortcut 1: Comment block
vim.keymap.set('n', '<leader>pc', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        '# ================================================================',
        '# ',
        '# ================================================================'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke baris kedua dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 2})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python comment block' })

-- Shortcut 2: Function definition
vim.keymap.set('n', '<leader>pf', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'def function_name():',
        '    """',
        '    Deskripsi function',
        '    """',
        '    pass'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke nama function dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row, 4})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python function definition' })

-- Shortcut 3: Class definition
vim.keymap.set('n', '<leader>pcl', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'class ClassName:',
        '    """',
        '    Deskripsi class',
        '    """',
        '    ',
        '    def __init__(self):',
        '        pass'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke nama class dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row, 6})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python class definition' })

-- Shortcut 4: Try-except block
vim.keymap.set('n', '<leader>pt', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'try:',
        '    ',
        'except Exception as e:',
        '    print(f"Error: {e}")'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke dalam try block dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 4})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python try-except block' })

-- Shortcut 5: For loop
vim.keymap.set('n', '<leader>pfor', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'for item in iterable:',
        '    '
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke 'item' dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row, 4})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python for loop' })

-- Shortcut 6: If statement
vim.keymap.set('n', '<leader>pif', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'if condition:',
        '    ',
        'else:',
        '    '
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke 'condition' dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row, 3})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python if-else statement' })

-- Shortcut 7: Import statements
vim.keymap.set('n', '<leader>pi', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'import numpy as np',
        'import pandas as pd',
        'import matplotlib.pyplot as plt',
        ''
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke baris setelah import dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 3, 0})
    vim.cmd('startinsert!')
end, { desc = 'Insert common Python imports' })

-- Shortcut 8: Print debug
vim.keymap.set('n', '<leader>pp', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        'print("Debug: ", )'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke dalam print dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row, 15})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python print debug' })

-- Shortcut 9: Docstring
vim.keymap.set('n', '<leader>pd', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        '"""',
        '',
        '"""'
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke dalam docstring dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
    vim.cmd('startinsert!')
end, { desc = 'Insert Python docstring' })

-- Shortcut 10: Cell separator (untuk Jupyter)
vim.keymap.set('n', '<leader>p%', function()
    local in_block, _ = is_in_python_block()
    if not in_block then
        vim.notify("Kursor tidak berada di dalam Python code block", vim.log.levels.WARN)
        return
    end
    
    local lines = {
        '# %%',
        ''
    }
    
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    
    -- Pindah ke baris setelah cell separator dan masuk insert mode
    vim.api.nvim_win_set_cursor(0, {row + 1, 0})
    vim.cmd('startinsert!')
end, { desc = 'Insert Jupyter cell separator' })
