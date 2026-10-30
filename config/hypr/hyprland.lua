-- The config lives in modules/: autoload.lua runs every .lua file there, in name order.
--
--   autostart.lua  programs started with Hyprland
--   binds.lua      programs and keybindings
--   env.lua        environment variables, permissions
--   input.lua      keyboard, mouse, touchpad, gestures, devices
--   look.lua       gaps, borders, the glass (opacity, blur, `glass` layer rule), animations
--   monitors.lua   monitors
--   rules.lua      window and workspace rules
--
-- session.lua (here, not in modules/) lists the programs that come with the session: autostart.lua
-- starts them, and Super+Shift+R restarts them along with the config.

require("autoload")
