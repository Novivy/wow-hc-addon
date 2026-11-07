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
    SpeedRunTimer = nil,
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

WHC.TAB = {
    GENERAL = "General",
    ACHIEVEMENTS = "Achievements",
    PVP = "PVP",
    SHOP = "Shop",
    SUPPORT = "Support",
    SETTINGS = "Settings"
}
WHC.TAB_KEYS = {
    WHC.TAB.GENERAL,
    WHC.TAB.ACHIEVEMENTS,
    WHC.TAB.PVP,
    WHC.TAB.SHOP,
    WHC.TAB.SUPPORT,
    WHC.TAB.SETTINGS,
}

WHC.SOUNDS = {
    abandonQuest = RETAIL == 0 and "igQuestLogAbandonQuest" or SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST,
    checkBoxOn   = RETAIL == 0 and "igMainMenuOptionCheckBoxOn" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,
    checkBoxOff  = RETAIL == 0 and "igMainMenuOptionCheckBoxOff" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF,
    openFrame    = RETAIL == 0 and "igCharacterInfoOpen" or SOUNDKIT.IG_CHARACTER_INFO_OPEN,
    closeFrame   = RETAIL == 0 and "igCharacterInfoClose" or SOUNDKIT.IG_CHARACTER_INFO_CLOSE,
    selectTab    = RETAIL == 0 and "igCharacterInfoTab" or SOUNDKIT.IG_CHARACTER_INFO_TAB,
    playerInvite = RETAIL == 0 and "igPlayerInvite" or SOUNDKIT.IG_PLAYER_INVITE,
}

-- Sound files shipped with the addon, for PlaySoundFile: .wav for 1.12 (its PlaySoundFile has no Ogg Vorbis), .ogg for
-- 1.14. Sounds\achievements = WotLK sound kits 12891 AchievementSound (sound/spells/achievmentsound1.ogg), 13832
-- AchievementMenuOpen, 13833 AchievementMenuClose (wago SoundKitEntry, build 3.4.3.54261), see COPYRIGHT_README.txt.
local SOUND_EXT = RETAIL == 0 and ".wav" or ".ogg"
local ACHIEVEMENT_SOUND_DIR = "Interface\\AddOns\\WOW_HC\\Sounds\\achievements\\"
WHC.SOUND_FILES = {
    achievementEarned    = ACHIEVEMENT_SOUND_DIR .. "achievementsound" .. SOUND_EXT,
    achievementMenuOpen  = ACHIEVEMENT_SOUND_DIR .. "achievementmenuopen" .. SOUND_EXT,
    achievementMenuClose = ACHIEVEMENT_SOUND_DIR .. "achievementmenuclose" .. SOUND_EXT,
}

WHC.ADDON_PREFIX = ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.LEGENDARY].hex.."[WHC]: "..FONT_COLOR_CODE_CLOSE

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

    WHC.lastTab = WHC.TAB.GENERAL
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

    -- Branding. Any realm other than the hardcore one is Dawnrest (same account DB, dawnrest.com runs the same
    -- website backend as wow-hc.com, so the /shop, /addon and /forums paths are the same on both).
    -- The Dawnrest full logo is 768x512: drawn from the top 171 rows of a 256x256 texture (logoV).
    if WHC.server.isHardcore then
        WHC.BRAND = {
            name = "WOW-HC",
            site = "https://wow-hc.com",
            siteLabel = "wow-hc.com",
            discord = "discord.gg/uGWu5YFjE3",
            welcome = "Welcome to WOW Hardcore!",
            tagline = "A permadeath realm where you permanently lose your character if you die.",
            logo = "Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo",
            logoW = 150, logoH = 75, logoY = 42, logoV = 1,
            logoRound = "Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round",
            legacyPortrait = "portrait_hc",
        }
    else
        WHC.BRAND = {
            name = "Dawnrest",
            site = "https://dawnrest.com",
            siteLabel = "dawnrest.com",
            discord = "discord.gg/dFkaUH66Fc",
            welcome = "Welcome to Dawnrest!",
            tagline = "A Classic PvP realm built on 3+ years of bug fixes from the main WOW-HC Hardcore realm.",
            logo = "Interface\\AddOns\\WOW_HC\\Images\\dawnrest-logo",
            logoW = 132, logoH = 88, logoY = 48, logoV = 171 / 256,
            logoRound = "Interface\\AddOns\\WOW_HC\\Images\\dawnrest-logo-round",
            legacyPortrait = "portrait_dawnrest",
        }
    end

    WhcAddonSettings = WhcAddonSettings or {}
    -- Ensure the specific setting exists and has a default value
    WhcAddonSettings.minimapicon = WhcAddonSettings.minimapicon or 1
    WhcAddonSettings.achievementbtn = WhcAddonSettings.achievementbtn or 1
    WhcAddonSettings.achievementToast = WhcAddonSettings.achievementToast or 1
    WhcAddonSettings.recentDeaths = WhcAddonSettings.recentDeaths or 1
    WhcAddonSettings.speedRunTimer = WhcAddonSettings.speedRunTimer or {}
    WhcAddonSettings.speedRunTimer.showTimer = WhcAddonSettings.speedRunTimer.showTimer or 1
    WhcAddonSettings.speedRunTimer.personalRecords = WhcAddonSettings.speedRunTimer.personalRecords or {}
    WhcAddonSettings.blueShaman = WhcAddonSettings.blueShaman or 1
    WhcAddonSettings.hideDeathNoticeInRaid = WhcAddonSettings.hideDeathNoticeInRaid or 1

    WhcAddonSettings.splash = WhcAddonSettings.splash or 0
    WhcAddonSettings.minimapAngle = WhcAddonSettings.minimapAngle or 225
    WhcAddonSettings.auction_short = WhcAddonSettings.auction_short or 0
    WhcAddonSettings.auction_medium = WhcAddonSettings.auction_medium or 0
    WhcAddonSettings.auction_long = WhcAddonSettings.auction_long or 0
    WhcAddonSettings.auction_deposit = WhcAddonSettings.auction_deposit or 0
    WhcAddonSettings.groupFinderIcon = WhcAddonSettings.groupFinderIcon or 1
    WhcAddonSettings.groupFinderAngle = WhcAddonSettings.groupFinderAngle or 195

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
    WhcAchievementSettings.onlyKillMurlocs = WhcAchievementSettings.onlyKillMurlocs or 0

    WHC.InitializeUI()
    WHC.InitializeMinimapIcon()
    WHC.InitializeGroupFinder()
    WHC.InitializeGroupFinderIcon()
    WHC.InitializeGuildBank()
    WHC.GF.InitLogoutHooks()
    WHC.InitializeDeathLogFrame()
    WHC.InitializeSpeedRunTimer()
    WHC.InitializeBlueShaman()
    WHC.InitializeAchievementButtons()
    WHC.InitializeSupport()
    WHC.InitializeUnitPopup()
    WHC.InitializeMakgora()
    WHC.InitializeSpec()
    WHC.InitializeHonorPanel()
    WHC.InitializeDynamicMounts()
    WHC.InitializeShopPets()
    WHC.InitializeTradableRaidLoot()
    WHC.InitializeDotCommandFix()
    WHC.InitializeDeathAnnouncementFilter()

    if WHC.server.isHardcore then
        WHC.InitializeDeathPopupAppeal()
    end

    -- splash is account wide, so 0 means a fresh install: a newcomer gets the General tab and is
    -- marked as having seen the current achievements announcement, which is only for returning players
    if (WhcAddonSettings.splash == 0) then
        WhcAddonSettings.splash = 1
        WhcAddonSettings.achievementsOpened = WHC.ACHIEVEMENTS_OPEN_VERSION

        WHC.UIShowTabContent(WHC.TAB.GENERAL)
    elseif ((WhcAddonSettings.achievementsOpened or 0) < WHC.ACHIEVEMENTS_OPEN_VERSION) then
        WhcAddonSettings.achievementsOpened = WHC.ACHIEVEMENTS_OPEN_VERSION

        WHC.RunAfterWorldLoad(function()
            WHC.UIShowTabContent(WHC.TAB.ACHIEVEMENTS)           -- opens the window and asks the server
            WHC.SelectLegacyCategory("Feats of Strength", "Hard Chores")
        end)
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

-- Hook the tooltip methods that build a spell/aura tooltip and call `handler`
-- once the client has filled the lines in.
--
-- This has to be a positive signal. A GameTooltip OnShow hook fires for every
-- tooltip, including world ones, and the mount/pet lookups fall back to matching
-- the tooltip's first line by name - so a mob sharing a mount's name (the
-- Nightsabers in Teldrassil) got rewritten too. Filtering that back out is not
-- possible: a corpse does not set the "mouseover" unit, so the 1.12 client draws
-- its tooltip natively instead of going through GameTooltip:SetUnit, leaving
-- GetUnit(), GetOwner() and "mouseover" all holding stale values from whichever
-- Lua-built tooltip came before it.
local function WhcHookSpellTooltips(handler)
    -- SetPlayerBuff is the 1.12 path for your own buffs; SetUnitAura the 1.14 one.
    local methods = { "SetSpell", "SetSpellByID", "SetAction", "SetPetAction", "SetShapeshift",
                      "SetPlayerBuff", "SetUnitBuff", "SetUnitDebuff", "SetUnitAura" }

    for _, method in pairs(methods) do
        local original = GameTooltip[method]
        if original then
            -- Explicit parameters rather than "...": 1.12 runs Lua 5.0, which
            -- cannot forward a vararg from inside an expression. None of the
            -- hooked methods take more than two arguments.
            GameTooltip[method] = function(self, a1, a2, a3)
                local result = original(self, a1, a2, a3)
                handler(self)
                return result
            end
        end
    end
end

function WHC.InitializeDynamicMounts()
    local dynamicMounts = {
        [23220] = true, ["Swift Dawnsaber"] = true,
        [16084] = true, ["Mottled Red Raptor"] = true,
        [17450] = true, ["Ivory Raptor"] = true,
        [10790] = true, ["Tiger"] = true,
        [16055] = true, ["Nightsaber"] = true,
        [16081] = true, ["Arctic Wolf"] = true,
        [578]   = true, ["Black Wolf"] = true,
        [16060] = true, ["Golden Sabercat"] = true,
        [17455] = true, ["Purple Mechanostrider"] = true,
        [17458] = true, ["Fluorescent Green Mechanostrider"] = true,
        [10798] = true, ["Obsidian Raptor"] = true,
        [16082] = true, ["Palomino Stallion"] = true
    }

    local speedPattern = "%d?%d%d%%" -- matches 2-3 numbers and the % sign. Used to match 60% or 100%

    local function setDynamicMountSpeedText(tooltip)
        local mountName
        local mountSpellID
        if tooltip.GetSpell then
            mountName, mountSpellID = tooltip:GetSpell()
        end
        -- 1.12 has no tooltip:GetSpell(), so fall back to the displayed name.
        mountName = mountName or GameTooltipTextLeft1:GetText()

        if dynamicMounts[mountSpellID] or dynamicMounts[mountName] then
            local buffDesc = GameTooltipTextLeft2:GetText()
            local isBuff = buffDesc and string.find(buffDesc, speedPattern)

            -- Make the spellbook name have artifact color
            if not isBuff then
                local artifactColor = ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.ARTIFACT]
                GameTooltipTextLeft1:SetTextColor(artifactColor.r, artifactColor.g, artifactColor.b)
            end

            -- Set buff text to the current speed
            if isBuff then
                local dynamicBuffText = string.gsub(buffDesc, speedPattern, WHC.player.dynamicRidingSpeed)
                GameTooltipTextLeft2:SetText(dynamicBuffText)
            end

            -- Spellbook text. Only touch line 3 when this tooltip actually has
            -- one - the buff tooltip does not, and writing to a line this tooltip
            -- never renders leaves the text parked on the shared fontstring for
            -- whatever tooltip shows that line next.
            if GameTooltipTextLeft3 and tooltip:NumLines() >= 3 then
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
    WhcHookSpellTooltips(setDynamicMountSpeedText)
end

function WHC.InitializeShopPets()
    -- Some shop pets reuse a client spell ID, so the client shows the wrong tooltip
    local shopPets = {
        [10687] = "Spectral Wolf", ["Summon White Plymouth Rock"] = "Spectral Wolf"
    }

    local function setShopPetTooltipText(tooltip)
        local petName
        local petSpellID
        if tooltip.GetSpell then
            petName, petSpellID = tooltip:GetSpell()
        end
        -- 1.12 has no tooltip:GetSpell(), so fall back to the displayed name.
        petName = petName or GameTooltipTextLeft1:GetText()

        local correctName = shopPets[petSpellID] or shopPets[petName]
        if correctName then
            GameTooltipTextLeft1:SetText(correctName)

            -- Spellbook text, same shared-fontstring caveat as the mounts above.
            if GameTooltipTextLeft3 and tooltip:NumLines() >= 3 then
                GameTooltipTextLeft3:SetText(string.format("Right Click to summon and dismiss your %s.", string.lower(correctName)))
            end

            tooltip:Show()
        end
    end

    if RETAIL == 1 then
        -- 1.14 spellbook
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip, ...)
            setShopPetTooltipText(tooltip)
        end)
    end

    -- 1.12 spellbook
    WhcHookSpellTooltips(setShopPetTooltipText)
end

-- 2.7: the new achievements window opens once by itself for every pre-existing install (bump to do it again)
WHC.ACHIEVEMENTS_OPEN_VERSION = 1

-- Runs fn once, a second after the next PLAYER_ENTERING_WORLD. ADDON_LOADED is too early on 1.14: a frame shown there
-- is hidden again once the world loads (the `.whc version` announce has gone out on PLAYER_LOGIN by then).
function WHC.RunAfterWorldLoad(fn)
    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    waitFrame:SetScript("OnEvent", function()
        waitFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local waited = 0
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            waited = waited + (elapsed or arg1)
            if waited < 1 then
                return
            end
            waitFrame:SetScript("OnUpdate", nil)

            fn()
        end)
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
