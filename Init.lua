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
eventFrame1:RegisterEvent("ADDON_LOADED")
eventFrame1:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "WOW_HC" then
        return
    end

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

    WhcAddonSettings = WhcAddonSettings or {}
    -- Ensure the specific setting exists and has a default value
    WhcAddonSettings.minimapicon = WhcAddonSettings.minimapicon or 1
    WhcAddonSettings.achievementbtn = WhcAddonSettings.achievementbtn or 1
    WhcAddonSettings.splash = WhcAddonSettings.splash or 0
    WhcAddonSettings.minimapX = WhcAddonSettings.minimapX or 0
    WhcAddonSettings.minimapY = WhcAddonSettings.minimapY or 0
    WhcAddonSettings.auction_short = WhcAddonSettings.auction_short or 0
    WhcAddonSettings.auction_medium = WhcAddonSettings.auction_medium or 0
    WhcAddonSettings.auction_long = WhcAddonSettings.auction_long or 0
    WhcAddonSettings.auction_deposit = WhcAddonSettings.auction_deposit or 0
    WhcAddonSettings.recentDeaths = WhcAddonSettings.recentDeaths or 1
    WhcAddonSettings.blockInvites = WhcAddonSettings.blockInvites or 0
    WhcAddonSettings.blockTrades = WhcAddonSettings.blockTrades or 0


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
        Whc_SetBlockInvites()
    end

    if WhcAddonSettings.blockTrades == 1 then
        Whc_SetBlockTrades()
    end

    if WhcAddonSettings.blockAuctionBuy == 1 then
        Whc_SetBlockAuctionBuy()
    end
  --    UIShowTabContent("PVP") -- todo remove
end)
