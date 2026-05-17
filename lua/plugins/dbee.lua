-- Database client for Neovim
-- Supports PostgreSQL, MySQL, SQLite, Oracle, SQL Server, MongoDB, Redis, DuckDB
-- Connections stored in ~/.local/share/nvim/dbee/connections.json

---@type LazySpec
return {
  {
    "naveenkanuri/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
      {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "sql" })
        end,
      },
    },
    build = function() require("dbee").install() end,
    cmd = { "Dbee" },
    keys = {
      { "<leader>ee", "<cmd>Dbee toggle<cr>", desc = "Toggle Dbee" },
      { "<leader>eo", "<cmd>Dbee open<cr>", desc = "Open Dbee" },
      { "<leader>ef", function() require("dbee").pick_notes() end, desc = "Dbee Notes" },
      { "<leader>ec", function() require("dbee").pick_connections() end, desc = "Dbee Connections" },
      { "<leader>eh", function() require("dbee").pick_history() end, desc = "Dbee History" },
      { "<leader>ed", function() require("dbee").toggle_drawer() end, desc = "Toggle Drawer" },
    },
    config = function()
      require("dbee").setup {
        sources = {
          require("dbee.sources").FileSource:new(vim.fn.stdpath "data" .. "/dbee/connections.json"),
        },
        result = {
          page_size = 100,
        },
        window_layout = require("dbee.layouts").Minimal:new {
          result_height_pct = 0.3,
          drawer_width = 40,
        },
      }
    end,
  },
}
