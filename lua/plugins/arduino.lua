-- Arduino: arduino-language-server (LSP) + arduino-cli (build/upload/serial monitor).
-- Sketch layout: <name>/<name>.ino. Board (FQBN): <sketch>/sketch.yaml `default_fqbn`,
-- else vim.g.arduino_fqbn, else UNO R4 WiFi. Baud: vim.g.arduino_baud (default 9600).
--
-- <Leader>ab build | <Leader>au build+upload | <Leader>am toggle monitor | <Leader>al toggle last log
-- Build/upload run in the background. Focus never leaves the editor. On failure the log opens
-- and compiler errors go to quickfix. Upload stops the monitor (it holds the port) and reopens it.

-- Machine setup (arduino-cli, board core, libraries, clangd 14): see ARDUINO.md.

local DEFAULT_FQBN = "arduino:renesas_uno:unor4wifi"

local IS_MAC = vim.uv.os_uname().sysname == "Darwin"
-- arduino-cli default data dir (cores, toolchains, arduino-cli.yaml).
local ARDUINO15 = vim.fn.expand(IS_MAC and "~/Library/Arduino15" or "~/.arduino15")

-- arduino-language-server 0.7.x crashes on symbol tags from newer clangd.
-- Tested: clangd 14 (Arduino) and Apple clangd 17 OK; Mason clangd 23 crashes.
-- Order: vim.g.arduino_clangd > Arduino clangd 14 (ARDUINO.md) > Apple clangd (macOS).
local function pick_clangd()
  local candidates = { vim.g.arduino_clangd or "", vim.fn.stdpath "data" .. "/arduino-clangd/clangd" }
  if IS_MAC then table.insert(candidates, "/usr/bin/clangd") end
  for _, p in ipairs(candidates) do
    if p ~= "" and vim.fn.executable(p) == 1 then return p end
  end
end
-- Wrapper that keeps clangd's index in ~/.cache/arduino-clangd across sessions (see the script).
local CLANGD_WRAPPER = vim.fn.stdpath "config" .. "/bin/arduino-clangd"

local ERRORFORMAT = table.concat({
  "%f:%l:%c: fatal %trror: %m",
  "%f:%l:%c: %trror: %m",
  "%f:%l:%c: %tarning: %m",
  "%f:%l: %trror: %m",
}, ",")

local function notify(msg, level) vim.notify(msg, level or vim.log.levels.INFO, { id = "arduino", title = "Arduino" }) end

local function sketch_dir() return vim.fn.expand "%:p:h" end

local function fqbn(dir)
  local f = io.open(dir .. "/sketch.yaml", "r")
  if f then
    local v = f:read("*a"):match "default_fqbn:%s*([^%s]+)"
    f:close()
    if v then return v end
  end
  return vim.g.arduino_fqbn or DEFAULT_FQBN
end

-- Serial port of the first connected board matching the FQBN.
local function find_port(board)
  local ok, data = pcall(vim.json.decode, vim.fn.system { "arduino-cli", "board", "list", "--format", "json" })
  if not ok or type(data) ~= "table" then return nil end
  for _, d in ipairs(data.detected_ports or {}) do
    for _, b in ipairs(d.matching_boards or {}) do
      if b.fqbn == board then return d.port.address end
    end
  end
end

---------------------------------------------------------------------------
-- Core sources (reached via go-to-definition) are plain .cpp files handled by the
-- regular clangd, which knows nothing about Arduino flags -> bogus errors. Generate the
-- board package's compile DB once per session and link it into the package root
-- (<Arduino15>/packages/<vendor>/hardware/<arch>/<version>/), where clangd finds it.
-- The toolchain's system headers and target are baked into the DB (what clangd's
-- --query-driver would do), so the regular clangd config needs no Arduino flags.
---------------------------------------------------------------------------

local cdb_done = {}

-- System include dirs of a gcc toolchain for a language ("c" or "c++").
local function gcc_includes(compiler, lang)
  local res = vim.system({ compiler, "-E", "-x", lang, "-v", "-" }, { stdin = "", text = true }):wait()
  local dirs, inside = {}, false
  for line in (res.stderr or ""):gmatch "[^\n]+" do
    if line:match "^#include <%.%.%.> search starts here:" then
      inside = true
    elseif line:match "^End of search list" then
      break
    elseif inside then
      table.insert(dirs, vim.fs.normalize(vim.trim(line)))
    end
  end
  return dirs
end

-- Prepend --target and -isystem <toolchain headers> to every entry.
local function add_toolchain_flags(entries)
  local compiler = entries[1] and entries[1].arguments and entries[1].arguments[1]
  if not compiler then return end
  local triple = vim.fs.basename(compiler):match "^(.-)%-g[c+][c+]$"
  local flags = {}
  for _, lang in ipairs { "c", "c++" } do
    flags[lang] = {}
    -- clang has no xtensa (ESP32) backend; only set targets it understands.
    if triple and (triple:match "^arm" or triple:match "^riscv") then
      table.insert(flags[lang], "--target=" .. triple)
    end
    for _, d in ipairs(gcc_includes(compiler, lang)) do
      vim.list_extend(flags[lang], { "-isystem", d })
    end
  end
  for _, e in ipairs(entries) do
    if e.arguments then
      local extra = flags[e.file:match "%.c$" and "c" or "c++"]
      for i = #extra, 1, -1 do
        table.insert(e.arguments, 2, extra[i])
      end
    end
  end
end

local function ensure_core_cdb(dir)
  local board = fqbn(dir)
  if cdb_done[board] then return end
  cdb_done[board] = true
  local out = vim.fn.stdpath "cache" .. "/arduino-cdb/" .. board:gsub("[^%w]", "_")
  local args = { "arduino-cli", "compile", "-b", board, "--only-compilation-database", "--build-path", out, dir }
  vim.system(args, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        cdb_done[board] = nil
        return
      end
      local db = out .. "/compile_commands.json"
      local f = io.open(db, "r")
      if not f then return end
      local ok, entries = pcall(vim.json.decode, f:read "*a")
      f:close()
      if not ok or type(entries) ~= "table" then return end
      add_toolchain_flags(entries)
      f = io.open(db, "w")
      if not f then return end
      f:write(vim.json.encode(entries))
      f:close()
      for _, e in ipairs(entries) do
        local root = e.file:match "^(.-/hardware/[^/]+/[^/]+)/"
        if root then
          local link = root .. "/compile_commands.json"
          if vim.uv.fs_readlink(link) ~= db then
            vim.uv.fs_unlink(link)
            vim.uv.fs_symlink(db, link)
          end
          return
        end
      end
    end)
  end)
end

---------------------------------------------------------------------------
-- Windows: always opened without focus (nvim_open_win enter=false)
---------------------------------------------------------------------------

local function show(buf, opts)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then return win end
  win = vim.api.nvim_open_win(buf, false, vim.tbl_extend("force", { win = -1 }, opts))
  local wo = vim.wo[win]
  wo.number, wo.relativenumber, wo.signcolumn = false, false, "no"
  if opts.height then wo.winfixheight = true end
  if opts.width then wo.winfixwidth = true end
  return win
end

local function hide(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if #vim.api.nvim_tabpage_list_wins(0) > 1 then vim.api.nvim_win_close(win, true) end
  end
end

local function scroll_to_end(buf)
  local last = vim.api.nvim_buf_line_count(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_set_cursor(win, { last, 0 })
  end
end

---------------------------------------------------------------------------
-- Build log (read-only scratch buffer)
---------------------------------------------------------------------------

local log_buf

local function get_log_buf()
  if log_buf and vim.api.nvim_buf_is_valid(log_buf) then return log_buf end
  log_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(log_buf, "arduino://log")
  vim.bo[log_buf].bufhidden = "hide"
  vim.bo[log_buf].modifiable = false
  vim.keymap.set("n", "q", function() hide(log_buf) end, { buffer = log_buf, desc = "Close log" })
  return log_buf
end

local function set_log(lines)
  local buf = get_log_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function show_log()
  local buf = get_log_buf()
  show(buf, { split = "below", height = math.floor(vim.o.lines * 0.3) })
  scroll_to_end(buf)
end

local function toggle_log()
  local buf = get_log_buf()
  if vim.fn.bufwinid(buf) ~= -1 then return hide(buf) end
  if vim.api.nvim_buf_line_count(buf) <= 1 then return notify "No build log yet" end
  show_log()
end

-- Compiler errors -> quickfix. arduino-cli maps them back to .ino lines.
local function set_quickfix(lines, title)
  local items = vim.tbl_filter(
    function(i) return i.valid == 1 end,
    vim.fn.getqflist({ lines = lines, efm = ERRORFORMAT }).items
  )
  vim.fn.setqflist({}, " ", { title = title, items = items })
  return #items
end

---------------------------------------------------------------------------
-- Background jobs (build/upload)
---------------------------------------------------------------------------

local busy = false

-- after(ok) runs on completion, success or failure.
local function run(args, dir, label, after)
  if busy then return notify("Already running", vim.log.levels.WARN) end
  busy = true
  vim.cmd "silent! write"
  notify(label .. "...")
  local start = vim.uv.hrtime()
  vim.system(args, { cwd = dir, text = true }, function(res)
    vim.schedule(function()
      busy = false
      local secs = (vim.uv.hrtime() - start) / 1e9
      local out = (res.stdout or "") .. (res.stderr or "")
      local lines = vim.split(out, "\n", { trimempty = true })
      table.insert(lines, 1, "$ " .. table.concat(args, " "))
      set_log(lines)
      local ok = res.code == 0
      if ok then
        hide(get_log_buf())
        vim.fn.setqflist({}, " ", { title = label, items = {} })
        local bytes, pct = out:match "Sketch uses (%d+) bytes %((%d+)%%%)"
        local size = bytes and string.format(" (%d KB, %s%% flash)", math.floor(bytes / 1024), pct) or ""
        notify(string.format("%s done in %.1fs%s", label, secs, size))
      else
        local n = set_quickfix(lines, label)
        show_log()
        local hint = n > 0 and string.format(" %d error(s), ]q to jump.", n) or ""
        notify(string.format("%s failed.%s", label, hint), vim.log.levels.ERROR)
      end
      if after then after(ok) end
    end)
  end)
end

---------------------------------------------------------------------------
-- Serial monitor (interactive terminal: you can type to send data)
---------------------------------------------------------------------------

local mon = { buf = nil, job = nil }

local function stop_monitor()
  if mon.job then
    vim.fn.jobstop(mon.job)
    vim.fn.jobwait({ mon.job }, 2000) -- wait until the port is released
    mon.job = nil
  end
  if mon.buf and vim.api.nvim_buf_is_valid(mon.buf) then vim.api.nvim_buf_delete(mon.buf, { force = true }) end
  mon.buf = nil
end

local function start_monitor(port)
  local buf = vim.api.nvim_create_buf(false, true)
  mon.buf = buf
  local win = show(buf, { split = "right", width = math.floor(vim.o.columns * 0.35) })
  local cmd = { "arduino-cli", "monitor", "-p", port, "-c", "baudrate=" .. (vim.g.arduino_baud or 9600) }
  vim.api.nvim_win_call(win, function()
    mon.job = vim.fn.jobstart(cmd, {
      term = true,
      on_stdout = function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then scroll_to_end(buf) end
        end)
      end,
      on_exit = function(id)
        if mon.job == id then mon.job = nil end
      end,
    })
  end)
  vim.keymap.set("n", "q", stop_monitor, { buffer = buf, desc = "Close serial monitor" })
end

local function toggle_monitor()
  if mon.job then return stop_monitor() end
  local port = find_port(fqbn(sketch_dir()))
  if not port then return notify("No board connected", vim.log.levels.ERROR) end
  start_monitor(port)
end

-- After upload the board resets and the port may briefly disappear; retry.
local function reconnect(board, tries)
  vim.defer_fn(function()
    if mon.job then return end
    local port = find_port(board)
    if port then
      start_monitor(port)
    elseif tries > 1 then
      reconnect(board, tries - 1)
    else
      notify("Monitor: board not found after upload", vim.log.levels.WARN)
    end
  end, 1000)
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

local function build()
  local dir = sketch_dir()
  run({ "arduino-cli", "compile", "-b", fqbn(dir), "." }, dir, "Build")
end

local function upload()
  local dir = sketch_dir()
  local board = fqbn(dir)
  local port = find_port(board)
  if not port then return notify("No " .. board .. " board connected", vim.log.levels.ERROR) end
  local reopen = mon.job ~= nil
  stop_monitor()
  run({ "arduino-cli", "compile", "-b", board, "-u", "-p", port, "." }, dir, "Upload", function()
    if reopen then reconnect(board, 5) end
  end)
end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = { "arduino_language_server" },
      config = {
        arduino_language_server = {
          -- Function form so the FQBN is resolved per sketch when the server starts.
          cmd = function(dispatchers, config)
            local dir = config and config.root_dir or vim.fn.getcwd()
            local clangd = pick_clangd()
            if not clangd then
              vim.schedule(
                function() notify("No compatible clangd. See lua/plugins/ARDUINO.md (clangd 14).", vim.log.levels.ERROR) end
              )
            end
            return vim.lsp.rpc.start({
              "arduino-language-server",
              "-cli",
              "arduino-cli",
              "-cli-config",
              ARDUINO15 .. "/arduino-cli.yaml",
              "-clangd",
              CLANGD_WRAPPER,
              "-fqbn",
              fqbn(dir),
            }, dispatchers, { cwd = dir, env = { ARDUINO_CLANGD = clangd or "clangd" } })
          end,
        },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed =
        require("astrocore").list_insert_unique(opts.ensure_installed, { "arduino-language-server" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "arduino" })
      end
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        arduino_keymaps = {
          {
            event = "FileType",
            pattern = "arduino",
            desc = "Arduino build/upload/monitor keymaps",
            callback = function(args)
              local map = function(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = args.buf, desc = desc }) end
              map("<Leader>ab", build, "Arduino: build")
              map("<Leader>au", upload, "Arduino: build + upload")
              map("<Leader>am", toggle_monitor, "Arduino: toggle serial monitor")
              map("<Leader>al", toggle_log, "Arduino: toggle last build log")
              ensure_core_cdb(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p:h"))
            end,
          },
        },
        arduino_vendor_readonly = {
          {
            event = "BufReadPost",
            pattern = ARDUINO15 .. "/*",
            desc = "Board package sources are reference-only",
            callback = function(args)
              vim.bo[args.buf].readonly = true
              vim.bo[args.buf].modifiable = false
            end,
          },
        },
      },
    },
  },
}
