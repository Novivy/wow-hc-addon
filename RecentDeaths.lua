function WHC.InitializeDeathLogFrame()
    local deathLogFrame = CreateFrame("Frame", "MyAddonFrame", UIParent, RETAIL_BACKDROP)
    deathLogFrame:SetWidth(400)
    deathLogFrame:SetHeight(300)
    deathLogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    deathLogFrame:SetMovable(true)
    deathLogFrame:EnableMouse(true)
    deathLogFrame:SetScript("OnMouseDown", function()
        deathLogFrame:StartMoving()
    end)

    deathLogFrame:SetScript("OnMouseUp", function()
        deathLogFrame:StopMovingOrSizing()
    end)

    deathLogFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    deathLogFrame:SetBackdropColor(0, 0, 0, 0.8)
    deathLogFrame:SetBackdropBorderColor(.5, .5, .5, 1)

    local title = deathLogFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", deathLogFrame, "TOP", 0, -10)
    title:SetText("Recent Deaths")
    title:SetTextColor(0.933, 0.765, 0)

    local scrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", deathLogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", deathLogFrame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", deathLogFrame, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", "MyAddonScrollContent", scrollFrame)
    content:SetWidth(360)
    content:SetHeight(0)
    scrollFrame:SetScrollChild(content)
    deathLogFrame.content = content

    local closeButton = CreateFrame("Button", nil, deathLogFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", deathLogFrame, "TOPRIGHT", 2, 1)
    closeButton:SetWidth(36)
    closeButton:SetHeight(36)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        WhcAddonSettings.recentDeaths = 0
        WHC_SETTINGS.recentDeathsBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.recentDeaths))
        deathLogFrame:Hide()
    end)

    local resizeButton = CreateFrame("Button", nil, deathLogFrame)
    resizeButton:SetPoint("BOTTOMRIGHT", deathLogFrame, "BOTTOMRIGHT", 2, -3)
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

    deathLogFrame:SetResizable(true)
    deathLogFrame:SetMinResize(10, 10)
    deathLogFrame:SetMaxResize(800, 600)

    resizeButton:EnableMouse(true)
    resizeButton:SetScript("OnMouseDown", function(self, button)
        deathLogFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function(self, button)
        deathLogFrame:StopMovingOrSizing()
    end)

    WHC.Frames.DeathLogFrame = deathLogFrame
    WHC.Frames.DeathLogFrame:Hide()
    if (WhcAddonSettings.recentDeaths == 1) then
        WHC.Frames.DeathLogFrame:Show()
    end
end

local deathMessages = {}
local fontHeight = 14
local messageRows = {} -- Table to store created font strings

function WHC.LogDeathMessage(msg)
    if (WhcAddonSettings.recentDeaths == 1) then
        local serverTime = date("%H:%M")
        local formattedMessage = WHC.COLORS.ACHIEVEMENT_COLOR_CODE .. serverTime .. FONT_COLOR_CODE_CLOSE .. " " .. msg

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
            local rowString = WHC.Frames.DeathLogFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            rowString:SetPoint("TOPLEFT", WHC.Frames.DeathLogFrame.content, "TOPLEFT", 0, -fontHeight * (i - 1))
            rowString:SetFont("Fonts\\FRIZQT__.TTF", fontHeight - 2, "OUTLINE")
            rowString:SetText(message)

            table.insert(messageRows, rowString)

            countRows = countRows + 1
        end

        WHC.Frames.DeathLogFrame.content:SetHeight(fontHeight * countRows)
    end
end
