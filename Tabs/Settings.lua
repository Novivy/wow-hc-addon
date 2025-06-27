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

    function checkBox:setEnabled(checked) -- Lowercase to avoid overwriting Blizzard function added in Patch 5.0.4
        local color = NORMAL_FONT_COLOR
        if checked == 1 then
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
    local sound = "igMainMenuOptionCheckBoxOff"
    if checked == 1 then
        sound = "igMainMenuOptionCheckBoxOn"
    end

    if RETAIL == 1 then
        sound = 857
        if checked == 1 then
            sound = 856
        end
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
    WHC_SETTINGS.minimap:SetScript("OnClick", function(self)
        WhcAddonSettings.minimapicon = getCheckedValueAndPlaySound(self)

        WHC.Frames.MapIcon:Hide()
        if (WhcAddonSettings.minimapicon == 1) then
            WHC.Frames.MapIcon:Show()
        end
    end)

    WHC_SETTINGS.achievementbtn = createSettingsCheckBox(scrollContent, "Display achievement button on inspect & character sheet")
    WHC_SETTINGS.achievementbtn:SetScript("OnClick", function(self)
        WhcAddonSettings.achievementbtn = getCheckedValueAndPlaySound(self)

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
    WHC_SETTINGS.recentDeathsBtn:SetScript("OnClick", function(self)
        WhcAddonSettings.recentDeaths = getCheckedValueAndPlaySound(self)

        WHC.Frames.DeathLogFrame:Hide()
        if (WhcAddonSettings.recentDeaths == 1) then
            WHC.Frames.DeathLogFrame:Show()
        end
    end)

    getNextOffsetY()
    createTitle(scrollContent, "Achievement Settings", 14)

	WHC_SETTINGS.onlyKillDemonsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting demons", WHC.Achievements.DEMON_SLAYER.itemLink))
	WHC_SETTINGS.onlyKillDemonsCheckbox:SetScript("OnClick", function(self)
		WhcAchievementSettings.onlyKillDemons = getCheckedValueAndPlaySound(self)
		WHC.SetWarningOnlyKill()
	end)

    WHC_SETTINGS.blockTaxiServiceCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block flying service", WHC.Achievements.GROUNDED.itemLink))
    WHC_SETTINGS.blockTaxiServiceCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockTaxiService = getCheckedValueAndPlaySound(self)
        WHC.SetBlockTaxiService()
    end)

    WHC_SETTINGS.blockQuestsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Auto-abandon non-class or profession quests", WHC.Achievements.HELP_YOURSELF.itemLink))
    WHC_SETTINGS.blockQuestsCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockQuests = getCheckedValueAndPlaySound(self)
        WHC.SetBlockQuests()
    end)

    WHC_SETTINGS.blockRepairCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block repairing items", WHC.Achievements.IRON_BONES.itemLink))
    WHC_SETTINGS.blockRepairCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockRepair = getCheckedValueAndPlaySound(self)
        WHC.SetBlockRepair()
    end)

    WHC_SETTINGS.blockAuctionSellCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block auction house selling", WHC.Achievements.KILLER_TRADER.itemLink))
    WHC_SETTINGS.blockAuctionSellCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockAuctionSell = getCheckedValueAndPlaySound(self)
        WHC.SetBlockAuctionSell()
    end)

    WHC_SETTINGS.onlyKillUndeadCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting undead", WHC.Achievements.LIGHTBRINGER.itemLink))
    WHC_SETTINGS.onlyKillUndeadCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.onlyKillUndead = getCheckedValueAndPlaySound(self)
        WHC.SetWarningOnlyKill()
    end)

    WHC_SETTINGS.blockInvitesCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block invites", WHC.Achievements.LONE_WOLF.itemLink))
    WHC_SETTINGS.blockInvitesCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockInvites = getCheckedValueAndPlaySound(self)
        WHC.SetBlockInvites()
    end)

    WHC_SETTINGS.blockRidingSkillCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning riding skill", WHC.Achievements.MARATHON_RUNNER.itemLink))
    WHC_SETTINGS.blockRidingSkillCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockRidingSkill = getCheckedValueAndPlaySound(self)
        WHC.SetBlockTrainSkill()
    end)

    if RETAIL == 0 then
        WHC_SETTINGS.blockMagicItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping magic items", WHC.Achievements.MISTER_WHITE.itemLink))
        WHC_SETTINGS.blockMagicItemsCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockMagicItems = getCheckedValueAndPlaySound(self)
            WHC_SETTINGS.blockMagicItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockMagicItems)

            if WhcAchievementSettings.blockMagicItems == 0 then
                WhcAchievementSettings.blockMagicItemsTooltip = 0
                WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockMagicItemsTooltip))
            end

            WHC.SetBlockEquipItems()
        end)

        WHC_SETTINGS.blockMagicItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
        WHC_SETTINGS.blockMagicItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockMagicItems)
        WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockMagicItemsTooltip = getCheckedValueAndPlaySound(self)
        end)
    end

    WHC_SETTINGS.blockTradesCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block trades", WHC.Achievements.MY_PRECIOUS.itemLink))
    WHC_SETTINGS.blockTradesCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockTrades = getCheckedValueAndPlaySound(self)
        WHC.SetBlockTrades()
    end)

    if RETAIL == 0 then
        WHC_SETTINGS.blockArmorItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping armor items", WHC.Achievements.ONLY_FAN.itemLink))
        WHC_SETTINGS.blockArmorItemsCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockArmorItems = getCheckedValueAndPlaySound(self)
            WHC_SETTINGS.blockArmorItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockArmorItems)

            if WhcAchievementSettings.blockArmorItems == 0 then
                WhcAchievementSettings.blockArmorItemsTooltip = 0
                WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockArmorItemsTooltip))
            end

            WHC.SetBlockEquipItems()
        end)

        WHC_SETTINGS.blockArmorItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
        WHC_SETTINGS.blockArmorItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockArmorItems)
        WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockArmorItemsTooltip = getCheckedValueAndPlaySound(self)
        end)

        WHC_SETTINGS.blockNonSelfMadeItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block equipping items you did not craft", WHC.Achievements.SELF_MADE.itemLink))
        WHC_SETTINGS.blockNonSelfMadeItemsCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockNonSelfMadeItems = getCheckedValueAndPlaySound(self)
            WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockNonSelfMadeItems)

            if WhcAchievementSettings.blockNonSelfMadeItems == 0 then
                WhcAchievementSettings.blockNonSelfMadeItemsTooltip = 0
                WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockNonSelfMadeItemsTooltip))
            end

            WHC.SetBlockEquipItems()
        end)

        WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
        WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:setEnabled(WhcAchievementSettings.blockNonSelfMadeItems)
        WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.blockNonSelfMadeItemsTooltip = getCheckedValueAndPlaySound(self)
        end)
    end

    WHC_SETTINGS.blockProfessionsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning primary professions", WHC.Achievements.SOFT_HANDS.itemLink))
    WHC_SETTINGS.blockProfessionsCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockProfessions = getCheckedValueAndPlaySound(self)
        WHC.SetBlockTrainSkill()
    end)

    WHC_SETTINGS.blockMailItemsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block mail items and money", WHC.Achievements.SPECIAL_DELIVERIES.itemLink))
    WHC_SETTINGS.blockMailItemsCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockMailItems = getCheckedValueAndPlaySound(self)
        WHC.SetBlockMailItems()
    end)

    -- There are too many quilboars to translate for 1.12
    if RETAIL == 1 or WHC.client.isEnglish then
        WHC_SETTINGS.onlyKillBoarsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Warning when not targeting boars or quilboars", WHC.Achievements.THAT_WHICH_HAS_NO_LIFE.itemLink))
        WHC_SETTINGS.onlyKillBoarsCheckbox:SetScript("OnClick", function(self)
            WhcAchievementSettings.onlyKillBoars = getCheckedValueAndPlaySound(self)
            WHC.SetWarningOnlyKill()
        end)
    end

    WHC_SETTINGS.blockAuctionBuyCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block auction house buying", WHC.Achievements.TIME_IS_MONEY.itemLink))
    WHC_SETTINGS.blockAuctionBuyCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockAuctionBuy = getCheckedValueAndPlaySound(self)
        WHC.SetBlockAuctionBuy()
    end)

    WHC_SETTINGS.blockTalentsCheckbox = createSettingsCheckBox(scrollContent, string.format("%s Achievement: Block learning talents", WHC.Achievements.UNTALENTED.itemLink))
    WHC_SETTINGS.blockTalentsCheckbox:SetScript("OnClick", function(self)
        WhcAchievementSettings.blockTalents = getCheckedValueAndPlaySound(self)
        WHC.SetBlockTalents()
    end)

    return content;
end
