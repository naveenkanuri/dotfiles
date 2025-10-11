-- GitLab integration for Oracle Hub (orahub)
-- Review MRs directly in Neovim without leaving the terminal
-- Requires: GITLAB_URL and GITLAB_TOKEN environment variables

return {
  {
    "harrisoncramer/gitlab.nvim",
    -- Only load if GitLab environment variables are set
    enabled = vim.env.GITLAB_URL ~= nil and vim.env.GITLAB_TOKEN ~= nil,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim", -- Better UI for inputs
      "nvim-tree/nvim-web-devicons", -- Icons support
    },
    build = function()
      require("gitlab.server").build(true) -- Build the Go binary for API calls
    end,
    config = function()
      require("gitlab").setup({
        -- GitLab URL is set via GITLAB_URL environment variable
        -- GITLAB_URL="https://orahub.oci.oraclecorp.com/"

        -- Debugging (set to false when working properly)
        debug = {
          go_request = false,
          go_response = false
        },

        -- Discussion tree settings
        discussion_tree = {
          auto_open = true, -- Auto open discussions when reviewing
          default_view = "discussions", -- or "notes"
          position = "left", -- or "right"
          size = "20%", -- Width of the tree
        },

        -- Diff settings
        diff = {
          delete_unmodified_lines = true, -- Clean diff view
          add_old_file_on_create = true,
        },
      })

      -- Optional: Set up autocommands for MR files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "gitlab",
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
        end,
      })
    end,
    keys = {
      -- MR Review
      { "<leader>glr", ":lua require('gitlab').review()<cr>", desc = "Start GitLab review" },
      { "<leader>gls", ":lua require('gitlab').summary()<cr>", desc = "MR summary" },
      { "<leader>gld", ":lua require('gitlab').toggle_discussions()<cr>", desc = "Toggle discussions" },

      -- MR Actions
      { "<leader>glA", ":lua require('gitlab').approve()<cr>", desc = "Approve MR" },
      { "<leader>glR", ":lua require('gitlab').revoke()<cr>", desc = "Revoke approval" },
      { "<leader>glM", ":lua require('gitlab').merge()<cr>", desc = "Merge MR" },

      -- Comments (works in visual mode too)
      { "<leader>glc", ":lua require('gitlab').create_comment()<cr>", desc = "Create comment", mode = { "n", "v" } },
      { "<leader>glC", ":lua require('gitlab').create_multiline_comment()<cr>", desc = "Create multiline comment", mode = "v" },
      { "<leader>gln", ":lua require('gitlab').create_note()<cr>", desc = "Create MR note" },

      -- Navigation
      { "<leader>glb", ":lua require('gitlab').choose_merge_request()<cr>", desc = "Choose MR to review" },
      { "<leader>glo", ":lua require('gitlab').open_in_browser()<cr>", desc = "Open in browser" },
      { "]g", ":lua require('gitlab').move_to_discussion_tree_from_diagnostic()<cr>", desc = "Next GitLab discussion" },
      { "[g", ":lua require('gitlab').move_to_discussion_tree_from_diagnostic('prev')<cr>", desc = "Prev GitLab discussion" },

      -- MR Management
      { "<leader>glm", ":lua require('gitlab').create_mr()<cr>", desc = "Create new MR" },
      { "<leader>gla", ":lua require('gitlab').add_assignee()<cr>", desc = "Add assignee" },
      { "<leader>glD", ":lua require('gitlab').delete_assignee()<cr>", desc = "Delete assignee" },
      { "<leader>gll", ":lua require('gitlab').add_label()<cr>", desc = "Add label" },
      { "<leader>glL", ":lua require('gitlab').delete_label()<cr>", desc = "Delete label" },

      -- Pipeline/CI
      { "<leader>glp", ":lua require('gitlab').pipeline()<cr>", desc = "View pipeline status" },
      { "<leader>glP", ":lua require('gitlab').retrigger_pipeline()<cr>", desc = "Retrigger pipeline" },
    },
  },
}