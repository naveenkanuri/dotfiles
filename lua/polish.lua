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

local bigfile_size = vim.g.bigfile_size or 1536 * 1024
vim.g.bigfile_size = bigfile_size

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
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undolevels = -1

  if vim.treesitter and vim.treesitter.stop then pcall(vim.treesitter.stop, bufnr) end

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
    if size <= bigfile_size then return end

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

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dap_semantic_tokens", { clear = true }),
  pattern = { "dapui_*", "dap-repl" },
  callback = function(args)
    if not (vim.lsp.semantic_tokens and vim.lsp.semantic_tokens.stop) then return end
    for _, client in ipairs(vim.lsp.get_clients { bufnr = args.buf }) do
      pcall(vim.lsp.semantic_tokens.stop, args.buf, client.id)
    end
  end,
  desc = "Stop semantic tokens in DAP UI buffers",
})

-- Make `gd` follow the markdown link under the cursor. Resolves the target
-- relative to the current file, jumps to a `#heading` anchor when present, and
-- opens http(s) links externally. Falls back to LSP definition off a link.
local function markdown_link_target()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed
  -- inline links: [text](target)  and bare wiki links: [[target]]
  for _, pat in ipairs { "%[[^%]]-%]%((%S-)%)", "%[%[([^%]]-)%]%]" } do
    local s, e, target = 1
    while true do
      s, e, target = line:find(pat, e and e + 1 or 1)
      if not s then break end
      if col >= s and col <= e then
        return (target:gsub('%s+".*$', "")) -- drop optional (path "title")
      end
    end
  end
  return nil
end

local function follow_markdown_link()
  local target = markdown_link_target()
  if not target then
    return vim.lsp.buf.definition() -- not on a link: normal go-to-definition
  end
  if target:match "^%a[%w+.-]*://" or target:match "^mailto:" then
    return vim.ui.open(target) -- external URL
  end
  local path, anchor = target:match "^([^#]*)#?(.*)$"
  if path == "" then -- pure in-file anchor: [x](#heading)
    path = vim.fn.expand "%:p"
  elseif not path:match "^/" then -- resolve relative to current file's dir
    path = vim.fn.expand "%:p:h" .. "/" .. path
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify("markdown gd: file not found: " .. path, vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  if anchor ~= "" then
    -- jump to the matching ATX heading (slug match, punctuation-insensitive)
    local want = anchor:gsub("%-", "[ %%-]"):lower()
    for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      local h = l:match "^#+%s+(.*)$"
      if h and h:lower():gsub("[^%w ]", ""):gsub("%s+", "-"):match("^" .. want) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        break
      end
    end
  end
end

local markdown_gd_group = vim.api.nvim_create_augroup("markdown_link_gd", { clear = true })
local function set_markdown_gd(buf)
  local ft = vim.bo[buf].filetype
  if ft ~= "markdown" and ft ~= "markdown.mdx" then return end
  vim.keymap.set(
    "n",
    "gd",
    follow_markdown_link,
    { buffer = buf, desc = "Follow markdown link / go to definition" }
  )
end

-- Set on FileType (no-LSP case) AND on LspAttach. LspAttach fires ~1s later
-- when marksman connects; AstroLSP remaps buffer-local `gd` to LSP definition
-- there, so we must re-assert ours afterward or it gets clobbered.
vim.api.nvim_create_autocmd("FileType", {
  group = markdown_gd_group,
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args) set_markdown_gd(args.buf) end,
  desc = "gd follows markdown links",
})
vim.api.nvim_create_autocmd("LspAttach", {
  group = markdown_gd_group,
  callback = function(args) vim.schedule(function() set_markdown_gd(args.buf) end) end,
  desc = "Re-assert markdown gd after LSP attach",
})
