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
    title:SetTextColor(0.933, 0.765, 0)

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
    checkBoxTitle:SetTextColor(0.933, 0.765, 0)

    return checkBox
end

local function createSettingsSubCheckBox(contentFrame, text)
    local settingsFrame = CreateFrame("Frame", "MySettingsFrame", contentFrame)
    settingsFrame:SetWidth(200)
    settingsFrame:SetHeight(100)
    settingsFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 30, getNextOffsetY())

    local checkBox = CreateFrame("CheckButton", "MyCheckBox", settingsFrame, "UICheckButtonTemplate")
    checkBox:SetWidth(20)
    checkBox:SetHeight(20)
    checkBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -10)

    local checkBoxTitle = checkBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBoxTitle:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBoxTitle:SetText(text)
    checkBoxTitle:SetWidth(390)
    checkBoxTitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
    checkBoxTitle:SetJustifyH("LEFT")
    checkBoxTitle:SetTextColor(0.933, 0.765, 0)

    return checkBox
end


function WHC.Tab_settings(content)
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
    WHC_SETTINGS.minimap = createSettingsSubCheckBox(scrollContent, "Display minimap button")
    WHC_SETTINGS.minimap:SetScript("OnClick", function(self)
        WhcAddonSettings.minimapicon = math.abs(WhcAddonSettings.minimapicon - 1)
        MapIcon:Hide()
        if (WhcAddonSettings.minimapicon == 1) then
            MapIcon:Show()
        end
    end)

    WHC_SETTINGS.achievementbtn = createSettingsSubCheckBox(scrollContent, "Display achievement button on inspect & character sheet")
    WHC_SETTINGS.achievementbtn:SetScript("OnClick", function(self)
        WhcAddonSettings.achievementbtn = math.abs(WhcAddonSettings.achievementbtn - 1)
        if (ACHBtn) then
            ACHBtn:Hide()
        end
        if (WhcAddonSettings.achievementbtn == 1) then
            if (ACHBtn) then
                ACHBtn:Show()
            end
        end
    end)

    WHC_SETTINGS.recentDeathsBtn = createSettingsSubCheckBox(scrollContent, "Display Recent deaths frame")
    WHC_SETTINGS.recentDeathsBtn:SetScript("OnClick", function(self)
        WhcAddonSettings.recentDeaths = math.abs(WhcAddonSettings.recentDeaths - 1)
        if (DeathLogFrame) then
            DeathLogFrame:Hide()
        end
        if (WhcAddonSettings.recentDeaths == 1) then
            if (DeathLogFrame) then
                DeathLogFrame:Show()
            end
        end
    end)

    getNextOffsetY()
    createTitle(scrollContent, "Achievement Settings", 14)

    WHC_SETTINGS.blockInvitesCheckbox = createSettingsSubCheckBox(scrollContent, "[Lone Wolf] Achievement: Block invites")
    WHC_SETTINGS.blockInvitesCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockInvites = math.abs(WhcAddonSettings.blockInvites - 1)
        WHC.SetBlockInvites()
    end)

    WHC_SETTINGS.blockTradesCheckbox = createSettingsSubCheckBox(scrollContent, "[My Precious!] Achievement: Block trades")
    WHC_SETTINGS.blockTradesCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockTrades = math.abs(WhcAddonSettings.blockTrades - 1)
        WHC.SetBlockTrades()
    end)

    WHC_SETTINGS.blockAuctionSellCheckbox = createSettingsSubCheckBox(scrollContent, "[Killer Trader] Achievement: Block auction house selling")
    WHC_SETTINGS.blockAuctionSellCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockAuctionSell = math.abs(WhcAddonSettings.blockAuctionSell - 1)
        WHC.SetBlockAuctionSell()
    end)

    WHC_SETTINGS.blockAuctionBuyCheckbox = createSettingsSubCheckBox(scrollContent, "[Time is Money] Achievement: Block auction house buying")
    WHC_SETTINGS.blockAuctionBuyCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockAuctionBuy = math.abs(WhcAddonSettings.blockAuctionBuy - 1)
        WHC.SetBlockAuctionBuy()
    end)

    WHC_SETTINGS.blockRepairCheckbox = createSettingsSubCheckBox(scrollContent, "[Iron Bones] Achievement: Block repairing items")
    WHC_SETTINGS.blockRepairCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockRepair = math.abs(WhcAddonSettings.blockRepair - 1)
        WHC.SetBlockRepair()
    end)

    WHC_SETTINGS.blockTaxiServiceCheckbox = createSettingsSubCheckBox(scrollContent, "[Grounded] Achievement: Block flying service")
    WHC_SETTINGS.blockTaxiServiceCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockTaxiService = math.abs(WhcAddonSettings.blockTaxiService - 1)
        WHC.SetBlockTaxiService()
    end)

    WHC_SETTINGS.blockMagicItemsCheckbox = createSettingsSubCheckBox(scrollContent, "[Mister White] Achievement: Block equipping magic items")
    WHC_SETTINGS.blockMagicItemsCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockMagicItems = math.abs(WhcAddonSettings.blockMagicItems - 1)
        if WhcAddonSettings.blockMagicItems == 0 then
            WhcAddonSettings.blockMagicItemsTooltip = 0
            WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAddonSettings.blockMagicItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockMagicItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockMagicItemsTooltipCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockMagicItemsTooltip = math.abs(WhcAddonSettings.blockMagicItemsTooltip - 1)
    end)

    WHC_SETTINGS.blockArmorItemsCheckbox = createSettingsSubCheckBox(scrollContent, "[Only Fan] Achievement: Block equipping armor items")
    WHC_SETTINGS.blockArmorItemsCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockArmorItems = math.abs(WhcAddonSettings.blockArmorItems - 1)
        if WhcAddonSettings.blockArmorItems == 0 then
            WhcAddonSettings.blockArmorItemsTooltip = 0
            WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAddonSettings.blockArmorItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockArmorItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockArmorItemsTooltipCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockArmorItemsTooltip = math.abs(WhcAddonSettings.blockArmorItemsTooltip - 1)
    end)

    WHC_SETTINGS.blockNonSelfMadeItemsCheckbox = createSettingsSubCheckBox(scrollContent, "[Self-made] Achievement: Block equipping items you did not craft")
    WHC_SETTINGS.blockNonSelfMadeItemsCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockNonSelfMadeItems = math.abs(WhcAddonSettings.blockNonSelfMadeItems - 1)
        if WhcAddonSettings.blockNonSelfMadeItems == 0 then
            WhcAddonSettings.blockNonSelfMadeItemsTooltip = 0
            WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetChecked(WHC.CheckedValue(WhcAddonSettings.blockNonSelfMadeItemsTooltip))
        end

        WHC.SetBlockEquipItems()
    end)

    WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox = createSettingsSubCheckBox(scrollContent, "Display tooltips on items you cannot equip")
    WHC_SETTINGS.blockNonSelfMadeItemsTooltipCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockNonSelfMadeItemsTooltip = math.abs(WhcAddonSettings.blockNonSelfMadeItemsTooltip - 1)
    end)

    return content;
end
