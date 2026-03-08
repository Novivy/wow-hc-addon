WHC_SETTINGS = {}

local offsetY = -10
local function getNextOffsetY()
    local nextOffsetY = offsetY
    offsetY = offsetY - 30
    return nextOffsetY
end

local function createTitle(contentFrame, text, fontSize)
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", contentFrame, "TOP", 0, getNextOffsetY()) -- Adjust y-offset based on logo size
    title:SetText(text)
    title:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
    title:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

    return title
end

local function createSettingsCheckBox(contentFrame, text)
    local settingsFrame = CreateFrame("Frame", "MySettingsFrame", contentFrame)
    settingsFrame:SetWidth(200)
    settingsFrame:SetHeight(100)
    settingsFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 30, getNextOffsetY())

    local checkBox = CreateFrame("CheckButton", "MyCheckBox", settingsFrame, "UICheckButtonTemplate")
    checkBox:SetWidth(24)
    checkBox:SetHeight(24)
    checkBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -10)

    local checkBoxTitle = checkBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBoxTitle:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBoxTitle:SetText(text)
    checkBoxTitle:SetWidth(400)
    checkBoxTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBoxTitle:SetJustifyH("LEFT")
    checkBoxTitle:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

    function checkBox:setEnabled(enabled, disabledReason) -- Lowercase to avoid overwriting Blizzard function added in Patch 5.0.4
        local color = NORMAL_FONT_COLOR
        if enabled == 1 then
            self:Enable()
        else
            self:Disable()
            color = GRAY_FONT_COLOR

            local hoverFrame = CreateFrame("Frame", "HoverFrame", self)
            hoverFrame:SetAllPoints(self)
            hoverFrame:Show()
            hoverFrame:EnableMouse(true)
            hoverFrame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(hoverFrame, "ANCHOR_RIGHT")
                GameTooltip:SetText(disabledReason, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, true)
                GameTooltip:Show()
            end)

            hoverFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        checkBoxTitle:SetTextColor(color.r, color.g, color.b)
    end

    return checkBox
end

local function createSettingsSubCheckBox(contentFrame, text)
    local settingsFrame = CreateFrame("Frame", "MySettingsFrame", contentFrame)
    settingsFrame:SetWidth(200)
    settingsFrame:SetHeight(100)
    settingsFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 30, getNextOffsetY())

    local checkBox = CreateFrame("CheckButton", "MyCheckBox", settingsFrame, "UICheckButtonTemplate")
    checkBox:SetWidth(24)
    checkBox:SetHeight(24)
    checkBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -10)

    local checkBoxTitle = checkBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBoxTitle:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBoxTitle:SetText(text)
    checkBoxTitle:SetWidth(390)
    checkBoxTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBoxTitle:SetJustifyH("LEFT")
    checkBoxTitle:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

    function checkBox:setEnabled(enabled) -- Lowercase to avoid overwriting Blizzard function added in Patch 5.0.4
        local color = NORMAL_FONT_COLOR
        if enabled == 1 then
            self:Enable()
        else
            self:Disable()
            color = GRAY_FONT_COLOR
        end

        checkBoxTitle:SetTextColor(color.r, color.g, color.b)
    end

    return checkBox
end

local function playCheckedSound(checked)
    local sound = WHC.sounds.checkBoxOff
    if checked == 1 then
        sound = WHC.sounds.checkBoxOn
    end

    PlaySound(sound)
end

local function getCheckedValueAndPlaySound(checkBox)
    local checked = 0
    if checkBox:GetChecked() then
        checked = 1
    end

    playCheckedSound(checked)
    return checked
end

function WHC.Tab_Settings(content)
    local title = createTitle(content, "Settings", 18)

    content.desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content.desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    content.desc1:SetText("Change display settings and select achievements you are going for on this character")
    content.desc1:SetWidth(320)

    local scrollFrame = CreateFrame("ScrollFrame", "ScrollFrameSettings", content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(466)
    scrollFrame:SetHeight(318)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -80)

    local scrollContent = CreateFrame("Frame", "ScrollFrameContentSettings", scrollFrame)
    scrollContent:SetWidth(500)
    scrollContent:SetHeight(500)
    scrollFrame:SetScrollChild(scrollContent) -- Attach the content frame to the scroll frame

    offsetY = 0 -- reset for scroll frame
    WHC_SETTINGS.minimap = createSettingsCheckBox(scrollContent, "Display minimap button")
    WHC_SETTINGS.minimap:SetScript("OnClick", function()
        WhcAddonSettings.minimapicon = getCheckedValueAndPlaySound(WHC_SETTINGS.minimap)

        WHC.Frames.MapIcon:Hide()
        if (WhcAddonSettings.minimapicon == 1) then
            WHC.Frames.MapIcon:Show()
        end
    end)

    WHC_SETTINGS.achievementbtn = createSettingsCheckBox(scrollContent, "Display achievement button on inspect & character sheet")
    WHC_SETTINGS.achievementbtn:SetScript("OnClick", function()
        WhcAddonSettings.achievementbtn = getCheckedValueAndPlaySound(WHC_SETTINGS.achievementbtn)

        WHC.Frames.AchievementButtonCharacter:Hide()
        if (WhcAddonSettings.achievementbtn == 1) then
            WHC.Frames.AchievementButtonCharacter:Show()
        end

        if WHC.Frames.AchievementButtonInspect then
            WHC.Frames.AchievementButtonInspect:Hide()
            if (WhcAddonSettings.achievementbtn == 1) then
                WHC.Frames.AchievementButtonInspect:Show()
            end
        end
    end)

    WHC_SETTINGS.recentDeathsBtn = createSettingsCheckBox(scrollContent, "Display Recent deaths frame")
    WHC_SETTINGS.recentDeathsBtn:SetScript("OnClick", function()
        WhcAddonSettings.recentDeaths = getCheckedValueAndPlaySound(WHC_SETTINGS.recentDeathsBtn)

        WHC.Frames.DeathLogFrame:Hide()
        if (WhcAddonSettings.recentDeaths == 1) then
            WHC.Frames.DeathLogFrame:Show()
        end
    end)

    getNextOffsetY()
    createTitle(scrollContent, "Achievement Settings", 14)

    WHC_SETTINGS.onlyKillDemonsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting demons", WHC.Achievements.DEMON_SLAYER.itemLink))
    WHC_SETTINGS.onlyKillDemonsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.onlyKillDemons = getCheckedValueAndPlaySound(WHC_SETTINGS.onlyKillDemonsCheckbox)
        WHC.SetWarningOnlyKill()
    end)

    WHC_SETTINGS.blockTaxiServiceCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block flying service", WHC.Achievements.GROUNDED.itemLink))
    WHC_SETTINGS.blockTaxiServiceCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockTaxiService = getCheckedValueAndPlaySound(WHC_SETTINGS.blockTaxiServiceCheckbox)
        WHC.SetBlockTaxiService()
    end)

    WHC_SETTINGS.blockQuestsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Auto-abandon non-class or profession quests", WHC.Achievements.HELP_YOURSELF.itemLink))
    WHC_SETTINGS.blockQuestsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockQuests = getCheckedValueAndPlaySound(WHC_SETTINGS.blockQuestsCheckbox)
        WHC.SetBlockQuests()
    end)

    WHC_SETTINGS.blockRepairCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block repairing items", WHC.Achievements.IRON_BONES.itemLink))
    WHC_SETTINGS.blockRepairCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockRepair = getCheckedValueAndPlaySound(WHC_SETTINGS.blockRepairCheckbox)
        WHC.SetBlockRepair()
    end)

    WHC_SETTINGS.blockAuctionSellCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block auction house selling", WHC.Achievements.KILLER_TRADER.itemLink))
    WHC_SETTINGS.blockAuctionSellCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockAuctionSell = getCheckedValueAndPlaySound(WHC_SETTINGS.blockAuctionSellCheckbox)
        WHC.SetBlockAuctionSell()
    end)

    WHC_SETTINGS.onlyKillUndeadCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting undead", WHC.Achievements.LIGHTBRINGER.itemLink))
    WHC_SETTINGS.onlyKillUndeadCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.onlyKillUndead = getCheckedValueAndPlaySound(WHC_SETTINGS.onlyKillUndeadCheckbox)
        WHC.SetWarningOnlyKill()
    end)

    WHC_SETTINGS.blockInvitesCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block invites", WHC.Achievements.LONE_WOLF.itemLink))
    WHC_SETTINGS.blockInvitesCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockInvites = getCheckedValueAndPlaySound(WHC_SETTINGS.blockInvitesCheckbox)
        WHC.SetBlockInvites()
    end)

    WHC_SETTINGS.blockRidingSkillCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning riding skill", WHC.Achievements.MARATHON_RUNNER.itemLink))
    WHC_SETTINGS.blockRidingSkillCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockRidingSkill = getCheckedValueAndPlaySound(WHC_SETTINGS.blockRidingSkillCheckbox)
        WHC.SetBlockTrainSkill()
    end)

    WHC_SETTINGS.blockMagicItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping magic items", WHC.Achievements.MISTER_WHITE.itemLink))
    WHC_SETTINGS.blockMagicItemsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockMagicItems = getCheckedValueAndPlaySound(WHC_SETTINGS.blockMagicItemsCheckbox)
        WHC_SETTINGS.blockMagicItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockMagicItems)

        if WhcAchievementSettings.blockMagicItems == 0 then
            WhcAchievementSettings.blockMagicItemsTooltip = 0
            WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockMagicItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockMagicItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockMagicItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockMagicItems)
    WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockMagicItemsTooltip = getCheckedValueAndPlaySound(WHC_SETTINGS.blockMagicItemsTooltipCheckbox)
    end)

    WHC_SETTINGS.blockTradesCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block trades", WHC.Achievements.MY_PRECIOUS.itemLink))
    WHC_SETTINGS.blockTradesCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockTrades = getCheckedValueAndPlaySound(WHC_SETTINGS.blockTradesCheckbox)
        WHC.SetBlockTrades()
    end)

    WHC_SETTINGS.blockArmorItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping armor items", WHC.Achievements.ONLY_FAN.itemLink))
    WHC_SETTINGS.blockArmorItemsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockArmorItems = getCheckedValueAndPlaySound(WHC_SETTINGS.blockArmorItemsCheckbox)
        WHC_SETTINGS.blockArmorItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockArmorItems)

        if WhcAchievementSettings.blockArmorItems == 0 then
            WhcAchievementSettings.blockArmorItemsTooltip = 0
            WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockArmorItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockArmorItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockArmorItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockArmorItems)
    WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockArmorItemsTooltip = getCheckedValueAndPlaySound(WHC_SETTINGS.blockArmorItemsTooltipCheckbox)
    end)

    WHC_SETTINGS.blockRestedExpCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block rested exp", WHC.Achievements.RESTLESS.itemLink))
    WHC_SETTINGS.blockRestedExpCheckbox:SetScript("OnClick", function()
        WHC.SendToggleRestedXpCommand()
    end)

    WHC_SETTINGS.blockNonSelfMadeItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping items you did not craft", WHC.Achievements.SELF_MADE.itemLink))
    WHC_SETTINGS.blockNonSelfMadeItemsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockNonSelfMadeItems = getCheckedValueAndPlaySound(WHC_SETTINGS.blockNonSelfMadeItemsCheckbox)
        WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockNonSelfMadeItems)

        if WhcAchievementSettings.blockNonSelfMadeItems == 0 then
            WhcAchievementSettings.blockNonSelfMadeItemsTooltip = 0
            WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockNonSelfMadeItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockNonSelfMadeItems)
    WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockNonSelfMadeItemsTooltip = getCheckedValueAndPlaySound(WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox)
    end)

    WHC_SETTINGS.blockProfessionsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning primary professions", WHC.Achievements.SOFT_HANDS.itemLink))
    WHC_SETTINGS.blockProfessionsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockProfessions = getCheckedValueAndPlaySound(WHC_SETTINGS.blockProfessionsCheckbox)
        WHC.SetBlockTrainSkill()
    end)

    WHC_SETTINGS.blockMailItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block mail items and money", WHC.Achievements.SPECIAL_DELIVERIES.itemLink))
    WHC_SETTINGS.blockMailItemsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockMailItems = getCheckedValueAndPlaySound(WHC_SETTINGS.blockMailItemsCheckbox)
        WHC.SetBlockMailItems()
    end)

    WHC_SETTINGS.onlyKillBoarsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting boars or quilboars", WHC.Achievements.THAT_WHICH_HAS_NO_LIFE.itemLink))
    WHC_SETTINGS.onlyKillBoarsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.onlyKillBoars = getCheckedValueAndPlaySound(WHC_SETTINGS.onlyKillBoarsCheckbox)
        WHC.SetWarningOnlyKill()
    end)

    WHC_SETTINGS.onlyKillMurlocsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting murlocs", WHC.Achievements.TIDEHUNTER.itemLink))
    WHC_SETTINGS.onlyKillMurlocsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.onlyKillMurlocs = getCheckedValueAndPlaySound(WHC_SETTINGS.onlyKillMurlocsCheckbox)
        WHC.SetWarningOnlyKill()
    end)

    WHC_SETTINGS.blockAuctionBuyCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block auction house buying", WHC.Achievements.TIME_IS_MONEY.itemLink))
    WHC_SETTINGS.blockAuctionBuyCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockAuctionBuy = getCheckedValueAndPlaySound(WHC_SETTINGS.blockAuctionBuyCheckbox)
        WHC.SetBlockAuctionBuy()
    end)

    WHC_SETTINGS.blockTalentsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning talents", WHC.Achievements.UNTALENTED.itemLink))
    WHC_SETTINGS.blockTalentsCheckbox:SetScript("OnClick", function()
        WhcAchievementSettings.blockTalents = getCheckedValueAndPlaySound(WHC_SETTINGS.blockTalentsCheckbox)
        WHC.SetBlockTalents()
    end)

    if WHC.client.is1_14 then
        WHC_SETTINGS.blockMagicItemsCheckbox:setEnabled(0, "Disable for 1.14 because the UseContainerItem function (right-click in backpack) is protected and cannot be overwritten.")
        WHC_SETTINGS.blockArmorItemsCheckbox:setEnabled(0, "Disable for 1.14 because the UseContainerItem function (right-click in backpack) is protected and cannot be overwritten.")
        WHC_SETTINGS.blockNonSelfMadeItemsCheckbox:setEnabled(0, "Disable for 1.14 because the UseContainerItem function (right-click in backpack) is protected and cannot be overwritten.")
    end

    if WHC.client.is1_12 and not WHC.client.isSuperWow and not WHC.client.isEnglish then
        WHC_SETTINGS.onlyKillBoarsCheckbox:setEnabled(0, "The 1.12 client cannot get the NPC ID and can only use the english NPC name to validate if the mob can be killed.\n\nUse SuperWoW or an english client to activate this achievement.")
        WHC_SETTINGS.onlyKillMurlocsCheckbox:setEnabled(0, "The 1.12 client cannot get the NPC ID and can only use the english NPC name to validate if the mob can be killed.\n\nUse SuperWoW or an english client to activate this achievement.")
    end

    return content;
end
