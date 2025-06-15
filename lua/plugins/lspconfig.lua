local LspConfig = {}
LspConfig.__index = LspConfig

function LspConfig:initialize()
    local config = {
        clients = {},
        attached_buffers = {},
        error_log = {},
        initialized = false
    }
    setmetatable(config, LspConfig)
    return config
end

function LspConfig:validateDependencies()
    local required_modules = {
        "cmp_nvim_lsp",
        "lspconfig", 
        "lspconfig.util"
    }
    for _, module in ipairs(required_modules) do
        local ok, _ = pcall(require, module)
        if not ok then
            error("Missing required module: " .. module)
            return false
        end
    end
    return true
end

function LspConfig:logError(client_name, error_message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    table.insert(self.error_log, {
        client = client_name,
        error = error_message,
        timestamp = timestamp
    })
    vim.notify(
        string.format("[LSP Error] %s: %s", client_name, error_message), 
        vim.log.levels.ERROR
    )
end

function LspConfig:trackClientAttachment(client_id, buffer_id)
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        self:logError("unknown", "Failed to get client by ID: " .. client_id)
        return false
    end
    self.clients[client.name] = self.clients[client.name] or {}
    self.clients[client.name][buffer_id] = client_id
    self.attached_buffers[buffer_id] = self.attached_buffers[buffer_id] or {}
    table.insert(self.attached_buffers[buffer_id], {
        client_name = client.name,
        client_id = client_id,
        attached_at = os.time()
    })
    return true
end

function LspConfig:preventDuplicateClients(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
        self:logError("duplicate_prevention", "Client not found: " .. args.data.client_id)
        return
    end
    local buffer_id = args.buf
    local existing_clients = vim.lsp.get_clients({ 
        bufnr = buffer_id, 
        name = client.name 
    })
    if #existing_clients > 1 then
        -- Keep the first client, stop duplicates
        for i = 2, #existing_clients do
            local duplicate_client = existing_clients[i]
            local success = pcall(vim.lsp.stop_client, duplicate_client.id)
            if success then
                vim.notify(
                    string.format("Stopped duplicate %s client (ID: %d)", 
                        client.name, duplicate_client.id), 
                    vim.log.levels.INFO
                )
            else
                self:logError(client.name, "Failed to stop duplicate client: " .. duplicate_client.id)
            end
        end
    end
    self:trackClientAttachment(client.id, buffer_id)
end

function LspConfig:setupCapabilities()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    -- Modern: offsetEncoding
    capabilities.offsetEncoding = { "utf-16" }
    -- Compatibility (untuk plugin2 lain, seperti otter/quarto)
    capabilities.general = capabilities.general or {}
    capabilities.general.positionEncodings = { "utf-16" }
    return capabilities
end

function LspConfig:getRootDirectory(fname)
    local util = require("lspconfig.util")
    local root_patterns = {
        "pyproject.toml", "setup.py", "setup.cfg",
        "requirements.txt", "Pipfile", "pyrightconfig.json",
        "environment.yml", "conda.yaml", ".git"
    }
    local root_dir = util.root_pattern(unpack(root_patterns))(fname)
    if not root_dir then
        root_dir = util.path.dirname(fname)
        -- Hilangkan notifikasi spam root (biarkan diam saja)
    end
    return root_dir
end

function LspConfig:setupRuffLsp(capabilities)
    local lspconfig = require("lspconfig")
    local ruff_config = {
        capabilities = capabilities,
        single_file_support = true,
        root_dir = function(fname)
            return self:getRootDirectory(fname)
        end,
        init_options = {
            settings = {
                logLevel = "error",    -- Ganti 'debug' jika debugging ruff
            }
        },
        filetypes = { "python" },
        on_attach = function(client, bufnr)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
        end
    }
    local success, error_msg = pcall(lspconfig.ruff.setup, ruff_config)
    if not success then
        self:logError("ruff", "Setup failed: " .. error_msg)
    end
end

function LspConfig:setupPyrightLsp(capabilities)
    local lspconfig = require("lspconfig")
    local pyright_config = {
        capabilities = capabilities,
        single_file_support = true,
        root_dir = function(fname)
            return self:getRootDirectory(fname)
        end,
        settings = {
            pyright = { disableOrganizeImports = true },
            python = {
                analysis = {
                    ignore = { '*' }, -- Ruff handle linting
               --     typeCheckingMode = "off", -- Bisa 'basic' jika mau type check, atau 'off' jika mypy eksternal
                }
            }
        },
        filetypes = { "python" },
        on_attach = function(client, bufnr) end
    }
    local success, error_msg = pcall(lspconfig.pyright.setup, pyright_config)
    if not success then
        self:logError("pyright", "Setup failed: " .. error_msg)
    end
end

function LspConfig:setupLuaLsp(capabilities)
    local lspconfig = require("lspconfig")
    local lua_config = {
        capabilities = capabilities,
        settings = {
            Lua = {
                runtime = { version = 'LuaJIT' },
                diagnostics = { globals = { 'vim' } },
                workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                },
                telemetry = { enable = false },
            }
        }
    }
    local success, error_msg = pcall(lspconfig.lua_ls.setup, lua_config)
    if not success then
        self:logError("lua_ls", "Setup failed: " .. error_msg)
    end
end

function LspConfig:setupAutocmds()
    -- Prevent duplicate client attachments
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup('robust_prevent_duplicates', { clear = true }),
        callback = function(args)
            self:preventDuplicateClients(args)
        end,
        desc = 'LSP: Robust duplicate client prevention',
    })
    -- Fix position encoding conflicts
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup('robust_fix_encoding', { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and (client.name == 'ruff' or client.name == 'pyright') then
                client.offset_encoding = 'utf-16'
            end
        end,
        desc = 'LSP: Fix position encoding conflicts',
    })
    -- Matikan hover Ruff (jaga-jaga redundancy)
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.name == "ruff" then
                client.server_capabilities.hoverProvider = false
            end
        end,
        desc = 'LSP: Disable hover from Ruff',
    })
    -- Hilangkan spam notifikasi attach/error (biarkan hanya error)
end

function LspConfig:setupKeymaps()
    local keymap_configs = {
        { "n", "gD", vim.lsp.buf.declaration, "Go to declaration" },
        { "n", "gd", vim.lsp.buf.definition, "Go to definition" },
        { "n", "K", vim.lsp.buf.hover, "Show hover information" },
        { "n", "gi", vim.lsp.buf.implementation, "Go to implementation" },
        { "n", "<leader>ca", vim.lsp.buf.code_action, "Code actions" },
        { "n", "<C-k>", vim.lsp.buf.signature_help, "Signature help" },
        { "n", "<space>rn", vim.lsp.buf.rename, "Rename symbol" },
        { "n", "gr", vim.lsp.buf.references, "Show references" },
        { "n", "<space>e", vim.diagnostic.open_float, "Show line diagnostics" },
        { "n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic" },
        { "n", "]d", vim.diagnostic.goto_next, "Next diagnostic" },
        { "n", "<space>q", vim.diagnostic.setloclist, "Diagnostics to location list" },
    }
    for _, config in ipairs(keymap_configs) do
        local mode, key, func, desc = unpack(config)
        vim.keymap.set(mode, key, func, { 
            desc = desc,
            silent = true,
            noremap = true 
        })
    end
end

function LspConfig:setup()
    if not self:validateDependencies() then
        return false
    end
    local capabilities = self:setupCapabilities()
    self:setupLuaLsp(capabilities)
    self:setupRuffLsp(capabilities)
    self:setupPyrightLsp(capabilities)
    self:setupAutocmds()
    self:setupKeymaps()
    self.initialized = true
    -- Hilangkan notifikasi spam init
    -- vim.notify("LSP Configuration initialized successfully", vim.log.levels.INFO)
    return true
end

-- Main configuration return
return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "ruff", "pyright" },
                automatic_installation = false,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local lsp_config = LspConfig:initialize()
            lsp_config:setup()
            -- Minimalkan log level (hanya error)
            vim.lsp.set_log_level("error")
        end,
    },
}

