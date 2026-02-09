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

local bigfile_group = vim.api.nvim_create_augroup("bigfile", { clear = true })

local function set_bigfile_window_opts(winid)
  if not vim.api.nvim_win_is_valid(winid) then return end
  vim.wo[winid].list = false
  vim.wo[winid].foldmethod = "manual"
  vim.wo[winid].spell = false
  vim.wo[winid].linebreak = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].number = false
end

local function apply_bigfile_opts(bufnr, size)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  -- Mark buffer so future LSP attaches can be detached for this buffer only.
  vim.b[bufnr].is_bigfile = true

  -- Buffer-local options.
  vim.bo[bufnr].syntax = "OFF"
  vim.bo[bufnr].filetype = "bigfile"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undolevels = -1

  -- Window-local options for all visible windows showing this buffer.
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    set_bigfile_window_opts(winid)
  end

  -- Detach existing LSP clients from this buffer without stopping them globally.
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end

  vim.notify(
    string.format("Large file detected (%.2f MB). Performance optimizations applied.", size / (1024 * 1024)),
    vim.log.levels.INFO
  )
end

vim.api.nvim_create_autocmd("BufReadPre", {
  group = bigfile_group,
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local file = args.file ~= "" and args.file or vim.api.nvim_buf_get_name(bufnr)
    local size = vim.fn.getfsize(file)

    -- getfsize returns -2 for directories and -1 for missing files.
    if size == -2 or size == -1 then return end
    if size <= vim.g.bigfile_size then return end

    vim.schedule(function() apply_bigfile_opts(bufnr, size) end)
  end,
  desc = "Disable expensive features for large files",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = bigfile_group,
  pattern = "*",
  callback = function(args)
    if not vim.b[args.buf].is_bigfile then return end
    set_bigfile_window_opts(vim.api.nvim_get_current_win())
  end,
  desc = "Apply bigfile window options when buffer is shown",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = bigfile_group,
  callback = function(args)
    if not vim.b[args.buf].is_bigfile then return end
    local client_id = args.data and args.data.client_id
    if client_id then vim.lsp.buf_detach_client(args.buf, client_id) end
  end,
  desc = "Detach LSP from bigfile buffers only",
})
