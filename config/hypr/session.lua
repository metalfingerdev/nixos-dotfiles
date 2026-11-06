-- The programs that come with the session: modules/autostart.lua starts them with Hyprland, and
-- Super+Shift+R (modules/binds.lua) reloads Hyprland's config and starts them over.
-- Loaded with dofile (not require), so a reload always reads this file again.
--
--   start    how to start it
--   stop     how to stop it: its own command, so only this instance goes (a quickshell run by hand
--            from another config, `qs -p ...`, is left alone)
--   running  succeeds while it's still running

local M = {}

M.apps = {
    { start = "awww-daemon", stop = "awww kill",       running = "awww query" },
    { start = "quickshell",  stop = "quickshell kill", running = "quickshell list -j | grep -q '\"pid\"'" },
}

function M.start()
    for _, app in ipairs(M.apps) do
        hl.exec_cmd(app.start)
    end
end

-- Reload the config, stop every app, wait (at most 3 s) until they're all gone, start them again.
-- Waiting matters: a new quickshell can't take the notification server while the old one has it.
function M.restart()
    local stop, running, start = {}, {}, {}
    for _, app in ipairs(M.apps) do
        stop[#stop + 1]       = app.stop
        running[#running + 1] = "{ " .. app.running .. "; }"
        start[#start + 1]     = "setsid -f " .. app.start
    end
    hl.exec_cmd(table.concat({
        "hyprctl reload",
        table.concat(stop, "; "),
        "i=0; while [ $i -lt 30 ] && { " .. table.concat(running, " || ") .. "; } >/dev/null 2>&1; do sleep 0.1; i=$((i + 1)); done",
        table.concat(start, "; "),
    }, "; "))
end

return M
