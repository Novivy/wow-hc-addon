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

    if (index < 3) then
        -- Alliance
        local iconAllianceFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
        iconAllianceFrame:SetTexture("Interface\\GroupFrame\\UI-Group-PVP-Alliance") -- INV_Misc_QuestionMark")
        iconAllianceFrame:SetWidth(24)
        iconAllianceFrame:SetHeight(24)
        iconAllianceFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 367, -31)
        iconAllianceFrame:SetDrawLayer("OVERLAY")

        local labelAlliance = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelAlliance:SetText("-")
        labelAlliance:SetJustifyH("LEFT")
        labelAlliance:SetWidth(50)
        labelAlliance:SetHeight(30)
        labelAlliance:SetPoint("TOPLEFT", iconAllianceFrame, "TOPLEFT", -15, 5)
        labelAlliance:SetFont("Fonts\\FRIZQT__.TTF", 12)
        MerchantItemTemplate.alliance = labelAlliance

        -- Horde
        local iconHordeFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
        iconHordeFrame:SetTexture("Interface\\GroupFrame\\UI-Group-PVP-Horde") -- INV_Misc_QuestionMark")
        iconHordeFrame:SetWidth(24)
        iconHordeFrame:SetHeight(24)
        iconHordeFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 302, -31)
        iconHordeFrame:SetDrawLayer("OVERLAY")

        local labelHorde = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
        labelHorde:SetText("-")
        labelHorde:SetJustifyH("RIGHT")
        labelHorde:SetWidth(50)
        labelHorde:SetHeight(30)
        labelHorde:SetPoint("TOPLEFT", iconHordeFrame, "TOPLEFT", -10, 5)
        labelHorde:SetFont("Fonts\\FRIZQT__.TTF", 12)
        MerchantItemTemplate.horde = labelHorde

        if (index == 0) then
            WHC.Frames.UIBattleGrounds.ws = MerchantItemTemplate
        elseif (index == 1) then
            WHC.Frames.UIBattleGrounds.ab = MerchantItemTemplate
        elseif (index == 2) then
            WHC.Frames.UIBattleGrounds.av = MerchantItemTemplate
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
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    end)

    if (index == 3) then
        createButton:SetButtonState("DISABLED")
        WHC.Frames.UIspecialEvent = createButton
    end
end

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
