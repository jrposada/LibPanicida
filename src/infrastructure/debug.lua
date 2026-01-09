---@diagnostic disable: undefined-global

-- LibPanicida_Debug.lua

local EM = EVENT_MANAGER
local GuiRoot = GuiRoot
local zo_callLater = zo_callLater
local GetTimeStamp = GetTimeStamp
local Achievement = Achievement
local GetNumFastTravelNodes = GetNumFastTravelNodes
local GetFastTravelNodeInfo = GetFastTravelNodeInfo
local ITEM_SET_COLLECTIONS_DATA_MANAGER = ITEM_SET_COLLECTIONS_DATA_MANAGER
local GetAchievementInfo = GetAchievementInfo
local ZO_PreHookHandler = ZO_PreHookHandler
local ZO_PreHook = ZO_PreHook
local pairs = pairs
local string_format = string.format
local tinsert = table.insert
local d = d

local Debug = {}

-----------------------------------------------------------
-- State Management
-----------------------------------------------------------

-- Track active debug features
local debugStates = {
    questLogging = false,
    setIdLogging = false,
    achievementLogging = false,
}

-- Store original functions for restoration
local originalAchievementToggle = nil

-----------------------------------------------------------
-- Private Helper Functions
-----------------------------------------------------------

-- Safe get control by name
local function getControl(name)
    return name and _G[name] or nil
end

-----------------------------------------------------------
-- Control Inspection & Logging
-----------------------------------------------------------

-- Delayed logging for debugging
function Debug.LogLater(obj, delay)
    zo_callLater(function() d(obj) end, delay)
end

-- Log when any top-level control is shown
-- WARNING: Very performance intensive - use only for debugging!
function Debug.EnableControlShownLogging()
    local numChildren = GuiRoot:GetNumChildren()

    for i = 1, numChildren do
        local child = GuiRoot:GetChild(i)
        if child then
            local childName = child:GetName()
            local control = getControl(childName)

            if control then
                ZO_PreHookHandler(control, "OnEffectivelyShown", function()
                    Debug.LogLater(string_format("%d %s shown", GetTimeStamp(), childName))
                end)
            end
        end
    end

    Debug.LogLater("Control shown logging enabled")
end

-- Log all children of a control when shown
-- @param parent: Control to inspect
function Debug.LogControlChildren(parent)
    if not parent then return end

    local function logChildren()
        local parentName = parent:GetName()
        local numChildren = parent:GetNumChildren()

        Debug.LogLater(string_format("%s children: %d", parentName, numChildren))

        for i = 1, numChildren do
            local child = parent:GetChild(i)
            if child then
                local childName = child:GetName()
                if childName then
                    Debug.LogLater(string_format(" -> %s", childName))
                end
            end
        end
    end

    ZO_PreHookHandler(parent, "OnEffectivelyShown", logChildren)
end

-- Log all children text of a control when shown
-- @param parent: Control to inspect
function Debug.LogControlChildrenText(parent)
    if not parent then return end

    local function logChildrenText()
        local parentName = parent:GetName()
        local numChildren = parent:GetNumChildren()

        Debug.LogLater(string_format("%s children: %d", parentName, numChildren))

        for i = 1, numChildren do
            local child = parent:GetChild(i)
            if child then
                local childName = child:GetName()
                local control = getControl(childName)

                if control then
                    if control.GetText then
                        local text = control:GetText() or "nil"
                        Debug.LogLater(string_format("-> %s", text))
                    else
                        Debug.LogLater("-> (no GetText method)")
                    end
                end
            end
        end
    end

    ZO_PreHookHandler(parent, "OnEffectivelyShown", logChildrenText)
end

-- Log all key-value pairs in a table
-- @param tbl: Table to log
-- @param name: Optional name for the table
function Debug.LogTable(tbl, name)
    if not tbl then
        Debug.LogLater("LogTable: table is nil")
        return
    end

    if name then
        Debug.LogLater(string_format("=== Table: %s ===", name))
    end

    for key, value in pairs(tbl) do
        Debug.LogLater(string_format("%s: %s", tostring(key), tostring(value)))
    end
end

-----------------------------------------------------------
-- Interactive Debugging Tools
-----------------------------------------------------------

-- Log all fast travel node IDs and names
function Debug.LogFastTravelNodes()
    Debug.LogLater("=== Fast Travel Nodes ===")

    local numNodes = GetNumFastTravelNodes()
    for id = 1, numNodes do
        local _, name = GetFastTravelNodeInfo(id)
        if name and name ~= "" then
            Debug.LogLater(string_format("%d - %s", id, name))
        end
    end

    Debug.LogLater(string_format("Total nodes: %d", numNodes))
end

-----------------------------------------------------------
-- Quest Logging
-----------------------------------------------------------

function Debug.EnableQuestLogging()
    if debugStates.questLogging then
        Debug.LogLater("Quest logging already enabled")
        return false
    end

    Debug.LogLater("Quest logging enabled - complete quests to log IDs")

    local eventName = "LibPanicida_QuestRemoved_Debug"

    local function logQuest(_, isCompleted, _, questName, _, _, questId)
        if questName and questId then
            local status = isCompleted and "completed" or "removed"
            Debug.LogLater(string_format("%s (%s) = %d", questName, status, questId))
        end
    end

    EM:RegisterForEvent(eventName, EVENT_QUEST_REMOVED, logQuest)
    debugStates.questLogging = true
    return true
end

function Debug.DisableQuestLogging()
    if not debugStates.questLogging then
        Debug.LogLater("Quest logging already disabled")
        return false
    end

    EM:UnregisterForEvent("LibPanicida_QuestRemoved_Debug", EVENT_QUEST_REMOVED)
    debugStates.questLogging = false
    Debug.LogLater("Quest logging disabled")
    return true
end

-----------------------------------------------------------
-- Set ID Logging
-----------------------------------------------------------

function Debug.EnableSetIdLogging()
    if debugStates.setIdLogging then
        Debug.LogLater("Set ID logging already enabled")
        return false
    end

    Debug.LogLater("Set ID logging enabled - right-click collection set headers")

    local function logSetId(control)
        if not control or not control.dataEntry then return end

        local headerData = control.dataEntry.data.header
        if not headerData then return end

        local setId = headerData:GetId()
        if not setId then return end

        local setCollectionData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(setId)
        if setCollectionData then
            local setName = setCollectionData:GetRawName()
            Debug.LogLater(string_format("%s = %d", setName, setId))
        end
    end

    ZO_PreHook("ZO_ItemSetsBook_Entry_Header_Keyboard_OnMouseUp", logSetId)
    debugStates.setIdLogging = true
    return true
end

function Debug.DisableSetIdLogging()
    if not debugStates.setIdLogging then
        Debug.LogLater("Set ID logging already disabled")
        return false
    end

    Debug.LogLater("Set ID logging can not be disabled. Reaload UI instead.")
    return true
end

-----------------------------------------------------------
-- Achievement Logging
-----------------------------------------------------------

function Debug.EnableAchievementIdLogging()
    if debugStates.achievementLogging then
        Debug.LogLater("Achievement ID logging already enabled")
        return false
    end

    if not Achievement or not Achievement.ToggleCollapse then
        Debug.LogLater("Error: Achievement.ToggleCollapse not found")
        return false
    end

    Debug.LogLater("Achievement ID logging enabled - click achievements to log")

    -- Store original if not already stored
    if not originalAchievementToggle then
        originalAchievementToggle = Achievement.ToggleCollapse
    end

    Achievement.ToggleCollapse = function(self, button)
        originalAchievementToggle(self, button)

        if self.achievementId then
            local name = GetAchievementInfo(self.achievementId)
            Debug.LogLater(string_format("%s = %d", name or "Unknown", self.achievementId))
        end
    end

    debugStates.achievementLogging = true
    return true
end

function Debug.DisableAchievementIdLogging()
    if not debugStates.achievementLogging then
        Debug.LogLater("Achievement ID logging already disabled")
        return false
    end

    if originalAchievementToggle and Achievement then
        Achievement.ToggleCollapse = originalAchievementToggle
    end

    debugStates.achievementLogging = false
    Debug.LogLater("Achievement ID logging disabled")
    return true
end

function Debug.ToggleAchievementIdLogging()
    if debugStates.achievementLogging then
        return Debug.DisableAchievementIdLogging()
    else
        return Debug.EnableAchievementIdLogging()
    end
end

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

-- Get current state of all debug features
function Debug.GetStatus()
    return {
        questLogging = debugStates.questLogging,
        setIdLogging = debugStates.setIdLogging,
        achievementLogging = debugStates.achievementLogging,
    }
end

-- Check if any debug feature is enabled
function Debug.IsAnyEnabled()
    for _, enabled in pairs(debugStates) do
        if enabled then return true end
    end
    return false
end

-- Enable all debug features
function Debug.EnableAll()
    Debug.EnableQuestLogging()
    Debug.EnableSetIdLogging()
    Debug.EnableAchievementIdLogging()
    Debug.LogLater("All debug features enabled")
end

-- Disable all debug features
function Debug.DisableAll()
    Debug.DisableQuestLogging()
    Debug.DisableSetIdLogging()
    Debug.DisableAchievementIdLogging()
    Debug.LogLater("All debug features disabled")
end

-----------------------------------------------------------
-- Slash Command Interface
-----------------------------------------------------------

-- Show current status of all features
function Debug.ShowStatus()
    Debug.LogLater("=== LibPanicida Debug Status ===")
    local status = Debug.GetStatus()

    local features = {
        { name = "Quest Logging",       key = "questLogging" },
        { name = "Set ID Logging",      key = "setIdLogging" },
        { name = "Achievement Logging", key = "achievementLogging" },
    }

    for _, feature in ipairs(features) do
        local enabled = status[feature.key]
        local state = enabled and "|c00FF00ON|r" or "|cFF0000OFF|r"
        Debug.LogLater(string_format("  %s: %s", feature.name, state))
    end
end

-- Show help message
function Debug.ShowHelp()
    Debug.LogLater("=== LibPanicida Debug Commands ===")
    Debug.LogLater("/lpd - Show current debug status")
    Debug.LogLater("/lpd help - Show this help")
    Debug.LogLater("/lpd status - Show current debug status")
    Debug.LogLater("")
    Debug.LogLater("Explicit control:")
    Debug.LogLater("  /lpd <feature> on - Enable feature")
    Debug.LogLater("  /lpd <feature> off - Disable feature")
    Debug.LogLater("")
    Debug.LogLater("Utility commands:")
    Debug.LogLater("  /lpd nodes - Log all fast travel nodes")
    Debug.LogLater("  /lpd controls - Enable control shown logging")
    Debug.LogLater("")
    Debug.LogLater("Aliases: quest/quests, set/sets, achieve/achievements")
end

-- Handle enable command
function Debug.HandleEnableCommand(feature)
    if not feature or feature == "all" then
        Debug.EnableAll()
    elseif feature == "quests" or feature == "quest" then
        Debug.EnableQuestLogging()
    elseif feature == "sets" or feature == "set" then
        Debug.EnableSetIdLogging()
    elseif feature == "achievements" or feature == "achieve" or feature == "achievement" then
        Debug.EnableAchievementIdLogging()
    else
        Debug.LogLater("Unknown feature: " .. feature)
        Debug.LogLater("Type '/lpd help' for available features")
    end
end

-- Handle disable command
function Debug.HandleDisableCommand(feature)
    if not feature or feature == "all" then
        Debug.DisableAll()
    elseif feature == "quests" or feature == "quest" then
        Debug.DisableQuestLogging()
    elseif feature == "sets" or feature == "set" then
        Debug.DisableSetIdLogging()
    elseif feature == "achievements" or feature == "achieve" or feature == "achievement" then
        Debug.DisableAchievementIdLogging()
    else
        Debug.LogLater("Unknown feature: " .. feature)
        Debug.LogLater("Type '/lpd help' for available features")
    end
end

-- Main slash command handler
function Debug.HandleSlashCommand(args)
    -- Trim and convert to lowercase
    args = args:gsub("^%s*(.-)%s*$", "%1"):lower()

    -- Split into parts
    local parts = {}
    for word in args:gmatch("%S+") do
        tinsert(parts, word)
    end

    local feature = parts[1]
    local action = parts[2]

    -- No arguments - show status
    if not feature or feature == "" then
        Debug.ShowStatus()
        return
    end

    -- Help command
    if feature == "help" or feature == "?" then
        Debug.ShowHelp()
        return
    end

    -- Status command
    if feature == "status" or feature == "list" then
        Debug.ShowStatus()
        return
    end

    -- Utility commands (no on/off)
    if feature == "nodes" or feature == "node" then
        Debug.LogFastTravelNodes()
        return
    end

    if feature == "controls" or feature == "control" then
        Debug.LogControlShown()
        return
    end

    -- Feature toggle commands
    local validFeatures = {
        quests = true,
        quest = true,
        sets = true,
        set = true,
        achievements = true,
        achieve = true,
        achievement = true,
        all = true,
    }

    if validFeatures[feature] then
        if not action then
            -- No action specified - enable
            Debug.HandleEnableCommand(feature)
        elseif action == "on" or action == "enable" then
            Debug.HandleEnableCommand(feature)
        elseif action == "off" or action == "disable" then
            Debug.HandleDisableCommand(feature)
        else
            Debug.LogLater("Unknown action: " .. action)
            Debug.LogLater("Use: on, off, or no action to on")
        end
    else
        Debug.LogLater("Unknown command: " .. feature)
        Debug.LogLater("Type '/lpd help' for available commands")
    end
end

SLASH_COMMANDS["/lpd"] = function(args)
    Debug.HandleSlashCommand(args)
end

-----------------------------------------------------------
-- Register in global namespace
-----------------------------------------------------------

LibPanicida = LibPanicida or {}
LibPanicida.Debug = Debug

return Debug

-----------------------------------------------------------
-- Data Extraction for Analysis
-----------------------------------------------------------

-- Extract LFG activity locations data to saved variables
-- Useful for analyzing activity finder structure
-- function Debug.ExtractLocationsData()
--     if not LibPanicida.SavedVars then
--         logLater("Error: LibPanicida.SavedVars not initialized")
--         return
--     end

--     local savedVars = LibPanicida.SavedVars
--     local sortedData = ZO_ACTIVITY_FINDER_ROOT_MANAGER and
--         ZO_ACTIVITY_FINDER_ROOT_MANAGER.sortedLocationsData

--     if not sortedData then
--         logLater("Error: ZO_ACTIVITY_FINDER_ROOT_MANAGER.sortedLocationsData not available")
--         return
--     end

--     -- Store activity type enum values
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_CHAMPION_Value = LFG_ACTIVITY_BATTLE_GROUND_CHAMPION
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL_Value = LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION_Value = LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION
--     savedVars.LFG_ACTIVITY_DUNGEON_Value = LFG_ACTIVITY_DUNGEON
--     savedVars.LFG_ACTIVITY_MASTER_DUNGEON_Value = LFG_ACTIVITY_MASTER_DUNGEON
--     savedVars.LFG_ACTIVITY_TRIAL_Value = LFG_ACTIVITY_TRIAL

--     -- Store location data
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_CHAMPION = sortedData[LFG_ACTIVITY_BATTLE_GROUND_CHAMPION]
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL = sortedData[LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL]
--     savedVars.LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION = sortedData[LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION]
--     savedVars.LFG_ACTIVITY_DUNGEON = sortedData[LFG_ACTIVITY_DUNGEON]
--     savedVars.LFG_ACTIVITY_MASTER_DUNGEON = sortedData[LFG_ACTIVITY_MASTER_DUNGEON]
--     savedVars.LFG_ACTIVITY_TRIAL = sortedData[LFG_ACTIVITY_TRIAL]

--     logLater("Locations data extracted to saved variables")
-- end

-- Extract all activity info for analysis
-- Scans activity IDs and stores their info
-- function Debug.ExtractActivitiesInfo()
--     if not LibPanicida.SavedVars then
--         logLater("Error: LibPanicida.SavedVars not initialized")
--         return
--     end

--     local info = {}
--     local maxActivityId = 1000 -- Reasonable upper bound

--     for activityId = 1, maxActivityId do
--         -- GetActivityInfo returns: name, levelMin, levelMax, championPointsMin,
--         -- championPointsMax, groupType, minGroupSize, description, sortOrder
--         local activityInfo = { GetActivityInfo(activityId) }

--         -- Only store if activity exists (name is not empty)
--         if activityInfo[1] and activityInfo[1] ~= "" then
--             info[activityId] = activityInfo
--         end
--     end

--     LibPanicida.SavedVars.ActivitiesInfo = info
--     logLater(string_format("Extracted info for %d activities", #info))
-- end
