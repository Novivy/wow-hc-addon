WHC_SETTINGS = {}

local offsetY = 20
local function getNextOffsetY()
    offsetY = offsetY - 30
    return offsetY
end

local function createTitle(contentFrame, text, fontSize)
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", contentFrame, "TOP", 0, getNextOffsetY()) -- Adjust y-offset based on logo size
    title:SetText(text)
    title:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
    title:SetTextColor(0.933, 0.765, 0)
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
    checkBoxTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBoxTitle:SetTextColor(0.933, 0.765, 0)

    return checkBox
end

function WHC.Tab_settings(content)
    createTitle(content, "Settings", 18)

    WHC_SETTINGS.minimap = createSettingsCheckBox(content, "Display minimap button")
    WHC_SETTINGS.minimap:SetScript("OnClick", function(self)
        WhcAddonSettings.minimapicon = math.abs(WhcAddonSettings.minimapicon - 1)
        MapIcon:Hide()
        if (WhcAddonSettings.minimapicon == 1) then
            MapIcon:Show()
        end
    end)

    WHC_SETTINGS.achievementbtn = createSettingsCheckBox(content, "Display achievement button on inspect & character sheet")
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

    WHC_SETTINGS.recentDeathsBtn = createSettingsCheckBox(content, "Display Recent deaths frame")
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
    createTitle(content, "Achievement Settings", 14)

    WHC_SETTINGS.blockInvitesCheckbox = createSettingsCheckBox(content, "[Lone Wolf] Achievement: Block invites")
    WHC_SETTINGS.blockInvitesCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockInvites = math.abs(WhcAddonSettings.blockInvites - 1)
        WHC.SetBlockInvites()
    end)

    WHC_SETTINGS.blockTradesCheckbox = createSettingsCheckBox(content, "[My Precious!] Achievement: Block trades")
    WHC_SETTINGS.blockTradesCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockTrades = math.abs(WhcAddonSettings.blockTrades - 1)
        WHC.SetBlockTrades()
    end)

    WHC_SETTINGS.blockAuctionSellCheckbox = createSettingsCheckBox(content, "[Killer Trader] Achievement: Block auction house posts")
    WHC_SETTINGS.blockAuctionSellCheckbox:SetScript("OnClick", function(self)
        WhcAddonSettings.blockAuctionSell = math.abs(WhcAddonSettings.blockAuctionSell - 1)
        WHC.SetBlockauctionSell()
    end)

    return content;
end
