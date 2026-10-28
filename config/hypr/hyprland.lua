-- The config lives in modules/: autoload.lua runs every .lua file there, in name order.
--
--   autostart.lua  programs started with Hyprland
--   binds.lua      programs and keybindings
--   env.lua        environment variables, permissions
--   input.lua      keyboard, mouse, touchpad, gestures, devices
--   look.lua       gaps, borders, the glass (opacity, blur, `glass` layer rule), animations
--   monitors.lua   monitors
--   rules.lua      window and workspace rules

require("autoload")
