local EM = EVENT_MANAGER
local GetTimeStamp = GetTimeStamp
local GetWorldName = GetWorldName
local GetDiffBetweenTimeStamps = GetDiffBetweenTimeStamps
local math_floor = math.floor
local string_format = string.format
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local tinsert = table.insert
local pairs = pairs

-- Constants
local SECONDS_PER_DAY = 86400
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_MINUTE = 60

-- Daily reset timestamps (updated for Update 8.3.5)
-- https://forums.elderscrollsonline.com/en/discussion/629071/pc-mac-patch-notes-v8-3-5
local DAILY_RESET_BASE_EU = 1517454000 -- 3am UTC for EU
local DAILY_RESET_BASE_NA = 1517479200 -- 10am UTC for NA

local Utils = {}

-----------------------------------------------------------
-- Timing & Scheduling Utilities
-----------------------------------------------------------

-- Schedule a function to run after a delay
-- @param name: Unique identifier for this scheduled call
-- @param ms: Delay in milliseconds (nil to cancel existing schedule)
-- @param func: Function to execute
-- @param ...: Optional arguments to pass to func
function Utils.CallLater(name, ms, func, ...)
    local eventName = "LibPanicida_CallLater_" .. name

    if ms then
        -- Store args for closure
        local args = { ... }

        EM:RegisterForUpdate(eventName, ms, function()
            EM:UnregisterForUpdate(eventName)
            func(unpack(args))
        end)
    else
        -- Cancel if ms is nil
        EM:UnregisterForUpdate(eventName)
    end
end

-- Parse timestamp into days, hours, minutes, seconds
-- @param timeStamp: Timestamp in seconds
-- @return: Formatted string "D HH:MM:SS"
function Utils.ParseTimeStamp(timeStamp)
    local seconds = timeStamp

    local days = math_floor(seconds / SECONDS_PER_DAY)
    seconds = seconds - (days * SECONDS_PER_DAY)

    local hours = math_floor(seconds / SECONDS_PER_HOUR)
    seconds = seconds - (hours * SECONDS_PER_HOUR)

    local mins = math_floor(seconds / SECONDS_PER_MINUTE)
    seconds = seconds - (mins * SECONDS_PER_MINUTE)

    return string_format("%01d %02d:%02d:%02d", days, hours, mins, seconds)
end

function Utils.GetDailyRestBase()
    return (GetWorldName() == "EU Megaserver")
        and DAILY_RESET_BASE_EU
        or DAILY_RESET_BASE_NA
end

-- Get the current daily reset day number
-- @param timestamp: Optional timestamp (defaults to current time)
-- @return: Day number since base reset timestamp
function Utils.GetDailyResetDay(timestamp)
    timestamp = timestamp or GetTimeStamp()

    local baseResetTimestamp = Utils.GetDailyRestBase()

    local secondsSinceBase = GetDiffBetweenTimeStamps(timestamp, baseResetTimestamp)
    return math_floor(secondsSinceBase / SECONDS_PER_DAY)
end

-----------------------------------------------------------
-- String Utilities
-----------------------------------------------------------

-- Split a string by delimiter
-- @param text: String to split
-- @param delimiter: Delimiter pattern (Lua pattern, not plain text)
-- @return: Array of substrings, count of substrings
function Utils.Split(text, delimiter)
    if not text or not delimiter then return {}, 0 end

    local result = {}
    local count = 0

    -- Add delimiter to end for pattern matching
    for match in string_gmatch(text .. delimiter, "(.-)" .. delimiter) do
        if match ~= "" then
            tinsert(result, match)
            count = count + 1
        end
    end

    return result, count
end

-- Clean pledge quest name by removing category prefix
-- Example: "Undaunted: Pledge - Fungal Grotto" -> "Fungal Grotto"
-- @param name: Full quest name
-- @return: Cleaned quest name
function Utils.CleanPledgeQuestName(name)
    if not name then return "" end
    return string_gsub(name, ".*:%s*", "")
end

-----------------------------------------------------------
-- Table Utilities
-----------------------------------------------------------

---Check if table contains a specific key
---@param tbl any Table to search
---@param key any Key to find
---@return boolean true if key exists, false otherwise
function Utils.TableContainsKey(tbl, key)
    if not tbl then return false end
    return tbl[key] ~= nil
end

-- Check if table contains a specific value
-- @param tbl: Table to search
-- @param value: Value to find
-- @return: true if value exists, false otherwise
function Utils.TableContainsValue(tbl, value)
    if not tbl then return false end

    for _, tableValue in pairs(tbl) do
        if tableValue == value then
            return true
        end
    end

    return false
end

LibPanicida.Utils = Utils
