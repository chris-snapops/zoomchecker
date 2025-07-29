-- require('ZoomChecker.zoomCheckerUI')
local config = require('ZoomChecker.config')
local json = require("hs.json")

local frequency = config.get_frequency()
local disable_dnd_during_zoom = config.get_disable_dnd_during_zoom()
local app_paths_to_disable = config.get_apps_to_quit_during_zoom()
local shortcut_base_path = os.getenv("HOME") .. "/.hammerspoon/ZoomChecker/mac_shortcuts"
local enable_shortcut_path = shortcut_base_path .. "/Enable DND.shortcut"
local disable_shortcut_path = shortcut_base_path .. "/Disable DND.shortcut"

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
    if not disable_dnd_during_zoom then return nil end

    log(action .. " DND")
    hs.osascript.applescript(string.format([[
        tell application "Shortcuts Events"
            run shortcut "%s DND"
        end tell
    ]], action))
end

local function check_zoom_meeting(zoom_app)
    if not zoom_app then return false end
    local menu_items = zoom_app:getMenuItems()
    if not menu_items then return false end
    for _, menu in ipairs(menu_items) do
        if menu["AXTitle"] == "Meeting" then
            return true
        end
    end
    return false
end


local function set_app_states(state)
    print('HERE ' .. tostring(json.encode(app_paths_to_disable)))

    for _, app_name in ipairs(app_paths_to_disable) do
        local app = hs.application.get(app_name)
        
        if state == "disable" then
            if app then
                app:kill()
                log(app_name .. " quit")
            end
        elseif state == "enable" then
            if not app then
                hs.application.launchOrFocus(app_name)
                hs.timer.doAfter(0.3, function()
                    local opened_app = hs.application.get(app_name)
                    if opened_app then
                        local win = opened_app:mainWindow()
                        if win then
                            win:minimize()
                            log(app_name .. " launched & minimized")
                        end
                    end
                end)
            end
        end
    end
end


-- Install shortcuts once
install_shortcut_if_needed(enable_shortcut_path)
install_shortcut_if_needed(disable_shortcut_path)

local last_state = nil

zoom_watcher = hs.timer.doEvery(frequency, function()
    local zoom_app = hs.application.get("zoom.us")
    local in_meeting = check_zoom_meeting(zoom_app)

    if zoom_app and in_meeting and last_state ~= "inMeeting" then
        last_state = "inMeeting"
        log(last_state)
        run_dnd_shortcut("Enable")
        set_app_states("disable")
    elseif not in_meeting and last_state ~= "notInMeeting" then
        last_state = "notInMeeting"
        log(last_state)
        run_dnd_shortcut("Disable")
        set_app_states("enable")
    end
end)

log("Checking for zoom meeting every " .. frequency .. " seconds.")