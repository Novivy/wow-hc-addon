WHC_SETTINGS = {}

local offsetY = 20
function getNextOffsetY()
    offsetY = offsetY - 30
    return offsetY
end

function tab_settings(content)
    createTitle(content, "Settings", 18)

    local checkBox = createSettingsCheckBox(content, "Display minimap button")
    checkBox:SetScript("OnClick", function(self)
        if (WhcAddonSettings.minimapicon == 1) then
            WhcAddonSettings.minimapicon = 0

            MapIcon:Hide()
        else
            WhcAddonSettings.minimapicon = 1
            MapIcon:Show()
        end
    end)
    WHC_SETTINGS.minimap = checkBox

    local checkBox1 = createSettingsCheckBox(content, "Display achievement button on inspect & character sheet")
    checkBox1:SetScript("OnClick", function(self)
        if (WhcAddonSettings.achievementbtn == 1) then
            WhcAddonSettings.achievementbtn = 0

            if (ACHBtn) then
                ACHBtn:Hide()
            end
        else
            WhcAddonSettings.achievementbtn = 1
            if (ACHBtn) then
                ACHBtn:Show()
            end
        end
    end)
    WHC_SETTINGS.achievementbtn = checkBox1

    local checkBox2 = createSettingsCheckBox(content, "Display Recent deaths frame")
    checkBox2:SetScript("OnClick", function(self)
        if (WhcAddonSettings.recentDeaths == 1) then
            WhcAddonSettings.recentDeaths = 0

            if (DeathLogFrame) then
                DeathLogFrame:Hide()
            end
        else
            WhcAddonSettings.recentDeaths = 1
            if (DeathLogFrame) then
                DeathLogFrame:Show()
            end
        end
    end)
    WHC_SETTINGS.recentDeathsBtn = checkBox2

    getNextOffsetY()
    createTitle(content, "Achievement Settings", 14)

    local blockInvitesCheckbox = createSettingsCheckBox(content, "[Lone Wolf] Achievement: Block invites")
    blockInvitesCheckbox:SetScript("OnClick", function(self)
        if WhcAddonSettings.blockInvites == 1 then
            WhcAddonSettings.blockInvites = 0
        else
            WhcAddonSettings.blockInvites = 1
        end
        Whc_SetBlockInvites()
    end)
    WHC_SETTINGS.blockInvitesCheckbox = blockInvitesCheckbox

    local blockTradesCheckbox = createSettingsCheckBox(content, "[My Precious!] Achievement: Block trades")
    blockTradesCheckbox:SetScript("OnClick", function(self)
        if WhcAddonSettings.blockTrades == 1 then
            WhcAddonSettings.blockTrades = 0
        else
            WhcAddonSettings.blockTrades = 1
        end
        Whc_SetBlockTrades()
    end)
    WHC_SETTINGS.blockTradesCheckbox = blockTradesCheckbox

    return content;
end

function createTitle(contentFrame, text, fontSize)
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", contentFrame, "TOP", 0, getNextOffsetY()) -- Adjust y-offset based on logo size
    title:SetText(text)
    title:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
    title:SetTextColor(0.933, 0.765, 0)
end

function createSettingsCheckBox(contentFrame, text)
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
