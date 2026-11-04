-- QuestX: Modules\WorldMap.lua
-- Puts a pulsing shine around the turn-in question mark of paragon reward
-- quests on the world map.

local _, ns = ...

local PIN_TEMPLATE  = "QuestPinTemplate"
local GLOW_ATLAS    = "ParagonReputation_Glow"
local SHINE_TEXTURE = [[Interface\Cooldown\star4]]
local GLOW_SIZE     = 56
local SHINE_SIZE    = 52
local SHINE_COLOR   = { 1, 0.82, 0.35 }   -- warm gold
local PULSE_TIME    = 1                   -- seconds from dim to bright
local SPIN_TIME     = 10                  -- seconds for one full turn

-- Our shine frames, keyed by map pin. Kept in our own table so we never
-- write keys onto Blizzard's frames.
local shines = setmetatable({}, { __mode = "k" })

local function CreateShine(pin)
    local frame = CreateFrame("Frame", nil, pin)
    frame:SetPoint("CENTER")
    frame:SetSize(1, 1)

    -- Soft paragon glow that pulses behind the question mark.
    local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    glow:SetAtlas(GLOW_ATLAS)
    glow:SetSize(GLOW_SIZE, GLOW_SIZE)
    glow:SetPoint("CENTER")
    glow:SetBlendMode("ADD")

    -- Star rays that turn slowly around it.
    local rays = frame:CreateTexture(nil, "BACKGROUND", nil, -3)
    rays:SetTexture(SHINE_TEXTURE)
    rays:SetSize(SHINE_SIZE, SHINE_SIZE)
    rays:SetPoint("CENTER")
    rays:SetBlendMode("ADD")
    rays:SetVertexColor(unpack(SHINE_COLOR))

    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.35)
    fade:SetToAlpha(1)
    fade:SetDuration(PULSE_TIME)
    fade:SetSmoothing("IN_OUT")

    local spin = rays:CreateAnimationGroup()
    spin:SetLooping("REPEAT")
    local turn = spin:CreateAnimation("Rotation")
    turn:SetDegrees(-360)
    turn:SetDuration(SPIN_TIME)

    frame.animations = { pulse, spin }
    shines[pin] = frame
    return frame
end

local function ShowShine(shine)
    shine:Show()
    for _, animation in ipairs(shine.animations) do
        if not animation:IsPlaying() then
            animation:Play()
        end
    end
end

local function HideShine(shine)
    shine:Hide()
    for _, animation in ipairs(shine.animations) do
        animation:Stop()
    end
end

local function UpdatePin(pin)
    local shine = shines[pin]

    if not (ns.db.paragon and ns:IsParagonQuest(pin:GetQuestID())) then
        if shine then
            HideShine(shine)
        end
        return
    end

    ShowShine(shine or CreateShine(pin))
end

local function RefreshWorldMap()
    if not WorldMapFrame then
        return
    end
    for pin in WorldMapFrame:EnumeratePinsByTemplate(PIN_TEMPLATE) do
        UpdatePin(pin)
    end
end

ns:RegisterRefresh(RefreshWorldMap)

-- The world map's quest pins are rebuilt in their data provider's
-- RefreshAllData; we add our shine after.
EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
    for provider in pairs(WorldMapFrame.dataProviders) do
        if provider.GetPinTemplate == QuestDataProviderMixin.GetPinTemplate then
            hooksecurefunc(provider, "RefreshAllData", RefreshWorldMap)
            break
        end
    end
end)