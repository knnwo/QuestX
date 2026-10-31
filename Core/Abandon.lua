-- QuestX: Core\Abandon.lua
-- Abandoning a quest, and the red X button that does it.
-- Shared by the objective tracker and the quest log.

local _, ns = ...
local L = ns.L

local BUTTON_ATLAS = "common-icon-redx"
local NORMAL_ALPHA = 0.8  -- the X brightens to full on mouseover

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

function ns:CanAbandon(questID)
    return type(questID) == "number" and C_QuestLog.CanAbandonQuest(questID)
end

function ns:AbandonQuest(questID)
    if not self:CanAbandon(questID) then
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
        -- Stops a double click; the list refreshes once the quest is gone.
        self:Disable()
    end
end

-- Makes a red X on `parent`. It sits above `below` (the frame under it that
-- also takes clicks) so clicks on the X always land on the X.
function ns:CreateAbandonButton(parent, below)
    local button = CreateFrame("Button", nil, parent)
    button:SetFrameLevel((below or parent):GetFrameLevel() + 5)

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

    return button
end

-- Points an X at a quest and shows it.
function ns:ShowAbandonButton(button, questID)
    button.questID = questID
    button:Enable()
    button:Show()
end