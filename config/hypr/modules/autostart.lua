-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- The programs are listed in ../session.lua (Super+Shift+R starts them over).
local session = dofile(os.getenv("HOME") .. "/.config/hypr/session.lua")

hl.on("hyprland.start", function ()
    session.start()
end)
