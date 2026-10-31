-- QuestX: Core\Commands.lua
-- The /questx slash command: lists the settings and switches them on or off.

local _, ns = ...
local L = ns.L

local COMMANDS = {
    { name = "toggle",  key = "enabled",     label = L.OPT_ENABLED },
    { name = "log",     key = "questLog",    label = L.OPT_QUEST_LOG },
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