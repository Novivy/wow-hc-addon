-- Create the main frame
UIframe = nil
UItabHeader = {}
UItab = {}
tabKeys = { "General", "Achievements", "PVP", "Shop", "Support", "Settings" }


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
function WHC.UIShowTabContent(tabIndex, arg1)
    if tabIndex == 0 then
        UIframe:Hide()
    else
        UIframe:Show()
        -- Hide all tab contents first

        if (tabIndex == "Support") then
            UItab["Support"].editBox:SetText("")
            UItab["Support"].createButton:SetText("Create ticket")
            UItab["Support"].closeButton:SetText("Close")
            local msg = ".whc ticketget"
            if (RETAIL == 1) then
                SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
            else
                SendChatMessage(msg);
            end
        elseif (tabIndex == "Achievements") then
            for key, value in pairs(UIachievements) do
                toggleAchievement(value, true)
            end

            local msg = ".whc achievements"
            if (arg1 == 1) then
                msg = msg .. " target"
            end

            if (RETAIL == 1) then
                SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
            else
                SendChatMessage(msg);
            end
        elseif (tabIndex == "PVP") then
            if (UIspecialEvent ~= nil) then
                UIspecialEvent:SetButtonState("DISABLED")
            end


            local msg = ".whc event"
            if (RETAIL == 1) then
                SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
            else
                SendChatMessage(msg);
            end
        elseif (tabIndex == "Settings") then
            WHC_SETTINGS.minimap:SetChecked(WHC.CheckedValue(WhcAddonSettings.minimapicon))
            WHC_SETTINGS.achievementbtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.achievementbtn))
            WHC_SETTINGS.recentDeathsBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.recentDeaths))
            WHC_SETTINGS.blockInvitesCheckbox:SetChecked(WHC.CheckedValue(WhcAddonSettings.blockInvites))
            WHC_SETTINGS.blockTradesCheckbox:SetChecked(WHC.CheckedValue(WhcAddonSettings.blockTrades))
        elseif (tabIndex == "General") then
            --
        end

        for index, value in ipairs(tabKeys) do
            if UItab[value] then
                UItab[value]:Hide()
                UItabHeader[value]:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-InActiveTab")
                UItabHeader[value].tabText:SetTextColor(0.933, 0.765, 0)
            end
        end

        if UItab[tabIndex] then
            UItab[tabIndex]:Show()
            UItabHeader[tabIndex]:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-ActiveTab")
            UItabHeader[tabIndex].tabText:SetTextColor(1, 1, 1)

            if (tabIndex == "Achievements") then
                if (arg1 ~= nil) then
                    UItab[tabIndex].desc1:SetText("\nListing |cff00C300" .. arg1 .. "|r's achievements")
                else
                    UItab[tabIndex].desc1:SetText(
                        "Achievements are optionnal goals that you start with but may lose depending on your actions")
                end
            end
        end
    end
end

function WHC.InitializeUI()
    local frame = CreateFrame("Frame", "MyMultiTabFrame", UIParent, RETAIL_BACKDROP)
    UIframe = frame
    frame:SetWidth(500)
    frame:SetHeight(450)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:Hide()


    local closeFrame = CreateFrame("Button", "GMToolGUIClose", frame, "UIPanelCloseButton")
    closeFrame:SetWidth(30)
    closeFrame:SetHeight(30)
    closeFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 7, 6)
    closeFrame:SetScript("OnClick", function()
        frame:Hide()
    end)

    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo")
    logo:SetWidth(150)
    logo:SetHeight(75)
    logo:SetPoint("TOP", frame, "TOP", 0, 42)


    local tabContainer = CreateFrame("Frame", "TabContainer", frame)
    tabContainer:SetWidth(500)
    tabContainer:SetHeight(30)
    tabContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, -20)



    local i = 1;
    local widthTotal = 0
    for index, value in ipairs(tabKeys) do
        local tabHeader = CreateFrame("Button", "TabHeader" .. value, tabContainer)


        local width = 0
        if value == "General" then
            tabHeader:SetWidth(90)
            tabHeader:SetHeight(30)
            width = 91
        elseif value == "Achievements" then
            tabHeader:SetWidth(130)
            tabHeader:SetHeight(30)
            width = 119
        elseif value == "PVP" then
            tabHeader:SetWidth(70)
            tabHeader:SetHeight(30)
            width = 64
        elseif value == "Shop" then
            tabHeader:SetWidth(70)
            tabHeader:SetHeight(30)
            width = 62
        elseif value == "Support" then
            tabHeader:SetWidth(84)
            tabHeader:SetHeight(30)
            width = 76
        elseif value == "Settings" then
            tabHeader:SetWidth(86)
            tabHeader:SetHeight(30)
            width = 0
        else
            tabHeader:SetWidth(120)
            tabHeader:SetHeight(30)
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
        tabText:SetText(value)
        tabHeader.tabText = tabText


        local index = value
        tabHeader:SetScript("OnClick", function()
            --WHC.DebugPrint("click " .. index)
            WHC.UIShowTabContent(index)
        end)

        UItabHeader[value] = tabHeader


        -- TABS Content
        local content = CreateFrame("Frame", "Tab" .. value .. "Content", frame)
        content:SetWidth(500)
        content:SetHeight(440)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -40)
        content:Hide()


        if value == "Achievements" then
            content = WHC.Tab_Achievements(content)
        elseif value == "Support" then
            content = WHC.Tab_Support(content)
        elseif value == "PVP" then
            content = WHC.Tab_PVP(content)
        elseif value == "General" then
            content = WHC.Tab_General(content)
        elseif value == "Shop" then
            content = WHC.Tab_Shop(content)
        elseif value == "Settings" then
            content = WHC.Tab_settings(content)
        else
            local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("CENTER", content, "CENTER", 0, 0)
            text:SetText("Content for Tab " .. value)
        end

        UItab[value] = content

        i = i + 1
        widthTotal = widthTotal + width
    end


    -- Slash command to toggle the frame
    SLASH_WOWHC1 = "/wowhc"
    SlashCmdList["WOWHC"] = function(msg)
        if UIframe:IsVisible() then
            UIframe:Hide()
        else
            UIframe:Show()
            WHC.UIShowTabContent("General") -- Initialize with the first tab visible
        end
    end
end
