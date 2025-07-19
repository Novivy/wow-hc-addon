function WHC.Tab_Shop(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Shop")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    desc1:SetText("Customize your adventure with various cosmetics and quality-of-life improvements")
    desc1:SetWidth(300)

    local desc2 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc2:SetPoint("TOP", desc1, "TOP", 0, -45) -- Adjust y-offset based on logo size
    desc2:SetText("We do not provide any " .. WHC.COLORS.DARK_RED_FONT_COLOR_CODE .. "Pay-to-Win" .. FONT_COLOR_CODE_CLOSE .. " content on this realm.")
    desc2:SetWidth(230)


    local iconFrame = content:CreateTexture("$parentNameFrame", "BACKGROUND")
    iconFrame:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\shop") -- INV_Misc_QuestionMark")
    iconFrame:SetWidth(256)
    iconFrame:SetHeight(256)
    iconFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 120, -130)
    -- iconFrame:SetDrawLayer("OVERLAY")


    local createButton = CreateFrame("Button", "CreateButtonShop", content, "UIPanelButtonTemplate")
    createButton:SetWidth(140)
    createButton:SetHeight(40)
    createButton:SetPoint("TOPLEFT", content, "TOPLEFT", 173, -310)
    createButton:SetText("OPEN SHOP")


    createButton:SetScript("OnClick", function()
        -- Create the URL frame
        local urlFrame = CreateFrame("Frame", "URLFrameWowHc", UIParent, RETAIL_BACKDROP)
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
        title:SetText("Copy and paste the following URL to your browser")
        title:SetWidth(200)

        -- URL input box
        local urlEditBox = CreateFrame("EditBox", "URLInputBox", urlFrame)
        urlEditBox:SetWidth(250)
        urlEditBox:SetHeight(20)
        urlEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
        urlEditBox:SetFontObject("ChatFontNormal")
        urlEditBox:SetText("https://wow-hc.com/shop")
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


        -- Cancel button
        local cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
        cancelButton:SetWidth(80)
        cancelButton:SetHeight(30)
        cancelButton:SetPoint("CENTER", buttonContainer, "CENTER", 5, 0) -- Position relative to container's center
        cancelButton:SetText("Back")
        cancelButton:SetScript("OnClick", function()
            urlFrame:Hide()
        end)

        -- Show the frame
        urlFrame:Show()
    end)


    return content;
end
