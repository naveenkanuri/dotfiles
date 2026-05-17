-- Go LSP tuning: gopls owns IDE features, golangci_lint_ls owns lint diagnostics.

local function center_after_jump()
  vim.defer_fn(function() vim.cmd "normal! zz" end, 100)
end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      opts.config = opts.config or {}

      local golangci_on_attach = opts.config.golangci_lint_ls and opts.config.golangci_lint_ls.on_attach
      opts.config.golangci_lint_ls = vim.tbl_deep_extend("force", opts.config.golangci_lint_ls or {}, {
        timeout = 30000,
        flags = {
          debounce_text_changes = 1000,
          allow_incremental_sync = true,
        },
        on_attach = function(client, bufnr)
          client.server_capabilities.semanticTokensProvider = nil
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          if golangci_on_attach then golangci_on_attach(client, bufnr) end
        end,
      })

      opts.config.gopls = vim.tbl_deep_extend("force", opts.config.gopls or {}, {
        settings = {
          gopls = {
            staticcheck = false, -- golangci_lint_ls provides lint diagnostics.
          },
        },
      })

      return opts
    end,
  },

  -- Performance optimizations
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}

      opts.autocmds.go_performance = {
        {
          event = "FileType",
          pattern = "go",
          callback = function()
            -- Disable expensive features for Go files
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.spell = false

            -- For large files, disable more features
            local line_count = vim.api.nvim_buf_line_count(0)
            if line_count > 1000 then
              vim.opt_local.cursorline = false
              vim.opt_local.relativenumber = false
            end
          end,
        },

        -- Auto-center when opening Go files
        {
          event = "BufWinEnter",
          pattern = "*.go",
          callback = function()
            vim.defer_fn(function()
              local line = vim.fn.line "."
              local total_lines = vim.fn.line "$"
              if line > (total_lines * 0.8) then vim.cmd "normal! zz" end
            end, 100)
          end,
        },
      }

      opts.autocmds.go_lsp_keymaps = {
        {
          event = "LspAttach",
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or client.name ~= "gopls" then return end

            local bufopts = { noremap = true, silent = true, buffer = args.buf }

            vim.keymap.set("n", "gd", function()
              vim.lsp.buf.definition()
              center_after_jump()
            end, vim.tbl_extend("force", bufopts, { desc = "Go to definition (centered)" }))

            vim.keymap.set("n", "gr", function()
              vim.lsp.buf.references()
              center_after_jump()
            end, vim.tbl_extend("force", bufopts, { desc = "Find references (centered)" }))

            vim.keymap.set("n", "gD", function()
              vim.lsp.buf.declaration()
              center_after_jump()
            end, vim.tbl_extend("force", bufopts, { desc = "Go to declaration (centered)" }))

            vim.keymap.set("n", "gi", function()
              vim.lsp.buf.implementation()
              center_after_jump()
            end, vim.tbl_extend("force", bufopts, { desc = "Go to implementation (centered)" }))
          end,
        },
      }

      opts.commands = opts.commands or {}
      opts.commands.GoLintDebug = {
        function()
          print "=== Go LSP Status ==="

          local golangci_clients = vim.lsp.get_clients { name = "golangci_lint_ls" }
          local gopls_clients = vim.lsp.get_clients { name = "gopls" }

          print("golangci_lint_ls clients: " .. #golangci_clients)
          print("gopls clients: " .. #gopls_clients)

          for _, client in ipairs(golangci_clients) do
            print "golangci_lint_ls:"
            print("  Root: " .. (client.config.root_dir or "unknown"))
            print("  Status: " .. (client.is_stopped() and "STOPPED" or "RUNNING"))
            print("  Buffers: " .. vim.tbl_count(client.attached_buffers))
          end

          for _, client in ipairs(gopls_clients) do
            print "gopls:"
            print("  Root: " .. (client.config.root_dir or "unknown"))
            print("  Status: " .. (client.is_stopped() and "STOPPED" or "RUNNING"))
            print("  Settings: " .. vim.inspect(client.config.settings))
          end

          -- Check config file
          local config_files = { ".golangci.yaml", ".golangci.yml" }
          local found_config = false
          for _, file in ipairs(config_files) do
            if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. file) == 1 then
              print("Found " .. file)
              found_config = true
              break
            end
          end
          if not found_config then print "No golangci config found" end
        end,
        desc = "Debug Go LSP setup",
      }

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>gD"] = { "<Cmd>GoLintDebug<CR>", desc = "Debug Go LSP" }

      return opts
    end,
  },
}
