-- QuestX: Core.lua
-- Namespace, strings, saved settings and slash commands.

local addonName, ns = ...

----------------------------------------------------------------------
-- Strings (one table, so translations can be added later)
----------------------------------------------------------------------
local L = {
    TOOLTIP_TITLE = "Abandon quest",
    HINT_CLICK    = "Click to abandon",
    HINT_ALT      = "Alt-click to abandon",
    NEED_ALT      = "Hold Alt and click the X to abandon this quest.",
    ABANDONED     = "Abandoned %s.",
    ITEMS_REMOVED = "Quest items removed: %s",
    STATE_ON      = "on",
    STATE_OFF     = "off",
    HELP_HEADER   = "commands:",
    OPT_ENABLED   = "Red X in the quest tracker",
    OPT_ALT       = "Require Alt-click",
    OPT_TOOLTIP   = "Tooltip on the X",
    OPT_CHAT      = "Chat message after abandoning",
}
ns.L = L

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------
local DB_VERSION = 1

local DEFAULTS = {
    enabled     = true,
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

    if ns.RefreshButtons then
        ns:RefreshButtons()
    end
end

EventUtil.ContinueOnAddOnLoaded(addonName, InitDB)

----------------------------------------------------------------------
-- Chat output
----------------------------------------------------------------------
local CHAT_PREFIX = "|cffff3333QuestX|r: "

function ns:Print(message)
    print(CHAT_PREFIX .. message)
end

----------------------------------------------------------------------
-- Slash commands: /questx
----------------------------------------------------------------------
local COMMANDS = {
    { name = "toggle",  key = "enabled",     label = L.OPT_ENABLED },
    { name = "alt",     key = "requireAlt",  label = L.OPT_ALT },
    { name = "tooltip", key = "showTooltip", label = L.OPT_TOOLTIP },
    { name = "chat",    key = "chatMessage", label = L.OPT_CHAT },
}

local function StateText(value)
    if value then
        return GREEN_FONT_COLOR:WrapTextInColorCode(L.STATE_ON)
    end
    return RED_FONT_COLOR:WrapTextInColorCode(L.STATE_OFF)
end

local function PrintHelp()
    ns:Print(L.HELP_HEADER)
    for _, command in ipairs(COMMANDS) do
        print(("  /questx %s - %s (%s)"):format(command.name, command.label, StateText(ns.db[command.key])))
    end
end

SLASH_QUESTX1 = "/questx"
SlashCmdList.QUESTX = function(input)
    local name = strtrim(input or ""):lower()

    for _, command in ipairs(COMMANDS) do
        if command.name == name then
            ns.db[command.key] = not ns.db[command.key]
            ns:Print(("%s: %s"):format(command.label, StateText(ns.db[command.key])))
            ns:RefreshButtons()
            return
        end
    end

    PrintHelp()
end