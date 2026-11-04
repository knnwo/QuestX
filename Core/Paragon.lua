-- QuestX: Core\Paragon.lua
-- Knows which quests are paragon reward quests ("Paragon of ...").

local _, ns = ...

-- Every faction ID in the game today sits well below this. Factions above it
-- are still found through the reputation list below.
local MAX_FACTION_ID = 5000

local rewardQuests -- questID -> true, built the first time it's needed

local function AddFaction(factionID)
    local _, _, rewardQuestID = C_Reputation.GetFactionParagonInfo(factionID)
    if rewardQuestID and rewardQuestID > 0 then
        rewardQuests[rewardQuestID] = true
    end
end

local function BuildRewardQuests()
    rewardQuests = {}

    for factionID = 1, MAX_FACTION_ID do
        AddFaction(factionID)
    end

    for index = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(index)
        if factionData and factionData.factionID and factionData.factionID > MAX_FACTION_ID then
            AddFaction(factionData.factionID)
        end
    end
end

function ns:IsParagonQuest(questID)
    if not questID then
        return false
    end
    if not rewardQuests then
        BuildRewardQuests()
    end
    return rewardQuests[questID] == true
end

-- A paragon reward quest arrives in the log already complete. If an unknown
-- quest shows up that way, rebuild the list in case it's a new paragon reward.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:SetScript("OnEvent", function(_, _, questID)
    if rewardQuests and not rewardQuests[questID] and C_QuestLog.IsComplete(questID) then
        rewardQuests = nil
    end
end)