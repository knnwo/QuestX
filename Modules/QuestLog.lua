-- QuestX: Modules\QuestLog.lua
-- Puts the same red X on each quest in the quest log, just right of the
-- tracking checkbox, so it lines up in one column for every quest.

local _, ns = ...

local BUTTON_SIZE = 13
local OFFSET_X    = 2    -- gap between the tracking checkbox and the X
local OFFSET_Y    = 0    -- nudge the X down (-) or up (+)

-- Our X buttons, keyed by quest log row. Kept in our own table so we never
-- write keys onto Blizzard's frames.
local buttons = setmetatable({}, { __mode = "k" })

local function UpdateRow(row)
    local button = buttons[row]
    local questID = row.questID

    if not (ns.db.questLog and row.Checkbox and ns:CanAbandon(questID)) then
        if button then
            button:Hide()
        end
        return
    end

    if not button then
        -- Above the checkbox, whose click area reaches past its edges.
        button = ns:CreateAbandonButton(row, row.Checkbox)
        button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        button:SetPoint("LEFT", row.Checkbox, "RIGHT", OFFSET_X, OFFSET_Y)
        buttons[row] = button
    end

    ns:ShowAbandonButton(button, questID)
end

local function RefreshQuestLog()
    local pool = QuestScrollFrame and QuestScrollFrame.titleFramePool
    if not pool then
        return
    end

    for row in pool:EnumerateActive() do
        UpdateRow(row)
    end
end

ns:RegisterRefresh(RefreshQuestLog)

-- The quest log rebuilds its rows in QuestLogQuests_Update; we add our X after.
EventUtil.ContinueOnAddOnLoaded("Blizzard_UIPanels_Game", function()
    if type(QuestLogQuests_Update) == "function" then
        hooksecurefunc("QuestLogQuests_Update", RefreshQuestLog)
        RefreshQuestLog()
    end
end)