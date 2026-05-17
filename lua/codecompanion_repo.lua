local M = {}

local STATE_PATH = vim.fs.normalize(vim.fn.stdpath("state") .. "/codecompanion-repo-sessions.json")

local ADAPTERS = {
  { name = "claude_code", label = "Claude Code" },
  { name = "opencode", label = "OpenCode" },
  { name = "codex", label = "Codex" },
}

local live_chats = {}
local ACP_TIMEOUT_MS = 2e4

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "CodeCompanion Repo" })
end

local function ensure_codecompanion()
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then lazy.load { plugins = { "codecompanion.nvim" } } end

  local ok, codecompanion = pcall(require, "codecompanion")
  if not ok then
    notify("CodeCompanion is not available: " .. codecompanion, vim.log.levels.ERROR)
    return nil
  end

  return codecompanion
end

local function get_repo_root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local name = vim.api.nvim_buf_get_name(bufnr)
  local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local root = vim.fs.root(start, { ".git" }) or vim.fn.getcwd()

  return vim.fs.normalize(root)
end

local function with_cwd(cwd, fn)
  local previous = vim.fn.getcwd()
  local changed = cwd and cwd ~= "" and cwd ~= previous

  if changed then vim.fn.chdir(cwd) end

  local ok, result_a, result_b, result_c = xpcall(fn, debug.traceback)

  if changed then pcall(vim.fn.chdir, previous) end

  if not ok then error(result_a) end

  return result_a, result_b, result_c
end

local function read_state()
  local state = { version = 1, repos = {} }

  if not vim.uv.fs_stat(STATE_PATH) then return state end

  local ok_read, lines = pcall(vim.fn.readfile, STATE_PATH)
  if not ok_read then return state end

  local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(decoded) ~= "table" then return state end

  decoded.version = 1
  decoded.repos = type(decoded.repos) == "table" and decoded.repos or {}

  return decoded
end

local function write_state(state)
  vim.fn.mkdir(vim.fn.fnamemodify(STATE_PATH, ":h"), "p")

  local ok_encode, encoded = pcall(vim.json.encode, state)
  if not ok_encode then
    notify("Failed to serialize repo session bindings", vim.log.levels.ERROR)
    return false
  end

  local ok_write, err = pcall(vim.fn.writefile, { encoded }, STATE_PATH)
  if not ok_write then
    notify("Failed to write repo session bindings: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function get_binding(repo_root)
  return read_state().repos[repo_root]
end

local function set_binding(repo_root, binding)
  local state = read_state()
  state.repos[repo_root] = binding
  return write_state(state)
end

local function clear_binding(repo_root)
  local state = read_state()
  state.repos[repo_root] = nil
  return write_state(state)
end

local function available_adapters()
  local config = require("codecompanion.config")
  local items = {}
  local acp_adapters = config.adapters and config.adapters.acp or {}

  for _, adapter in ipairs(ADAPTERS) do
    if acp_adapters[adapter.name] then table.insert(items, adapter) end
  end

  return items
end

local function get_live_chat(repo_root)
  local bufnr = live_chats[repo_root]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    live_chats[repo_root] = nil
    return nil
  end

  local codecompanion = ensure_codecompanion()
  if not codecompanion then return nil end

  local chat = codecompanion.buf_get_chat(bufnr)
  if not chat then
    live_chats[repo_root] = nil
    return nil
  end

  return chat
end

local function close_live_chat(repo_root)
  local chat = get_live_chat(repo_root)
  if not chat then return end

  pcall(chat.close, chat)
  live_chats[repo_root] = nil
end

local function format_adapter_name(adapter_name)
  for _, adapter in ipairs(ADAPTERS) do
    if adapter.name == adapter_name then return adapter.label end
  end

  return adapter_name
end

local function choose_adapter(callback, preferred)
  local items = available_adapters()
  if #items == 0 then
    notify("No supported ACP adapters are configured for CodeCompanion", vim.log.levels.ERROR)
    return
  end

  if preferred then
    table.sort(items, function(left, right)
      if left.name == preferred then return true end
      if right.name == preferred then return false end
      return left.label < right.label
    end)
  end

  vim.ui.select(items, {
    prompt = "CodeCompanion client",
    format_item = function(item) return item.label end,
  }, function(choice)
    callback(choice and choice.name or nil)
  end)
end

local function make_connection(adapter_name, repo_root)
  local ok_adapter, adapter = pcall(require("codecompanion.adapters").resolve, adapter_name)
  if not ok_adapter then return nil, adapter end

  local ok_connection, connection = pcall(function()
    return require("codecompanion.acp").new { adapter = adapter }
  end)
  if not ok_connection then return nil, connection end

  local ok_connect, connect_result = pcall(function()
    return with_cwd(repo_root, function()
      return connection:connect_and_authenticate()
    end)
  end)

  if not ok_connect or not connect_result then
    if type(connection.disconnect) == "function" then pcall(connection.disconnect, connection) end
    return nil, ok_connect and "Failed to connect to the ACP agent" or connect_result
  end

  return connection
end

local function fetch_sessions(adapter_name, repo_root)
  local connection, err = make_connection(adapter_name, repo_root)
  if not connection then return nil, err end

  local supports_load = connection:can_load_session()
  local supports_list = connection:can_list_sessions()

  if not supports_load then
    if type(connection.disconnect) == "function" then pcall(connection.disconnect, connection) end
    return nil, format_adapter_name(adapter_name) .. " cannot load existing sessions"
  end

  local sessions = {}
  if supports_list then
    local ok_list, listed = pcall(function()
      return with_cwd(repo_root, function()
        return connection:session_list { max_sessions = 500 }
      end)
    end)
    if not ok_list then
      if type(connection.disconnect) == "function" then pcall(connection.disconnect, connection) end
      return nil, listed
    end
    sessions = listed or {}
  end

  if type(connection.disconnect) == "function" then pcall(connection.disconnect, connection) end

  return {
    supports_list = supports_list,
    sessions = sessions,
  }
end

local function to_iso8601_millis(epoch_ms)
  if type(epoch_ms) ~= "number" then return nil end

  return os.date("!%Y-%m-%dT%H:%M:%SZ", math.floor(epoch_ms / 1000))
end

local function fetch_opencode_sessions_async(repo_root, callback)
  notify("Loading OpenCode sessions...", vim.log.levels.INFO)

  vim.system(
    { "opencode", "session", "list", "--format", "json", "-n", "200" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local stderr = vim.trim(result.stderr or "")
        callback(nil, stderr ~= "" and stderr or "Failed to list OpenCode sessions")
        return
      end

      local ok, decoded = pcall(vim.json.decode, result.stdout or "[]")
      if not ok or type(decoded) ~= "table" then
        callback(nil, "Failed to parse OpenCode sessions")
        return
      end

      local sessions = {}
      for _, session in ipairs(decoded) do
        local directory = session.directory and vim.fs.normalize(session.directory) or nil
        if directory == repo_root then
          table.insert(sessions, {
            sessionId = session.id,
            title = session.title,
            updatedAt = to_iso8601_millis(session.updated),
          })
        end
      end

      callback({ supports_list = true, sessions = sessions })
    end)
  )
end

local function fetch_claude_sessions(repo_root)
  local project_key = repo_root:gsub("[^%w]", "-")
  local index_path = vim.fs.normalize(
    vim.fn.expand("~/.claude/projects/" .. project_key .. "/sessions-index.json")
  )

  if not vim.uv.fs_stat(index_path) then return nil end

  local ok_read, lines = pcall(vim.fn.readfile, index_path)
  if not ok_read then return nil end

  local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(decoded) ~= "table" or type(decoded.entries) ~= "table" then
    return nil
  end

  local sessions = {}
  for _, entry in ipairs(decoded.entries) do
    if entry.projectPath == repo_root then
      table.insert(sessions, {
        sessionId = entry.sessionId,
        title = entry.summary or entry.firstPrompt,
        updatedAt = entry.modified,
      })
    end
  end

  table.sort(sessions, function(left, right)
    return (left.updatedAt or "") > (right.updatedAt or "")
  end)

  return {
    supports_list = true,
    sessions = sessions,
  }
end

local function fetch_sessions_for_picker(adapter_name, repo_root, callback)
  if adapter_name == "opencode" then
    fetch_opencode_sessions_async(repo_root, callback)
    return
  end

  if adapter_name == "claude_code" then
    local result = fetch_claude_sessions(repo_root)
    if result then
      callback(result)
      return
    end
  end

  local result, err = fetch_sessions(adapter_name, repo_root)
  callback(result, err)
end

local function format_session(session)
  local pieces = {}

  if session.updatedAt then
    local utils = require("codecompanion.utils")
    local ts = utils.parse_iso8601(session.updatedAt)
    if ts then table.insert(pieces, "(" .. utils.make_relative(ts) .. ")") end
  end

  table.insert(pieces, session.title or session.sessionId)
  table.insert(pieces, "- " .. session.sessionId)

  return table.concat(pieces, " ")
end

local function prompt_for_session_id(callback)
  vim.ui.input({ prompt = "Session ID: " }, function(input)
    local session_id = vim.trim(input or "")
    if session_id == "" then
      callback(nil)
      return
    end

    callback {
      session_id = session_id,
      title = nil,
    }
  end)
end

local function choose_session(adapter_name, repo_root, callback)
  fetch_sessions_for_picker(adapter_name, repo_root, function(result, err)
    if not result then
      notify(tostring(err), vim.log.levels.ERROR)
      return
    end

    if not result.supports_list or #result.sessions == 0 then
      if result.supports_list then
        notify("No sessions were listed; enter a session ID manually", vim.log.levels.INFO)
      end
      prompt_for_session_id(callback)
      return
    end

    local items = {
      {
        kind = "manual",
        label = "Enter session ID manually",
      },
    }

    for _, session in ipairs(result.sessions) do
      table.insert(items, {
        kind = "session",
        label = format_session(session),
        session_id = session.sessionId,
        title = session.title,
      })
    end

    vim.ui.select(items, {
      prompt = "CodeCompanion session",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then
        callback(nil)
        return
      end

      if choice.kind == "manual" then
        prompt_for_session_id(callback)
        return
      end

      callback {
        session_id = choice.session_id,
        title = choice.title,
      }
    end)
  end)
end

local function normalize_error(err, fallback)
  if type(err) == "table" then
    if err.message then return err.message end
    return vim.inspect(err)
  end

  if err == nil then return fallback end

  return tostring(err)
end

local function disconnect_connection(connection)
  if type(connection) == "table" and type(connection.disconnect) == "function" then pcall(connection.disconnect, connection) end
end

local function acp_contract_error(connection)
  if type(connection) ~= "table" then return "CodeCompanion ACP connection is unavailable" end
  if type(connection.METHODS) ~= "table" then return "CodeCompanion ACP methods are unavailable" end
  if type(connection.methods) ~= "table" or type(connection.methods.encode) ~= "function" then
    return "CodeCompanion ACP message encoder is unavailable"
  end
  if type(connection.write_message) ~= "function" then return "CodeCompanion ACP writer is unavailable" end
  if type(connection.pending_responses) ~= "table" then return "CodeCompanion ACP response queue is unavailable" end
  if type(connection._state) ~= "table" or not connection._state.id_gen then
    return "CodeCompanion ACP request ID generator is unavailable"
  end
  if type(connection.adapter_modified) ~= "table" then return "CodeCompanion ACP adapter state is unavailable" end

  connection.adapter_modified.defaults = connection.adapter_modified.defaults or {}

  return nil
end

local function send_rpc_request_async(connection, method, params, callback)
  local contract_err = acp_contract_error(connection)
  if contract_err then
    vim.schedule(function()
      callback(nil, contract_err)
    end)
    return
  end
  if type(method) ~= "string" then
    vim.schedule(function()
      callback(nil, "CodeCompanion ACP method is unavailable")
    end)
    return
  end

  local ok_jsonrpc, jsonrpc = pcall(require, "codecompanion.utils.jsonrpc")
  if not ok_jsonrpc then
    vim.schedule(function()
      callback(nil, "CodeCompanion JSON-RPC helpers are unavailable")
    end)
    return
  end

  local ok_id, id = pcall(function()
    return connection._state.id_gen:next()
  end)
  if not ok_id then
    vim.schedule(function()
      callback(nil, "Failed to allocate ACP request ID")
    end)
    return
  end

  local request = jsonrpc.request(id, method, params)
  local ok_encoded, encoded = pcall(connection.methods.encode, request)
  if not ok_encoded then
    vim.schedule(function()
      callback(nil, "Failed to encode ACP request: " .. method)
    end)
    return
  end

  local ok_write, written = pcall(function()
    return connection:write_message(encoded .. "\n")
  end)
  if not ok_write or not written then
    vim.schedule(function()
      callback(nil, "Failed to send ACP request: " .. method)
    end)
    return
  end

  local timer = vim.uv.new_timer()
  local start_time = vim.uv.hrtime()
  local timeout_ms = connection.adapter_modified.defaults.timeout or ACP_TIMEOUT_MS
  local done = false

  local function finish(result, err)
    if done then return end
    done = true

    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end

    vim.schedule(function()
      callback(result, err)
    end)
  end

  timer:start(
    0,
    10,
    vim.schedule_wrap(function()
      if connection.pending_responses[id] then
        local result, err = unpack(connection.pending_responses[id])
        connection.pending_responses[id] = nil
        finish(err and nil or result, err)
        return
      end

      if vim.uv.hrtime() - start_time >= timeout_ms * 1e6 then
        finish(nil, "ACP request timed out: " .. method)
      end
    end)
  )
end

local function register_disconnect_autocmd(connection)
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("codecompanion.acp.disconnect", { clear = false }),
    callback = function()
      pcall(function()
        connection:disconnect()
      end)
    end,
  })
end

local function authenticate_connection_async(connection, callback)
  local contract_err = acp_contract_error(connection)
  if contract_err then
    callback(false, contract_err)
    return
  end

  if
    not connection._authenticated
    and connection.adapter_modified
    and connection.adapter_modified.handlers
    and connection.adapter_modified.handlers.auth
  then
    local ok, result = pcall(connection.adapter_modified.handlers.auth, connection.adapter_modified)
    if not ok then
      callback(false, normalize_error(result, "Adapter auth hook failed"))
      return
    end
    if result == true then connection._authenticated = true end
  end

  if connection._authenticated then
    callback(true)
    return
  end

  local auth_methods = (connection._agent_info and connection._agent_info.authMethods) or {}
  if #auth_methods == 0 then
    connection._authenticated = true
    callback(true)
    return
  end

  local wanted = connection.adapter_modified.defaults.auth_method
  local method_id
  for _, method in ipairs(auth_methods) do
    if method.id == wanted then
      method_id = method.id
      break
    end
  end
  method_id = method_id or (auth_methods[1] and auth_methods[1].id)

  if not method_id then
    connection._authenticated = true
    callback(true)
    return
  end

  send_rpc_request_async(connection, connection.METHODS.AUTHENTICATE, { methodId = method_id }, function(result, err)
    if not result then
      callback(false, normalize_error(err, "Authentication failed"))
      return
    end

    connection._authenticated = true
    callback(true)
  end)
end

local function connect_and_authenticate_async(adapter_name, repo_root, callback)
  local ok_adapter, adapter = pcall(require("codecompanion.adapters").resolve, adapter_name)
  if not ok_adapter then
    callback(nil, normalize_error(adapter, "Could not resolve ACP adapter"))
    return
  end

  local ok_connection, connection = pcall(function()
    return require("codecompanion.acp").new { adapter = adapter }
  end)
  if not ok_connection then
    callback(nil, normalize_error(connection, "Could not create ACP connection"))
    return
  end

  local ok_start, started = pcall(function()
    return with_cwd(repo_root, function()
      return connection:start_agent_process()
    end)
  end)

  if not ok_start or not started then
    disconnect_connection(connection)
    callback(nil, normalize_error(started, "Failed to start ACP process"))
    return
  end

  local contract_err = acp_contract_error(connection)
  if contract_err then
    disconnect_connection(connection)
    callback(nil, contract_err)
    return
  end

  send_rpc_request_async(connection, connection.METHODS.INITIALIZE, connection.adapter_modified.parameters, function(initialized, err)
    if not initialized then
      disconnect_connection(connection)
      callback(nil, normalize_error(err, "Failed to initialize ACP agent"))
      return
    end

    connection._agent_info = initialized
    connection._initialized = true
    register_disconnect_autocmd(connection)

    authenticate_connection_async(connection, function(ok, auth_err)
      if not ok then
        disconnect_connection(connection)
        callback(nil, auth_err)
        return
      end

      callback(connection)
    end)
  end)
end

local function load_session_async(connection, repo_root, session_id, callback)
  local contract_err = acp_contract_error(connection)
  if contract_err then
    callback(nil, contract_err)
    return
  end

  local config = require("codecompanion.config")
  local updates = {}
  local session_args = {
    cwd = repo_root,
    mcpServers = connection.adapter_modified.defaults.mcpServers,
  }

  if
    connection.adapter_modified.defaults.mcpServers == "inherit_from_config"
    and config.mcp
    and config.mcp.opts
    and config.mcp.opts.acp_enabled
  then
    session_args.mcpServers = require("codecompanion.mcp").transform_to_acp()
  end

  connection.session_id = session_id
  connection._loading_session = true
  connection._on_session_update = function(update)
    table.insert(updates, update)
  end

  send_rpc_request_async(
    connection,
    connection.METHODS.SESSION_LOAD,
    vim.tbl_extend("force", session_args, { sessionId = session_id }),
    function(result, err)
      connection._loading_session = nil
      connection._on_session_update = nil

      if not result then
        connection.session_id = nil
        callback(nil, normalize_error(err, "Failed to load session"))
        return
      end

      callback(updates)
    end
  )
end

local function create_restored_chat(codecompanion, binding, connection, updates)
  local chat = codecompanion.chat {
    hidden = true,
    params = { adapter = binding.adapter },
  }

  if not chat then error("Could not create a CodeCompanion chat") end

  chat.acp_connection = connection
  chat:update_metadata()
  local watch = require("codecompanion.interactions.shared.watch")
  local commands = require("codecompanion.interactions.chat.acp.commands")
  local render = require("codecompanion.interactions.chat.acp.render")

  if type(watch.enable) ~= "function" then error("CodeCompanion watch API is unavailable") end
  if type(commands.link_buffer_to_session) ~= "function" then error("CodeCompanion ACP command API is unavailable") end
  if type(render.restore_session) ~= "function" then error("CodeCompanion ACP render API is unavailable") end

  watch.enable()
  commands.link_buffer_to_session(chat.bufnr, connection.session_id)
  render.restore_session(chat, updates)

  if binding.title and binding.title ~= "" then chat:set_title(binding.title) end

  return chat
end

local function show_or_toggle_chat(chat)
  local codecompanion = ensure_codecompanion()
  if not codecompanion then return end

  if chat.ui:is_visible() then
    chat.ui:hide()
    return
  end

  codecompanion.close_last_chat()
  codecompanion.restore(chat.bufnr)
end

local function open_bound_chat(repo_root, binding)
  local codecompanion = ensure_codecompanion()
  if not codecompanion then return end

  notify("Restoring " .. format_adapter_name(binding.adapter) .. " session...", vim.log.levels.INFO)

  connect_and_authenticate_async(binding.adapter, repo_root, function(connection, connect_err)
    if not connection then
      notify(connect_err, vim.log.levels.ERROR)
      notify("Use <Leader>Ab to rebind this repo session", vim.log.levels.INFO)
      return
    end

    load_session_async(connection, repo_root, binding.session_id, function(updates, load_err)
      if not updates then
        disconnect_connection(connection)
        notify(load_err, vim.log.levels.ERROR)
        notify("Use <Leader>Ab to rebind this repo session", vim.log.levels.INFO)
        return
      end

      local ok_chat, chat_or_err = pcall(create_restored_chat, codecompanion, binding, connection, updates)
      if not ok_chat then
        disconnect_connection(connection)
        notify(tostring(chat_or_err), vim.log.levels.ERROR)
        return
      end

      live_chats[repo_root] = chat_or_err.bufnr
      show_or_toggle_chat(chat_or_err)
    end)
  end)
end

local function bind_repo(opts)
  opts = opts or {}

  if not ensure_codecompanion() then return end

  local repo_root = opts.repo_root or get_repo_root()
  local current = get_binding(repo_root)

  choose_adapter(function(adapter_name)
    if not adapter_name then return end

    choose_session(adapter_name, repo_root, function(session)
      if not session then return end

      local binding = {
        adapter = adapter_name,
        session_id = session.session_id,
        title = session.title,
      }

      if not set_binding(repo_root, binding) then return end

      close_live_chat(repo_root)
      notify(
        string.format("Bound %s to %s", format_adapter_name(adapter_name), session.session_id),
        vim.log.levels.INFO
      )

      if opts.open ~= false then open_bound_chat(repo_root, binding) end
    end)
  end, current and current.adapter or nil)
end

function M.open_repo_chat()
  local repo_root = get_repo_root()
  local chat = get_live_chat(repo_root)
  if chat then
    show_or_toggle_chat(chat)
    return
  end

  local binding = get_binding(repo_root)
  if not binding then
    bind_repo { repo_root = repo_root, open = true }
    return
  end

  open_bound_chat(repo_root, binding)
end

function M.bind_repo_chat()
  bind_repo { open = false }
end

function M.clear_repo_binding()
  local repo_root = get_repo_root()

  if clear_binding(repo_root) then
    close_live_chat(repo_root)
    notify("Cleared the repo session binding", vim.log.levels.INFO)
  end
end

function M.show_repo_info()
  local repo_root = get_repo_root()
  local binding = get_binding(repo_root)
  if not binding then
    notify("No session binding stored for this repo", vim.log.levels.INFO)
    return
  end

  local chat = get_live_chat(repo_root)
  local lines = {
    "Repo: " .. repo_root,
    "Client: " .. format_adapter_name(binding.adapter),
    "Session: " .. binding.session_id,
  }

  if binding.title and binding.title ~= "" then table.insert(lines, "Title: " .. binding.title) end
  if chat then table.insert(lines, "Chat buffer: " .. chat.bufnr) end

  notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
