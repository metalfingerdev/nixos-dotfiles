-----------------------
---- COLOUR PALETTE ----
-----------------------

local beige  = "rgb(D8CAB8)"
local lime   = "rgb(C4E881)"
local purple = "rgb(AC82E9)"
local violet = "rgb(8F56E1)"


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,

        border_size = 1,

        col = {
          active_border   = { colors = { beige }, angle = 90 },
          inactive_border = { colors = { violet }, angle = 90 },
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2,

        -- Glass: every window at 80 %, over the blur below, so what's behind shows through frosted
        -- while the window itself stays readable. Fullscreen stays opaque (video, games).
        -- Quickshell's island reads active_opacity and draws itself at the same opacity.
        active_opacity     = 0.8,
        inactive_opacity   = 0.8,
        fullscreen_opacity = 1.0,

        -- macOS: a wide soft shadow, lying below the window as if lit from above, deep on the window
        -- in focus and fading to about half on the others. rules.lua keeps it to floating windows.
        -- All but the colours are global in Hyprland: no window can have a smaller one of its own.
        -- The island is a layer, and Hyprland has no shadows for layers: Quickshell draws its own (Bar).
        shadow = {
            enabled        = true,
            range          = 70,
            render_power   = 2,
            offset         = { 0, 12 },
            scale          = 0.985, -- pulls the shadow's solid core under the window, or it shows as a dark band below it
            color          = 0x66000000,
            color_inactive = 0x33000000,
        },

        -- Frosted, not just soft: a wide smooth blur (size x passes), a little grain, and a touch
        -- darker so text on the glass keeps its contrast
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            noise             = 0.02,
            contrast          = 0.9,
            brightness        = 0.8,
            vibrancy          = 0.17,
            new_optimizations = true,
            xray              = false, -- blur what is really behind (other windows too), not only the wallpaper
            popups            = true,  -- menus and tooltips are glass too
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true, -- You probably want this
    },

    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})

-- The glass layer: any layer surface (a shell, bar, launcher) named `glass`, or `glass:<something>`,
-- gets the same blur as the windows. Quickshell's island is `glass:island`.
hl.layer_rule({
    name         = "glass",
    match        = { namespace = "^glass(:.+)?$" },
    blur         = true,
    ignore_alpha = 0.4, -- a full-screen overlay is transparent outside what it draws: blur only that, and not its shadow
})

-- Curves: plain beziers, none of them overshoots (no springs).
-- Glide is shared with Quickshell's island (Config.curve / motionMs: same points, 350 ms = speed 3.5),
-- so windows and the island move alike.
hl.curve("Glide",   { type = "bezier", points = { {0.22, 1},    {0.36, 1}    } })  -- ease-out for movement
hl.curve("Snap",    { type = "bezier", points = { {0.25, 0.1},  {0.25, 1}    } })  -- general smooth ease
hl.curve("Close",   { type = "bezier", points = { {0.4,  0},    {0.6,  1}    } })  -- clean ease-in for close
hl.curve("Slide",   { type = "bezier", points = { {0.25, 0.46}, {0.45, 0.94} } })  -- workspace slide
hl.curve("Fade",    { type = "bezier", points = { {0.4,  0},    {1,    1}    } })  -- quick fade out

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default"   })

hl.animation({ leaf = "windows",       enabled = true,  speed = 3.5,  bezier = "Glide"               })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 3.5,  bezier = "Glide",  style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 2.0,  bezier = "Close",  style = "popin 92%" })

hl.animation({ leaf = "border",        enabled = true,  speed = 4,    bezier = "Snap"   })

hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 2.5,  bezier = "Snap"   })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 2.0,  bezier = "Fade"   })
hl.animation({ leaf = "fade",          enabled = true,  speed = 2.5,  bezier = "Snap"   })

hl.animation({ leaf = "layers",        enabled = true,  speed = 3,    bezier = "Snap"              })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 2.8,  bezier = "Snap",  style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.8,  bezier = "Fade",  style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 2.2,  bezier = "Snap"   })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.6,  bezier = "Fade"   })

hl.animation({ leaf = "workspaces",    enabled = true,  speed = 3.5,  bezier = "Slide", style = "slide"  })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 3.5,  bezier = "Slide", style = "slide"  })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 3.5,  bezier = "Slide", style = "slide"  })

hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 5,    bezier = "Snap"   })
