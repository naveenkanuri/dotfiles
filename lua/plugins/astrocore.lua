--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local prefix = "<Leader>t"

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = false, -- sets vim.opt.wrap
        showtabline = 0,
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
      wo = {
        -- configure window-local options (vim.wo)
        conceallevel = 2, -- sets vim.wo.conceallevel
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs with `H` and `L`
        -- L = {
        --   function() require("astrocore.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
        --   desc = "Next buffer",
        -- },
        -- H = {
        --   function() require("astrocore.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
        --   desc = "Previous buffer",
        -- },
        ["<Leader>o"] = { function() require("oil").open() end, desc = "Open folder in Oil" },
        ["<M-h>"] = { "<C-w>h", desc = "Move to left window" },
        ["<M-l>"] = { "<C-w>l", desc = "Move to right window" },
        ["gP"] = { function() require("gitsigns").prev_hunk() end, desc = "Previous Git hunk" },
        ["gN"] = { function() require("gitsigns").next_hunk() end, desc = "Next Git hunk" },
        -- maps.n["[g"] = { function() require("gitsigns").prev_hunk() end, desc = "Previous Git hunk" }
        -- ["<M-j>"] = { "<C-w>j", desc = "Move to down window" },
        -- ["<M-k>"] = { "<C-w>k", desc = "Move to up window" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Pick to close",
        },
        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        ["<Leader>b"] = { desc = "Buffers" },

        [prefix .. "t"] = { function() require("neotest").run.run() end, desc = "Run test" },
        [prefix .. "d"] = { function() require("neotest").run.run { strategy = "dap" } end, desc = "Debug test" },
        [prefix .. "f"] = {
          function() require("neotest").run.run(vim.fn.expand "%") end,
          desc = "Run all tests in file",
        },
        [prefix .. "p"] = {
          function() require("neotest").run.run(vim.fn.getcwd()) end,
          desc = "Run all tests in project",
        },
        [prefix .. "<CR>"] = { function() require("neotest").summary.toggle() end, desc = "Test Summary" },
        [prefix .. "o"] = { function() require("neotest").output.open() end, desc = "Output hover" },
        [prefix .. "O"] = { function() require("neotest").output_panel.toggle() end, desc = "Output window" },
        -- quick save
        -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
      },
      t = {
        -- setting a mapping to false will disable it
        -- ["<esc>"] = false,
      },
    },
  },
}
