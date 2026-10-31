-- QuestX: Modules\Tracker.lua
-- Puts a small red X in the top-right corner of each quest in the objective tracker.

local _, ns = ...

local OFFSET_X = 0    -- nudge the X left (-) or right (+)
local OFFSET_Y = 1    -- nudge the X down (-) or up (+)

-- Tracker modules whose blocks are quests you can abandon.
local MODULE_NAMES = {
    "QuestObjectiveTracker",
    "CampaignQuestObjectiveTracker",
}

-- Our X buttons, keyed by tracker block. Kept in our own table so we never
-- write keys onto Blizzard's frames (that can spread taint).
local buttons = setmetatable({}, { __mode = "k" })
local hookedModules = {}

----------------------------------------------------------------------
-- X placement
----------------------------------------------------------------------

-- Top-right corner of the quest's title line, the same spot for every quest.
-- The title's right edge stops short of Blizzard's quest item and group
-- finder buttons, so the X lines up just left of those when a quest has one.
local function PositionButton(button, block)
    local header = block.HeaderText
    local _, fontHeight = header:GetFont()
    local size = math.floor((fontHeight or 12) + 2.5)
    button:SetSize(size, size)

    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", header, "TOPRIGHT", OFFSET_X, OFFSET_Y)
end

local function UpdateBlock(block)
    local button = buttons[block]
    local questID = block.id

    if not (ns.db.enabled and block.used and block.HeaderText and ns:CanAbandon(questID)) then
        if button then
            button:Hide()
        end
        return
    end

    if not button then
        -- Above the quest title's own click area so clicks land on the X.
        button = ns:CreateAbandonButton(block, block.HeaderButton)
        buttons[block] = button
    end

    PositionButton(button, block)
    ns:ShowAbandonButton(button, questID)
end

----------------------------------------------------------------------
-- Tracker hooks
----------------------------------------------------------------------
local function IsQuestBlock(module, block)
    return block.template == module.blockTemplate
end

local function OnLayoutBlock(module, block)
    if IsQuestBlock(module, block) then
        UpdateBlock(block)
    end
end

local function OnFreeBlock(_, block)
    local button = buttons[block]
    if button then
        button:Hide()
    end
end

local function RefreshTracker()
    for module in pairs(hookedModules) do
        module:EnumerateActiveBlocks(function(block)
            OnLayoutBlock(module, block)
        end)
    end
end

local function HookModule(module)
    if type(module) ~= "table" or hookedModules[module] then
        return
    end
    if type(module.LayoutBlock) ~= "function" or type(module.FreeBlock) ~= "function" then
        return
    end

    hooksecurefunc(module, "LayoutBlock", OnLayoutBlock)
    hooksecurefunc(module, "FreeBlock", OnFreeBlock)
    hookedModules[module] = true
end

ns:RegisterRefresh(RefreshTracker)

EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker", function()
    for _, name in ipairs(MODULE_NAMES) do
        HookModule(_G[name])
    end
    RefreshTracker()
end)