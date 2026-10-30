---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "yazi"
local menu        = "quickshell ipc call island open launcher"
local browser     = "firefox"
local fastfetch   = "fastfetch"


---------------------
---- KEYBINDINGS ----
---------------------

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q",                hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q",        hl.dsp.window.close({ force = true }))
hl.bind(mainMod .. " + SHIFT + CTRL + Q", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + R",        hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + SPACE",    hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + SPACE",     hl.dsp.window.pseudo())
hl.bind(mainMod .. " + ALT + SPACE",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F",                hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + A",                hl.dsp.window.pin())
hl.bind(mainMod .. " + Z",                hl.dsp.exec_cmd("hyprlock"))

-- Quickshell island
hl.bind(mainMod .. " + CTRL + A",         hl.dsp.exec_cmd("quickshell ipc call island togglePeek"))
hl.bind(mainMod .. " + SHIFT + A",        hl.dsp.exec_cmd("quickshell ipc call island toggleAutohide"))
hl.bind(mainMod .. " + A",                hl.dsp.exec_cmd("quickshell ipc call island open tabs"))

hl.bind(mainMod .. " + B",                hl.dsp.exec_cmd("quickshell ipc call island open bluetooth"))
hl.bind(mainMod .. " + Y",                hl.dsp.exec_cmd("quickshell ipc call island open network"))
hl.bind(mainMod .. " + N",                hl.dsp.exec_cmd("quickshell ipc call island open notifications"))
hl.bind(mainMod .. " + V",                hl.dsp.exec_cmd("quickshell ipc call island open mixer"))      -- every app's volume

hl.bind(mainMod .. " + TAB",              hl.dsp.exec_cmd("quickshell ipc call island open workspaces"))
hl.bind(mainMod .. " + G",                hl.dsp.exec_cmd("quickshell ipc call island open dashboard"))
hl.bind(mainMod .. " + I",                hl.dsp.exec_cmd("quickshell ipc call island open settings"))
hl.bind(mainMod .. " + M",                hl.dsp.exec_cmd("quickshell ipc call island open media"))
hl.bind(mainMod .. " + U",                hl.dsp.exec_cmd("quickshell ipc call island open battery"))
hl.bind(mainMod .. " + T",                hl.dsp.exec_cmd("quickshell ipc call island open theme"))
hl.bind(mainMod .. " + C",                hl.dsp.exec_cmd("quickshell ipc call island open clock"))
hl.bind(mainMod .. " + X",                hl.dsp.exec_cmd("quickshell ipc call island open power"))

hl.bind(mainMod .. " + SPACE", function()
    local win = hl.get_active_window()
    if not win then return end -- nothing focused (e.g. empty workspace)
    hl.dispatch(hl.dsp.window.cycle_next({
        floating = not win.floating
    }))
end, { description = "Switch focus between tiled and floating windows" })

hl.bind(mainMod .. " + SHIFT + Return",   hl.dsp.exec_cmd(terminal .. " --hold -e " .. fastfetch))
hl.bind(mainMod .. " + Return",           hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",                hl.dsp.exec_cmd(terminal .. " -e " .. fileManager))
hl.bind(mainMod .. " + D",                hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + W",                hl.dsp.exec_cmd(browser))

-- Screenshots
hl.bind("PRINT",                          hl.dsp.exec_cmd("grimblast --notify copy area"),   { locked = true })
hl.bind(mainMod .. " + PRINT",            hl.dsp.exec_cmd("grimblast --notify copy screen"), { locked = true })
hl.bind(mainMod .. " + SHIFT + PRINT",     hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grimblast --notify save area ~/Pictures/Screenshots/$(date +%s).png"), { locked = true })

-- Move focus
hl.bind(mainMod .. " + Left",             hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right",            hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",               hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",                hl.dsp.focus({ direction = "down" }))

-- Move windows around in the tiling layout
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.swap({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))

-- Switch/move workspaces with mainMod + [0-9]
for i = 1, 10 do
  local key = tostring(i % 10)  -- 10 → "0", 1-9 → "1"-"9"
  hl.bind(mainMod .. " +" .. key,         hl.dsp.focus({ workspace = tostring(i) }))
  hl.bind(mainMod .. " + SHIFT +" .. key,   hl.dsp.window.move({ workspace = tostring(i) }))
end

-- ─── Window Resize (hold to repeat) ──────────────────────────
hl.bind(mainMod .. " + ALT + Left",  hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.resize({ x = 30,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Up",    hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Down",  hl.dsp.window.resize({ x = 0, y = 30,  relative = true }), { repeating = true })

hl.bind(mainMod .. " + ALT + H",  hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + L",  hl.dsp.window.resize({ x = 30,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + K",  hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + J",  hl.dsp.window.resize({ x = 0, y = 30,  relative = true }), { repeating = true })

-- ─── Window Move / Float (hold to repeat) ─────────────────────
hl.bind(mainMod .. " + CTRL + Left",  hl.dsp.window.move({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ x = 30,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Up",    hl.dsp.window.move({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + Down",  hl.dsp.window.move({ x = 0, y = 30,  relative = true }), { repeating = true })

hl.bind(mainMod .. " + CTRL + H",  hl.dsp.window.move({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L",  hl.dsp.window.move({ x = 30,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K",  hl.dsp.window.move({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J",  hl.dsp.window.move({ x = 0, y = 30,  relative = true }), { repeating = true })

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
