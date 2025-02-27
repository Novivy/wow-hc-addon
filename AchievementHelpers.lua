ADDON_COLOR_CODE = "|cffff7800"
ACHIEVEMENT_COLOR_CODE = "|cffffff00";
local addonPrefix = ADDON_COLOR_CODE.."[WOW-HC.com]: "..FONT_COLOR_CODE_CLOSE

local function printAchievementInfo(achievement, message)
    local achievementMsg = ACHIEVEMENT_COLOR_CODE..achievement..HIGHLIGHT_FONT_COLOR_CODE.." Achievement active. "
    DEFAULT_CHAT_FRAME:AddMessage(addonPrefix..achievementMsg..message..FONT_COLOR_CODE_CLOSE)
end

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

BlizzardFunctions = {}
BlizzardFunctions.AcceptGroup = AcceptGroup
BlizzardFunctions.InviteUnit = InviteUnit -- Retail
BlizzardFunctions.InviteByName = InviteByName -- 1.12

--region ====== Lone Wolf ======
local LONE_WOLF_ACHIEVEMENT = "[Lone Wolf]"
-- Disables right-click menu "Invite" button
hooksecurefunc("UnitPopup_OnUpdate", function(self, dropdownMenu, which, unit, name)
    if WhcAddonSettings.blockInvites == 1 then
        for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G["DropDownList1Button" .. i]
            if button and button.value == "INVITE" then
                button:Disable()
                return
            end
        end
    end
end)

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
    printAchievementInfo(LONE_WOLF_ACHIEVEMENT, "Group invite auto declined.")

    local playerName = arg1
    if RETAIL == 1 then
        playerName = name
    end
    SendChatMessage("I am on the "..LONE_WOLF_ACHIEVEMENT.." achievement. I cannot group with other players.", "WHISPER", GetDefaultLanguage(), playerName)
end)

function SetBlockInvites()
    if WhcAddonSettings.blockInvites == 1 then
        -- Blocks incoming invites
        inviteEventHandler:RegisterEvent("PARTY_INVITE_REQUEST")
        -- Blocks addons like LazyPig from auto accepting invites
        AcceptGroup = function() end

        -- blocks outgoing invites via /i <char_name>
        local blockInvites = function(name)
            printAchievementInfo(LONE_WOLF_ACHIEVEMENT, "Group invite is blocked.")
        end
        InviteUnit = blockInvites
        InviteByName = blockInvites
    else
        inviteEventHandler:UnregisterEvent("PARTY_INVITE_REQUEST")
        AcceptGroup = BlizzardFunctions.AcceptGroup
        InviteUnit = BlizzardFunctions.InviteUnit
        InviteByName = BlizzardFunctions.InviteByName
    end
end
--endregion
