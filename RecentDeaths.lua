function WHC.InitializeDeathLogFrame()
    WHC.Frames.DeathLogFrame = CreateFrame("Frame", "MyAddonFrame", UIParent, RETAIL_BACKDROP)
    WHC.Frames.DeathLogFrame:SetWidth(400)
    WHC.Frames.DeathLogFrame:SetHeight(300)
    WHC.Frames.DeathLogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    WHC.Frames.DeathLogFrame:SetMovable(true)
    WHC.Frames.DeathLogFrame:EnableMouse(true)
    WHC.Frames.DeathLogFrame:SetScript("OnMouseDown", function()
        WHC.Frames.DeathLogFrame:StartMoving()
    end)

    WHC.Frames.DeathLogFrame:SetScript("OnMouseUp", function()
        WHC.Frames.DeathLogFrame:StopMovingOrSizing()
    end)

    WHC.Frames.DeathLogFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    WHC.Frames.DeathLogFrame:SetBackdropColor(0, 0, 0, 0.8)
    WHC.Frames.DeathLogFrame:SetBackdropBorderColor(.5, .5, .5, 1)

    local title = WHC.Frames.DeathLogFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", WHC.Frames.DeathLogFrame, "TOP", 0, -10)
    title:SetText("Recent Deaths")
    title:SetTextColor(0.933, 0.765, 0)

    local scrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", WHC.Frames.DeathLogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", WHC.Frames.DeathLogFrame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", WHC.Frames.DeathLogFrame, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", "MyAddonScrollContent", scrollFrame)
    content:SetWidth(360)
    content:SetHeight(0)
    scrollFrame:SetScrollChild(content)
    WHC.DeathLogFrame.content = content

    local closeButton = CreateFrame("Button", nil, WHC.Frames.DeathLogFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", WHC.Frames.DeathLogFrame, "TOPRIGHT", 2, 1)
    closeButton:SetWidth(36)
    closeButton:SetHeight(36)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        WhcAddonSettings.recentDeaths = 0
        WHC_SETTINGS.recentDeathsBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.recentDeaths))
        WHC.Frames.DeathLogFrame:Hide()
    end)

    local resizeButton = CreateFrame("Button", nil, WHC.Frames.DeathLogFrame)
    resizeButton:SetPoint("BOTTOMRIGHT", WHC.Frames.DeathLogFrame, "BOTTOMRIGHT", 2, -3)
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

    WHC.Frames.DeathLogFrame:SetResizable(true)
    WHC.Frames.DeathLogFrame:SetMinResize(10, 10)
    WHC.Frames.DeathLogFrame:SetMaxResize(800, 600)

    resizeButton:EnableMouse(true)
    resizeButton:SetScript("OnMouseDown", function(self, button)
        WHC.Frames.DeathLogFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function(self, button)
        WHC.Frames.DeathLogFrame:StopMovingOrSizing()
    end)
end

local deathMessages = {}
local fontHeight = 14
local messageRows = {} -- Table to store created font strings

function WHC.LogDeathMessage(msg)
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
            local rowString = WHC.DeathLogFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            rowString:SetPoint("TOPLEFT", WHC.DeathLogFrame.content, "TOPLEFT", 0, -fontHeight * (i - 1))
            rowString:SetFont("Fonts\\FRIZQT__.TTF", fontHeight - 2, "OUTLINE")
            rowString:SetText(message)

            table.insert(messageRows, rowString)

            countRows = countRows + 1
        end

        WHC.DeathLogFrame.content:SetHeight(fontHeight * countRows)
    end
end
