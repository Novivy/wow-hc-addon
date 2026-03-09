local previousRow = nil
local function createRow(parent, labelText, valueText)
    local row = CreateFrame("Frame", nil, parent)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    label:SetFontObject(GameFontWhite)
    label:SetPoint("TOPLEFT", row, "TOPLEFT")
    label:SetText(labelText)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    value:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    value:SetFontObject(GameFontWhite)
    value:SetPoint("TOPRIGHT", row, "TOPRIGHT")
    value:SetText(valueText)
    value:SetJustifyH("RIGHT")

    row.label = label
    row.value = value
    row:SetHeight(label:GetHeight())
    row:SetWidth(parent:GetWidth() - 6)
    row:Show()

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT")
    else
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3)
    end

    previousRow = row

    return row
end

function WHC.InitializeSpeedRunTimer()
    local speedRunTimer = CreateFrame("Frame", "SpeedRunTimer", UIParent, RETAIL_BACKDROP)
    speedRunTimer:Show()
    speedRunTimer:SetWidth(200)
    speedRunTimer:SetHeight(70)
    speedRunTimer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    speedRunTimer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    speedRunTimer:EnableMouse(true)
    speedRunTimer:SetMovable(true)
    speedRunTimer:RegisterForDrag("LeftButton")
    speedRunTimer:SetScript("OnDragStart", function()
        this:StartMoving()
    end)

    speedRunTimer:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    local dungeon = createRow(speedRunTimer, "DungeonName", "(10-20)")
    local status = createRow(speedRunTimer, "Status", "Valid")
    local currentTime = createRow(speedRunTimer, "Current time:", "0:00:00")
    local personalRecord = createRow(speedRunTimer, "Personal record:", "0:00:00")
    local serverRecord = createRow(speedRunTimer, "Server record:", "0:00:00")
end