--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Shadows (look.lua) only where a window lies over something, as on macOS: floating windows, dialogs
-- and pinned ones. A tiled window has nothing under it but its neighbours, 4 px away, and a shadow
-- this wide would lie across them. These follow a window as it's toggled between the two.
hl.window_rule({
    name  = "no-shadow-tiled",
    match = { float = false },

    no_shadow = true,
})
hl.window_rule({
    name  = "no-shadow-fullscreen",
    match = { fullscreen = true },

    no_shadow = true,
})

-- Video stays solid: the 80 % glass (look.lua) washes the blurred wallpaper into the picture.
-- Fullscreen is already opaque; these cover video in a tiled or floating window.
hl.window_rule({
    -- Players that say they're showing video (mpv and others speaking wp-content-type)
    name  = "opaque-video-content",
    match = { content = "video" },

    opaque = true,
})

-- Firefox is always solid, whatever the tab shows.
hl.window_rule({
    name  = "opaque-firefox",
    match = { class = "^firefox$" },

    opaque = true,
})


-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
