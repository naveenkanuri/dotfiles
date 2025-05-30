-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

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
  -- { import = "astrocommunity.pack.sql" },
  -- lsp
  -- { import = "astrocommunity.lsp.coc-nvim", enabled = true },
  { import = "astrocommunity.lsp.actions-preview-nvim", enabled = true },
  { import = "astrocommunity.lsp.delimited-nvim", enabled = false },
  { import = "astrocommunity.lsp.garbage-day-nvim", enabled = true },
  { import = "astrocommunity.lsp.lsp-lens-nvim", enabled = true },
  { import = "astrocommunity.lsp.lsp-signature-nvim", enabled = true },
  { import = "astrocommunity.lsp.lsplinks-nvim", enabled = true },
  { import = "astrocommunity.lsp.lspsaga-nvim", enabled = true },
  -- git
  { import = "astrocommunity.git.blame-nvim", enabled = true },
  { import = "astrocommunity.git.diffview-nvim", enabled = true },
  { import = "astrocommunity.git.gitgraph-nvim", enabled = true },
  -- bars-and-lines
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim", enabled = false },
  { import = "astrocommunity.bars-and-lines.dropbar-nvim", enabled = false },
  -- code-runner
  { import = "astrocommunity.code-runner.compiler-nvim", enabled = true },
  -- completion
  -- { import = "astrocommunity.completion.copilot-lua" },
  -- colorschemes
  { import = "astrocommunity.colorscheme.everforest", enabled = false },
  { import = "astrocommunity.colorscheme.catppuccin", enabled = true },
  -- editing-support
  -- { import = "astrocommunity.editing-support.treesj" },
  { import = "astrocommunity.editing-support.zen-mode-nvim" },
  { import = "astrocommunity.editing-support.telescope-undo-nvim" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim", enabled = true },
  { import = "astrocommunity.editing-support.todo-comments-nvim", enabled = true },
  { import = "astrocommunity.editing-support.mini-splitjoin", enabled = true },
  -- { import = "astrocommunity.editing-support.multicursors-nvim", enabled = true },
  { import = "astrocommunity.editing-support.multiple-cursors-nvim", enabled = true },
  { import = "astrocommunity.editing-support.undotree", enabled = true },
  { import = "astrocommunity.editing-support.nvim-treesitter-context", enabled = true },
  { import = "astrocommunity.editing-support.refactoring-nvim", enabled = true },
  -- fuzzy-finder
  { import = "astrocommunity.fuzzy-finder.telescope-zoxide", enabled = true },
  -- programming-language-support
  { import = "astrocommunity.programming-language-support.csv-vim", enabled = true },
  { import = "astrocommunity.programming-language-support.nvim-jqx", enabled = true },
  { import = "astrocommunity.programming-language-support.rest-nvim", enabled = false },
  -- motions
  { import = "astrocommunity.motion.flash-nvim", enabled = true },
  { import = "astrocommunity.motion.harpoon", enabled = true },
  { import = "astrocommunity.motion.mini-move", enabled = true },
  { import = "astrocommunity.motion.mini-surround", enabled = true },
  { import = "astrocommunity.motion.nvim-spider", enabled = true },
  -- diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim", enabled = true },
  -- debugging
  { import = "astrocommunity.debugging.persistent-breakpoints-nvim", enabled = true },
  { import = "astrocommunity.debugging.nvim-dap-virtual-text", enabled = true },
  -- scrolling
  { import = "astrocommunity.scrolling.mini-animate", enabled = true },
  -- markdown-preview-nvim
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim", enabled = true },
  -- syntax
  { import = "astrocommunity.syntax.hlargs-nvim", enabled = true },
  -- test
  { import = "astrocommunity.test.neotest", enabled = true },
  { import = "astrocommunity.test.nvim-coverage", enabled = true },
  -- workflow
  { import = "astrocommunity.workflow.hardtime-nvim", enabled = false },
  -- file-explorer
  { import = "astrocommunity.file-explorer.oil-nvim", enabled = true },
  -- bars-and-lines
  { import = "astrocommunity.bars-and-lines.vim-illuminate", enabled = true },
  -- comment
  { import = "astrocommunity.comment.mini-comment", enabled = true },
  -- note-taking
  { import = "astrocommunity.note-taking.obsidian-nvim", enabled = true },
  -- color
  { import = "astrocommunity.color.headlines-nvim", enabled = true },
  { import = "astrocommunity.color.modes-nvim", enabled = true },
  -- terminal-integration
  { import = "astrocommunity.terminal-integration.vim-tmux-navigator", enabled = true },
  { -- further customize the options set by the community
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
  -- { -- further customize the options set by the community
  --   "zbirenbaum/copilot.lua",
  --   opts = {
  --     suggestion = {
  --       keymap = {
  --         accept = "<C-l>",
  --         accept_word = false,
  --         accept_line = false,
  --         next = "<C-.>",
  --         prev = "<C-,>",
  --         dismiss = "<C/>",
  --       },
  --     },
  --   },
  -- },
  -- {
  --   "Wansmer/treesj",
  --   keys = { { "<leader>J", "<CMD>TSJToggle<CR>", desc = "Toggle Treesitter Toggle" } },
  -- },
  {
    "folke/todo-comments.nvim",
    keys = {
      { "]t", mode = { "n" }, function() require("todo-comments").jump_next() end, desc = "Jump to next todo" },
      { "[t", mode = { "n" }, function() require("todo-comments").jump_prev() end, desc = "Jump to prev todo" },
      { "<leader>xs", "<CMD>TodoTelescope<CR>", desc = "Open Telescope todo picker" },
      { "<leader>xt", "<CMD>TodoTrouble<CR>", desc = "Open Telescope trouble" },
    },
  },
  -- {
  --   "smoka7/multicursors.nvim",
  --   keys = {
  --     { mode = { "v", "n" }, "<Leader>m", "<cmd>MCstart<cr>", desc = "Create a selection for word under the cursor" },
  --   },
  -- },
  {
    "Zeioth/compiler.nvim",
    keys = {
      { "<leader>co", "<cmd>CompilerOpen<cr>", desc = "Open compiler" },
      { "<leader>ct", "<cmd>CompilerToggleResults<cr>", desc = "Open compiler" },
    },
  },
  {
    "echasnovski/mini.surround",
    opts = {
      mappings = {
        add = "sa", -- Add surrounding in Normal and Visual modes
        delete = "sd", -- Delete surrounding
        find = "sf", -- Find surrounding (to the right)
        find_left = "sF", -- Find surrounding (to the left)
        highlight = "sh", -- Highlight surrounding
        replace = "sr", -- Replace surrounding
        update_n_lines = "sn", -- Update `n_lines`
        suffix_last = "l", -- Suffix to search with "prev" method
        suffix_next = "n", -- Suffix to search with "next" method
      },
    },
  },
  {
    "chrisgrieser/nvim-spider",
    opts = {
      skipInsignificantPunctuation = false,
    },
  },
  {
    "andythigpen/nvim-coverage",
    keys = {
      { "<leader>tl", "<cmd>CoverageLoad<cr>", desc = "Load coverage" },
      { "<leader>tj", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage Display" },
      { "<leader>ts", "<cmd>CoverageSummary<cr>", desc = "Toggle coverage Summary" },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    opts = {
      prompt_func_return_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
      },
      -- prompt for function parameters
      prompt_func_param_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
      },
    },
  },
  {
    "epwalsh/obsidian.nvim",
    opts = {
      ui = { enable = false },
    },
  },
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          format = {
            enabled = true,
            settings = { -- you can use your preferred format style
              url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
              profile = "GoogleStyle",
            },
          },
        },
      },
    },
  },
}
