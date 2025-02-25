function printAchievementInfo(message)
    DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE..message..FONT_COLOR_CODE_CLOSE)
end

BlizzardFunctions = {}
BlizzardFunctions.AcceptGroup = AcceptGroup
BlizzardFunctions.InviteUnit = InviteUnit -- Retail
BlizzardFunctions.InviteByName = InviteByName -- 1.12

--region ====== Lone Wolf ======
local inviteEventHandler = CreateFrame("Frame")
inviteEventHandler:SetScript("OnEvent", function(self, event)
    DeclineGroup()
    StaticPopup_Hide("PARTY_INVITE"); -- Needed to remove the popup
    printAchievementInfo("[Lone Wolf] Auto declining group invite.")
end)

function SetBlockInvites()
    if WhcAddonSettings.blockInvites == 1 then
        -- Blocks incoming invites
        inviteEventHandler:RegisterEvent("PARTY_INVITE_REQUEST")
        -- Blocks addons like LazyPig from auto accepting invites
        AcceptGroup = function() end

        -- blocks outgoing invites via /i or /who right click
        local blockInvites = function(name)
            printAchievementInfo("[Lone Wolf] Invites are blocked.")
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