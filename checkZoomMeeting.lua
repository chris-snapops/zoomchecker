local frequency = 2
local aircallAppName = "Aircall Workspace"
local aircallAppPath = "/Applications/Aircall Workspace.app"
local shortcutBasePath = os.getenv("HOME") .. "/.hammerspoon/ZoomChecker/mac_shortcuts"
local enableShortcutPath = shortcutBasePath .. "/Enable DND.shortcut"
local disableShortcutPath = shortcutBasePath .. "/Disable DND.shortcut"

local function log(msg)
    print('[ZoomChecker] ' .. msg)
end

local function is_shortcut_installed(shortcut_path)
    local shortcut_name = shortcut_path:match("([^/\\]+)%.shortcut$")
    if not shortcut_name then
        log("Could not extract shortcut name from path: " .. shortcut_path)
        return false
    end
    local script = string.format([[
        tell application "Shortcuts Events"
            set shortcutNames to name of shortcuts
            return shortcutNames contains "%s"
        end tell
    ]], shortcut_name)
    local ok, result = hs.osascript.applescript(script)
    return ok and result == true
end

local function install_shortcut_if_needed(shortcut_path)
    if is_shortcut_installed(shortcut_path) then
        log("Shortcut already installed.")
    else
        log("Shortcut not found. Prompting user to install it.")
        hs.execute("open '" .. shortcut_path .. "'")
    end
end

local function run_dnd_shortcut(action)
    log(action .. " DND")
    hs.osascript.applescript(string.format([[
        tell application "Shortcuts Events"
            run shortcut "%s DND"
        end tell
    ]], action))
end

local function checkZoomMeeting(zoomApp)
    if not zoomApp then return false end
    local menuItems = zoomApp:getMenuItems()
    if not menuItems then return false end
    for _, menu in ipairs(menuItems) do
        if menu["AXTitle"] == "Meeting" then
            return true
        end
    end
    return false
end

-- Check Aircall exists in /Applications once
local aircallInstalled = hs.fs.attributes(aircallAppPath, "mode") == "directory"
if not aircallInstalled then
    log("Aircall is not installed in /Applications. Skipping Aircall controls.")
end

local function set_aircall_state(state)
    if not aircallInstalled then return end
    local aircall = hs.application.get(aircallAppName)

    if state == "disable" then
        if aircall then
            aircall:kill()
            log("Aircall quit")
        end
    elseif state == "enable" then
        if not aircall then
            hs.application.launchOrFocus(aircallAppName)
            hs.timer.doAfter(0.3, function()
                local app = hs.application.get(aircallAppName)
                if app then app:hide() end
                log("Aircall launched & minimized")
            end)
        end
    end
end

-- Install shortcuts once
install_shortcut_if_needed(enableShortcutPath)
install_shortcut_if_needed(disableShortcutPath)

local lastState = nil

zoomWatcher = hs.timer.doEvery(frequency, function()
    local zoomApp = hs.application.get("zoom.us")
    local inMeeting = checkZoomMeeting(zoomApp)

    if zoomApp and inMeeting and lastState ~= "inMeeting" then
        lastState = "inMeeting"
        log(lastState)
        run_dnd_shortcut("Enable")
        set_aircall_state("disable")
    elseif not inMeeting and lastState ~= "notInMeeting" then
        lastState = "notInMeeting"
        log(lastState)
        run_dnd_shortcut("Disable")
        set_aircall_state("enable")
    end
end)

log("Checking for zoom meeting every " .. frequency .. " seconds.")