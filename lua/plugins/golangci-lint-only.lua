-- Ultra-minimal gopls configuration for v0.19.1
-- This only configures what we absolutely need

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      opts.config = opts.config or {}

      -- Configure golangci_lint_ls (this is what actually provides LSP features)
      opts.config.golangci_lint_ls = {
        timeout = 30000,
        flags = {
          debounce_text_changes = 1000,
          allow_incremental_sync = true,
        },
        on_attach = function(client, bufnr)
          -- Performance: disable expensive features
          client.server_capabilities.semanticTokensProvider = nil
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false

          -- Set up keymaps with auto-centering
          local bufopts = { noremap = true, silent = true, buffer = bufnr }

          vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
            vim.defer_fn(function() vim.cmd "normal! zz" end, 100)
          end, vim.tbl_extend("force", bufopts, { desc = "Go to definition (centered)" }))

          vim.keymap.set("n", "gr", function()
            vim.lsp.buf.references()
            vim.defer_fn(function() vim.cmd "normal! zz" end, 100)
          end, vim.tbl_extend("force", bufopts, { desc = "Find references (centered)" }))

          vim.keymap.set("n", "gD", function()
            vim.lsp.buf.declaration()
            vim.defer_fn(function() vim.cmd "normal! zz" end, 100)
          end, vim.tbl_extend("force", bufopts, { desc = "Go to declaration (centered)" }))

          vim.keymap.set("n", "gi", function()
            vim.lsp.buf.implementation()
            vim.defer_fn(function() vim.cmd "normal! zz" end, 100)
          end, vim.tbl_extend("force", bufopts, { desc = "Go to implementation (centered)" }))

          vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        end,
      }

      -- DON'T configure gopls directly - let golangci_lint_ls handle it
      -- This prevents configuration conflicts

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

      -- Debug command
      opts.commands = opts.commands or {}
      opts.commands.GoLintDebug = {
        function()
          print "=== Go LSP Status ==="

          local golangci_clients = vim.lsp.get_clients { name = "golangci_lint_ls" }
          local gopls_clients = vim.lsp.get_clients { name = "gopls" }

          print("golangci_lint_ls clients: " .. #golangci_clients)
          print("gopls clients: " .. #gopls_clients)

          for _, client in ipairs(golangci_clients) do
            print "✅ golangci_lint_ls:"
            print("  Root: " .. (client.config.root_dir or "unknown"))
            print("  Status: " .. (client.is_stopped() and "STOPPED" or "RUNNING"))
            print("  Buffers: " .. vim.tbl_count(client.attached_buffers))
          end

          for _, client in ipairs(gopls_clients) do
            print "ℹ️  gopls (internal):"
            print("  Root: " .. (client.config.root_dir or "unknown"))
            print("  Status: " .. (client.is_stopped() and "STOPPED" or "RUNNING"))
            print("  Settings: " .. vim.inspect(client.config.settings))
          end

          -- Check config file
          local config_files = { ".golangci.yaml", ".golangci.yml" }
          local found_config = false
          for _, file in ipairs(config_files) do
            if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. file) == 1 then
              print("✅ Found " .. file)
              found_config = true
              break
            end
          end
          if not found_config then print "⚠️  No golangci config found" end
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
