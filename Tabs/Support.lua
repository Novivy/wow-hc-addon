function WHC.Tab_Support(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Support")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "TOP", 0, -40) -- Adjust y-offset based on logo size
    desc:SetText("In-game support is reserved for the following urgent situations only:")
    desc:SetWidth(260)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 14)
    desc:SetTextColor(1, 0, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", desc, "TOP", 0, -40) -- Adjust y-offset based on logo size
    desc1:SetText(
        "Ongoing dungeon/raid issue or Bot/Cheat reports.")
    desc1:SetWidth(400)

    local desc2 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc2:SetPoint("TOP", desc1, "TOP", 0, -20) -- Adjust y-offset based on logo size
    desc2:SetText(
        "All other issues should be reported through our forums [wow-hc.com]")
    desc2:SetWidth(260)

    local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOP", desc2, "TOP", 0, -60) -- Adjust y-offset based on logo size
    label:SetText(
        "Describe your issue (max 200 characters):")
    label:SetTextColor(0.933, 0.765, 0)
    label:SetJustifyH("LEFT")


    local editBox = CreateFrame("EditBox", "Tab3EditBox", content, RETAIL_BACKDROP)
    editBox:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBox:SetBackdropColor(0, 0, 0)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3)
    editBox:SetMultiLine(true)
    editBox:SetWidth(440)
    editBox:SetAutoFocus(true)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetMaxLetters(200)
    editBox:SetTextInsets(16, 16, 16, 16)

    editBox:SetPoint("TOP", label, "TOP", 0, -20) --


    content.editBox = editBox;

    -- Create Create button
    local createButton = CreateFrame("Button", "CreateButton", content, "UIPanelButtonTemplate")
    createButton:SetWidth(130)
    createButton:SetHeight(30)
    createButton:SetPoint("TOP", editBox, "BOTTOM", 60, -5)
    createButton:SetText("Create ticket")
    createButton:SetScript("OnClick", function()
        local issue = editBox:GetText()
        if issue ~= "" then
            local msg = ".whc ticketcreate " .. issue
            SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));

            WHC.UIShowTabContent(0)
        end
    end)


    content.createButton = createButton;

    -- Create Close button
    local closeButton = CreateFrame("Button", "CloseButton", content, "UIPanelButtonGrayTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(30)
    closeButton:SetPoint("TOP", editBox, "BOTTOM", -60, -5)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        local msg = ".whc ticketdelete"
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));

        WHC.UIShowTabContent(0)
    end)
    content.closeButton = closeButton;

    return content;
end
