-- QuestX: Tracker.lua
-- Puts a small red X in the top-right corner of each quest in the objective tracker.
-- Clicking the X abandons that quest straight away.

local _, ns = ...
local L = ns.L

local BUTTON_ATLAS = "common-icon-redx"
local OFFSET_X     = 0    -- nudge the X left (-) or right (+)
local OFFSET_Y     = 1    -- nudge the X down (-) or up (+)
local NORMAL_ALPHA = 0.8  -- the X brightens to full on mouseover

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
-- Abandoning
----------------------------------------------------------------------
local function GetItemNames(itemIDs)
    local names = {}
    for _, itemID in ipairs(itemIDs or {}) do
        local name = C_Item.GetItemNameByID(itemID)
        if name then
            names[#names + 1] = name
        end
    end
    if #names > 0 then
        return table.concat(names, ", ")
    end
end

function ns:AbandonQuest(questID)
    if not (questID and C_QuestLog.CanAbandonQuest(questID)) then
        return false
    end

    local questLink = GetQuestLink(questID) or C_QuestLog.GetTitleForQuestID(questID) or tostring(questID)
    local previousQuestID = C_QuestLog.GetSelectedQuest()

    C_QuestLog.SetSelectedQuest(questID)
    C_QuestLog.SetAbandonQuest()

    -- Safety check: only go ahead if the game picked up the quest we clicked.
    if C_QuestLog.GetAbandonQuest() ~= questID then
        C_QuestLog.SetSelectedQuest(previousQuestID)
        return false
    end

    local itemNames = GetItemNames(C_QuestLog.GetAbandonQuestItems())

    C_QuestLog.AbandonQuest()
    if previousQuestID ~= questID then
        C_QuestLog.SetSelectedQuest(previousQuestID)
    end
    PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST)

    if self.db.chatMessage then
        self:Print(L.ABANDONED:format(questLink))
        if itemNames then
            self:Print(L.ITEMS_REMOVED:format(itemNames))
        end
    end
    return true
end

----------------------------------------------------------------------
-- X button
----------------------------------------------------------------------
local function Button_OnEnter(self)
    if not ns.db.showTooltip then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip_SetTitle(GameTooltip, L.TOOLTIP_TITLE, RED_FONT_COLOR)

    local title = self.questID and C_QuestLog.GetTitleForQuestID(self.questID)
    if title then
        GameTooltip:AddLine(title, HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    GameTooltip_AddInstructionLine(GameTooltip, ns.db.requireAlt and L.HINT_ALT or L.HINT_CLICK)
    GameTooltip:Show()
end

local function Button_OnClick(self)
    if ns.db.requireAlt and not IsAltKeyDown() then
        UIErrorsFrame:AddExternalErrorMessage(L.NEED_ALT)
        return
    end

    GameTooltip_Hide()
    if ns:AbandonQuest(self.questID) then
        -- Stops a double click; the block refreshes once the quest is gone.
        self:Disable()
    end
end

local function CreateButton(block)
    local button = CreateFrame("Button", nil, block)

    -- Sit above the quest title's own click area so our clicks land on the X.
    local below = block.HeaderButton or block
    button:SetFrameLevel(below:GetFrameLevel() + 5)

    button:SetNormalAtlas(BUTTON_ATLAS)
    button:GetNormalTexture():SetAlpha(NORMAL_ALPHA)
    button:SetHighlightAtlas(BUTTON_ATLAS, "ADD")
    button:SetPushedAtlas(BUTTON_ATLAS)
    button:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
    button:SetDisabledAtlas(BUTTON_ATLAS)
    button:GetDisabledTexture():SetDesaturated(true)

    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Button_OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)

    buttons[block] = button
    return button
end

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

    local shouldShow = ns.db.enabled
        and block.used
        and block.HeaderText
        and type(questID) == "number"
        and C_QuestLog.CanAbandonQuest(questID)

    if not shouldShow then
        if button then
            button:Hide()
        end
        return
    end

    button = button or CreateButton(block)
    button.questID = questID
    PositionButton(button, block)
    button:Enable()
    button:Show()
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

function ns:RefreshButtons()
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

EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker", function()
    for _, name in ipairs(MODULE_NAMES) do
        HookModule(_G[name])
    end
    ns:RefreshButtons()
end)