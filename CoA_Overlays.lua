local AddonName, addon = ...
local frame = CreateFrame("Frame", "CoA_OverlaysFrame", UIParent)

-- Tabla para gestionar el estado del sonido de cada hechizo de forma independiente por su spellID
local soundPlayedState = {}

-- ============================================================================
-- BASE DE DATOS DE CLASES DE COA
-- ============================================================================
addon.Classes = {
    ["Barbarian"]        = { color = {138/255, 51/255, 3/255},   icon = "class-barbarian" },
    ["Witch Doctor"]     = { color = {245/255, 0/255, 255/255},  icon = "class-witchdoctor" },
    ["Felsworn"]         = { color = {117/255, 250/255, 0/255},  icon = "class-demonhunter" },
    ["Witch Hunter"]     = { color = {84/255, 51/255, 207/255},  icon = "class-witchhunter" },
    ["Stormbringer"]     = { color = {0/255, 125/255, 237/255},  icon = "class-stormbringer" },
    ["Knight of Xoroth"] = { color = {252/255, 0/255, 5/255},    icon = "class-fleshwarden" },
    ["Guardian"]         = { color = {156/255, 148/255, 130/255},icon = "class-guardian" },
    ["Templar"]          = { color = {255/255, 255/255, 179/255},icon = "class-monk" },
    ["Bloodmage"]        = { color = {163/255, 0/255, 0/255},    icon = "class-sonofarugal" },
    ["Ranger"]           = { color = {191/255, 240/255, 107/255},icon = "class-ranger" },
    ["Chronomancer"]     = { color = {255/255, 237/255, 74/255}, icon = "class-chronomancer" },
    ["Necromancer"]      = { color = {69/255, 219/255, 156/255}, icon = "class-necromancer" },
    ["Pyromancer"]       = { color = {255/255, 97/255, 18/255},  icon = "class-pyromancer" },
    ["Cultist"]          = { color = {156/255, 69/255, 242/255}, icon = "class-cultist" },
    ["Starcaller"]       = { color = {143/255, 255/255, 255/255},icon = "class-starcaller" },
    ["Sun Cleric"]       = { color = {255/255, 179/255, 64/255}, icon = "class-suncleric" },
    ["Tinker"]           = { color = {217/255, 217/255, 217/255},icon = "class-tinker" },
    ["Venomancer"]       = { color = {107/255, 166/255, 0/255},  icon = "class-prophet" },
    ["Reaper"]           = { color = {10/255, 135/255, 107/255}, icon = "class-reaper" },
    ["Primalist"]        = { color = {227/255, 140/255, 89/255}, icon = "class-wildwalker" },
    ["Runemaster"]       = { color = {64/255, 199/255, 235/255}, icon = "class-spiritmage" },
}

addon.Spells = {}

function addon:RegisterSpell(spellID, data)
    addon.Spells[spellID] = data
end

-- ============================================================================
-- TOOLTIP INVISIBLE PARA BÚSQUEDA DINÁMICA DE BOTONES
-- ============================================================================
local scanTooltip = CreateFrame("GameTooltip", "CoA_ScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local actionButtonPrefixes = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "BonusActionButton"
}

local function FindActionButtonsByTooltip(targetSpellName)
    local matchingButtons = {}
    if not targetSpellName then return matchingButtons end

    local targetLower = string.lower(targetSpellName)

    for _, prefix in ipairs(actionButtonPrefixes) do
        for i = 1, 12 do
            local btnName = prefix .. i
            local btn = _G[btnName]
            
            if btn and btn:IsShown() and btn.action then
                scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                scanTooltip:ClearLines()
                scanTooltip:SetAction(btn.action)
                
                local tooltipText = CoA_ScanTooltipTextLeft1:GetText()
                scanTooltip:Hide()

                if tooltipText and string.lower(tooltipText) == targetLower then
                    table.insert(matchingButtons, btn)
                end
            end
        end
    end

    return matchingButtons
end

-- ============================================================================
-- COMPROBACIÓN DE TALENTOS (INTEGRACIÓN TOTAL CON ASCENSION)
-- ============================================================================
local function HasTalent(talentID, talentName, talentCAID)
    if not C_CharacterAdvancement then return false end

    -- 1. Comprobación por SpellID de WoW
    if talentID and C_CharacterAdvancement.GetTalentRankBySpellID then
        local rank = C_CharacterAdvancement.GetTalentRankBySpellID(talentID)
        if rank and rank > 0 then return true end
    end

    -- 2. Comprobación por CAID de Ascension
    if talentCAID and C_CharacterAdvancement.GetTalentRankByID then
        local rank = C_CharacterAdvancement.GetTalentRankByID(talentCAID)
        if rank and rank > 0 then return true end
    end

    return false
end

-- ============================================================================
-- SISTEMA DE RESPLANDOR (DORADO PRINCIPAL + FALLBACK VERDE)
-- ============================================================================
local function SetButtonGlow(btn, show)
    if not btn then return end

    -- Opción 1: Resplandor Dorado Nativo de WoW
    if ActionButton_ShowOverlayGlow and ActionButton_HideOverlayGlow then
        if show then
            ActionButton_ShowOverlayGlow(btn)
        else
            ActionButton_HideOverlayGlow(btn)
        end
        return
    end

    -- Opción 2: Fallback Marco Verde Ajustado
    if not btn.CoA_BorderGlow then
        local overlay = CreateFrame("Frame", nil, btn)
        overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
        overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
        overlay:SetFrameLevel(btn:GetFrameLevel() + 10)

        local tex = overlay:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(overlay)
        tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        tex:SetBlendMode("ADD")
        tex:SetVertexColor(0.2, 1, 0.2, 1)
        
        btn.CoA_BorderGlow = overlay
    end

    if show then
        btn.CoA_BorderGlow:Show()
    else
        btn.CoA_BorderGlow:Hide()
    end
end

-- ============================================================================
-- EVALUACIÓN DE AURAS Y REPRODUCCIÓN DE AUDIO DINÁMICA
-- ============================================================================
local function EvaluateAuras()
    for spellID, data in pairs(addon.Spells) do
        local targetDebuff = data.auraName or data.name
        local name, _, _, count = UnitDebuff("player", targetDebuff)
        if not name then
            name, _, _, count = UnitBuff("player", targetDebuff)
        end

        local stacks = count or 0
        local hasTalent = HasTalent(data.talentID, data.talentName, data.talentCAID)
        
        local requiredStacks = hasTalent and data.minStacksWithTalent or data.minStacksWithoutTalent
        local shouldGlow = (name ~= nil) and (stacks >= requiredStacks)

        -- --------------------------------------------------------------------
        -- GESTIÓN DE AUDIO DINÁMICA SEGÚN CONFIGURACIÓN DEL SPELL
        -- --------------------------------------------------------------------
        if data.playSound then
            if shouldGlow then
                if not soundPlayedState[spellID] then
                    PlaySoundFile(data.playSound)
                    soundPlayedState[spellID] = true
                end
            else
                soundPlayedState[spellID] = false
            end
        end

        -- Actualizar botones en barra de acción
        local buttons = FindActionButtonsByTooltip(data.targetSpellName)
        for _, btn in ipairs(buttons) do
            SetButtonGlow(btn, shouldGlow)
        end
    end
end

-- ============================================================================
-- EVENTOS
-- ============================================================================
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    EvaluateAuras()
end)
