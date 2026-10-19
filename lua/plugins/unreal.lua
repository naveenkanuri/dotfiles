-- Unreal Engine workflow: build the game and refresh clangd's view of it without leaving Neovim.
--
-- Keymaps exist only in buffers that live inside an Unreal project (a folder holding a
-- `*.uproject`), so other repos are untouched:
--   <Leader>Ub  build `<Project>Editor`; compile errors land in the quickfix list
--   <Leader>Ur  regenerate `compile_commands.json`, point the engine link here, restart clangd
--
-- Engine headers have no compile database above them, so the clangd user config
-- (~/Library/Preferences/clangd/config.yaml) sends any `UE_*` engine file to the database
-- behind `ENGINE_LINK`. <Leader>Ur repoints that link at the current project.

local ENGINE_LINK = vim.fn.expand "~/.cache/clangd/unreal-active"
local BUILD_LOG = vim.fn.stdpath "cache" .. "/unreal-build.log"
local LAUNCHER_MANIFEST = vim.fn.expand "~/Library/Application Support/Epic/UnrealEngineLauncher/LauncherInstalled.dat"

-- clang reports `file:line:col: error: msg`; Unreal Header Tool (reflection codegen) uses the
-- MSVC style `file(line): Error: msg`. Everything else UBT prints is progress noise.
local ERROR_FORMAT = table.concat({
  "%f:%l:%c: fatal %trror: %m",
  "%f:%l:%c: %trror: %m",
  "%f:%l:%c: %tarning: %m",
  "%f(%l): %trror: %m",
  "%f(%l): %tarning: %m",
  "%-G%.%#",
}, ",")

-- UBT holds a global mutex anyway; this just avoids stacking a second job behind the first.
local job_running = false

local function notify(msg, level) vim.notify(msg, level or vim.log.levels.INFO, { title = "Unreal" }) end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return nil end
  local decoded_ok, value = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and value or nil
end

-- Describe the Unreal project that owns `buf`, or return nil plus why not.
local function find_project(buf)
  local root = vim.fs.root(buf, function(name) return name:match "%.uproject$" ~= nil end)
  if not root then return nil, "not inside an Unreal project" end

  local uproject
  for name, kind in vim.fs.dir(root) do
    if kind == "file" and name:match "%.uproject$" then uproject = root .. "/" .. name end
  end
  -- Invariant: vim.fs.root matched this folder because it holds a .uproject file.
  assert(uproject, "vim.fs.root returned a folder without a .uproject in it")

  local association = (read_json(uproject) or {}).EngineAssociation
  if not association then return nil, "while attempting to read EngineAssociation from " .. uproject end

  -- Launcher installs are listed as AppName `UE_<version>`. A GUID association means a
  -- source-built engine registered elsewhere.
  -- TODO: support source-built engines if one is ever used.
  local engine
  for _, install in ipairs((read_json(LAUNCHER_MANIFEST) or {}).InstallationList or {}) do
    if install.AppName == "UE_" .. association then engine = install.InstallLocation end
  end
  if not engine then return nil, "while attempting to find the launcher install of UE_" .. association end

  local name = vim.fn.fnamemodify(uproject, ":t:r")
  return {
    root = root,
    uproject = uproject,
    -- Unreal's templates name the editor target `<Project>Editor`; projects that rename it
    -- would need this read from Source/*.Target.cs instead.
    editor_target = name .. "Editor",
    build_sh = engine .. "/Engine/Build/BatchFiles/Mac/Build.sh",
  }
end

-- Run an UnrealBuildTool command in the background; `on_done(code, lines)` runs on the main loop.
local function run_ubt(label, cmd, on_done)
  if job_running then return notify("an Unreal job is already running", vim.log.levels.WARN) end
  job_running = true
  local started = vim.uv.hrtime()
  notify(label .. "...")

  vim.system(
    cmd,
    { text = true },
    vim.schedule_wrap(function(result)
      job_running = false
      local lines = vim.split((result.stdout or "") .. (result.stderr or ""), "\n")
      vim.fn.writefile(lines, BUILD_LOG)
      local seconds = (vim.uv.hrtime() - started) / 1e9
      on_done(result.code, lines, ("%.0fs"):format(seconds))
    end)
  )
end

local function build(project)
  local cmd = {
    project.build_sh,
    project.editor_target,
    "Mac",
    "Development",
    "-project=" .. project.uproject,
    "-waitmutex",
  }
  run_ubt("Building " .. project.editor_target, cmd, function(code, lines, took)
    vim.fn.setqflist({}, " ", { title = "Unreal build", lines = lines, efm = ERROR_FORMAT })
    local errors, warnings = 0, 0
    for _, item in ipairs(vim.fn.getqflist()) do
      if item.valid == 1 then
        if item.type:lower() == "e" then
          errors = errors + 1
        else
          warnings = warnings + 1
        end
      end
    end

    if code == 0 then
      notify(("Build succeeded in %s (%d warnings)"):format(took, warnings))
    elseif errors > 0 then
      notify(("Build failed in %s: %d errors"):format(took, errors), vim.log.levels.ERROR)
      vim.cmd "copen"
    else
      -- Failures UBT reports without a file location (e.g. a locked binary) only show in the log.
      notify(("Build failed in %s; see %s"):format(took, BUILD_LOG), vim.log.levels.ERROR)
    end
  end)
end

local function regenerate_clang_database(project)
  local cmd = {
    project.build_sh,
    "-mode=GenerateClangDatabase",
    "-project=" .. project.uproject,
    project.editor_target,
    "Mac",
    "Development",
    "-OutputDir=" .. project.root,
    "-waitmutex",
  }
  run_ubt("Regenerating clangd database", cmd, function(code, _, took)
    if code ~= 0 then
      return notify(("Regenerating failed in %s; see %s"):format(took, BUILD_LOG), vim.log.levels.ERROR)
    end

    -- Repoint the engine link. Unlink first because fs_symlink refuses to replace a link.
    vim.fn.mkdir(vim.fs.dirname(ENGINE_LINK), "p")
    vim.uv.fs_unlink(ENGINE_LINK)
    local ok, err = vim.uv.fs_symlink(project.root, ENGINE_LINK)
    if not ok then
      return notify("while attempting to link " .. ENGINE_LINK .. ": " .. tostring(err), vim.log.levels.ERROR)
    end

    -- clangd caches each compile database it loads, so it must restart to see the new one.
    vim.cmd "lsp restart clangd"
    notify(("clangd database regenerated in %s"):format(took))
  end)
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    autocmds = {
      unreal_keymaps = {
        {
          event = { "BufReadPost", "BufNewFile" },
          desc = "Add Unreal build keymaps in Unreal projects",
          callback = function(args)
            if vim.bo[args.buf].buftype ~= "" or not find_project(args.buf) then return end

            -- Look the project up again on each press so a stale buffer never builds the wrong one.
            local function with_project(action)
              return function()
                local project, why = find_project(args.buf)
                if not project then return notify(why, vim.log.levels.ERROR) end
                action(project)
              end
            end
            vim.keymap.set("n", "<Leader>Ub", with_project(build), { buffer = args.buf, desc = "Unreal: build editor" })
            vim.keymap.set(
              "n",
              "<Leader>Ur",
              with_project(regenerate_clang_database),
              { buffer = args.buf, desc = "Unreal: regenerate clangd database" }
            )
          end,
        },
      },
    },
  },
}
