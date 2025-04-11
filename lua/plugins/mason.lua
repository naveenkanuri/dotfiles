--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Mason plugins

---@type LazySpec
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        -- Core
        "lua_ls", -- Lua
        "jsonls", -- JSON
        "marksman", -- Markdown
        "textlsp", -- Plain text (optional, experimental)

        -- Golang
        "gopls", -- Go

        -- Java
        "jdtls", -- Java

        -- Web (HTML / JS / TS / CSS)
        "html", -- HTML
        "cssls", -- CSS

        -- Rust
        "rust_analyzer", -- Rust

        -- C / C++
        "clangd", -- C/C++

        -- Zig
        "zls", -- Zig

        -- Dockerfile
        "dockerls",
        -- add more arguments for adding more language servers
      })
    end,
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        -- General
        "prettier", -- for formatting JS, HTML, Markdown, JSON, etc.
        "stylua", -- for Lua
        "markdownlint", -- linter for Markdown
        "jsonlint", -- linter for JSON
        "misspell", -- spell checker for plaintext/code comments
        "checkmake", -- for Makefiles

        -- Golang
        "golangci-lint", -- linter for Go
        "gofumpt", -- stricter gofmt
        "goimports", -- go import organizer
        "golines", -- formatter for long Go lines

        -- Java
        "checkstyle", -- Java linter (ensure you have config if used)
        "google_java_format", -- formatter for Java

        -- HTML / JS / Web
        "eslint_d", -- fast JS/TS linter
        "stylelint", -- CSS/SCSS/Less linter

        -- Shell / misc
        "shellcheck", -- bash linter
        "shfmt", -- shell script formatter

        -- C / C++
        "clang_format", -- Formatter for C/C++
        "cpplint", -- Linter for C/C++

        -- Zig
        "zigfmt", -- Zig formatter

        -- docker
        "hadolint",
        -- add more arguments for adding more null-ls sources
      })
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        -- Scripting & general
        "python", -- Python debugger (debugpy)

        -- Go
        "go", -- Go debugger (delve)

        -- Rust
        "codelldb", -- Rust/C++ via CodeLLDB

        -- Java
        "java-debug-adapter", -- Java debugger (requires jdtls integration)

        -- C / C++
        "cppdbg", -- Microsoft C++ debugger

        -- JavaScript / TypeScript
        "js", -- DAP for JS/TS (based on vscode-js-debug)

        -- Zig (uses codelldb or lldb-vscode generally)
        "codelldb", -- covers Zig too
        -- add more arguments for adding more debuggers
      })
    end,
  },
}
