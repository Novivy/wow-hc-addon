local version = GetBuildInfo()

RETAIL = 1
if (version == "1.12.0" or version == "1.12.1") then
    RETAIL = 0
end

RETAIL_BACKDROP = nil
if (RETAIL == 1) then
    RETAIL_BACKDROP = "BackdropTemplate"
end

WHC = CreateFrame("Frame", "WowHcUIFrame", UIParent, RETAIL_BACKDROP)
-- Define the frame names here so my IDE can do a usage search.
WHC.Frames = {
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

WHC.COLORS = {
    GM_BLUE_FONT_COLOR_CODE = "|cff06daf0",
    DARK_RED_FONT_COLOR_CODE = "|cffe53c15",
    ACHIEVEMENT_COLOR_CODE = ACHIEVEMENT_COLOR_CODE or "|cffffff00", -- Added for 1.12
}

WHC.ITEM_QUALITY = {
    POOR = 0,      -- Gray
    COMMON = 1,    -- White
    UNCOMMON = 2,  -- Green
    RARE = 3,      -- Blue
    EPIC = 4,      -- Purple
    LEGENDARY = 5, -- Orange
    ARTIFACT = 6,  -- Light Gold
}

WHC.ADDON_PREFIX = ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.LEGENDARY].hex.."[WOW-HC addon]: "..FONT_COLOR_CODE_CLOSE

WHC:RegisterEvent("ADDON_LOADED")
WHC:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "WOW_HC" then
        return
    end
    WHC:UnregisterEvent("ADDON_LOADED")

    RETAIL = 1
    local version = GetBuildInfo()
    if (version == "1.12.0" or version == "1.12.1") then
        RETAIL = 0
    end

    RETAIL_BACKDROP = nil
    if (RETAIL == 1) then
        RETAIL_BACKDROP = "BackdropTemplate"
    end

    WHC.player = {
        name = UnitName("player"),
        class = UnitClass("player"),
        dynamicRidingSpeed = "60%%"
    }

    local locale = GetLocale()
    local is1_12 = version == "1.12.0" or version == "1.12.1"
    local isSuperWow = false
    if is1_12 and GetPlayerBuffID and CombatLogAdd and SpellInfo then isSuperWow = true end

    WHC.client = {
        isEnglish = locale == "enUS" or locale == "enGB",
        is1_12 = is1_12,
        isSuperWow = isSuperWow,
        is1_14 = not is1_12
    }

    local realmName = GetRealmName()
    WHC.server = {
        name = realmName,
        isHardcore = realmName == "Permadeath - EU"
    }

    WHC.sounds = {
        checkBoxOn = RETAIL == 0 and "igMainMenuOptionCheckBoxOn" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,
        checkBoxOff = RETAIL == 0 and "igMainMenuOptionCheckBoxOff" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF,
        openFrame = RETAIL == 0 and "igCharacterInfoOpen" or SOUNDKIT.IG_CHARACTER_INFO_OPEN,
        closeFrame = RETAIL == 0 and "igCharacterInfoClose" or SOUNDKIT.IG_CHARACTER_INFO_CLOSE,
        selectTab = RETAIL == 0 and "igCharacterInfoTab" or SOUNDKIT.IG_CHARACTER_INFO_TAB,
    }

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
    WhcAchievementSettings.blockRestedExp = WhcAchievementSettings.blockRestedExp or 0
    WhcAchievementSettings.onlyKillDemons = WhcAchievementSettings.onlyKillDemons or 0
    WhcAchievementSettings.onlyKillUndead = WhcAchievementSettings.onlyKillUndead or 0
    WhcAchievementSettings.onlyKillBoars = WhcAchievementSettings.onlyKillBoars or 0

    WHC.InitializeUI()
    WHC.InitializeMinimapIcon()
    WHC.InitializeDeathLogFrame()
    WHC.InitializeAchievementButtons()
    WHC.InitializeSupport()
    WHC.InitializeDynamicMounts()
    WHC.InitializeTradableRaidLoot()

    if WHC.server.isHardcore then
        WHC.InitializeDeathPopupAppeal()
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

function WHC.InitializeDynamicMounts()
    local dynamicMounts = {
        [23220] = true, ["Swift Dawnsaber"] = true,
        [16084] = true, ["Mottled Red Raptor"] = true,
        [17450] = true, ["Ivory Raptor"] = true,
        [10790] = true, ["Tiger"] = true
    }

    local speedPattern = "%d?%d%d%%" -- matches 2-3 numbers and the % sign. Used to match 60% or 100%

    local function setDynamicMountSpeedText(tooltip)
        local mountName
        local mountSpellID
        if tooltip.GetSpell then
            mountName, mountSpellID = tooltip:GetSpell()
        end
        mountName = mountName or GameTooltipTextLeft1:GetText()

        if dynamicMounts[mountSpellID] or dynamicMounts[mountName] then
            local buffDesc = GameTooltipTextLeft2:GetText()
            local isBuff = string.find(buffDesc, speedPattern)

            -- Make the spellbook name have artifact color
            if not isBuff then
                local artifactColor = ITEM_QUALITY_COLORS[6]
                GameTooltipTextLeft1:SetTextColor(artifactColor.r, artifactColor.g, artifactColor.b)
            end

            -- Set buff text to the current speed
            if isBuff then
                local dynamicBuffText = string.gsub(buffDesc, speedPattern, WHC.player.dynamicRidingSpeed)
                GameTooltipTextLeft2:SetText(dynamicBuffText)
            end

            -- Spellbook text
            if GameTooltipTextLeft3 then
                GameTooltipTextLeft3:SetText(string.format("Summons and dismisses a rideable %s. This mount's speed changes depending on your Riding skill.", mountName))
            end

            tooltip:Show()
        end
    end

    if RETAIL == 1 then
        -- 1.14 spellbook
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip, ...)
            setDynamicMountSpeedText(tooltip)
        end)
    end

    -- 1.12 spellbook and buff + 1.14 buff
    local tooltip = CreateFrame("Frame", nil, GameTooltip)
    tooltip:SetScript("OnShow", function()
        setDynamicMountSpeedText(GameTooltip)
    end)
end

function WHC.InitializeTradableRaidLoot()
    WHC.HookSecureFunc(GameTooltip, "SetBagItem", function(self, container, slot)
        if GameTooltipTextLeft2:GetText() == "Binds when picked up" then
            local msg = WHC.COLORS.GM_BLUE_FONT_COLOR_CODE .. "You may trade this item with players who were also eligible to loot it (for a limited time only)" .. FONT_COLOR_CODE_CLOSE
            GameTooltip:AddLine(msg, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
end
