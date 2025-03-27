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
    if (RETAIL == 1) then
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    else
        SendChatMessage(msg);
    end


    if (RETAIL == 1) then
        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
            if (GameTooltip.isBagHook == 1 and GameTooltipTextLeft2:GetText() == "Binds when picked up") then
                tooltip:AddLine(
                    "|cff06daf0You may trade this item with players\nwho were also eligible to loot it\n(for a limited time only)|r",
                    1, 1, 1, true)


                tooltip:Show()
            end
        end)

        local xx_SetBagItem = GameTooltip.SetBagItem
        function GameTooltip.SetBagItem(self, container, slot)
            GameTooltip.isBagHook = 1

            return xx_SetBagItem(self, container, slot)
        end

        GameTooltip:HookScript("OnHide", function()
            GameTooltip.isBagHook = 0
        end)


        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip, ...)
            if (GameTooltipTextLeft1:GetText() == "Swift Dawnsaber") then
                -- todo should check on spellId instead of name because of locales

                tooltip:ClearLines()
                tooltip:AddLine(
                    "Swift Dawnsaber",
                    0.90, 0.80, 0.50, true)
                tooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                tooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Mottled Red Raptor") then
                -- todo should check on spellId instead of name because of locales

                tooltip:ClearLines()
                tooltip:AddLine(
                    "Mottled Red Raptor",
                    0.90, 0.80, 0.50, true)
                tooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                tooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Ivory Raptor") then
                -- todo should check on spellId instead of name because of locales

                tooltip:ClearLines()
                tooltip:AddLine(
                    "Ivory Raptor",
                    0.90, 0.80, 0.50, true)
                tooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                tooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Tiger") then
                -- todo should check on spellId instead of name because of locales

                tooltip:ClearLines()
                tooltip:AddLine(
                    "Tiger",
                    0.90, 0.80, 0.50, true)
                tooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                tooltip:Show()
            end
        end)
    else
        local tooltip = CreateFrame("Frame", nil, GameTooltip)
        tooltip:SetScript("OnShow", function()
            if (GameTooltip.isBagHook == 1 and GameTooltipTextLeft2:GetText() == "Binds when picked up") then
                GameTooltip:AddLine(
                    "|cff06daf0You may trade this item with players\nwho were also eligible to loot it\n(for a limited time only)|r",
                    1, 1, 1, true)
                GameTooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Swift Dawnsaber") then
                -- todo should check on spellId instead of name because of locales

                GameTooltip:ClearLines()
                GameTooltip:AddLine(
                    "Swift Dawnsaber",
                    0.90, 0.80, 0.50, true)
                GameTooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                GameTooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Mottled Red Raptor") then
                -- todo should check on spellId instead of name because of locales

                GameTooltip:ClearLines()
                GameTooltip:AddLine(
                    "Mottled Red Raptor",
                    0.90, 0.80, 0.50, true)
                GameTooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                GameTooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Ivory Raptor") then
                -- todo should check on spellId instead of name because of locales

                GameTooltip:ClearLines()
                GameTooltip:AddLine(
                    "Ivory Raptor",
                    0.90, 0.80, 0.50, true)
                GameTooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                GameTooltip:Show()
            elseif (GameTooltipTextLeft1:GetText() == "Tiger") then
                -- todo should check on spellId instead of name because of locales

                GameTooltip:ClearLines()
                GameTooltip:AddLine(
                    "Tiger",
                    0.90, 0.80, 0.50, true)
                GameTooltip:AddLine(
                    "This mount's speed changes depending on your Riding skill.",
                    1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        tooltip:SetScript("OnHide", function()
            GameTooltip.isBagHook = 0
        end)

        local xx_SetBagItem = GameTooltip.SetBagItem
        function GameTooltip.SetBagItem(self, container, slot)
            GameTooltip.isBagHook = 1
            return xx_SetBagItem(self, container, slot)
        end

        local inInstance, instanceType = IsInInstance()
        if (instanceType == "PVP") then
            WHC.UpdateDeathWindow(true)
        else
            WHC.UpdateDeathWindow(false)
        end
    end
end)

local function createAchievementButton(frame, name)
    local viewAchButton = CreateFrame("Button", "TabCharFrame" .. name, frame)

    viewAchButton:SetWidth(28)
    viewAchButton:SetHeight(28)

    viewAchButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -41) -- Start position for the first tab
    viewAchButton:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round")

    viewAchButton:EnableMouse(true)

    viewAchButton:SetFrameStrata("HIGH")
    viewAchButton:SetFrameLevel(10)

    local border = viewAchButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", viewAchButton, "CENTER", 13, -14)
    border:SetWidth(64)
    border:SetHeight(64)

    if (name == "character") then
        viewAchButton:SetScript("OnClick", function()
            WHC.UIShowTabContent("Achievements")
        end)
    else
        viewAchButton:SetScript("OnClick", function()
            WHC.UIShowTabContent("Achievements", UnitName("target"))
        end)
    end

    viewAchButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(viewAchButton, "ANCHOR_CURSOR")
        GameTooltip:SetText("View character achievements", 1, 1, 1)
        GameTooltip:Show()
    end)

    viewAchButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ResetCursor()
    end)

    viewAchButton:Hide()
    if (WhcAddonSettings.achievementbtn == 1) then
        viewAchButton:Show()
    end

    return viewAchButton
end

function WHC.InitializeAchievementButtons()
    WHC.Frames.AchievementButtonCharacter = createAchievementButton(getglobal("CharacterFrame"), "character")

    local inspectUIEventListener = CreateFrame("Frame")
    inspectUIEventListener:RegisterEvent("ADDON_LOADED")
    inspectUIEventListener:SetScript("OnEvent", function(self, event, addonName)
        addonName = addonName or arg1
        if addonName ~= "Blizzard_InspectUI" then
            return
        end

        WHC.Frames.AchievementButtonInspect = createAchievementButton(getglobal("InspectFrame"), "inspect")
    end)

    if (RETAIL == 1) then
        CharacterFrame:HookScript("OnHide", function(self)
            WHC.UIShowTabContent(0)
        end)
    else
        xx_CharacterFrame_OnHide = CharacterFrame_OnHide
        function CharacterFrame_OnHide()
            xx_CharacterFrame_OnHide()
            WHC.UIShowTabContent(0)
        end
    end
end

local auctionHouseEvents = CreateFrame("Frame")
auctionHouseEvents:RegisterEvent("AUCTION_HOUSE_SHOW")
auctionHouseEvents:SetScript("OnEvent", function()
    local shortButton = AuctionsShortAuctionButton
    local mediumButton = AuctionsMediumAuctionButton
    local longButton = AuctionsLongAuctionButton

    local short = WhcAddonSettings.auction_short / 60 / 24

    if (short == 1) then
        getglobal(shortButton:GetName() .. "Text"):SetText(short .. " day");
    else
        getglobal(shortButton:GetName() .. "Text"):SetText(short .. " days");
    end

    local medium = WhcAddonSettings.auction_medium / 60 / 24
    if (medium == 1) then
        getglobal(mediumButton:GetName() .. "Text"):SetText(medium .. " day");
    else
        getglobal(mediumButton:GetName() .. "Text"):SetText(medium .. " days");
    end

    local long = WhcAddonSettings.auction_long / 60 / 24
    if (long == 1) then
        getglobal(longButton:GetName() .. "Text"):SetText(long .. " day");
    else
        getglobal(longButton:GetName() .. "Text"):SetText(long .. " days");
    end
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

local mapChangeEventHandler = CreateFrame("Frame")
mapChangeEventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
mapChangeEventHandler:SetScript("OnEvent", function(self, event)
    local inInstance, instanceType = IsInInstance()
    -- message(instanceType)
    if (instanceType == "pvp") then
        WHC.UpdateDeathWindow(true)
    else
        WHC.UpdateDeathWindow(false)
    end
end)


local function handleChatEvent(arg1)
    if strfind(string.lower(arg1), string.lower("::whc::ticket:")) then
        local result = string.gsub(arg1, "::whc::ticket:", "")

        UItab["Support"].editBox:SetText(result)
        UItab["Support"].createButton:SetText("Update ticket")
        UItab["Support"].closeButton:SetText("Cancel ticket")

        return 0
        -- message(result)
    elseif strfind(string.lower(arg1), string.lower("::whc::achievement:")) then
        local result = string.gsub(arg1, "::whc::achievement:", "")

        result = tonumber(result)
        if (WHC.Frames.Achievements[result]) then
            WHC.ToggleAchievement(WHC.Frames.Achievements[result], false)
        else
            -- message("error")
        end

        return 0
        -- message(result)
    elseif strfind(string.lower(arg1), string.lower("::whc::auction:deposit")) then
        local result = string.gsub(arg1, "::whc::auction:deposit:", "")

        result = tonumber(result)
        WhcAddonSettings.auction_deposit = result
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::auction:short")) then
        local result = string.gsub(arg1, "::whc::auction:short:", "")

        result = tonumber(result)
        WhcAddonSettings.auction_short = result
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::auction:medium")) then
        local result = string.gsub(arg1, "::whc::auction:medium:", "")

        result = tonumber(result)
        WhcAddonSettings.auction_medium = result
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::auction:long")) then
        local result = string.gsub(arg1, "::whc::auction:long:", "")

        result = tonumber(result)
        WhcAddonSettings.auction_long = result
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::event:")) then
        if (UIspecialEvent ~= nil) then
            UIspecialEvent:SetButtonState("NORMAL")
        end
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::bg:")) then
        if strfind(string.lower(arg1), string.lower("::whc::bg:horde:")) then
            if strfind(string.lower(arg1), string.lower("::whc::bg:horde:ws:")) then
                local result = string.gsub(arg1, "::whc::bg:horde:ws:", "")
                UIWS.horde:SetText(result)
            elseif strfind(string.lower(arg1), string.lower("::whc::bg:horde:ab")) then
                local result = string.gsub(arg1, "::whc::bg:horde:ab:", "")
                UIAB.horde:SetText(result)
            elseif strfind(string.lower(arg1), string.lower("::whc::bg:horde:av")) then
                local result = string.gsub(arg1, "::whc::bg:horde:av:", "")
                UIAV.horde:SetText(result)
            end
        elseif strfind(string.lower(arg1), string.lower("::whc::bg:alliance:")) then
            if strfind(string.lower(arg1), string.lower("::whc::bg:alliance:ws:")) then
                local result = string.gsub(arg1, "::whc::bg:alliance:ws:", "")
                UIWS.alliance:SetText(result)
            elseif strfind(string.lower(arg1), string.lower("::whc::bg:alliance:ab")) then
                local result = string.gsub(arg1, "::whc::bg:alliance:ab:", "")
                UIAB.alliance:SetText(result)
            elseif strfind(string.lower(arg1), string.lower("::whc::bg:alliance:av")) then
                local result = string.gsub(arg1, "::whc::bg:alliance:av:", "")
                UIAV.alliance:SetText(result)
            end
        end
        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::debug:")) then
        local result = string.gsub(arg1, "::whc::debug:", "")
        if (RETAIL == 1) then
            SendChatMessage(result, "WHISPER", GetDefaultLanguage(), UnitName("player"));
        else
            SendChatMessage(result);
        end

        return 0
    elseif strfind(string.lower(arg1), string.lower("::whc::outdated:")) then
        if (WHC_ALERT_UPDATE) then
            WHC_ALERT_UPDATE:Show()
        else
            -- Create the URL frame
            local urlFrame = CreateFrame("Frame", "URLFrameUpdate", UIParent, RETAIL_BACKDROP)
            urlFrame:SetWidth(300)
            urlFrame:SetHeight(160)
            urlFrame:SetPoint("TOP", UIParent, "TOP", 0, -154)
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
            title:SetText(
                "The WOW-HC addon is out of date. Please update it to continue playing on this realm\n\nCopy and paste the following URL to your browser:")
            title:SetWidth(220)

            -- URL input box
            local urlEditBox = CreateFrame("EditBox", "URLInputBox", urlFrame)
            urlEditBox:SetWidth(250)
            urlEditBox:SetHeight(20)
            urlEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
            urlEditBox:SetFontObject("ChatFontNormal")
            urlEditBox:SetText("https://wow-hc.com/addon")
            urlEditBox:SetJustifyH("CENTER")
            urlEditBox:SetAutoFocus(false)
            urlEditBox:HighlightText()
            urlEditBox:SetFocus()
            urlEditBox:SetTextColor(1, 0.631, 0.317)
            urlEditBox:SetScript("OnMouseDown", function(self)
                urlEditBox:HighlightText()
                urlEditBox:SetFocus()
            end)


            urlFrame:Show()
            WHC_ALERT_UPDATE = urlFrame
        end

        return 0
        -- message(result)
    elseif strfind(string.lower(arg1), string.lower("::whc::difficulty:lead:")) then
        local result = string.gsub(arg1, "::whc::difficulty:lead:", "")

        result = tonumber(result)

        if (result == 1) then
            RAID = "Raid |cff06daf0(Dynamic difficulty)|r"
        else
            RAID = "Raid |cffffffff(Normal difficulty)|r"
        end

        if (WHC_ALERT_DIFF) then
            WHC_ALERT_DIFF:Show()
        else
            -- Create the URL frame
            local urlFrame = CreateFrame("Frame", "URLFrameDiff", UIParent, RETAIL_BACKDROP)
            urlFrame:SetWidth(300)
            urlFrame:SetHeight(160)
            urlFrame:SetPoint("TOP", UIParent, "TOP", 0, -154)
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
            title:SetText(
                "Current raid difficulty:")
            title:SetWidth(220)


            local desc = urlFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            desc:SetPoint("TOP", title, "TOP", 0, -20)
            desc:SetText("Loading..")
            desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
            desc:SetTextColor(0.933, 0.765, 0)

            urlFrame.diff = desc;


            local createButton = CreateFrame("Button", "CreateButtonShop", urlFrame, "UIPanelButtonTemplate")
            createButton:SetWidth(130)
            createButton:SetHeight(35)
            createButton:SetPoint("TOPLEFT", urlFrame, "TOPLEFT", 85, -70)
            createButton:SetText("SWITCH")
            createButton:SetScript("OnClick", function()
                local msg = ".diff"
                if (RETAIL == 1) then
                    SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
                else
                    SendChatMessage(msg);
                end
            end)

            -- Create Close button
            local closeButton = CreateFrame("Button", "CloseButton", urlFrame, "UIPanelButtonGrayTemplate")
            closeButton:SetWidth(100)
            closeButton:SetHeight(30)
            closeButton:SetPoint("TOPLEFT", urlFrame, "TOPLEFT", 100, -110)
            closeButton:SetText("Close")
            closeButton:SetScript("OnClick", function()
                WHC_ALERT_DIFF:Hide()
            end)

            urlFrame:Show()
            WHC_ALERT_DIFF = urlFrame
        end

        if (result == 1) then
            WHC_ALERT_DIFF.diff:SetText("Dynamic")
        else
            WHC_ALERT_DIFF.diff:SetText("Normal")
        end
        return 0
        -- message(result)
    elseif strfind(string.lower(arg1), string.lower("::whc::difficulty:")) then
        local result = string.gsub(arg1, "::whc::difficulty:", "")

        result = tonumber(result)



        if (result == 1) then
            RAID = "Raid |cff06daf0(Dynamic difficulty)|r"
        else
            RAID = "Raid |cffffffff(Normal difficulty)|r"
        end
        return 0
    else
        return 1
    end
end

local function handleMonsterChatEvent(arg1)
    if (strfind(string.lower(arg1), string.lower("has died at level"))) then

        WHC.LogDeathMessage(arg1)
        return 0
    else
        return 1
    end
end

if (RETAIL == 1) then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_EMOTE", function(frame, event, message, sender, ...)
        handleMonsterChatEvent(message)
    end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", function(frame, event, message, sender, ...)
       handleMonsterChatEvent(message)
    end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(frame, event, message, sender, ...)
        if (handleChatEvent(message) == 0) then
            return true
        end
    end)
else
    xx_ChatFrame_OnEvent = ChatFrame_OnEvent

    WHC_ALERT_UPDATE = nil
    WHC_ALERT_DIFF = nil
    function ChatFrame_OnEvent(event)
        if (event == "CHAT_MSG_RAID_BOSS_EMOTE" or event == "CHAT_MSG_MONSTER_EMOTE") then
            handleMonsterChatEvent(arg1)
                xx_ChatFrame_OnEvent(event)

        elseif (event == "CHAT_MSG_SYSTEM") then
            if (handleChatEvent(arg1) == 1) then
                xx_ChatFrame_OnEvent(event)
            end
        else
            xx_ChatFrame_OnEvent(event)
        end
    end
end
