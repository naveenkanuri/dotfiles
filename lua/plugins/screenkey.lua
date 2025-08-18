return {
  {
    "NStefan002/screenkey.nvim",
    version = "*", -- keep on a tagged release
    lazy = false, -- loads itself lazily when first used; explicit false is fine
    opts = {
      -- Position the overlay in the bottom-right
      win_opts = {
        anchor = "SE",
        relative = "editor",
        row = vim.o.lines - vim.o.cmdheight - 1,
        col = vim.o.columns - 1,
        width = 40,
        height = 3,
        border = "single",
        title = "Screenkey",
        title_pos = "center",
        focusable = false,
        noautocmd = true,
      },
      -- Compress repeated input: "jjjj" -> "j..x4"
      compress_after = 3,
      -- Clear overlay after N seconds of inactivity
      clear_after = 3,
      -- Show <leader> literally and group mapped combos like `<leader>ff`
      show_leader = true,
      group_mappings = true,
      -- Don’t show keys while in terminal buffers
      disable = { buftypes = { "terminal" } },
      -- Map some special keys nicely (already defaults, but you can tweak)
      keys = {
        ["<CR>"] = "↵",
        ["<TAB>"] = "⇥",
        ["<ESC>"] = "Esc",
        ["<SPACE>"] = "␣",
      },
    },
    keys = {
      -- Toggle on/off
      { "<leader>sk", "<cmd>Screenkey toggle<cr>", desc = "Toggle Screenkey" },
    },
  },
}
