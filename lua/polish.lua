-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Enhanced Mark Persistence for Large Codebases
-- Increase shada limits to keep marks across 1000 files (default is only 100)
vim.opt.shada = {
  "!", -- Save and restore global variables
  "'1000", -- Remember marks for 1000 files (increased from 100)
  "<500", -- Save up to 500 lines for each register
  "s100", -- Max item size 100KB
  "h", -- Disable hlsearch on start
}

-- Performance optimization for large files (YAML, logs, XML)
-- Files over 1.5MB will disable syntax highlighting and other expensive features
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB

vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  pattern = "*",
  callback = function()
    local file = vim.fn.expand("<afile>")
    local size = vim.fn.getfsize(file)

    if size > vim.g.bigfile_size or size == -2 then
      -- Disable features for large files
      vim.schedule(function()
        vim.bo.syntax = false
        vim.bo.filetype = "bigfile"
        vim.bo.swapfile = false
        vim.bo.undolevels = -1
        vim.bo.undoreload = 0
        vim.bo.list = false
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.spell = false
        vim.opt_local.linebreak = false
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false

        -- Disable LSP for huge files
        vim.cmd("LspStop")

        -- Show warning
        vim.notify(
          string.format("Large file detected (%.2f MB). Performance optimizations applied.", size / (1024 * 1024)),
          vim.log.levels.INFO
        )
      end)
    end
  end,
  desc = "Disable expensive features for large files",
})
