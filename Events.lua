local playerLogin = CreateFrame("Frame");
playerLogin:RegisterEvent("PLAYER_LOGIN")
playerLogin:SetScript("OnEvent", function(self, event)
    if (RETAIL == 1) then
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_SAY")
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_YELL")
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_EMOTE")
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_WHISPER")
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_BOSS_EMOTE")
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "MONSTER_BOSS_WHISPER")
    else
        ChatFrame_AddMessageGroup(DEFAULT_CHAT_FRAME, "CREATURE")
        JoinChannelByName("world", nil, DEFAULT_CHAT_FRAME) -- Not working on retail version
    end

    local msg = ".whc version " .. GetAddOnMetadata("WOW_HC", "Version")
    SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));

    -- Initialize UI to same state as server
    WHC.SendGetRestedXpStatusCommand()
end)

local function createAchievementButton(frame, name)
    local viewAchButton = CreateFrame("Button", "TabCharFrame" .. name, frame)

    viewAchButton:SetWidth(28)
    viewAchButton:SetHeight(28)
    viewAchButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -41) -- Start position for the first tab
    viewAchButton:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round")
    viewAchButton:SetFrameStrata("HIGH")
    viewAchButton:SetFrameLevel(10)

    local border = viewAchButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", viewAchButton, "CENTER", 13, -14)
    border:SetWidth(64)
    border:SetHeight(64)

    viewAchButton:EnableMouse(true)
    viewAchButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(viewAchButton, "ANCHOR_CURSOR")
        GameTooltip:SetText("View character achievements", 1, 1, 1)
        GameTooltip:Show()
    end)

    viewAchButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ResetCursor()
    end)

    viewAchButton:SetScript("OnClick", function()
        WHC.UIShowTabContent("Achievements")
    end)

    viewAchButton:Hide()
    if (WhcAddonSettings.achievementbtn == 1) then
        viewAchButton:Show()
    end

    return viewAchButton
end

function WHC.InitializeAchievementButtons()
    WHC.Frames.AchievementButtonCharacter = createAchievementButton(CharacterFrame, "character")

    local inspectUIEventListener = CreateFrame("Frame")
    inspectUIEventListener:RegisterEvent("ADDON_LOADED")
    inspectUIEventListener:SetScript("OnEvent", function(self, event, addonName)
        addonName = addonName or arg1
        if addonName ~= "Blizzard_InspectUI" then
            return
        end
        inspectUIEventListener:UnregisterEvent("ADDON_LOADED")

        WHC.Frames.AchievementButtonInspect = createAchievementButton(InspectFrame, "inspect")
    end)
end

local function getAuctionButtonText(duration)
    local plural = ""
    if duration ~= 1 then
        plural = "s"
    end

    return duration .. " day" .. plural
end

local auctionHouseEvents = CreateFrame("Frame")
auctionHouseEvents:RegisterEvent("AUCTION_HOUSE_SHOW")
auctionHouseEvents:SetScript("OnEvent", function()
    local short = WhcAddonSettings.auction_short / 60 / 24
    getglobal(AuctionsShortAuctionButton:GetName() .. "Text"):SetText(getAuctionButtonText(short));

    local medium = WhcAddonSettings.auction_medium / 60 / 24
    getglobal(AuctionsMediumAuctionButton:GetName() .. "Text"):SetText(getAuctionButtonText(medium));

    local long = WhcAddonSettings.auction_long / 60 / 24
    getglobal(AuctionsLongAuctionButton:GetName() .. "Text"):SetText(getAuctionButtonText(long));
end)

local xx_MoneyFrame_Update = MoneyFrame_Update
function MoneyFrame_Update(frameName, money)
    if frameName == "AuctionsDepositMoneyFrame" then
        local customDeposit = money * WhcAddonSettings.auction_deposit
        xx_MoneyFrame_Update(frameName, customDeposit)
    else
        xx_MoneyFrame_Update(frameName, money)
    end
end

local updateAddonFrame
local function initializeUpdateAddonFrame()
    updateAddonFrame = CreateFrame("Frame", "UpdateAddonFrame", UIParent, RETAIL_BACKDROP)
    updateAddonFrame:SetWidth(300)
    updateAddonFrame:SetHeight(210)
    updateAddonFrame:SetPoint("TOP", UIParent, "TOP", 0, -154)
    updateAddonFrame:SetBackdrop({
        bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 300,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    updateAddonFrame:SetFrameStrata("HIGH")
    updateAddonFrame:SetFrameLevel(10)

    -- Title
    local title = updateAddonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", updateAddonFrame, "TOP", 0, -20)
    title:SetText(WHC.ADDON_PREFIX.."is out of date.\n\nPlease update it to keep things running smoothly.\n\nCopy and paste this URL\ninto your browser:")
    title:SetWidth(220)

    -- URL input box
    local updateAddonEditBox = CreateFrame("EditBox", "UpdateAddonInputBox", updateAddonFrame)
    updateAddonEditBox:SetWidth(250)
    updateAddonEditBox:SetHeight(20)
    updateAddonEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
    updateAddonEditBox:SetFontObject("ChatFontNormal")
    updateAddonEditBox:SetText("https://wow-hc.com/addon")
    updateAddonEditBox:SetJustifyH("CENTER")
    updateAddonEditBox:SetAutoFocus(false)
    updateAddonEditBox:HighlightText()
    updateAddonEditBox:SetFocus()
    updateAddonEditBox:SetTextColor(1, 0.631, 0.317)
    updateAddonEditBox:SetScript("OnMouseDown", function(self)
        updateAddonEditBox:HighlightText()
        updateAddonEditBox:SetFocus()
    end)

    local closeButton = CreateFrame("Button", "CloseButton", updateAddonFrame, "UIPanelButtonGrayTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(30)
    closeButton:SetPoint("BOTTOMLEFT", updateAddonFrame, "BOTTOMLEFT", 100, 24)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        updateAddonFrame:Hide()
    end)

    updateAddonFrame:Hide()
end

local raidDifficultyFrame
local function initializeRaidDifficultyFrame()
    raidDifficultyFrame = CreateFrame("Frame", "RaidDifficultyFrame", UIParent, RETAIL_BACKDROP)
    raidDifficultyFrame:SetWidth(300)
    raidDifficultyFrame:SetHeight(160)
    raidDifficultyFrame:SetPoint("TOP", UIParent, "TOP", 0, -154)
    raidDifficultyFrame:SetBackdrop({
        bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 300,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    raidDifficultyFrame:SetFrameStrata("HIGH")
    raidDifficultyFrame:SetFrameLevel(10)

    -- Title
    local title = raidDifficultyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", raidDifficultyFrame, "TOP", 0, -20)
    title:SetText("Current raid difficulty:")
    title:SetWidth(220)


    local desc = raidDifficultyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "TOP", 0, -20)
    desc:SetText("Loading..")
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetTextColor(0.933, 0.765, 0)

    raidDifficultyFrame.diff = desc;

    local createButton = CreateFrame("Button", "CreateButtonShop", raidDifficultyFrame, "UIPanelButtonTemplate")
    createButton:SetWidth(130)
    createButton:SetHeight(35)
    createButton:SetPoint("TOPLEFT", raidDifficultyFrame, "TOPLEFT", 85, -70)
    createButton:SetText("SWITCH")
    createButton:SetScript("OnClick", function()
        local msg = ".diff"
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    end)

    -- Create Close button
    local closeButton = CreateFrame("Button", "CloseButton", raidDifficultyFrame, "UIPanelButtonGrayTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(30)
    closeButton:SetPoint("TOPLEFT", raidDifficultyFrame, "TOPLEFT", 100, -110)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        raidDifficultyFrame:Hide()
    end)

    raidDifficultyFrame:Hide()
end

local function getColorCode(colorObject)
    local colorStr = colorObject.colorStr

    if not colorStr then
        -- Scale the 0-1 values to 0-255
        local r = colorObject.r * 255
        local g = colorObject.g * 255
        local b = colorObject.b * 255

        -- Format the numbers into a hex string (e.g., "ff33c9ff")
        colorStr = string.format("ff%02x%02x%02x", r, g, b)
    end

    return string.format("|c%s", colorStr)
end

local function getTargetAchievementsDescription()
    local name = UnitName("target")
    local _, englishClass = UnitClass("target")

    local color = RAID_CLASS_COLORS[englishClass]
    if englishClass == "SHAMAN" then
        color = {r = 0.14, g = 0.35, b = 1, colorStr = "ff2459ff"} -- TBC Shaman color
    end

    local classColorCode = getColorCode(color)
    local player = classColorCode .. name .. FONT_COLOR_CODE_CLOSE
    return "\nListing " .. player .. "'s achievements"
end

local function handleChatEvent(arg1)
    local lowerArg = string.lower(arg1)
    if not string.find(lowerArg, "^::whc::") then
        return 1
    end

    if string.find(lowerArg, "^::whc::ticket:") then
        local result = string.gsub(arg1, "^::whc::ticket:", "")

        WHC.Frames.UItab["Support"].editBox:SetText(result)
        WHC.Frames.UItab["Support"].createButton:SetText("Update ticket")
        WHC.Frames.UItab["Support"].closeButton:SetText("Cancel ticket")

        return 0
    end

    if string.find(lowerArg, "^::whc::achievement%-target:") then
        local result = string.gsub(lowerArg, "^::whc::achievement%-target:", "")
        local desc = "Achievements are optional goals that you start with but may lose depending on your actions"
        if result ~= "0" then
            desc = getTargetAchievementsDescription()
        end

        WHC.Frames.UItab["Achievements"].desc1:SetText(desc)

        return 0
    end

    if string.find(lowerArg, "^::whc::achievement:") then
        local result = string.gsub(arg1, "^::whc::achievement:", "")
        result = tonumber(result)
        if (WHC.Frames.Achievements[result]) then
            WHC.ToggleAchievement(WHC.Frames.Achievements[result], false)
        end

        return 0
    end

    if string.find(lowerArg, "^::whc::restedxp:status:%d") then
        local result = string.gsub(arg1, "^::whc::restedxp:status:", "")
        result = tonumber(result)

        WHC.OnRestedXpStatusReceived(result)

        return 0
    end

    if string.find(lowerArg, "^::whc::auction:") then
        local _, _ , variable, result = string.find(lowerArg, "^::whc::auction:(%l+):([%d\.]+)")
        if WhcAddonSettings["auction_"..variable] then
            WhcAddonSettings["auction_"..variable] = tonumber(result)
        end

        return 0
    end

    if string.find(lowerArg, "^::whc::event:") then
        if (WHC.Frames.UIspecialEvent ~= nil) then
            WHC.Frames.UIspecialEvent:SetButtonState("NORMAL")
        end

        return 0
    end

    if string.find(lowerArg, "^::whc::bg:") then
        local _, _, faction, bg, result = string.find(lowerArg, "^::whc::bg:(%l+):(%l+):(%d+)")
        if WHC.Frames.UIBattleGrounds[bg] and WHC.Frames.UIBattleGrounds[bg][faction] then
            WHC.Frames.UIBattleGrounds[bg][faction]:SetText(result)
        end

        return 0
    end

    if string.find(lowerArg, "^::whc::debug:") then
        local result = string.gsub(arg1, "^::whc::debug:", "")
        SendChatMessage(result, "WHISPER", GetDefaultLanguage(), UnitName("player"));

        return 0
    end

    if string.find(lowerArg, "^::whc::outdated:") then
        if not updateAddonFrame then
            initializeUpdateAddonFrame()
        end

        updateAddonFrame:Show()
        return 0
    end

    if string.find(lowerArg, "^::whc::difficulty:lead:") then
        local result = string.gsub(arg1, "^::whc::difficulty:lead:", "")
        result = tonumber(result)

        if not raidDifficultyFrame then
            initializeRaidDifficultyFrame()
        end

        raidDifficultyFrame:Show()

        RAID = "Raid " .. HIGHLIGHT_FONT_COLOR_CODE .. "(Normal difficulty)" .. FONT_COLOR_CODE_CLOSE
        raidDifficultyFrame.diff:SetText("Normal")
        if (result == 1) then
            RAID = "Raid " .. WHC.COLORS.GM_BLUE_FONT_COLOR_CODE .. "(Dynamic difficulty)" .. FONT_COLOR_CODE_CLOSE
            raidDifficultyFrame.diff:SetText("Dynamic")
        end

        return 0
    end

    if string.find(lowerArg, "^::whc::difficulty:") then
        local result = string.gsub(arg1, "^::whc::difficulty:", "")
        result = tonumber(result)

        RAID = "Raid " .. HIGHLIGHT_FONT_COLOR_CODE .. "(Normal difficulty)" .. FONT_COLOR_CODE_CLOSE
        if (result == 1) then
            RAID = "Raid " .. WHC.COLORS.GM_BLUE_FONT_COLOR_CODE .. "(Dynamic difficulty)" .. FONT_COLOR_CODE_CLOSE
        end

        return 0
    end

    return 1
end

local function handleMonsterChatEvent(arg1)
    if (string.find(string.lower(arg1), "has died at level")) then

        WHC.LogDeathMessage(arg1)
        return 0
    end

    return 1
end

if (RETAIL == 1) then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_EMOTE", function(frame, event, message, sender, ...)
        handleMonsterChatEvent(message)
    end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", function(frame, event, message, sender, ...)
        handleMonsterChatEvent(message)
    end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(frame, event, message, sender, ...)
        return handleChatEvent(message) == 0
    end)
else
    xx_ChatFrame_OnEvent = ChatFrame_OnEvent

    function ChatFrame_OnEvent(event)
        if event == "CHAT_MSG_SYSTEM" then
            if handleChatEvent(arg1) == 0 then
                return
            end
        end

        if (event == "CHAT_MSG_RAID_BOSS_EMOTE" or event == "CHAT_MSG_MONSTER_EMOTE") then
            handleMonsterChatEvent(arg1)
        end

        xx_ChatFrame_OnEvent(event)
    end
end
