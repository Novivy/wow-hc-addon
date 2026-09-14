-- Dual specialization on the talent window: two side tabs on the right border of the talent
-- frame, one per spec, showing the icon of the tree each spec has most points in. Clicking
-- the inactive one switches from anywhere through ".whc spec <n>" (the server keeps the
-- innkeeper's rules: rested area, level 40, 1h cooldown, dual spec unlocked). Server lines:
--   ::whc::spec:<active 1|2>:<tab spec 1>:<tab spec 2>   tab = tree file name (MageFire), empty = no talents
--   ::whc::spec:error:<text>                             refused, shown as a red line
--   ::whc::spec:locked                                   dual spec not unlocked, "how to" modal
-- The innkeeper gossip keeps working for players without the addon.
local S = {}
WHC.Spec = S

-- On-screen refusals the server keeps for the gossip path; the addon shows its own
WHC.HideServerLines({
    "to change specializations",
    "|cffff0000You are in combat|r",
    "|cffff0000You are moving|r",
    "|cffff0000You are falling|r",
    "Requires level 40 to use dual specialization",
    "Specialization change is on cooldown",
    "Visit an innkeeper to unlock Dual Specialization",
})

local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
-- Tree icons by the tree's file name (4th return of GetTalentTabInfo on both clients, locale
-- independent); the 1.14 client returns no tab icon. From TalentTab.dbc / SpellIcon.dbc.
local TAB_ICONS = {
    WarriorArms = "INV_Sword_27",                    WarriorFury = "Ability_Warrior_BattleShout",   WarriorProtection = "INV_Shield_06",
    PaladinHoly = "Spell_Holy_HolyBolt",             PaladinProtection = "Spell_Holy_DevotionAura", PaladinCombat = "Spell_Holy_AuraOfLight",
    HunterBeastMastery = "Ability_Hunter_BeastTaming", HunterMarksmanship = "Ability_Marksmanship", HunterSurvival = "Ability_Hunter_SwiftStrike",
    RogueAssassination = "Ability_Rogue_Garrote",    RogueCombat = "INV_Weapon_ShortBlade_14",      RogueSubtlety = "Ability_Ambush",
    PriestDiscipline = "Spell_Holy_AuraOfLight",     PriestHoly = "Spell_Holy_LayOnHands",          PriestShadow = "Spell_Shadow_Possession",
    ShamanElementalCombat = "Spell_Fire_Volcano",    ShamanEnhancement = "Spell_Nature_UnyeildingStamina", ShamanRestoration = "Spell_Nature_HealingWaveGreater",
    MageArcane = "Spell_Nature_WispSplode",          MageFire = "Spell_Fire_Fire",                  MageFrost = "Spell_Frost_FreezingBreath",
    WarlockCurses = "Spell_Shadow_UnsummonBuilding", WarlockSummoning = "Spell_Shadow_CurseOfTounges", WarlockDestruction = "Spell_Fire_Incinerate",
    DruidBalance = "Spell_Nature_Lightning",         DruidFeralCombat = "Ability_Physical_Taunt",   DruidRestoration = "Spell_Nature_HealingTouch",
}
local SPEC_NAMES = { "Primary Specialization", "Secondary Specialization" }
local TITLES = { "Primary Talents", "Secondary Talents" }

local state = { active = 1, tabs = { "", "" }, known = false }
local talentFrame, titleText
local tabs = {}

local function RequestInfo()
    SendChatMessage(".whc spec info", "WHISPER", GetDefaultLanguage(), UnitName("player"))
end

-- Tree (file name) with most points in the active spec, straight from the client (stays
-- right while points are being spent); nil when nothing is spent yet
local function ClientDominantTab()
    local best, bestPoints
    for i = 1, 3 do
        local name, _, pointsSpent, fileName = GetTalentTabInfo(i)
        if name and pointsSpent and pointsSpent > 0 and (not bestPoints or pointsSpent > bestPoints) then
            best, bestPoints = fileName, pointsSpent
        end
    end
    return best
end

local function TabOfSpec(spec)
    if spec == state.active then
        local tab = ClientDominantTab()
        if tab then
            return tab
        end
    end
    local tab = state.tabs[spec]
    if tab ~= "" then
        return tab
    end
    return nil
end

-- localized tree name for a tree file name
local function TabName(tab)
    if not tab then
        return nil
    end
    for i = 1, 3 do
        local name, _, _, fileName = GetTalentTabInfo(i)
        if fileName == tab then
            return name
        end
    end
    return nil
end

local function TabIcon(tab)
    local icon = tab and TAB_ICONS[tab]
    if icon then
        return "Interface\\Icons\\" .. icon
    end
    return QUESTION_MARK
end

function S.Update()
    if not talentFrame then
        return
    end
    for spec = 1, 2 do
        local button = tabs[spec]
        button.icon:SetTexture(TabIcon(TabOfSpec(spec)))
        if spec == state.active then
            button.checked:Show()
        else
            button.checked:Hide()
        end
    end
    if titleText then
        titleText:SetText(TITLES[state.active])
    end
end

function S.OnServerMessage(payload)
    if payload == "locked" then
        StaticPopup_Show("WHC_SPEC_LOCKED")
        return
    end
    local _, _, text = string.find(payload, "^error:(.+)$")
    if text then
        WHC.Announce(text)
        return
    end
    local _, _, active, tab1, tab2 = string.find(payload, "^(%d):(%w*):(%w*)$")
    if active then
        state.active = tonumber(active)
        state.tabs = { tab1, tab2 }
        state.known = true
        S.Update()
    end
end

-- re-measures the locked-spec dialog one frame after its text was narrowed (see OnShow)
local specLockedResizer = CreateFrame("Frame")
specLockedResizer:Hide()
specLockedResizer:SetScript("OnUpdate", function(self)
    self = self or this
    self:Hide()
    local dialog = self.dialog
    if dialog and dialog:IsShown() and dialog.which == "WHC_SPEC_LOCKED" then
        StaticPopup_Resize(dialog, dialog.which)
        dialog:SetHeight(dialog:GetHeight() + 16)
    end
end)

StaticPopupDialogs["WHC_SPEC_LOCKED"] = {
    text = "\n" .. RED_FONT_COLOR_CODE .. "Dual Specialization is not unlocked on this character." .. FONT_COLOR_CODE_CLOSE
        .. "\n\nAt level 40, visit an innkeeper and Sip from the Cup of Fate (250 gold and an eel), or subscribe to Tier 2 or higher to have it on every character for free.",
    button1 = "Subscriptions",
    button2 = CLOSE or "Close",
    OnAccept = function()
        WHC.OpenSubscriptionTab()
    end,
    -- narrower text block and some air under the buttons. The wrapped text only reports
    -- its new height on the next frame, so the dialog is re-measured from a one-shot
    -- OnUpdate; StaticPopup_Show re-anchors the buttons on every show and the text width
    -- is put back on hide, so the next dialog reusing the frame is unaffected.
    OnShow = function(self)
        self = self or this
        local name = self:GetName()
        local text = getglobal(name .. "Text")
        self.whcTextWidth = text:GetWidth()
        text:SetWidth(self.whcTextWidth * 0.7)
        local button1, button2 = getglobal(name .. "Button1"), getglobal(name .. "Button2")
        button1:ClearAllPoints()
        button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -6, 27)
        button2:ClearAllPoints()
        button2:SetPoint("LEFT", button1, "RIGHT", 13, 0)
        specLockedResizer.dialog = self
        specLockedResizer:Show()
    end,
    OnHide = function(self)
        self = self or this
        if self.whcTextWidth then
            getglobal(self:GetName() .. "Text"):SetWidth(self.whcTextWidth)
            self.whcTextWidth = nil
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function OnTabClick(button)
    local spec = button.spec
    if spec == state.active then
        return
    end
    SendChatMessage(".whc spec " .. spec, "WHISPER", GetDefaultLanguage(), UnitName("player"))
end

local function OnTabEnter(button)
    button.hover:Show()
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(SPEC_NAMES[button.spec], 1, 1, 1)
    local treeName = TabName(TabOfSpec(button.spec))
    if treeName then
        GameTooltip:AddLine(treeName, 0.9, 0.9, 0.9)
    else
        GameTooltip:AddLine("No talents yet", 0.6, 0.6, 0.6)
    end
    if button.spec == state.active then
        GameTooltip:AddLine("Active", 0, 1, 0)
    else
        GameTooltip:AddLine("Click to switch (rested area, level 40, 1h cooldown)", 0.6, 0.6, 0.6, 1)
    end
    GameTooltip:Show()
end

local function OnTabLeave(button)
    button.hover:Hide()
    GameTooltip:Hide()
end

-- Builds the two tabs on the right border of the talent frame
local function AttachToTalentFrame(frame, title)
    talentFrame = frame
    titleText = title
    for spec = 1, 2 do
        local button = WHC.CreateSideTab("WhcSpecTab" .. spec, frame, WHC.SIDE_TAB_GREY)
        button.spec = spec
        if spec == 1 then
            button.frame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -34, -70)
        else
            button.frame:SetPoint("TOPLEFT", tabs[1].frame, "BOTTOMLEFT", 0, 0)
        end
        button:SetScript("OnClick", function(self)
            OnTabClick(self or this)
        end)
        button:SetScript("OnEnter", function(self)
            OnTabEnter(self or this)
        end)
        button:SetScript("OnLeave", function(self)
            OnTabLeave(self or this)
        end)
        tabs[spec] = button
    end

    -- refresh when the window opens (the other spec's tree can change server side)
    local blizzardOnShow = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function(self)
        if blizzardOnShow then
            blizzardOnShow(self or this)
        end
        RequestInfo()
        S.Update()
    end)
    S.Update()
end

function WHC.InitializeSpec()
    -- spec info once at login (icons ready before the first open), live icon while
    -- spending points
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("CHARACTER_POINTS_CHANGED")
    events:SetScript("OnEvent", function(self, eventName)
        eventName = eventName or event -- 1.12 passes nothing, the event is a global
        if eventName == "PLAYER_LOGIN" then
            RequestInfo()
        else
            S.Update()
        end
    end)

    -- the talent window is the load-on-demand Blizzard_TalentUI on both clients:
    -- TalentFrame on 1.12, PlayerTalentFrame on 1.14
    local function tryAttach()
        if talentFrame then
            return
        end
        if WHC.client.is1_12 and TalentFrame then
            AttachToTalentFrame(TalentFrame, TalentFrameTitleText)
        elseif PlayerTalentFrame then
            AttachToTalentFrame(PlayerTalentFrame, PlayerTalentFrameTitleText)
        end
    end
    tryAttach()
    if not talentFrame then
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(self, eventName, name)
            if (name or arg1) == "Blizzard_TalentUI" then
                tryAttach()
                loader:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end
