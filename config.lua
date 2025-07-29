local json = require("hs.json")
local config_path = os.getenv("HOME") .. "/.hammerspoon/ZoomChecker/config.json"

local function set_default_config()
    local default_config = {
        check_frequency = 2,
        disable_dnd_during_zoom = true,
        apps_to_quit_during_zoom = {}
    }

    local file = io.open(config_path, "r")
    if not file then
        -- File doesn't exist — create it with default content
        local new_file = io.open(config_path, "w")
        if new_file then
            local encoded = json.encode(default_config, true)
            new_file:write(encoded)
            new_file:close()
            print("Created config.json with default settings.")
        else
            print("Failed to create config.json")
            return
        end
    else
        file:close()
    end
end

local function read_config()
    set_default_config()

    local file = io.open(config_path, "r")
    local config = json.decode(file:read("*a"))
    file:close()

    if not config then
        print("Failed to parse config.json")
        return nil
    else
        return config
    end
end

local function write_config(config)
    local config_file = io.open(config_path, "w")
    if config_file then
        local encoded = json.encode(config, true)
        config_file:write(encoded)
        config_file:close()
        print("Updated config.json with new settings.")
    else
        print("Failed to open config.json")
        return
    end
end


local function print_config(config)
    for key, value in pairs(config) do
        if type(value) == "table" then
            -- Loop through and print items
            for i, item in ipairs(value) do
                print(i, item)
            end
        else
            print(key .. ": " .. tostring(value))
        end
    end
end


local M = {}

-- helper functions
function M.get_frequency()
    return read_config().check_frequency
end
function M.set_frequency(val)
    if type(val) ~= "number" then
        error("Expected number for disable_dnd_during_zoom, got " .. type(val))
    end
    local config = read_config()
    config.check_frequency = val
    write_config(config)
end

function M.get_disable_dnd_during_zoom()
    return read_config().disable_dnd_during_zoom
end
function M.set_disable_dnd_during_zoom(val)
    if type(val) ~= "boolean" then
        error("Expected boolean for disable_dnd_during_zoom, got " .. type(val))
    end
    local config = read_config()
    config.disable_dnd_during_zoom = val
    write_config(config)
end

function M.get_apps_to_quit_during_zoom()
    return read_config().apps_to_quit_during_zoom
end
function M.set_apps_to_quit_during_zoom(val)
    if type(val) ~= "table" then
        error("Expected table for disable_dnd_during_zoom, got " .. type(val))
    end
    local config = read_config()
    config.apps_to_quit_during_zoom = val
    write_config(config)
end

return M