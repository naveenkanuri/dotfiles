-- Enhanced mark visualization and persistence
return {
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {
      -- which builtin marks to show
      builtin_marks = { ".", "<", ">", "^" },

      -- whether movements cycle back to the beginning/end of buffer
      cyclic = true,

      -- don't use plugin's default mappings (we define our own)
      default_mappings = false,

      -- Bookmark groups (optional - for categorizing marks)
      bookmark_0 = {
        sign = "⚑",
        virt_text = "bookmark",
        annotate = false,
      },

      mappings = {
        -- Set mark at cursor (keep vim default: ma, mA, etc.)
        set = "m",

        -- Navigate between marks
        next = "m,", -- Jump to next mark
        prev = "m.", -- Jump to previous mark

        -- Preview all marks
        preview = "m;", -- Show all marks in preview window

        -- Delete marks
        delete = "dm", -- Delete mark at cursor: dma, dmA, etc.
        delete_buf = "dm<space>", -- Delete all marks in current buffer
        delete_line = "dm-", -- Delete all marks on current line

        -- Bookmarks (optional - if you want to use them)
        set_bookmark0 = "mb",
        delete_bookmark = "dmb",
      }
    },
    config = function(_, opts)
      require("marks").setup(opts)

      -- Register with which-key for better discoverability (new spec)
      local present, wk = pcall(require, "which-key")
      if present then
        wk.add({
          -- Mark navigation commands
          { "m,", desc = "Next mark" },
          { "m.", desc = "Previous mark" },
          { "m;", desc = "Preview all marks" },
          { "mb", desc = "Set bookmark" },

          -- Delete mark commands
          { "dm", group = "Delete marks" },
          { "dm<space>", desc = "Delete all marks in buffer" },
          { "dm-", desc = "Delete marks on line" },
          { "dmb", desc = "Delete bookmark" },
        })
      end
    end,
  },
}
