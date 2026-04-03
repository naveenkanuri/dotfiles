return {
  {
    "olimorris/codecompanion.nvim",
    optional = true,
    init = function()
      vim.api.nvim_create_user_command("CodeCompanionRepoChat", function()
        require("codecompanion_repo").open_repo_chat()
      end, { desc = "Open the repo-bound CodeCompanion chat" })

      vim.api.nvim_create_user_command("CodeCompanionRepoBind", function()
        require("codecompanion_repo").bind_repo_chat()
      end, { desc = "Bind the current repo to a CodeCompanion ACP session" })

      vim.api.nvim_create_user_command("CodeCompanionRepoInfo", function()
        require("codecompanion_repo").show_repo_info()
      end, { desc = "Show the current repo CodeCompanion binding" })

      vim.api.nvim_create_user_command("CodeCompanionRepoClear", function()
        require("codecompanion_repo").clear_repo_binding()
      end, { desc = "Clear the current repo CodeCompanion binding" })
    end,
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}

      opts.mappings.n["<Leader>Ac"] = {
        function() require("codecompanion_repo").open_repo_chat() end,
        desc = "Toggle repo chat",
      }
      opts.mappings.n["<Leader>Ab"] = {
        function() require("codecompanion_repo").bind_repo_chat() end,
        desc = "Bind repo session",
      }
      opts.mappings.n["<Leader>Ai"] = {
        function() require("codecompanion_repo").show_repo_info() end,
        desc = "Repo session info",
      }
      opts.mappings.n["<Leader>Ax"] = {
        function() require("codecompanion_repo").clear_repo_binding() end,
        desc = "Clear repo session",
      }
    end,
  },
}
