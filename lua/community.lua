-- Optimized community.lua - Replace your current community.lua with this
-- Performance-focused: Remove redundant LSP plugins that conflict with gopls

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- Language packs (keep these)
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.golangci-lint" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.angular" },
  { import = "astrocommunity.pack.cpp" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.helm" },
  { import = "astrocommunity.pack.zig" },
  { import = "astrocommunity.pack.python" },

  -- LSP: Reduce to essential plugins only
  { import = "astrocommunity.lsp.actions-preview-nvim", enabled = true },
  { import = "astrocommunity.lsp.garbage-day-nvim", enabled = true }, -- This helps with memory
  -- DISABLED for performance: lsp-lens, lsp-signature, lspsaga (removed entirely)

  -- Git (keep these - they don't interfere with LSP)
  { import = "astrocommunity.git.blame-nvim", enabled = true },
  { import = "astrocommunity.git.diffview-nvim", enabled = true },
  { import = "astrocommunity.git.gitgraph-nvim", enabled = true },

  -- Bars and lines (minimal)
  { import = "astrocommunity.bars-and-lines.vim-illuminate", enabled = true },

  -- Code runner
  { import = "astrocommunity.code-runner.compiler-nvim", enabled = true },

  -- Colorschemes
  { import = "astrocommunity.colorscheme.catppuccin", enabled = true },

  -- Editing support (reduced set)
  { import = "astrocommunity.editing-support.zen-mode-nvim" },
  { import = "astrocommunity.editing-support.telescope-undo-nvim" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim", enabled = true },
  { import = "astrocommunity.editing-support.todo-comments-nvim", enabled = true },
  { import = "astrocommunity.editing-support.undotree", enabled = true },
  { import = "astrocommunity.editing-support.mini-splitjoin", enabled = true },
  -- DISABLED for performance:
  -- { import = "astrocommunity.editing-support.nvim-treesitter-context", enabled = false }, -- Resource heavy
  -- { import = "astrocommunity.editing-support.refactoring-nvim", enabled = false }, -- Can conflict with LSP

  -- Fuzzy finder
  { import = "astrocommunity.fuzzy-finder.telescope-zoxide", enabled = true },

  -- Programming language support
  { import = "astrocommunity.programming-language-support.csv-vim", enabled = true },
  { import = "astrocommunity.programming-language-support.nvim-jqx", enabled = true },

  -- Motion
  { import = "astrocommunity.motion.flash-nvim", enabled = true },
  { import = "astrocommunity.motion.harpoon", enabled = true },
  { import = "astrocommunity.motion.mini-move", enabled = true },
  { import = "astrocommunity.motion.mini-surround", enabled = true },

  -- Diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim", enabled = true },

  -- Debugging (minimal)
  { import = "astrocommunity.debugging.persistent-breakpoints-nvim", enabled = true },

  -- Test
  { import = "astrocommunity.test.neotest", enabled = true },
  { import = "astrocommunity.test.nvim-coverage", enabled = true },

  -- File explorer
  { import = "astrocommunity.file-explorer.oil-nvim", enabled = true },

  -- Comment
  { import = "astrocommunity.comment.mini-comment", enabled = true },

  -- Scrolling
  -- { import = "astrocommunity.scrolling.mini-animate", enabled = true },

  -- Note taking
  { import = "astrocommunity.note-taking.obsidian-nvim", enabled = true },

  -- Color
  { import = "astrocommunity.color.headlines-nvim", enabled = true },

  -- Terminal integration
  { import = "astrocommunity.terminal-integration.vim-tmux-navigator", enabled = true },

  -- Customizations
  {
    "catppuccin",
    opts = {
      integrations = {
        sandwich = false,
        noice = true,
        mini = true,
        leap = true,
        markdown = true,
        neotest = true,
        cmp = true,
        overseer = true,
        lsp_trouble = true,
        rainbow_delimiters = true,
      },
    },
  },

  -- Todo comments optimization
  {
    "folke/todo-comments.nvim",
    keys = {
      { "]t", mode = { "n" }, function() require("todo-comments").jump_next() end, desc = "Jump to next todo" },
      { "[t", mode = { "n" }, function() require("todo-comments").jump_prev() end, desc = "Jump to prev todo" },
      { "<leader>xs", "<CMD>TodoTelescope<CR>", desc = "Open Telescope todo picker" },
      { "<leader>xt", "<CMD>TodoTrouble<CR>", desc = "Open Telescope trouble" },
    },
  },

  -- Compiler
  {
    "Zeioth/compiler.nvim",
    keys = {
      { "<leader>co", "<cmd>CompilerOpen<cr>", desc = "Open compiler" },
      { "<leader>ct", "<cmd>CompilerToggleResults<cr>", desc = "Open compiler" },
    },
  },

  -- Coverage
  {
    "andythigpen/nvim-coverage",
    keys = {
      { "<leader>tl", "<cmd>CoverageLoad<cr>", desc = "Load coverage" },
      { "<leader>tj", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage Display" },
      { "<leader>ts", "<cmd>CoverageSummary<cr>", desc = "Toggle coverage Summary" },
    },
  },

  -- Obsidian optimization
  {
    "epwalsh/obsidian.nvim",
    opts = {
      ui = { enable = false },
    },
  },

  -- Java settings
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          format = {
            enabled = true,
            settings = {
              url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
              profile = "GoogleStyle",
            },
          },
        },
      },
    },
  },
}
