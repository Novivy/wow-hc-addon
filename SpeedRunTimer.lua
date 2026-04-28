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

local STATUS_VALID = 1
local STATUS_INVALID_LEVEL = 2
local STATUS_INVALID_WORLD_BUFF = 3

local previousRow = nil
local function createTitleRow(parent, labelText)
    local row = CreateFrame("Frame", nil, parent)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(labelText)
    label:SetPoint("TOP", row, "TOP", 0, -10)

    row.label = label
    row:SetHeight(label:GetHeight() + 20)
    row:SetWidth(parent:GetWidth())
    row:Show()

    row:SetPoint("TOP", parent, "TOP")

    previousRow = row

    return row
end
local function createRow(parent, labelText, valueText)
    local row = CreateFrame("Frame", nil, parent)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    label:SetPoint("LEFT", row, "LEFT")
    label:SetText(labelText)

    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    value:SetPoint("RIGHT", row, "RIGHT")
    value:SetText(valueText)
    value:SetJustifyH("RIGHT")

    row.label = label
    row.value = value
    row:SetHeight(label:GetHeight() + 2)
    row:SetWidth(parent:GetWidth() - 15)
    row:Show()

    row:SetPoint("TOP", previousRow, "BOTTOM")

    previousRow = row

    return row
end

function WHC.InitializeSpeedRunTimer()
    local speedRunTimer = CreateFrame("Frame", "SpeedRunTimer", UIParent, RETAIL_BACKDROP)
    speedRunTimer:Hide()
    speedRunTimer:SetWidth(210)
    speedRunTimer:SetHeight(125)
    speedRunTimer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    speedRunTimer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    speedRunTimer:SetBackdropColor(0, 0, 0, 0.8)
    speedRunTimer:SetBackdropBorderColor(.5, .5, .5, 1)

    speedRunTimer:EnableMouse(true)
    speedRunTimer:SetMovable(true)
    speedRunTimer:RegisterForDrag("LeftButton")
    speedRunTimer:SetScript("OnDragStart", function()
        speedRunTimer:StartMoving()
    end)

    speedRunTimer:SetScript("OnDragStop", function()
        speedRunTimer:StopMovingOrSizing()
    end)

    local closeButton = CreateFrame("Button", nil, speedRunTimer, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", speedRunTimer, "TOPRIGHT", 0, 1)
    closeButton:SetWidth(36)
    closeButton:SetHeight(36)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        PlaySound(WHC.sounds.checkBoxOff)
        WhcAddonSettings.speedRunTimer.showTimer = 0
        WHC_SETTINGS.speedRunTimerBtn:SetChecked(WHC.CheckedValue(WhcAddonSettings.speedRunTimer.showTimer))
        speedRunTimer:Hide()
    end)

    createTitleRow(speedRunTimer, "Dungeon timer")
    speedRunTimer.dungeon = createRow(speedRunTimer, "DungeonName", "(10-20)")
    speedRunTimer.status = createRow(speedRunTimer, "Status:", "Valid")
    speedRunTimer.progress = createRow(speedRunTimer, "Progress:", "0/0")
    speedRunTimer.currentTime = createRow(speedRunTimer, "Current time:", "0:00:00")
    speedRunTimer.personalRecord = createRow(speedRunTimer, "Personal record:", "0:00:00")
    speedRunTimer.serverRecord = createRow(speedRunTimer, "Server record:", "0:00:00")

    speedRunTimer.currentTime.seconds = 0
    speedRunTimer.personalRecord.seconds = 0
    speedRunTimer.serverRecord.seconds = 0

    local firedCommand = false

    function speedRunTimer:ShowInDungeon()
        local _, instanceType = IsInInstance()
        if instanceType == "party" then
            return self:Show()
        end
    end

    function speedRunTimer:HideAndClear()
        self:Hide()
        self:SetScript("OnUpdate", nil)

        self.dungeon.label:SetText("")
        self.dungeon.value:SetText("")
        self.status.value:SetText("")
        self.currentTime.value:SetText("")
        self.personalRecord.value:SetText("")
        self.serverRecord.value:SetText("")

        self.currentTime.seconds = 0
        self.personalRecord.seconds = 0
        self.serverRecord.seconds = 0

        firedCommand = false
    end

    function speedRunTimer:StartTimer(status, seconds)
        if status ~= STATUS_VALID then
            return self:StopTimer(status, seconds)
        end

        self:SetStatus(status)
        local firstTimestamp = GetTime()
        local i = 0

        self:SetScript("OnUpdate", function()
            local elapsed = GetTime() - firstTimestamp

            if elapsed > i then
                i = i + 1
                if WHC.Modulus(i, 120) == 0 then -- sync with server every 2 minutes
                    SendChatMessage(".whc speedrun timer", "WHISPER", GetDefaultLanguage(), UnitName("player"))
                else
                    seconds = seconds + 1
                    self:SetCurrentTime(seconds)
                end
            end
        end)

        if WhcAddonSettings.speedRunTimer.showTimer == 1 then
            self:Show()
        end
    end

    function speedRunTimer:StopTimer(status, seconds)
        local wasTimerRunning = self:GetScript("OnUpdate")
        self:SetScript("OnUpdate", nil)
        self:SetCurrentTime(seconds)
        self:SetStatus(status)

        -- Only update records on valid runs where the timer was running
        -- This prevents people from getting a personal record from entering an already cleared dungeon
        if status == STATUS_VALID and wasTimerRunning then
            local dungeonName = GetRealZoneText()
            local personalRecord = WhcAddonSettings.speedRunTimer.personalRecords[dungeonName] or 0
            if personalRecord == 0 or seconds < personalRecord then
                WhcAddonSettings.speedRunTimer.personalRecords[dungeonName] = seconds
                self:SetPersonalRecord(seconds)
                self:FlashAnimation(self.personalRecord)
            end

            if self.serverRecord.seconds == 0 or seconds < self.serverRecord.seconds then
                self:SetServerRecord(seconds)
                self:FlashAnimation(self.serverRecord)
            end
        end

        if WhcAddonSettings.speedRunTimer.showTimer == 1 then
            self:Show()
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
    end

    function speedRunTimer:SetProgress(killed, total)
        self.progress.value:SetText(string.format("%d / %d", killed, total))
    end

    function speedRunTimer:setTime(frame, seconds)
        frame.seconds = seconds
        frame.value:SetText(WHC.SecondsToClock(seconds))
    end

    function speedRunTimer:SetCurrentTime(seconds)
        self:setTime(self.currentTime, seconds)
    end

    function speedRunTimer:SetPersonalRecord(seconds)
        self:setTime(self.personalRecord, seconds)
    end

    function speedRunTimer:SetServerRecord(seconds)
        self:setTime(self.serverRecord, seconds)
    end

    function speedRunTimer:FlashAnimation(frame)
        local animationTimeSeconds = 5

        local firstTimestamp = GetTime()
        frame:SetScript("OnUpdate", function()
            local elapsed = GetTime() - firstTimestamp

            local alpha = WHC.Modulus(math.floor(elapsed * 2), 2)
            frame:SetAlpha(alpha)

            -- Ensures the frame is visible when the animation stops
            if elapsed > animationTimeSeconds and alpha == 1 then
                frame:SetScript("OnUpdate", nil)
            end
        end)
    end

    speedRunTimer:RegisterEvent("PLAYER_ENTERING_WORLD")
    speedRunTimer:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- backup event to get the correct name for Blackrock Spire and Stockades
    speedRunTimer:SetScript("OnEvent", function(self, eventName)
        self = self or this
        local _, instanceType = IsInInstance()
        if instanceType ~= "party" then
            return self:HideAndClear()
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

        self:SetPersonalRecord(WhcAddonSettings.speedRunTimer.personalRecords[dungeonName] or 0)
    end)

    WHC.Frames.SpeedRunTimer = speedRunTimer
end
