function WHC.CheckedValue(value)
    if RETAIL == 0 then
        return value
    end

    if value == 1 then
        return true
    end

    return false
end

-- Function to show the selected tab's content
function WHC.UIShowTabContent(tabIndex)
    if tabIndex == 0 then
        return WHC:Hide()
    end

    if tabIndex == WHC.lastTab and WHC:IsVisible() then
        return WHC:Hide()
    end

    WHC.lastTab = tabIndex
    WHC:Show()
    if (tabIndex == WHC.TAB.GENERAL) then
        --
    elseif (tabIndex == WHC.TAB.ACHIEVEMENTS) then
        -- Set all achievements as failed
        for key, value in pairs(WHC.Frames.Achievements) do
            WHC.ToggleAchievement(value, true)
        end

        -- Update achievement status from server
        local msg = ".whc achievements"
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    elseif (tabIndex == WHC.TAB.PVP) then
        if (WHC.Frames.UIspecialEvent ~= nil) then
            WHC.Frames.UIspecialEvent:SetButtonState("DISABLED")
        end

        local msg = ".whc event"
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    elseif (tabIndex == WHC.TAB.SUPPORT) then
        WHC.Frames.UItab[tabIndex].editBox:SetText("")
        WHC.Frames.UItab[tabIndex].createButton:SetText("Create ticket")
        WHC.Frames.UItab[tabIndex].closeButton:SetText("Close")

        local msg = ".whc ticketget"
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    elseif (tabIndex == WHC.TAB.SETTINGS) then
        WHC_SETTINGS.minimap:SetChecked(WHC.CheckedValue(WhcAddonSettings.minimapicon))
        WHC_SETTINGS.achievementbtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.achievementbtn))
        WHC_SETTINGS.recentDeathsBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.recentDeaths))
        WHC_SETTINGS.speedRunTimerBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.speedRunTimer.showTimer))
        WHC_SETTINGS.blueShamanBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.blueShaman))

        WHC_SETTINGS.blockInvitesCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockInvites))
        WHC_SETTINGS.blockTradesCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockTrades))
        WHC_SETTINGS.blockAuctionSellCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockAuctionSell))
        WHC_SETTINGS.blockAuctionBuyCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockAuctionBuy))
        WHC_SETTINGS.blockRepairCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockRepair))
        WHC_SETTINGS.blockTaxiServiceCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockTaxiService))
        WHC_SETTINGS.blockMailItemsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockMailItems))
        WHC_SETTINGS.blockRidingSkillCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockRidingSkill))
        WHC_SETTINGS.blockProfessionsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockProfessions))
        WHC_SETTINGS.blockQuestsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockQuests))
        WHC_SETTINGS.blockTalentsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockTalents))
        WHC_SETTINGS.blockRestedExpCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockRestedExp))
        WHC_SETTINGS.blockMagicItemsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockMagicItems))
        WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockMagicItemsTooltip))
        WHC_SETTINGS.blockArmorItemsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockArmorItems))
        WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockArmorItemsTooltip))
        WHC_SETTINGS.blockNonSelfMadeItemsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockNonSelfMadeItems))
        WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockNonSelfMadeItemsTooltip))
        WHC_SETTINGS.onlyKillDemonsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.onlyKillDemons))
        WHC_SETTINGS.onlyKillUndeadCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.onlyKillUndead))
        WHC_SETTINGS.onlyKillBoarsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.onlyKillBoars))
        WHC_SETTINGS.onlyKillMurlocsCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.onlyKillMurlocs))
    end

    -- Hide all tab contents first
    for _, tabKey in ipairs(WHC.TAB_KEYS) do
        if WHC.Frames.UItab[tabKey] then
            WHC.Frames.UItab[tabKey]:Hide()
            WHC.Frames.UItabHeader[tabKey]:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-InActiveTab")
            WHC.Frames.UItabHeader[tabKey].tabText:SetTextColor(0.933, 0.765, 0)
            WHC.Frames.UItabHeader[tabKey]:Enable()
        end
    end

    -- Show relevant tab
    if WHC.Frames.UItab[tabIndex] then
        WHC.Frames.UItab[tabIndex]:Show()
        WHC.Frames.UItabHeader[tabIndex]:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-ActiveTab")
        WHC.Frames.UItabHeader[tabIndex].tabText:SetTextColor(1, 1, 1)
        WHC.Frames.UItabHeader[tabIndex]:Disable()
    end
end

function WHC.InitializeUI()
    -- Close with escape key
    tinsert(UISpecialFrames, WHC:GetName());

    WHC.UIShowTabContent(0)
    WHC:SetWidth(500)
    WHC:SetHeight(450)
    WHC:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    WHC:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    WHC:SetBackdropColor(0, 0, 0, 1)

    WHC:SetScript("OnShow", function()
        PlaySound(WHC.sounds.openFrame)
    end)
    WHC:SetScript("OnHide", function()
        PlaySound(WHC.sounds.closeFrame)
    end)

    local closeFrame = CreateFrame("Button", "GMToolGUIClose", WHC, "UIPanelCloseButton")
    closeFrame:SetWidth(30)
    closeFrame:SetHeight(30)
    closeFrame:SetPoint("TOPRIGHT", WHC, "TOPRIGHT", 7, 6)
    closeFrame:SetScript("OnClick", function()
        WHC.UIShowTabContent(0)
    end)

    local logo = WHC:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo")
    logo:SetWidth(150)
    logo:SetHeight(75)
    logo:SetPoint("TOP", WHC, "TOP", 0, 42)


    local tabContainer = CreateFrame("Frame", "TabContainer", WHC)
    tabContainer:SetWidth(500)
    tabContainer:SetHeight(30)
    tabContainer:SetPoint("BOTTOMLEFT", WHC, "BOTTOMLEFT", 8, -20)

    WHC.Frames.UItabHeader = {}
    WHC.Frames.UItab = {}

    local i = 1;
    local widthTotal = 0
    for _, tabKey in ipairs(WHC.TAB_KEYS) do
        local tabHeader = CreateFrame("Button", "TabHeader" .. tabKey, tabContainer)
        tabHeader:SetHeight(30)

        local width = 0
        if tabKey == WHC.TAB.GENERAL then
            tabHeader:SetWidth(90)
            width = 91
        elseif tabKey == WHC.TAB.ACHIEVEMENTS then
            tabHeader:SetWidth(130)
            width = 119
        elseif tabKey == WHC.TAB.PVP then
            tabHeader:SetWidth(70)
            width = 64
        elseif tabKey == WHC.TAB.SHOP then
            tabHeader:SetWidth(70)
            width = 62
        elseif tabKey == WHC.TAB.SUPPORT then
            tabHeader:SetWidth(84)
            width = 76
        elseif tabKey == WHC.TAB.SETTINGS then
            tabHeader:SetWidth(86)
            width = 0
        else
            tabHeader:SetWidth(120)
            width = 90
        end

        if i == 1 then
            tabHeader:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 0, 0)                  -- Start position for the first tab
        else
            tabHeader:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", -14 + (widthTotal), 0) -- Position next to the previous tab
        end

        tabHeader:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-InActiveTab")
        tabHeader:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
        tabHeader:EnableMouse(true)

        local tabText = tabHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tabText:SetPoint("CENTER", tabHeader, "CENTER", 0, 3)
        tabText:SetText(tabKey)
        tabHeader.tabText = tabText

        local index = tabKey
        tabHeader:SetScript("OnClick", function()
            --WHC.DebugPrint("click " .. index)
            WHC.UIShowTabContent(index)
            PlaySound(WHC.sounds.selectTab)
        end)

        WHC.Frames.UItabHeader[tabKey] = tabHeader

        -- TABS Content
        local content = CreateFrame("Frame", "Tab" .. tabKey .. "Content", WHC)
        content:SetWidth(500)
        content:SetHeight(440)
        content:SetPoint("TOPLEFT", WHC, "TOPLEFT", 0, -40)
        content:Hide()

        if tabKey == WHC.TAB.ACHIEVEMENTS then
            content = WHC.Tab_Achievements(content)
        elseif tabKey == WHC.TAB.SUPPORT then
            content = WHC.Tab_Support(content)
        elseif tabKey == WHC.TAB.PVP then
            content = WHC.Tab_PVP(content)
        elseif tabKey == WHC.TAB.GENERAL then
            content = WHC.Tab_General(content)
        elseif tabKey == WHC.TAB.SHOP then
            content = WHC.Tab_Shop(content)
        elseif tabKey == WHC.TAB.SETTINGS then
            content = WHC.Tab_Settings(content)
        else
            local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("CENTER", content, "CENTER", 0, 0)
            text:SetText("Content for Tab " .. tabKey)
        end

        WHC.Frames.UItab[tabKey] = content

        i = i + 1
        widthTotal = widthTotal + width
    end


    -- Slash command to toggle the frame
    SLASH_WOWHC1 = "/wowhc"
    SlashCmdList["WOWHC"] = function(msg)
        WHC.UIShowTabContent(WHC.lastTab)
    end
end
