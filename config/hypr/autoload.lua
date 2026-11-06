-- Runs every .lua file under modules/ (subfolders too), in path order.
-- Each file runs on its own, so locals don't carry from one module to the next.
-- A module that fails is shown as a notification and skipped; the rest still load.

local modules = os.getenv("HOME") .. "/.config/hypr/modules"

local function warn(text)
    hl.notification.create({
        text    = "autoload: " .. text,
        timeout = 8000,
        icon    = "warning",
    })
end

local p = io.popen('find -L "' .. modules .. '" -type f -name "*.lua" | sort')
if not p then
    warn("could not list " .. modules)
    return
end

local loaded = 0
for path in p:lines() do
    local ok, err = pcall(dofile, path)
    if ok then
        loaded = loaded + 1
    else
        warn(path .. "\n" .. tostring(err))
    end
end

p:close()

if loaded == 0 then
    warn("no modules loaded from " .. modules)
end
