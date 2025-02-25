function colorText(message, colorCode)
    return colorCode .. message .. FONT_COLOR_CODE_CLOSE
end

function printAchievementInfo(message)
    DEFAULT_CHAT_FRAME:AddMessage(colorText(message, LIGHTYELLOW_FONT_COLOR_CODE))
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
-- needs testing. This should block invites from the right click menu
hooksecurefunc("UnitPopup_ShowMenu", function(self, dropdownMenu, which, unit, name)
    if WhcAddonSettings.blockInvites == 1 then
        if UIDROPDOWNMENU_MENU_LEVEL == 1 then
            for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
                local button = _G["DropDownList1Button" .. i]
                if button and button.value == "PARTY_INVITE" then
                    button:Disable()
                    button:SetText(colorText("Invite Blocked", GRAY_FONT_COLOR_CODE))
                end
            end
        end
    end
end)

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