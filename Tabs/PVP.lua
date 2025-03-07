local function bgSlot(content, index, icon, label, desc)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("PVP")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    desc1:SetWidth(400)
    desc1:SetText("No permadeath in battlegrounds—join from anywhere!")


    local MerchantItemTemplate = CreateFrame("Frame", "MerchantItemTemplate", content)
    MerchantItemTemplate:SetWidth(350)
    MerchantItemTemplate:SetHeight(37)
    MerchantItemTemplate:SetPoint("TOPLEFT", content, "TOPLEFT", 40, -55 + -(index * 80))

    local iconFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    iconFrame:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\" .. icon) -- INV_Misc_QuestionMark")
    iconFrame:SetWidth(65)
    iconFrame:SetHeight(65)
    iconFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 4, -12)
    iconFrame:SetDrawLayer("OVERLAY")

    -- Name Frame Texture
    local NameFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    NameFrame:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\UI-Merchant-LabelSlots-big")
    NameFrame:SetWidth(512)
    NameFrame:SetHeight(64)
    NameFrame:SetPoint("LEFT", iconFrame, "RIGHT", -5, -3)

    -- Name FontString
    local labelTitle = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelTitle:SetText(label)
    labelTitle:SetJustifyH("LEFT")
    labelTitle:SetWidth(350)
    labelTitle:SetHeight(30)
    labelTitle:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 70, 0)
    labelTitle:SetTextColor(0.933, 0.765, 0)
    labelTitle:SetFont("Fonts\\FRIZQT__.TTF", 13)

    -- Desc FontString
    local labelDesc = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelDesc:SetText(desc)
    labelDesc:SetJustifyH("LEFT")
    labelDesc:SetWidth(220)
    labelDesc:SetHeight(40)
    labelDesc:SetPoint("LEFT", iconFrame, "RIGHT", 5, -7)
    labelDesc:SetTextColor(0.874, 0.874, 0.874)

    if (index ~= 3) then
        local iconHFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
        iconHFrame:SetTexture("Interface\\GroupFrame\\UI-Group-PVP-Horde") -- INV_Misc_QuestionMark")
        iconHFrame:SetWidth(24)
        iconHFrame:SetHeight(24)
        iconHFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 302, -31)
        iconHFrame:SetDrawLayer("OVERLAY")


        local iconAFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
        iconAFrame:SetTexture("Interface\\GroupFrame\\UI-Group-PVP-Alliance") -- INV_Misc_QuestionMark")
        iconAFrame:SetWidth(24)
        iconAFrame:SetHeight(24)
        iconAFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 367, -31)
        iconAFrame:SetDrawLayer("OVERLAY")


        -- Name FontString
        local labelH = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelH:SetText("-")
        labelH:SetJustifyH("RIGHT")
        labelH:SetWidth(50)
        labelH:SetHeight(30)
        labelH:SetPoint("TOPLEFT", iconHFrame, "TOPLEFT", -10, 5)
        labelH:SetFont("Fonts\\FRIZQT__.TTF", 12)
        MerchantItemTemplate.horde = labelH

        -- Name FontString
        local labelA = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelA:SetText("-")
        labelA:SetJustifyH("LEFT")
        labelA:SetWidth(50)
        labelA:SetHeight(30)
        labelA:SetPoint("TOPLEFT", iconAFrame, "TOPLEFT", -15, 5)
        labelA:SetFont("Fonts\\FRIZQT__.TTF", 12)
     MerchantItemTemplate.alliance = labelA

        if (index == 0) then
            UIWS = MerchantItemTemplate
        elseif (index == 1) then
            UIAB = MerchantItemTemplate
        elseif (index == 2) then
            UIAV = MerchantItemTemplate
        end



        -- Name FontString
        local labelP = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelP:SetText("Queued:")
        labelP:SetJustifyH("LEFT")
        labelP:SetWidth(100)
        labelP:SetHeight(30)
        labelP:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 328, -10)
        labelP:SetFont("Fonts\\FRIZQT__.TTF", 8)
        labelP:SetTextColor(1, 1, 1)


        -- Name FontString
        local labelSlash = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelSlash:SetText("/")
        labelSlash:SetJustifyH("LEFT")
        labelSlash:SetWidth(20)
        labelSlash:SetHeight(30)
        labelSlash:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 344, -25)
        labelSlash:SetFont("Fonts\\FRIZQT__.TTF", 12)
        labelSlash:SetTextColor(1, 1, 1)
    end

    -- Create Create button
    local createButton = CreateFrame("Button", "CreateButtonJoin" .. index, MerchantItemTemplate, "UIPanelButtonTemplate")
    createButton:SetWidth(100)
    createButton:SetHeight(30)
    createButton:SetPoint("TOPRIGHT", MerchantItemTemplate, "TOPRIGHT", 44, -52)
    createButton:SetText("JOIN")
    createButton:SetScript("OnClick", function()
        local msg = "." .. icon

        if (RETAIL == 1) then
            SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
        else
            SendChatMessage(msg);
        end
    end)


    if (index == 3) then
        createButton:SetButtonState("DISABLED")
        UIspecialEvent = createButton
    end
end


UIspecialEvent = nil
UIWS = nil
UIAB = nil
UIAV = nil
function WHC.Tab_PVP(content)
    bgSlot(content, 0, "warsong", "Warsong Gulch",
        "As a 10 vs 10 capture-the-flag battleground, the first faction to capture three flags is victorious")

    bgSlot(content, 1, "arathi", "Arathi Basin",
        "A 15 vs 15 domination battleground, where each side attempts to control strategic points")

    bgSlot(content, 2, "alterac", "Alterac Valley",
        "A 40 vs 40 battleground where teams aim to defeat the enemy general")

    bgSlot(content, 3, "attend", "Special Event",
        "Teleport your character to an ongoing special event (if one is available)")

    return content;
end
