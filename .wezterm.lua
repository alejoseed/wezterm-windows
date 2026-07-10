-- .wezterm.lua  (place in your Windows home: %USERPROFILE%\.wezterm.lua)
-- tmux-flavored WezTerm config: Ctrl-S is the "prefix" (leader), like tmux.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- Shell: open straight into a WSL distro.
-- Change `wsl_distro` to match this machine (run `wsl -l -q` to list them).
-- Set it to nil to use WezTerm's default program instead of WSL.
--------------------------------------------------------------------------------
local wsl_distro = 'Arch'
config.default_domain = wsl_distro and ('WSL:' .. wsl_distro) or 'local'

--------------------------------------------------------------------------------
-- Look & feel
--------------------------------------------------------------------------------
config.font = wezterm.font 'JetBrains Mono'   -- ships with WezTerm
config.font_size = 11.0
config.line_height = 1.3                      -- thickens the retro tab bar (also spaces terminal text a bit)
config.color_scheme = 'Catppuccin Mocha'      -- built in; swap freely
config.scrollback_lines = 50000               -- native scrollback (mouse wheel just works)
config.enable_scroll_bar = true
config.window_decorations = 'RESIZE'          -- thin/no title bar
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.tab_bar_at_bottom = false              -- bar on top
config.use_fancy_tab_bar = false              -- retro bar: required for tmux-style powerline segments
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.tab_bar_style = { new_tab = '', new_tab_hover = '' }  -- hide the stray "+" button
config.window_close_confirmation = 'NeverPrompt'  -- Ctrl-S x closes without nagging

--------------------------------------------------------------------------------
-- Performance / input latency (WebGpu felt snappier than OpenGL; 60->144 fps)
--------------------------------------------------------------------------------
config.front_end = 'WebGpu'                         -- Dx12 backend; tighter frame pacing than OpenGL on NVIDIA
config.webgpu_power_preference = 'HighPerformance'  -- prefer the discrete GPU
config.max_fps = 144                                -- set to your monitor's refresh rate (default is 60)

--------------------------------------------------------------------------------
-- Leader key = Ctrl-S  (the tmux prefix). ~1s window to press the next key.
--------------------------------------------------------------------------------
config.leader = { key = 's', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- Press Ctrl-S twice to send a literal Ctrl-S to the shell
  { key = 's', mods = 'LEADER|CTRL', action = act.SendKey { key = 's', mods = 'CTRL' } },

  -- Tabs (tmux "windows")
  { key = 'c', mods = 'LEADER',       action = act.SpawnTab 'CurrentPaneDomain' },      -- new tab
  { key = 'x', mods = 'LEADER',       action = act.CloseCurrentPane { confirm = true } }, -- close (asks to confirm)
  { key = 'n', mods = 'LEADER',       action = act.ActivateTabRelative(1) },            -- next
  { key = 'p', mods = 'LEADER',       action = act.ActivateTabRelative(-1) },           -- prev
  { key = ',', mods = 'LEADER',       action = act.PromptInputLine {                    -- rename tab
      description = 'Rename tab:',
      action = wezterm.action_callback(function(window, _, line)
        if line and #line > 0 then window:active_tab():set_title(line) end
      end),
  } },

  -- Panes / windowing (tmux splits)
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } }, -- split right
  { key = '-', mods = 'LEADER',       action = act.SplitVertical   { domain = 'CurrentPaneDomain' } }, -- split down
  { key = 'h', mods = 'LEADER',       action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER',       action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER',       action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER',       action = act.ActivatePaneDirection 'Right' },
  { key = 'z', mods = 'LEADER',       action = act.TogglePaneZoomState },               -- zoom pane
  { key = 'w', mods = 'LEADER',       action = act.CloseCurrentPane { confirm = false } }, -- close pane

  -- Resize panes: Ctrl-S then Shift+arrow
  { key = 'LeftArrow',  mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'DownArrow',  mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'UpArrow',    mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },

  -- Scrollback / copy mode (tmux prefix-[)
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },

  -- Quality of life
  { key = 'f', mods = 'LEADER', action = act.Search { CaseInSensitiveString = '' } },   -- search scrollback
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },                     -- reload config
}

-- Ctrl-S then a number jumps to that tab (1-9), like tmux
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'LEADER', action = act.ActivateTab(i - 1),
  })
end

--------------------------------------------------------------------------------
-- tmux-style powerline status bar (all local, no plugins)
--------------------------------------------------------------------------------
local SEP_RIGHT = utf8.char(0xe0b0) --
local SEP_LEFT  = utf8.char(0xe0b2) --

-- Catppuccin Mocha palette
local P = {
  bar     = '#1e1e2e',
  surface = '#313244',
  text    = '#cdd6f4',
  crust   = '#11111b',
  green   = '#a6e3a1',
  blue    = '#89b4fa',
  mauve   = '#cba6f7',
  peach   = '#fab387',
  red     = '#f38ba8',
}

-- Each tab rendered as an angled powerline segment
wezterm.on('format-tab-title', function(tab)
  local title = tab.tab_title
  if not title or #title == 0 then title = tab.active_pane.title end
  title = title:gsub('%.exe$', '')
  local bg = tab.is_active and P.mauve or P.surface
  local fg = tab.is_active and P.crust or P.text
  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Text = ' ' .. (tab.tab_index + 1) .. ' ' .. title .. ' ' },
    { Background = { Color = P.bar } },
    { Foreground = { Color = bg } },
    { Text = SEP_RIGHT },
  }
end)

wezterm.on('update-status', function(window, pane)
  -- LEFT: workspace segment; turns red + "PREFIX" while Ctrl-S leader is armed
  local armed = window:leader_is_active()
  local ws_bg = armed and P.red or P.green
  local ws = armed and ('PREFIX ' .. window:active_workspace()) or window:active_workspace()
  window:set_left_status(wezterm.format {
    { Background = { Color = ws_bg } },
    { Foreground = { Color = P.crust } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = ' ' .. ws .. ' ' },
    { Background = { Color = P.bar } },
    { Foreground = { Color = ws_bg } },
    { Text = SEP_RIGHT },
  })

  -- RIGHT: powerline segments  cwd | domain | date-time
  local cwd = ''
  local ok_cwd, uri = pcall(function() return pane:get_current_working_dir() end)
  if ok_cwd and uri then
    cwd = type(uri) == 'userdata' and (uri.file_path or '') or tostring(uri)
    cwd = cwd:gsub('/$', ''):gsub('.*/', '')
  end
  local domain = (pane and pane:get_domain_name()) or ''

  local segments = {
    { bg = P.surface, fg = P.text,  text = cwd ~= '' and cwd or '~' },
    { bg = P.blue,    fg = P.crust, text = domain },
    { bg = P.peach,   fg = P.crust, text = wezterm.strftime '%a %b %d  %H:%M' },
  }

  local cells, prev = {}, P.bar
  for _, s in ipairs(segments) do
    table.insert(cells, { Background = { Color = prev } })
    table.insert(cells, { Foreground = { Color = s.bg } })
    table.insert(cells, { Text = SEP_LEFT })
    table.insert(cells, { Background = { Color = s.bg } })
    table.insert(cells, { Foreground = { Color = s.fg } })
    table.insert(cells, { Attribute = { Intensity = 'Bold' } })
    table.insert(cells, { Text = ' ' .. s.text .. ' ' })
    prev = s.bg
  end
  window:set_right_status(wezterm.format(cells))
end)

--------------------------------------------------------------------------------
-- Session persistence (resurrect.wezterm plugin, fetched from GitHub on first
-- launch). Guarded so a failed fetch never breaks the config.
--   Ctrl-S Shift-S  save workspace   |   Ctrl-S Shift-R  restore (picker)
--   Auto-saves every 5 minutes.
--------------------------------------------------------------------------------
local ok_res, resurrect = pcall(function()
  return wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
end)

if ok_res then
  resurrect.state_manager.periodic_save {
    interval_seconds = 300,
    save_workspaces = true,
  }

  table.insert(config.keys, {
    key = 'S', mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(function(win, _)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      win:toast_notification('WezTerm', 'workspace saved', nil, 2000)
    end),
  })

  table.insert(config.keys, {
    key = 'R', mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load_state(win, pane, function(id)
        local kind = string.match(id, '^([^/]+)')
        id = string.match(id, '([^/]+)$')
        id = string.match(id, '(.+)%..+$')
        local state = resurrect.state_manager.load_state(id, kind)
        resurrect.workspace_state.restore_workspace(state, {
          window = win:mux_window(),
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        })
      end)
    end),
  })
else
  wezterm.log_warn 'resurrect.wezterm unavailable (offline?); session persistence disabled'
end

return config
