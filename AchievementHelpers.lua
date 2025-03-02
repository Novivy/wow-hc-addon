local ACHIEVEMENT_COLOR_CODE = "|cffff8000";
local addonPrefix = ACHIEVEMENT_COLOR_CODE.."[WOW-HC.com]: "..FONT_COLOR_CODE_CLOSE

local function achievementLink(achievement)
    return ACHIEVEMENT_COLOR_CODE.."|Hitem:"..achievement.itemId..":0:0:0|h["..achievement.name.."]|h"..FONT_COLOR_CODE_CLOSE
end

local function printAchievementInfo(link, message)
    local achievementMsg = link..HIGHLIGHT_FONT_COLOR_CODE.." Achievement active. "
    DEFAULT_CHAT_FRAME:AddMessage(addonPrefix..achievementMsg..message..FONT_COLOR_CODE_CLOSE)
end

local _G = getfenv(0);
local function hooksecurefunc(arg1, arg2, arg3)
    if type(arg1) == "string" then
        arg1, arg2, arg3 = _G, arg1, arg2
    end
    local orig = arg1[arg2]
    arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
    end
end

local BlizzardFunctions = {}
-- Disables right-click menu buttons
hooksecurefunc("UnitPopup_OnUpdate", function(self, dropdownMenu, which, unit, name)
    for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList1Button" .. i]
        if button then
            if button.value == "INVITE" and WhcAddonSettings.blockInvites == 1 then
                button:Disable()
            end

            if button.value == "TRADE" and WhcAddonSettings.blockTrades == 1 then
                button:Disable()
            end
        end
    end
end)

--region ====== Lone Wolf ======
BlizzardFunctions.AcceptGroup = AcceptGroup
BlizzardFunctions.InviteUnit = InviteUnit -- Retail
BlizzardFunctions.InviteByName = InviteByName -- 1.12
local loneWolfLink = achievementLink(TabAchievements[ACHIEVEMENT_LONE_WOLF])

-- Disables friend list "Group Invite" button
hooksecurefunc("FriendsList_Update", function()
    if WhcAddonSettings.blockInvites == 1 and FriendsFrameGroupInviteButton then
        FriendsFrameGroupInviteButton:Disable()
    end
end)

-- Disables who "Group Invite" button
hooksecurefunc("WhoList_Update", function()
    if WhcAddonSettings.blockInvites == 1 and WhoFrameGroupInviteButton then
        WhoFrameGroupInviteButton:Disable()
    end
end)

-- Disables guild details "Group Invite" button
hooksecurefunc("GuildStatus_Update", function()
    if WhcAddonSettings.blockInvites == 1 and GuildMemberGroupInviteButton then
        GuildMemberGroupInviteButton:Disable()
    end
end)

local inviteEventHandler = CreateFrame("Frame")
inviteEventHandler:SetScript("OnEvent", function(self, event, name)
    DeclineGroup()
    StaticPopup_Hide("PARTY_INVITE"); -- Needed to remove the popup
    printAchievementInfo(loneWolfLink, "Group invite auto declined.")

    name = name or arg1
    SendChatMessage("I am on the "..loneWolfLink.." achievement. I cannot group with other players.", "WHISPER", GetDefaultLanguage(), name)
end)

function Whc_SetBlockInvites()
    inviteEventHandler:UnregisterEvent("PARTY_INVITE_REQUEST")
    AcceptGroup = BlizzardFunctions.AcceptGroup
    InviteUnit = BlizzardFunctions.InviteUnit
    InviteByName = BlizzardFunctions.InviteByName

    if WhcAddonSettings.blockInvites == 1 then
        -- Blocks incoming invites
        inviteEventHandler:RegisterEvent("PARTY_INVITE_REQUEST")
        -- Blocks addons like LazyPig from auto accepting invites
        AcceptGroup = function() end

        -- blocks outgoing invites via /i <char_name>
        local blockInvites = function(name)
            printAchievementInfo(loneWolfLink, "Group invites are blocked.")
        end
        InviteUnit = blockInvites
        InviteByName = blockInvites
    end
end
--endregion

--region ====== My precious! ======
BlizzardFunctions.InitiateTrade = InitiateTrade
local myPreciousLink = achievementLink(TabAchievements[ACHIEVEMENT_MY_PRECIOUS])
function Whc_SetBlockTrades()
    InitiateTrade = BlizzardFunctions.InitiateTrade

    -- Block incoming trade via Blizzard interface checkbox
    SetCVar("blockTrades", WhcAddonSettings.blockTrades)
    if WhcAddonSettings.blockTrades == 1 then
        -- Block outgoing trade
        InitiateTrade = function()
            printAchievementInfo(myPreciousLink, "Trade requests are blocked.")
        end
    end
end
--endregion

--region ====== My precious! ======
BlizzardFunctions.TakeInboxItem = TakeInboxItem
BlizzardFunctions.TakeInboxMoney = TakeInboxMoney
local specialDeliveriesLink = achievementLink(TabAchievements[ACHIEVEMENT_SPECIAL_DELIVERIES])
function Whc_SetBlockMailItems()
    TakeInboxMoney = BlizzardFunctions.TakeInboxMoney
    TakeInboxItem = BlizzardFunctions.TakeInboxItem
    if WhcAddonSettings.blockMailItems == 1 then
        -- Block mail items and money
        local blockMailItemsFunc = function()
            printAchievementInfo(specialDeliveriesLink, "Taking mail items and money is blocked.")
        end
        TakeInboxMoney = function(index)
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(index)

            -- GM money is okay
            if isGM then
                return BlizzardFunctions.TakeInboxMoney(index)
            end

            blockMailItemsFunc()
        end
        TakeInboxItem = function(index, itemIndex)
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(index)

            -- GM items are okay
            if isGM then
                return BlizzardFunctions.TakeInboxItem(index, itemIndex)
            end

            -- If the sender has a space in their name then it is a NPC
            -- Players cannot use spaces when creating their characters
            local _, count = string.gsub(sender, " ")
            if count > 0 then
                return BlizzardFunctions.TakeInboxItem(index, itemIndex)
            end

            blockMailItemsFunc()
        end
    end
end
--endregion