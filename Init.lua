local version = GetBuildInfo()

RETAIL = 1
if (version == "1.12.0" or version == "1.12.1") then
    RETAIL = 0
else
    RETAIL = 1
end


RETAIL_BACKDROP = nil
if (RETAIL == 1) then
    RETAIL_BACKDROP = "BackdropTemplate"
else
    RETAIL_BACKDROP = nil
end



local eventFrame1 = CreateFrame("Frame")
eventFrame1:RegisterEvent("VARIABLES_LOADED")
eventFrame1:SetScript("OnEvent", function(self, event, arg1)

    local version = GetBuildInfo()
    if (version == "1.12.0" or version == "1.12.1") then
        RETAIL = 0
    else
        RETAIL = 1
    end


    if (RETAIL == 1) then
        RETAIL_BACKDROP = "BackdropTemplate"
    else
        RETAIL_BACKDROP = nil
    end

    initUI()


    if (RETAIL == 1) then
        -- todo (low prio since ticket status block not displayed on retail)
    else
        StaticPopupDialogs["HELP_TICKET"].OnAccept = function()
            UIShowTabContent("Support")
        end

        StaticPopupDialogs["HELP_TICKET"].OnCancel = function()
            UIShowTabContent("Support")
        end
    end


    if not WhcAddonSettings then
        WhcAddonSettings = {}
        WhcAddonSettings.minimapicon = 1
        WhcAddonSettings.minimapX = 0
        WhcAddonSettings.minimapY = 0
        WhcAddonSettings.achievementbtn = 1
        WhcAddonSettings.splash = 0
        WhcAddonSettings.auction_short = 0
        WhcAddonSettings.auction_medium = 0
        WhcAddonSettings.auction_long = 0
        WhcAddonSettings.auction_deposit = 0
        WhcAddonSettings.recentDeaths = 1
        WhcAddonSettings.blockInvites = 0
    else
        -- Ensure the specific setting exists and has a default value
        WhcAddonSettings.minimapicon = WhcAddonSettings.minimapicon or 1
        WhcAddonSettings.achievementbtn = WhcAddonSettings.achievementbtn or 1
        WhcAddonSettings.splash = WhcAddonSettings.splash or 1
        WhcAddonSettings.minimapX = WhcAddonSettings.minimapX or 0
        WhcAddonSettings.minimapY = WhcAddonSettings.minimapY or 0
        WhcAddonSettings.auction_short = WhcAddonSettings.auction_short or 0
        WhcAddonSettings.auction_medium = WhcAddonSettings.auction_medium or 0
        WhcAddonSettings.auction_long = WhcAddonSettings.auction_long or 0
        WhcAddonSettings.auction_deposit = WhcAddonSettings.auction_deposit or 0
        WhcAddonSettings.recentDeaths = WhcAddonSettings.recentDeaths or 1
        WhcAddonSettings.blockInvites = WhcAddonSettings.blockInvites or 0
    end


    if (WhcAddonSettings.minimapicon == 1) then
        MapIcon:Show()
    else
        MapIcon:Hide()
    end

    if (WhcAddonSettings.recentDeaths == 1) then
        DeathLogFrame:Show()
    else
        DeathLogFrame:Hide()
    end

    local msg = ".whc version " .. GetAddOnMetadata("WOW_HC", "Version")
    if (RETAIL == 1) then
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    else
        SendChatMessage(msg);
    end

    if (WhcAddonSettings.splash == 0) then
        WhcAddonSettings.splash = 1

        UIShowTabContent("General")
    end

    if WhcAddonSettings.blockInvites == 1 then
        SetBlockInvites()
    end

  --    UIShowTabContent("PVP") -- todo remove
end)
