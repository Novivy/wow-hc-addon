WHC_SETTINGS = {}

function tab_settings(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Settings")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    --  local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    --  desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    --   desc1:SetText("Customize your adventure with various cosmetics and quality-of-life improvements")
    --  desc1:SetWidth(300)





    local settingsFrame = CreateFrame("Frame", "MySettingsFrame1", content)
    settingsFrame:SetWidth(200)
    settingsFrame:SetHeight(100)
    settingsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -50)


    local checkBox = CreateFrame("CheckButton", "MyCheckBox", settingsFrame, "UICheckButtonTemplate")
    checkBox:SetWidth(24)
    checkBox:SetHeight(24)
    checkBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -10)

    local checkBoxTitle = checkBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBoxTitle:SetPoint("TOPLEFT", checkBox, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBoxTitle:SetText("Display minimap button")
    checkBoxTitle:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBoxTitle:SetTextColor(0.933, 0.765, 0)


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








    local settingsFrame1 = CreateFrame("Frame", "MySettingsFrame2", settingsFrame)
    settingsFrame1:SetWidth(200)
    settingsFrame1:SetHeight(100)
    settingsFrame1:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 0, -30)


    local checkBox1 = CreateFrame("CheckButton", "MyCheckBox", checkBox, "UICheckButtonTemplate")
    checkBox1:SetWidth(24)
    checkBox1:SetHeight(24)
    checkBox1:SetPoint("TOPLEFT", settingsFrame1, "TOPLEFT", 10, -10)

    local checkBox1Title = checkBox1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBox1Title:SetPoint("TOPLEFT", checkBox1, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBox1Title:SetText("Display achievement button on inspect & character sheet")
    checkBox1Title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBox1Title:SetTextColor(0.933, 0.765, 0)


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






    local settingsFrame2 = CreateFrame("Frame", "MySettingsFrame3", settingsFrame)
    settingsFrame2:SetWidth(200)
    settingsFrame2:SetHeight(100)
    settingsFrame2:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 0, -60)


    local checkBox2 = CreateFrame("CheckButton", "MyCheckBox", checkBox, "UICheckButtonTemplate")
    checkBox2:SetWidth(24)
    checkBox2:SetHeight(24)
    checkBox2:SetPoint("TOPLEFT", settingsFrame2, "TOPLEFT", 10, -10)

    local checkBox2Title = checkBox2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkBox2Title:SetPoint("TOPLEFT", checkBox2, "TOPLEFT", 25, -5) -- Adjust y-offset based on logo size
    checkBox2Title:SetText("Display Recent deaths frame")
    checkBox2Title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    checkBox2Title:SetTextColor(0.933, 0.765, 0)


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


    return content;
end
