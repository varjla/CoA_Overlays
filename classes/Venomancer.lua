local AddonName, addon = ...

-- ============================================================================
-- FORTITUDE: Expulsion (Exposed Flesh)
-- ============================================================================
addon:RegisterSpell(92144, {
    name                   = "Expulsion",
    targetSpellName        = "Expulsion",
    auraName               = "Exposed Flesh",
    minStacksWithoutTalent = 10,
    minStacksWithTalent    = 15,
    talentID               = 705991,
    talentCAID             = 30499,
    talentName             = "Unbreakable",
    playSound              = "Interface\\AddOns\\CoA_Overlays\\sounds\\G_GongTroll01.ogg",
})

-- ============================================================================
-- FORTITUDE: Barbed Stinger (Exposed Flesh)
-- ============================================================================
addon:RegisterSpell(803196, {
    name                   = "Barbed Stinger",
    targetSpellName        = "Barbed Stinger",
    auraName               = "Exposed Flesh",
    minStacksWithoutTalent = 6,
    minStacksWithTalent    = 6,
    talentID               = 803196,
    talentCAID             = 30080,
    talentName             = "Barbed Stinger",
    playSound              = nil,
})

-- ============================================================================
-- FORTITUDE: Regrow Exoskeleton (Exposed Flesh)
-- ============================================================================
addon:RegisterSpell(803197, {
    name                   = "Regrow Exoskeleton",
    targetSpellName        = "Regrow Exoskeleton",
    auraName               = "Exposed Flesh",
    minStacksWithoutTalent = 10,
    minStacksWithTalent    = 15,
    talentID               = 705991,
    talentCAID             = 30499,
    talentName             = "Unbreakable",
    playSound              = nil,
})
