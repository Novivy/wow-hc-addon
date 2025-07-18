local function mathMod(a, b)
    return a - b * math.floor(a / b)
end

local function infoSlot(block, x, y, name, desc, icon, id)
    local MerchantItemTemplate = CreateFrame("Frame", "MerchantItemTemplate", block)
    MerchantItemTemplate:SetWidth(359)
    MerchantItemTemplate:SetHeight(37)
    MerchantItemTemplate:SetPoint("TOPLEFT", block, "TOPLEFT", x, y)


    local iconFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    iconFrame:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\" .. icon) -- INV_Misc_QuestionMark")
    iconFrame:SetWidth(500)
    iconFrame:SetHeight(128)
    iconFrame:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 2, 0)
    iconFrame:SetDrawLayer("OVERLAY")

    -- Name FontString
    local labelTitle = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelTitle:SetText(name)


    if (mathMod(id, 2) == 1) then
        labelTitle:SetJustifyH("RIGHT")
        labelTitle:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 0, 4)
    else
        labelTitle:SetJustifyH("LEFT")
        labelTitle:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 10, 0)
    end



    labelTitle:SetWidth(450)
    labelTitle:SetHeight(35)

    labelTitle:SetTextColor(0.933, 0.765, 0)
    labelTitle:SetFont("Fonts\\FRIZQT__.TTF", 18)

    -- Desc FontString
    local labelDesc = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelDesc:SetText(desc)


    labelDesc:SetHeight(150)

    labelDesc:SetTextColor(0.874, 0.874, 0.874)

    if (mathMod(id, 2) == 1) then
        labelDesc:SetWidth(220)
        labelDesc:SetJustifyH("RIGHT")
        labelDesc:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 230, 5)
    else
        labelDesc:SetWidth(210)
        labelDesc:SetJustifyH("LEFT")
        labelDesc:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", 10, -0)
    end
end

local tabInfos = {
    { id = 1, icon = "appeal", name = "Death Appeal",       desc = "If you died due to a bug or disconnection, you can appeal your death. We will review our logs to verify your claim and restore your character.\n\nWhile video recording is not required, it is highly recommended in case we cannot verify your death." },
    { id = 2, icon = "raid",   name = "Dynamic Difficulty", desc = "Raid difficulty can be set to either Normal or Dynamic.\n\nThis setting scales the melee damage, health, mana, and loot of mobs based on the current raid size (with a minimum of 20 players)." },
    { id = 3, icon = "ach",    name = "Achievements",       desc = "Achievements are optional goals that you start with but may lose depending on your actions.\n\nClick on the Achievements tab below to view your character's achievements.\n\nYou can also inspect other players' achievements!" },
    { id = 4, icon = "chrono", name = "Chronoboon",         desc = "Embark on a mysterious cooking quest to upgrade your campfire to a spiritual one.\n\nThis upgrade will allow you to interact with it and suspend your world buffs whenever you wish." },
    { id = 5, icon = "mag",    name = "Mak'gora",           desc = "Challenge players to a Duel to the Death by typing the "..NORMAL_FONT_COLOR_CODE..".makgora"..FONT_COLOR_CODE_CLOSE.." command\n\nIf the challenged player accepts, you will fight to the death until only one remains.\n\nFleeing a Mak'gora will result in your immediate execution." },
}

function WHC.Tab_General(content)
    local wowhclinkbtn = CreateFrame("Button", "WowhcBtn", content)

    wowhclinkbtn:SetWidth(28)
    wowhclinkbtn:SetHeight(28)

    wowhclinkbtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 2, 10) -- Start position for the first tab
    wowhclinkbtn:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round")

    wowhclinkbtn:EnableMouse(true)

    wowhclinkbtn:SetFrameStrata("HIGH")
    wowhclinkbtn:SetFrameLevel(10)

    local border = wowhclinkbtn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", wowhclinkbtn, "CENTER", 13, -14)
    border:SetWidth(64)
    border:SetHeight(64)

    local index = value
    wowhclinkbtn:SetScript("OnClick", function()
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
        urlEditBox:SetText("https://wow-hc.com")
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


    wowhclinkbtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(wowhclinkbtn, "ANCHOR_CURSOR")
        GameTooltip:SetText("Visit wow-hc.com", 1, 1, 1)
        GameTooltip:Show()
    end)

    wowhclinkbtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ResetCursor()
    end)

    local discordBtnLink = CreateFrame("Button", "DiscordBtn", content)

    discordBtnLink:SetWidth(28)
    discordBtnLink:SetHeight(28)

    discordBtnLink:SetPoint("TOPRIGHT", content, "TOPRIGHT", 2, -28) -- Start position for the first tab
    discordBtnLink:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\discord")

    discordBtnLink:EnableMouse(true)

    discordBtnLink:SetFrameStrata("HIGH")
    discordBtnLink:SetFrameLevel(10)

    local border = discordBtnLink:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", discordBtnLink, "CENTER", 13, -14)
    border:SetWidth(64)
    border:SetHeight(64)


    local index = value
    discordBtnLink:SetScript("OnClick", function()
        -- Create the URL frame
        local urlFrame = CreateFrame("Frame", "URLFrameDiscord", UIParent, RETAIL_BACKDROP)
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
        urlEditBox:SetText("https://discord.gg/uGWu5YFjE3")
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


    discordBtnLink:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(discordBtnLink, "ANCHOR_CURSOR")
        GameTooltip:SetText("Visit discord.gg/uGWu5YFjE3", 1, 1, 1)
        GameTooltip:Show()
    end)

    discordBtnLink:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ResetCursor()
    end)




    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Welcome to WOW Hardcore!")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    desc1:SetText("A permadeath realm where you permanently lose your character if you die")
    desc1:SetWidth(280)

    content.desc1 = desc1

    local scrollFrameBG = CreateFrame("ScrollFrame", "MyScrollFrameBGGeneral", content, RETAIL_BACKDROP)
    scrollFrameBG:SetWidth(485)
    scrollFrameBG:SetHeight(330)
    scrollFrameBG:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -76)
    scrollFrameBG:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    local topBorder = CreateFrame("Frame", "BorderGeneral", content, RETAIL_BACKDROP)
    topBorder:SetPoint("TOPLEFT", content, "TOPLEFT", 9, -77)
    topBorder:SetHeight(2)                                        -- Desired height of the top border
    topBorder:SetWidth(482)                                       -- Width of the top border
    topBorder:SetBackdrop({
        bgFile = "",                                              -- No background texture
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Border texture
        tile = false,                                             -- No tiling
        tileSize = 16,                                            -- Tile size (not used here)
        edgeSize = 4,                                             -- Set edgeSize to match the desired height
        insets = { left = 0, right = 0, top = 0, bottom = 0 }     -- No insets
    })

    local scrollFrame = CreateFrame("ScrollFrame", "MyScrollFrameGeneral", content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(466)
    scrollFrame:SetHeight(318)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -80)


    local scrollContent = CreateFrame("Frame", "MyScrollFrameContentGeneral", scrollFrame)
    scrollContent:SetWidth(500)
    scrollContent:SetHeight(500)
    scrollFrame:SetScrollChild(scrollContent) -- Attach the content frame to the scroll frame

    local i = 0;
    for key, value in pairs(tabInfos) do
        if (i == 0) then
            y = 0
        else
            y = 0 + -(i * 129)
        end

        infoSlot(scrollContent, 10, y, value.name, value.desc, value.icon, value.id);


        i = i + 1
    end



    return content;
end
