-- Clean DAP UI: scopes + console by default, everything else toggleable
return {
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        -- Left sidebar: scopes only
        {
          elements = {
            { id = "scopes", size = 1 },
          },
          position = "left",
          size = 40,
        },
        -- Bottom panel: console only
        {
          elements = {
            { id = "console", size = 1 },
          },
          position = "bottom",
          size = 12,
        },
      },
      floating = {
        border = "rounded",
        max_width = 80,
        max_height = 20,
      },
    },
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>dh"] = {
            function()
              require("dapui").eval(nil, { enter = true, width = math.floor(vim.o.columns * 0.4) })
            end,
            desc = "Debugger Hover",
          },
          ["<Leader>dw"] = {
            function() require("dapui").float_element("watches", { width = math.floor(vim.o.columns * 0.4), enter = true }) end,
            desc = "Watches (float)",
          },
          ["<Leader>dk"] = {
            function() require("dapui").float_element("stacks", { enter = true }) end,
            desc = "Stacks (float)",
          },
          ["<Leader>dB"] = {
            function() require("dapui").float_element("breakpoints", { enter = true }) end,
            desc = "Breakpoints (float)",
          },
          ["<Leader>dq"] = {
            function()
              require("dap").close()
              require("dapui").close()
            end,
            desc = "Close Session",
          },
          ["<Leader>dQ"] = {
            function()
              require("dap").terminate()
              require("dapui").close()
            end,
            desc = "Terminate Session",
          },
        },
        v = {
          ["<Leader>dh"] = {
            function() require("dapui").eval(nil, { enter = true }) end,
            desc = "Debugger Hover",
          },
        },
      },
    },
  },
}
