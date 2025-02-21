DeathLogFrame = CreateFrame("Frame", "MyAddonFrame", UIParent, RETAIL_BACKDROP)
DeathLogFrame:SetWidth(400)
DeathLogFrame:SetHeight(300)
DeathLogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
DeathLogFrame:SetMovable(true)
DeathLogFrame:EnableMouse(true)
DeathLogFrame:SetScript("OnMouseDown", function()
    DeathLogFrame:StartMoving()
end)

DeathLogFrame:SetScript("OnMouseUp", function()
    DeathLogFrame:StopMovingOrSizing()
end)

DeathLogFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DeathLogFrame:SetBackdropColor(0, 0, 0, 0.8)
DeathLogFrame:SetBackdropBorderColor(.5, .5, .5, 1)

local title = DeathLogFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", DeathLogFrame, "TOP", 0, -10)
title:SetText("Recent Deaths")
title:SetTextColor(0.933, 0.765, 0)


local scrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", DeathLogFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", DeathLogFrame, "TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", DeathLogFrame, "BOTTOMRIGHT", -30, 10)


local content = CreateFrame("Frame", "MyAddonScrollContent", scrollFrame)
content:SetWidth(360)
content:SetHeight(0)
scrollFrame:SetScrollChild(content)



local deathMessages = {}
local fontHeight = 14
local messageRows = {} -- Table to store created font strings

function logDeathMessage(msg)
    if (WhcAddonSettings.recentDeaths == 1) then
        local serverTime = date("%H:%M")
        local formattedMessage = string.format("|cffFFFF00%s|r %s", serverTime, msg)

        table.insert(deathMessages, 1, formattedMessage) -- Insert at the beginning

        for _, row in ipairs(messageRows) do
            row:Hide()
            if (RETAIL == 1) then
             -- row:SetParent(nil)
            else
              row:SetParent(nil)
            end

            row = nil
        end
        messageRows = {}

        local countRows = 0
        for i, message in ipairs(deathMessages) do
            local rowString = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            rowString:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -fontHeight * (i - 1))
            rowString:SetFont("Fonts\\FRIZQT__.TTF", fontHeight - 2, "OUTLINE")
            rowString:SetText(message)

            table.insert(messageRows, rowString)

            countRows = countRows + 1
        end

        content:SetHeight(fontHeight * countRows)
    end
end







local closeButton = CreateFrame("Button", nil, DeathLogFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", DeathLogFrame, "TOPRIGHT", 2, 1)
closeButton:SetWidth(36)
closeButton:SetHeight(36)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    WhcAddonSettings.recentDeaths = 0
    DeathLogFrame:Hide()
end)


local resizeButton = CreateFrame("Button", nil, DeathLogFrame)
resizeButton:SetPoint("BOTTOMRIGHT", DeathLogFrame, "BOTTOMRIGHT", 2, -3)
resizeButton:SetWidth(16)
resizeButton:SetHeight(16)

local function SetRotation(texture, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    texture:SetTexCoord(
        0.5 - 0.5 * cos + 0.5 * sin, 0.5 - 0.5 * sin - 0.5 * cos,
        0.5 + 0.5 * cos + 0.5 * sin, 0.5 + 0.5 * sin - 0.5 * cos,
        0.5 - 0.5 * cos - 0.5 * sin, 0.5 - 0.5 * sin + 0.5 * cos,
        0.5 + 0.5 * cos - 0.5 * sin, 0.5 + 0.5 * sin + 0.5 * cos
    )
end

local resizeTexture = resizeButton:CreateTexture(nil, "BACKGROUND")
resizeTexture:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
resizeTexture:SetWidth(9)
resizeTexture:SetHeight(9)
resizeTexture:SetPoint("CENTER", resizeButton, "CENTER", 0, 0)
SetRotation(resizeTexture, math.rad(80))



DeathLogFrame:SetResizable(true)
DeathLogFrame:SetMinResize(10, 10)
DeathLogFrame:SetMaxResize(800, 600)

resizeButton:EnableMouse(true)
resizeButton:SetScript("OnMouseDown", function(self, button)
    DeathLogFrame:StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function(self, button)
    DeathLogFrame:StopMovingOrSizing()
end)
