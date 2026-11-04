-- QuestX: Core\Core.lua
-- Chat output, the refresh hub every module plugs into, and saved settings.

local addonName, ns = ...

----------------------------------------------------------------------
-- Chat output
----------------------------------------------------------------------
local CHAT_PREFIX = "|cffff3333QuestX|r: "

function ns:Print(message)
    print(CHAT_PREFIX .. message)
end

----------------------------------------------------------------------
-- Refresh: each module registers how to redraw its X buttons
----------------------------------------------------------------------
local refreshCallbacks = {}

function ns:RegisterRefresh(callback)
    refreshCallbacks[#refreshCallbacks + 1] = callback
end

function ns:RefreshButtons()
    for _, callback in ipairs(refreshCallbacks) do
        callback()
    end
end

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------
local DB_VERSION = 1

local DEFAULTS = {
    enabled     = true,
    questLog    = true,
    paragon     = true,
    requireAlt  = false,
    showTooltip = true,
    chatMessage = true,
}

-- Working copy until the saved variables load, so ns.db is never nil.
ns.db = CopyTable(DEFAULTS)

local function InitDB()
    if type(QuestXDB) ~= "table" then
        QuestXDB = {}
    end
    for key, value in pairs(DEFAULTS) do
        if QuestXDB[key] == nil then
            QuestXDB[key] = value
        end
    end
    QuestXDB.version = DB_VERSION
    ns.db = QuestXDB

    ns:RefreshButtons()
end

EventUtil.ContinueOnAddOnLoaded(addonName, InitDB)