local instanceLevelRange = {
    ["Ragefire Chasm"]            = "(13-18)",
    ["The Deadmines"]             = "(17-26)",
    ["Wailing Caverns"]           = "(17-24)",
    ["Shadowfang Keep"]           = "(22-30)",
    ["Blackfathom Deeps"]         = "(24-32)",
    ["The Stockade"]              = "(24-32)",
    ["Gnomeregan"]                = "(29-38)",
    ["Razorfen Kraul"]            = "(29-38)",
    ["Scarlet Monastery"]         = "(34-45)",
    ["Razorfen Downs"]            = "(37-46)",
    ["Uldaman"]                   = "(41-51)",
    ["Maraudon"]                  = "(46-55)",
    ["Zul'Farrak"]                = "(44-54)",
    ["The Temple of Atal'Hakkar"] = "(50-60)",
    ["Blackrock Depths"]          = "(52-60)",
    ["Blackrock Spire"]           = "(55-60)",
    ["Stratholme"]                = "(58-60)",
    ["Dire Maul"]                 = "(56-60)",
    ["Scholomance"]               = "(58-60)",
}

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

local STATUS_VALID = 1
local STATUS_INVALID_LEVEL = 2
local STATUS_INVALID_WORLD_BUFF = 3
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
    speedRunTimer:SetScript("OnDragStart", function(self)
        self = self or this
        self:StartMoving()
    end)

    speedRunTimer:SetScript("OnDragStop", function(self)
        self = self or this
        self:StopMovingOrSizing()
    end)

    speedRunTimer.dungeon = createRow(speedRunTimer, "DungeonName", "(10-20)")
    speedRunTimer.status = createRow(speedRunTimer, "Status", "Valid")
    speedRunTimer.currentTime = createRow(speedRunTimer, "Current time:", "0:00:00")
    speedRunTimer.personalRecord = createRow(speedRunTimer, "Personal record:", "0:00:00")
    speedRunTimer.serverRecord = createRow(speedRunTimer, "Server record:", "0:00:00")

    local firedCommand = false

    function speedRunTimer:hide()
        self:Hide()

        self.dungeon.label:SetText("")
        self.dungeon.value:SetText("")
        self.status.value:SetText("")
        self.currentTime.value:SetText("")
        self.personalRecord.value:SetText("")
        self.serverRecord.value:SetText("")

        firedCommand = false
    end

    function speedRunTimer:StartTimer(status, seconds)
        if status ~= STATUS_VALID then
            return self:StopTimer(status, seconds)
        end

        self:SetStatus(status)
        local firstTimestamp = GetTime()
        local i = 1

        self:SetScript("OnUpdate", function()
            local elapsed = GetTime() - firstTimestamp

            if elapsed > i then
                i = i + 1
                if i % 120 == 0 then -- sync with server every 2 minutes
                    SendChatMessage(".whc speedrun timer", "WHISPER", GetDefaultLanguage(), UnitName("player"))
                else
                    seconds = seconds + 1
                    self:SetCurrentTime(seconds)
                end
            end
        end)

        self:Show()
    end

    function speedRunTimer:StopTimer(status, seconds)
        self:SetScript("OnUpdate", nil)
        self:SetCurrentTime(seconds)
        self:SetStatus(status)

        if status == STATUS_VALID then
            local dungeonName = GetRealZoneText()
            local personalRecord = WhcAddonSettings.speedRunTimer[dungeonName]
            if not personalRecord or seconds < personalRecord then
                WhcAddonSettings.speedRunTimer[dungeonName] = seconds
                -- flash animation
            end

            if self.serverRecord.seconds == 0 or seconds < self.serverRecord.seconds then
                -- flash animation
            end
        end
    end

    function speedRunTimer:SetStatus(status)
        local color = GREEN_FONT_COLOR
        if status == STATUS_VALID then
            self.status.value:SetText("Valid")
            color = GREEN_FONT_COLOR
        elseif status == STATUS_INVALID_LEVEL then
            self.status.value:SetText("Too high level")
            color = RED_FONT_COLOR
        elseif status == STATUS_INVALID_WORLD_BUFF then
            self.status.value:SetText("World buff detected")
            color = RED_FONT_COLOR
        end
        self.status.value:SetTextColor(color.r, color.g, color.b, 1)

        self:Show()
    end

    function speedRunTimer:SetCurrentTime(seconds)
        self.currentTime.value:SetText(WHC.SecondsToClock(seconds))
    end

    function speedRunTimer:SetPersonalRecord(seconds)
        self.personalRecord.value:SetText(WHC.SecondsToClock(seconds))
    end

    function speedRunTimer:SetServerRecord(seconds)
        self.serverRecord.seconds = seconds
        self.serverRecord.value:SetText(WHC.SecondsToClock(seconds))
    end

    speedRunTimer:RegisterEvent("PLAYER_ENTERING_WORLD")
    speedRunTimer:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- backup event to get the correct name for Blackrock Spire and Stockades
    speedRunTimer:SetScript("OnEvent", function(self, eventName)
        self = self or this
        local _, instanceType = IsInInstance()
        if instanceType ~= "party" then
            return self:hide()
        end

        local dungeonName = GetRealZoneText()
        self.dungeon.label:SetText(dungeonName)
        self.dungeon.value:SetText(instanceLevelRange[dungeonName] or "")

        -- Some instances only fire PLAYER_ENTERING_WORLD while others also fire ZONE_CHANGED_NEW_AREA
        -- This check prevents the command being fired more than once
        if not firedCommand then
            firedCommand = true
            SendChatMessage(".whc speedrun timer", "WHISPER", GetDefaultLanguage(), UnitName("player"))
            SendChatMessage(".whc speedrun record", "WHISPER", GetDefaultLanguage(), UnitName("player"))
        end

        if WhcAddonSettings.speedRunTimer[dungeonName] then
            self:SetPersonalRecord(WhcAddonSettings.speedRunTimer[dungeonName])
        end
    end)

    WHC.Frames.SpeedRunTimer = speedRunTimer
end