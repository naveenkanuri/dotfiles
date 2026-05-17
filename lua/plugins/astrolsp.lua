---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true, -- enable/disable codelens refresh on start
      inlay_hints = false, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    formatting = {
      format_on_save = {
        enabled = true,
        allow_filetypes = { "go", "lua", "rust" },
      },
      disabled = { "golangci_lint_ls" },
      timeout_ms = 1000,
    },
    mappings = {
      n = {
        gl = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" },
        gp = { function() vim.diagnostic.jump { count = -1 } end, desc = "Previous diagnostic" },
        gn = { function() vim.diagnostic.jump { count = 1 } end, desc = "Next diagnostic" },
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
  },
}
