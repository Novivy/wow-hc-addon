function WHC.UpdateDeathWindow(pvp)

    if (pvp) then

        DEATH_RELEASE = "Release Spirit";
        StaticPopupDialogs["DEATH"].text = "YOU DIED";
        StaticPopupDialogs["DEATH"].button1 = "Release Spirit";
        StaticPopupDialogs["DEATH"].button2 = "";

        StaticPopupDialogs["DEATH"].DisplayButton2 = function()
            return false
        end
    else
        DEATH_RELEASE = "Go again";
        StaticPopupDialogs["DEATH"].text = "|cffff0000YOU DIED|r";
        StaticPopupDialogs["DEATH"].button1 = "Go again";
        StaticPopupDialogs["DEATH"].button2 = "Appeal";

        StaticPopupDialogs["DEATH"].DisplayButton2 = function()
            return true
        end
    end
end

-- WHC.UpdateDeathWindow(false);


local function showDeathWindow(show)
    if (RETAIL == 1) then
        StaticPopupDialogs["DEATH"].OnButton2 = function(data, reason)
            if (reason == "override") then
                return
            end
            if (reason == "timeout") then
                return
            end

            -- Create the URL frame
            local urlFrame = CreateFrame("Frame", "URLFrame", UIParent, RETAIL_BACKDROP)
            urlFrame:SetWidth(300)
            urlFrame:SetHeight(150)
            urlFrame:SetPoint("TOP", UIParent, "TOP", 0, -128)
            urlFrame:SetBackdrop({
                bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
                edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
                tile = true,
                tileSize = 300,
                edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })

            urlFrame:SetFrameStrata("HIGH")
            urlFrame:SetFrameLevel(10)

            -- Title
            local title = urlFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            title:SetPoint("TOP", urlFrame, "TOP", 0, -20)
            title:SetText("Copy and paste the following URL to your browser to appeal")
            title:SetWidth(200)

            -- URL input box
            local urlEditBox = CreateFrame("EditBox", "URLInputBox", urlFrame)
            urlEditBox:SetWidth(250)
            urlEditBox:SetHeight(20)
            urlEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
            urlEditBox:SetFontObject("ChatFontNormal")
            urlEditBox:SetText("https://wow-hc.com/appeal")
            urlEditBox:SetJustifyH("CENTER")
            urlEditBox:SetAutoFocus(false)
            urlEditBox:HighlightText()
            urlEditBox:SetFocus()
            urlEditBox:SetTextColor(1, 0.631, 0.317)
            urlEditBox:SetScript("OnMouseDown", function(self)
                urlEditBox:HighlightText()
                urlEditBox:SetFocus()
            end)

            -- Create a container for the buttons to manage their positioning
            local buttonContainer = CreateFrame("Frame", nil, urlFrame)
            buttonContainer:SetWidth(250) -- Width enough to fit both buttons
            buttonContainer:SetHeight(30) -- Height of the buttons
            buttonContainer:SetPoint("TOP", urlEditBox, "BOTTOM", 0, -20)

            -- Copy button
            -- local copyButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
            -- copyButton:SetWidth(120)
            -- copyButton:SetHeight(30)
            -- copyButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0) -- Position relative to container's center
            -- copyButton:SetText("Select Text")
            -- copyButton:SetScript("OnClick", function()
            --     urlEditBox:HighlightText()
            --    urlEditBox:SetFocus()
            --    WHC.DebugPrint("URL text selected. Please use Ctrl+C to copy.")
            --end)

            -- Cancel button
            local cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
            cancelButton:SetWidth(80)
            cancelButton:SetHeight(30)
            cancelButton:SetPoint("CENTER", buttonContainer, "CENTER", 5, 0) -- Position relative to container's center
            cancelButton:SetText("Back")
            cancelButton:SetScript("OnClick", function()
                urlFrame:Hide()
                showDeathWindow(true);
            end)

            -- Show the frame
            urlFrame:Show()
        end
    else
        StaticPopupDialogs["DEATH"].OnCancel = function(data, reason)
            if (reason == "override") then
                return
            end
            if (reason == "timeout") then
                return
            end
            if (reason == "clicked") then
                -- Create the URL frame
                local urlFrame = CreateFrame("Frame", "URLFrame", UIParent, RETAIL_BACKDROP)
                urlFrame:SetWidth(300)
                urlFrame:SetHeight(150)
                urlFrame:SetPoint("TOP", UIParent, "TOP", 0, -128)
                urlFrame:SetBackdrop({
                    bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
                    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
                    tile = true,
                    tileSize = 300,
                    edgeSize = 32,
                    insets = { left = 11, right = 12, top = 12, bottom = 11 }
                })

                urlFrame:SetFrameStrata("HIGH")
                urlFrame:SetFrameLevel(10)

                -- Title
                local title = urlFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                title:SetPoint("TOP", urlFrame, "TOP", 0, -20)
                title:SetText("Copy and paste the following URL to your browser to appeal")
                title:SetWidth(200)

                -- URL input box
                local urlEditBox = CreateFrame("EditBox", "URLInputBox", urlFrame)
                urlEditBox:SetWidth(250)
                urlEditBox:SetHeight(20)
                urlEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
                urlEditBox:SetFontObject("ChatFontNormal")
                urlEditBox:SetText("https://wow-hc.com/appeal")
                urlEditBox:SetJustifyH("CENTER")
                urlEditBox:SetAutoFocus(false)
                urlEditBox:HighlightText()
                urlEditBox:SetFocus()
                urlEditBox:SetTextColor(1, 0.631, 0.317)
                urlEditBox:SetScript("OnMouseDown", function(self)
                    urlEditBox:HighlightText()
                    urlEditBox:SetFocus()
                end)

                -- Create a container for the buttons to manage their positioning
                local buttonContainer = CreateFrame("Frame", nil, urlFrame)
                buttonContainer:SetWidth(250) -- Width enough to fit both buttons
                buttonContainer:SetHeight(30) -- Height of the buttons
                buttonContainer:SetPoint("TOP", urlEditBox, "BOTTOM", 0, -20)

                -- Copy button
                -- local copyButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
                -- copyButton:SetWidth(120)
                -- copyButton:SetHeight(30)
                -- copyButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0) -- Position relative to container's center
                -- copyButton:SetText("Select Text")
                -- copyButton:SetScript("OnClick", function()
                --     urlEditBox:HighlightText()
                --    urlEditBox:SetFocus()
                --    WHC.DebugPrint("URL text selected. Please use Ctrl+C to copy.")
                --end)

                -- Cancel button
                local cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
                cancelButton:SetWidth(80)
                cancelButton:SetHeight(30)
                cancelButton:SetPoint("CENTER", buttonContainer, "CENTER", 5, 0) -- Position relative to container's center
                cancelButton:SetText("Back")
                cancelButton:SetScript("OnClick", function()
                    urlFrame:Hide()
                    showDeathWindow(true);
                end)

                -- Show the frame
                urlFrame:Show()
            end
        end
    end

    if (show) then
        StaticPopup_Show("DEATH");
    end
end

showDeathWindow(false);
