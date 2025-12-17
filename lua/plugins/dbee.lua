-- Database client for Neovim
-- Supports PostgreSQL, MySQL, SQLite, Oracle, SQL Server, MongoDB, Redis, DuckDB
-- Connections stored in ~/.local/share/nvim/dbee/connections.json

---@type LazySpec
return {
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "sql" })
        end,
      },
    },
    build = function()
      require("dbee").install()
    end,
    cmd = { "Dbee" },
    keys = {
      { "<leader>ee", "<cmd>Dbee toggle<cr>", desc = "Toggle Dbee" },
      { "<leader>eo", "<cmd>Dbee open<cr>", desc = "Open Dbee" },
      { "<leader>ec", "<cmd>Dbee close<cr>", desc = "Close Dbee" },
    },
    config = function()
      require("dbee").setup({
        sources = {
          require("dbee.sources").FileSource:new(vim.fn.stdpath("data") .. "/dbee/connections.json"),
        },
        result = {
          page_size = 100,
        },
      })
    end,
  },
}
