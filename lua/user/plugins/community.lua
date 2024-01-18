return {
  "AstroNvim/astrocommunity",
  -- language packs
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.cpp" },
  { import = "astrocommunity.pack.cmake" },
  { import = "astrocommunity.pack.bash" },
  -- colorschemes
  { import = "astrocommunity.colorscheme.everforest", enabled = true },
  { import = "astrocommunity.colorscheme.catppuccin", enabled = true },
  -- motions
  { import = "astrocommunity.motion.flash-nvim", enabled = true },
  { import = "astrocommunity.motion.harpoon", enabled = true },
  -- diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim", enabled = true },
  -- editing
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim", enabled = true },
  { import = "astrocommunity.editing-support.todo-comments-nvim", enabled = true },
  { import = "astrocommunity.editing-support.mini-splitjoin", enabled = true },
  { import = "astrocommunity.editing-support.multicursors-nvim", enabled = true },
  -- scrolling
  { import = "astrocommunity.scrolling.mini-animate", enabled = true },
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
  { import = "astrocommunity.completion.copilot-lua" },
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
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = 120,
      disabled_filetypes = { "help" },
    },
  },
}
