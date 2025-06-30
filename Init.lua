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
-- Define the frame names here so my IDE can do a usage search.
WHC.Frames = {
    UIframe = nil,
    UItabHeader = nil,
    UItab = nil,
    MapIcon = nil,
    DeathLogFrame = nil,
    Achievements = nil,
    AchievementButtonCharacter = nil,
    AchievementButtonInspect = nil,
    UIBattleGrounds = {
        ws = nil,
        ab = nil,
        av = nil,
    },
    UIspecialEvent = nil
}

local _G = getfenv(0);
function WHC.HookSecureFunc(arg1, arg2, arg3)
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

WHC:RegisterEvent("ADDON_LOADED")
WHC:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "WOW_HC" then
        return
    end

    local class = UnitClass("player")
    WHC.player = {
        name = UnitName("player"),
        class = class,
    }

    local locale = GetLocale()
    WHC.client = {
        isEnglish = locale == "enUS" or locale == "enGB"
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

    WhcAchievementSettings = WhcAchievementSettings or {}
    WhcAchievementSettings.blockInvites = WhcAchievementSettings.blockInvites or 0
    WhcAchievementSettings.blockTrades = WhcAchievementSettings.blockTrades or 0
    WhcAchievementSettings.blockAuctionSell = WhcAchievementSettings.blockAuctionSell or 0
    WhcAchievementSettings.blockAuctionBuy = WhcAchievementSettings.blockAuctionBuy or 0
    WhcAchievementSettings.blockRepair = WhcAchievementSettings.blockRepair or 0
    WhcAchievementSettings.blockTaxiService = WhcAchievementSettings.blockTaxiService or 0
    WhcAchievementSettings.blockMagicItems = WhcAchievementSettings.blockMagicItems or 0
    WhcAchievementSettings.blockMagicItemsTooltip = WhcAchievementSettings.blockMagicItemsTooltip or 0
    WhcAchievementSettings.blockArmorItems = WhcAchievementSettings.blockArmorItems or 0
    WhcAchievementSettings.blockArmorItemsTooltip = WhcAchievementSettings.blockArmorItemsTooltip or 0
    WhcAchievementSettings.blockNonSelfMadeItems = WhcAchievementSettings.blockNonSelfMadeItems or 0
    WhcAchievementSettings.blockNonSelfMadeItemsTooltip = WhcAchievementSettings.blockNonSelfMadeItemsTooltip or 0
    WhcAchievementSettings.blockMailItems = WhcAchievementSettings.blockMailItems or 0
    WhcAchievementSettings.blockRidingSkill = WhcAchievementSettings.blockRidingSkill or 0
    WhcAchievementSettings.blockProfessions = WhcAchievementSettings.blockProfessions or 0
    WhcAchievementSettings.blockQuests = WhcAchievementSettings.blockQuests or 0
    WhcAchievementSettings.blockTalents = WhcAchievementSettings.blockTalents or 0
    WhcAchievementSettings.onlyKillDemons = WhcAchievementSettings.onlyKillDemons or 0
    WhcAchievementSettings.onlyKillUndead = WhcAchievementSettings.onlyKillUndead or 0
    WhcAchievementSettings.onlyKillBoars = WhcAchievementSettings.onlyKillBoars or 0

    WHC.InitializeUI()
    WHC.InitializeMinimapIcon()
    WHC.InitializeDeathLogFrame()
    WHC.InitializeAchievementButtons()

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
    WHC.SetBlockMailItems()
    WHC.SetBlockTrainSkill()
    WHC.SetBlockQuests()
    WHC.SetWarningOnlyKill()
    if RETAIL == 0 then
        WHC.SetBlockEquipItems()
    end
end)
