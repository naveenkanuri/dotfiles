local prefix = "<Leader>t"
local bigfile_size = 1536 * 1024

return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    features = {
      large_buf = { size = bigfile_size, lines = 10000 },
      autopairs = true,
      cmp = true,
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = false,
      virtual_lines = {
        current_line = true,
      },
      underline = true,
    },
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        showtabline = 0,
      },
      g = {
        bigfile_size = bigfile_size,
      },
    },
    mappings = {
      n = {
        ["<Leader>fw"] = {
          function() require("snacks").picker.git_grep() end,
          desc = "Find words (git)",
        },

        ["<Leader>o"] = { function() require("oil").open() end, desc = "Open folder in Oil" },
        ["gP"] = { function() require("gitsigns").nav_hunk "prev" end, desc = "Previous Git hunk" },
        ["gN"] = { function() require("gitsigns").nav_hunk "next" end, desc = "Next Git hunk" },

        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        [prefix .. "t"] = { function() require("neotest").run.run() end, desc = "Run test" },
        [prefix .. "d"] = {
          function() require("neotest").run.run { suite = false, vim.fn.expand "%", strategy = "dap" } end,
          desc = "Debug test",
        },
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
      },
    },
  },
}
