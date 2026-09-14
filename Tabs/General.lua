-- Welcome tab: the corner link buttons (wow-hc.com, Discord, Group Finder) and a short
-- pointer to the server overview post, everything else lives on the website.
local OVERVIEW_URL = "https://wow-hc.com/forums/6215"

-- Round icon button with the minimap-style ring, top right corner of the tab
local function cornerButton(name, parent, x, y, texture, tooltip, onClick)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(28)
    button:SetHeight(28)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, y)
    button:SetNormalTexture(texture)
    button:EnableMouse(true)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(10)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", button, "CENTER", 13, -14)
    border:SetWidth(64)
    border:SetHeight(64)

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
        GameTooltip:SetText(tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ResetCursor()
    end)
    return button
end

function WHC.Tab_General(content)
    cornerButton("WowhcBtn", content, 2, 10, "Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round", "Visit wow-hc.com", function()
        WHC.ShowUrlPopup("Copy and paste the following URL to your browser", "https://wow-hc.com")
    end)
    cornerButton("DiscordBtn", content, 2, -28, "Interface\\AddOns\\WOW_HC\\Images\\discord", "Visit discord.gg/uGWu5YFjE3", function()
        WHC.ShowUrlPopup("Copy and paste the following URL to your browser", "https://discord.gg/uGWu5YFjE3")
    end)

    -- Group Finder button (parented to the main frame so it shows on every tab)
    local gfBtn = CreateFrame("Button", "WhcGFOpenBtn", WHC)
    gfBtn:SetWidth(28)
    gfBtn:SetHeight(28)
    gfBtn:SetPoint("TOPLEFT", WHC, "TOPLEFT", -2, -48)
    gfBtn:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\groupfinder\\eye\\battlenetworking0")
    local gnt = gfBtn:GetNormalTexture()
    if gnt then gnt:ClearAllPoints(); gnt:SetPoint("CENTER", gfBtn, "CENTER", 0, -0.5); gnt:SetWidth(42); gnt:SetHeight(42) end
    gfBtn:EnableMouse(true)
    gfBtn:SetFrameStrata("HIGH")
    gfBtn:SetFrameLevel(10)

    local gfBorder = gfBtn:CreateTexture(nil, "OVERLAY")
    gfBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    gfBorder:SetPoint("CENTER", gfBtn, "CENTER", 13, -14)
    gfBorder:SetWidth(64)
    gfBorder:SetHeight(64)

    gfBtn:SetScript("OnClick", function()
        if WHC.GF then WHC.GF.Toggle() end
    end)
    gfBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(gfBtn, "ANCHOR_CURSOR")
        GameTooltip:SetText("Group Finder", 1, 1, 1)
        GameTooltip:AddLine("Click to open the Group Finder", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    gfBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Centered block: title, short text, button
    local block = CreateFrame("Frame", nil, content)
    block:SetWidth(360)
    block:SetHeight(230)
    block:SetPoint("CENTER", content, "CENTER", 0, 20)

    local title = block:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", block, "TOP", 0, 0)
    title:SetText("Welcome to WOW Hardcore!")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local tagline = block:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tagline:SetPoint("TOP", title, "BOTTOM", 0, -28)
    tagline:SetWidth(272)
    tagline:SetJustifyH("CENTER")
    tagline:SetText("A permadeath realm where you permanently lose your character if you die.")

    local desc = block:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", tagline, "BOTTOM", 0, -32)
    desc:SetWidth(272)
    desc:SetJustifyH("CENTER")
    desc:SetText("One forum post covers everything about the server and its custom features. Read it before you head out:")

    local readButton = CreateFrame("Button", "WhcOverviewBtn", block, "UIPanelButtonTemplate")
    readButton:SetWidth(200)
    readButton:SetHeight(51)
    readButton:SetPoint("TOP", desc, "BOTTOM", 0, -32)
    readButton:SetText("Server overview post")
    readButton:SetScript("OnClick", function()
        WHC.ShowUrlPopup("Copy and paste the following URL to your browser", OVERVIEW_URL)
    end)

    return content
end
