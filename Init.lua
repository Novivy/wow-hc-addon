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

WHC = CreateFrame("Frame")
WHC.Frames = {}
WHC:RegisterEvent("ADDON_LOADED")
WHC:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "WOW_HC" then
        return
    end

    WHC.player = {
        name = UnitName("player"),
    }

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

    WHC.InitializeUI()
    WHC.InitializeMinimapIcon()
    WHC.InitializeDeathLogFrame()

    if (RETAIL == 1) then
        -- todo (low prio since ticket status block not displayed on retail)
    else
        StaticPopupDialogs["HELP_TICKET"].OnAccept = function()
            WHC.UIShowTabContent("Support")
        end

        StaticPopupDialogs["HELP_TICKET"].OnCancel = function()
            WHC.UIShowTabContent("Support")
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
    WhcAddonSettings.blockAuctionSell = WhcAddonSettings.blockAuctionSell or 0
    WhcAddonSettings.blockAuctionBuy = WhcAddonSettings.blockAuctionBuy or 0
    WhcAddonSettings.blockRepair = WhcAddonSettings.blockRepair or 0
    WhcAddonSettings.blockTaxiService = WhcAddonSettings.blockTaxiService or 0
    WhcAddonSettings.blockMagicItems = WhcAddonSettings.blockMagicItems or 0
    WhcAddonSettings.blockMagicItemsTooltip = WhcAddonSettings.blockMagicItemsTooltip or 0
    WhcAddonSettings.blockArmorItems = WhcAddonSettings.blockArmorItems or 0
    WhcAddonSettings.blockArmorItemsTooltip = WhcAddonSettings.blockArmorItemsTooltip or 0
    WhcAddonSettings.blockNonSelfMadeItems = WhcAddonSettings.blockNonSelfMadeItems or 0
    WhcAddonSettings.blockNonSelfMadeItemsTooltip = WhcAddonSettings.blockNonSelfMadeItemsTooltip or 0

    if (WhcAddonSettings.minimapicon == 1) then
        WHC.Frames.MapIcon:Show()
    else
        WHC.Frames.MapIcon:Hide()
    end

    if (WhcAddonSettings.recentDeaths == 1) then
        WHC.Frames.DeathLogFrame:Show()
    else
        WHC.Frames.DeathLogFrame:Hide()
    end

    local msg = ".whc version " .. GetAddOnMetadata("WOW_HC", "Version")
    if (RETAIL == 1) then
        SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
    else
        SendChatMessage(msg);
    end

    if (WhcAddonSettings.splash == 0) then
        WhcAddonSettings.splash = 1

        WHC.UIShowTabContent("General")
    end

    WHC.SetBlockInvites()
    WHC.SetBlockTrades()
    WHC.SetBlockAuctionSell()
    WHC.SetBlockAuctionBuy()
    WHC.SetBlockRepair()
    WHC.SetBlockTaxiService()
    WHC.SetBlockEquipItems()
    WHC.SetBlockEquipItems()
    WHC.SetBlockEquipItems()
end)
