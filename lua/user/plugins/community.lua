return {
  "AstroNvim/astrocommunity",
  -- language packs
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.angular" },
  { import = "astrocommunity.pack.cpp" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.java" },
  -- bars-and-lines
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.bars-and-lines.dropbar-nvim", enabled = false },
  -- code-runner
  { import = "astrocommunity.code-runner.compiler-nvim", enabled = true },
  -- completion
  { import = "astrocommunity.completion.copilot-lua" },
  -- colorschemes
  { import = "astrocommunity.colorscheme.everforest", enabled = true },
  { import = "astrocommunity.colorscheme.catppuccin", enabled = true },
  -- editing-support
  { import = "astrocommunity.editing-support.treesj" },
  { import = "astrocommunity.editing-support.zen-mode-nvim" },
  { import = "astrocommunity.editing-support.telescope-undo-nvim" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim", enabled = true },
  { import = "astrocommunity.editing-support.todo-comments-nvim", enabled = true },
  { import = "astrocommunity.editing-support.mini-splitjoin", enabled = true },
  { import = "astrocommunity.editing-support.multicursors-nvim", enabled = true },
  -- motions
  { import = "astrocommunity.motion.flash-nvim", enabled = true },
  { import = "astrocommunity.motion.harpoon", enabled = true },
  { import = "astrocommunity.motion.mini-move", enabled = true },
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
  { import = "astrocommunity.workflow.hardtime-nvim", enabled = true },
  -- bars-and-lines
  { import = "astrocommunity.bars-and-lines.vim-illuminate", enabled = true },
  -- comment
  { import = "astrocommunity.comment.mini-comment", enabled = true },
  -- note-taking
  { import = "astrocommunity.note-taking.obsidian-nvim", enabled = true },
  -- color
  { import = "astrocommunity.color.headlines-nvim", enabled = true },
  { import = "astrocommunity.color.modes-nvim", enabled = true },
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
  { -- further customize the options set by the community
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        keymap = {
          accept = "<C-l>",
          accept_word = false,
          accept_line = false,
          next = "<C-.>",
          prev = "<C-,>",
          dismiss = "<C/>",
        },
      },
    },
  },
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = 120,
      disabled_filetypes = { "help" },
    },
  },
  {
    "Wansmer/treesj",
    keys = { { "<leader>J", "<CMD>TSJToggle<CR>", desc = "Toggle Treesitter Toggle" } },
  },
  {
    "folke/flash.nvim",
    keys = {
      { "<leader>j", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },
  {
    "folke/todo-comments.nvim",
    keys = {
      { "]t", mode = { "n" }, function() require("todo-comments").jump_next() end, desc = "Jump to next todo" },
      { "[t", mode = { "n" }, function() require("todo-comments").jump_prev() end, desc = "Jump to prev todo" },
      { "<leader>xs", "<CMD>TodoTelescope<CR>", desc = "Open Telescope todo picker" },
      { "<leader>xt", "<CMD>TodoTrouble<CR>", desc = "Open Telescope trouble" },
    },
  },
  {
    "smoka7/multicursors.nvim",
    keys = {
      { mode = { "v", "n" }, "<Leader>m", "<cmd>MCstart<cr>", desc = "Create a selection for word under the cursor" },
    },
  },
  {
    "Zeioth/compiler.nvim",
    keys = {
      { "<leader>co", "<cmd>CompilerOpen<cr>", desc = "Open compiler" },
      { "<leader>ct", "<cmd>CompilerToggleResults<cr>", desc = "Open compiler" },
    },
  },
}
