local function itemSlot(block, x, y, achievement)
    local MerchantItemTemplate = CreateFrame("Frame", "MerchantItemTemplate", block)
    MerchantItemTemplate:SetWidth(350)
    MerchantItemTemplate:SetHeight(37)
    MerchantItemTemplate:SetPoint("TOPLEFT", block, "TOPLEFT", x, y)


    -- Slot Texture
    local SlotTexture = MerchantItemTemplate:CreateTexture("$parentSlotTexture", "BACKGROUND")
    SlotTexture:SetTexture("Interface\\Buttons\\UI-EmptySlot")
    SlotTexture:SetWidth(64)
    SlotTexture:SetHeight(64)
    SlotTexture:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", -13, 13)
    MerchantItemTemplate.SlotTexture = SlotTexture

    -- Name Frame Texture
    local NameFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    NameFrame:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\UI-Merchant-LabelSlots-Large")
    NameFrame:SetWidth(512)
    NameFrame:SetHeight(64)
    NameFrame:SetPoint("LEFT", SlotTexture, "RIGHT", -9, -10)
    MerchantItemTemplate.NameFrame = NameFrame

    -- Name FontString
    local labelTitle = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelTitle:SetText(achievement.name)
    labelTitle:SetJustifyH("LEFT")
    labelTitle:SetWidth(350)
    labelTitle:SetHeight(30)
    labelTitle:SetPoint("LEFT", SlotTexture, "RIGHT", -5, 13)
    labelTitle:SetTextColor(0.933, 0.765, 0)
    MerchantItemTemplate.labelTitle = labelTitle

    -- Name FontString
    local labelLost = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelLost:SetText("FAILED")
    labelLost:SetJustifyH("RIGHT")
    labelLost:SetWidth(354)
    labelLost:SetHeight(30)
    labelLost:SetPoint("LEFT", SlotTexture, "RIGHT", -4, 14)
    labelLost:SetTextColor(0.588, 0.235, 0.235)
    labelLost:SetFont("Fonts\\FRIZQT__.TTF", 7)
    MerchantItemTemplate.labelLost = labelLost

    -- Desc FontString
    local labelDesc = MerchantItemTemplate:CreateFontString("$parentName", "BACKGROUND", "GameFontNormalSmall")
    labelDesc:SetText(achievement.desc)
    labelDesc:SetJustifyH("LEFT")
    labelDesc:SetWidth(350)
    labelDesc:SetHeight(30)
    labelDesc:SetPoint("LEFT", SlotTexture, "RIGHT", -5, -5)
    labelDesc:SetTextColor(0.874, 0.874, 0.874)
    MerchantItemTemplate.labelDesc = labelDesc


    local iconFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    iconFrame:SetTexture("Interface\\Icons\\" .. achievement.icon) -- INV_Misc_QuestionMark")
    iconFrame:SetWidth(39)
    iconFrame:SetHeight(39)
    iconFrame:SetPoint("TOPLEFT", SlotTexture, "TOPLEFT", 12, -12)
    iconFrame:SetDrawLayer("OVERLAY")
    MerchantItemTemplate.iconFrame = iconFrame

    -- Item Button
    local ItemButton = CreateFrame("Button", "$parentName", MerchantItemTemplate, "ItemButtonTemplate")
    ItemButton:SetPoint("TOPLEFT", MerchantItemTemplate, "TOPLEFT", -6, 8)
    ItemButton:SetNormalTexture(nil)
    ItemButton:SetPushedTexture(nil)
    ItemButton:SetHighlightTexture(nil)
    ItemButton:SetWidth(414)
    ItemButton:SetHeight(50)

    --  ItemButton:SetScript("OnEnter", function(self)
    --     -- display why achievement is disabled or not  in a tooltip
    --  GameTooltip:SetOwner(ItemButton, "ANCHOR_CURSOR")
    --       GameTooltip:SetText("tooltip", 1, 1, 1) -- Set the tooltip text and color
    --       GameTooltip:Show()
    --  end)

    --   ItemButton:SetScript("OnLeave", function(self)
    --       GameTooltip:Hide()
    --       ResetCursor()
    --  end)

    WHC.Frames.Achievements[achievement.id] = MerchantItemTemplate;
end


function WHC.ToggleAchievement(itemAch, failed)
    if (failed) then
        itemAch.iconFrame:SetVertexColor(0.45, 0.45, 0.45)
        itemAch.SlotTexture:SetVertexColor(0.45, 0.45, 0.45)
        itemAch.NameFrame:SetVertexColor(0.45, 0.45, 0.45)
        itemAch.labelTitle:SetTextColor(0.588, 0.235, 0.235)
        itemAch.labelDesc:SetTextColor(0.486, 0.486, 0.486)
        itemAch.labelLost:SetTextColor(0.588, 0.235, 0.235)
        itemAch.labelLost:SetText("FAILED")
    else
        itemAch.iconFrame:SetVertexColor(1, 1, 1)
        itemAch.SlotTexture:SetVertexColor(1, 1, 1)
        itemAch.NameFrame:SetVertexColor(1, 1, 1)
        itemAch.labelTitle:SetTextColor(0.933, 0.765, 0)
        itemAch.labelDesc:SetTextColor(0.874, 0.874, 0.874)
        itemAch.labelLost:SetTextColor(0.152, 0.878, 0.098)
        itemAch.labelLost:SetText("ACTIVE")
    end
end

WHC.Achievements = {
    DEMON_SLAYER           = { id = 16384,  icon = "spell_shadow_unsummonbuilding",       itemId = "707016", itemLink = "", name = "Demon Slayer",           desc = "Reach level 60 while only gaining monster experience from demons." },
    GROUNDED               = { id = 4096,   icon = "spell_nature_strengthofearthtotem02", itemId = "707014", itemLink = "", name = "Grounded",               desc = "Reach level 60 without ever using flying services." },
    HELP_YOURSELF          = { id = 64,     icon = "inv_misc_note_02",                    itemId = "707006", itemLink = "", name = "Help Yourself",          desc = "Reach level 60 without ever turning in a quest (class and profession quests allowed)." },
    IRON_BONES             = { id = 1,      icon = "trade_blacksmithing",                 itemId = "707000", itemLink = "", name = "Iron Bones",             desc = "Reach level 60 without ever repairing the durability of an item." },
    KILLER_TRADER          = { id = 4,      icon = "inv_misc_coin_03",                    itemId = "707002", itemLink = "", name = "Killer Trader",          desc = "Reach level 60 without ever using the auction house to sell an item." },
    LIGHTBRINGER           = { id = 32768,  icon = "spell_holy_holynova",                 itemId = "707017", itemLink = "", name = "Lightbringer",           desc = "Reach level 60 while only gaining monster experience from undead creatures." },
    LONE_WOLF              = { id = 2048,   icon = "spell_nature_spiritwolf",             itemId = "707013", itemLink = "", name = "Lone Wolf",              desc = "Reach level 60 without ever grouping with other players." },
    MARATHON_RUNNER        = { id = 256,    icon = "inv_gizmo_rocketboot_01",             itemId = "707010", itemLink = "", name = "Marathon Runner",        desc = "Reach level 60 without ever learning a riding skill." },
    MISTER_WHITE           = { id = 128,    icon = "inv_shirt_white_01",                  itemId = "707007", itemLink = "", name = "Mister White",           desc = "Reach level 60 without ever equipping an uncommon or greater quality item (only white/grey items allowed. All ammunition and bags allowed)." },
    MY_PRECIOUS            = { id = 8,      icon = "inv_box_01",                          itemId = "707003", itemLink = "", name = "My precious!",           desc = "Reach level 60 without ever trading goods or money with another player." },
    ONLY_FAN               = { id = 32,     icon = "inv_pants_wolf",                      itemId = "707005", itemLink = "", name = "Only Fan",               desc = "Reach level 60 without ever equipping anything other than weapons, shields, ammos, shirts, tabards and bags." },
    RESTLESS               = { id = 131072, icon = "spell_shadow_mindsteal",              itemId = "707020", itemLink = "", name = "Restless",               desc = "Reach level 60 without ever gaining rested experience. Use '.restedxp' to toggle rested XP gain." },
    SELF_MADE              = { id = 8192,   icon = "inv_hammer_20",                       itemId = "707015", itemLink = "", name = "Self-made",              desc = "Reach level 60 without ever equipping items that you did not craft yourself (all fishing poles, ammunition, and bags allowed)." },
    SOFT_HANDS             = { id = 1024,   icon = "spell_holy_layonhands",               itemId = "707012", itemLink = "", name = "Soft Hands",             desc = "Reach level 60 without ever learning any primary profession." },
    SPECIAL_DELIVERIES     = { id = 16,     icon = "inv_crate_03",                        itemId = "707004", itemLink = "", name = "Special Deliveries",     desc = "Reach level 60 without ever getting goods or money from player mail (simple letters, NPC and AH allowed)." },
    THAT_WHICH_HAS_NO_LIFE = { id = 512,    icon = "ability_hunter_pet_boar",             itemId = "707011", itemLink = "", name = "That Which Has No Life", desc = "Reach level 60 while only gaining monster experience from boars and quilboars." },
    TIDEHUNTER             = { id = 262144, icon = "inv_misc_head_murloc_01",             itemId = "707021", itemLink = "", name = "Tidehunter",             desc = "Reach level 60 while only gaining monster experience from murlocs." },
    TIME_IS_MONEY          = { id = 2,      icon = "inv_misc_coin_05",                    itemId = "707001", itemLink = "", name = "Time is money",          desc = "Reach level 60 without ever using the auction house to buy an item." },
    UNTALENTED             = { id = 65536,  icon = "ability_marksmanship",                itemId = "707019", itemLink = "", name = "Untalented",             desc = "Reach level 60 without ever spending a talent point." },
}

local function achievementLink(achievement)
    return ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.LEGENDARY].hex.."|Hitem:"..achievement.itemId..":0:0:0|h["..achievement.name.."]|h"..FONT_COLOR_CODE_CLOSE
end

local sortedAchievements = {}
local achievementsItemIDTable = {}
for key, value in pairs(WHC.Achievements) do
    value.itemLink = achievementLink(value)
    table.insert(sortedAchievements, value)
    achievementsItemIDTable[tonumber(value.itemId)] = value
end
table.sort(sortedAchievements, function(a, b)
    return a.name < b.name  -- Sort alphabetically by name
end)

local function initializeAchievementItemLinks()
    WHC.HookSecureFunc("ChatFrame_OnHyperlinkShow", function(chatFrame, linkData, link, button)
        local itemID = WHC.GetItemIDFromLink(linkData)
        if not itemID then
            return
        end

        local achievement = achievementsItemIDTable[itemID]
        local itemName = GetItemInfo(itemID)
        if achievement and not itemName then
            local titleColor = ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.LEGENDARY]
            ItemRefTooltipTextLeft1:SetText(achievement.name)
            ItemRefTooltipTextLeft1:SetTextColor(titleColor.r, titleColor.g, titleColor.b)
            local descColor = ITEM_QUALITY_COLORS[WHC.ITEM_QUALITY.ARTIFACT]
            ItemRefTooltip:AddLine(string.format("\"%s\"", achievement.desc), descColor.r, descColor.g, descColor.b, true)
            ItemRefTooltip:Show()
        end
    end)
end

function WHC.Tab_Achievements(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Achievements")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    desc1:SetText("Achievements are optional goals that you start with but may lose depending on your actions")
    desc1:SetWidth(320)

    content.desc1 = desc1

    local scrollFrameBG = CreateFrame("ScrollFrame", "MyScrollFrameBG", content, RETAIL_BACKDROP)
    scrollFrameBG:SetWidth(455)
    scrollFrameBG:SetHeight(262)
    scrollFrameBG:SetPoint("TOPLEFT", content, "TOPLEFT", 24, -76)
    scrollFrameBG:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    local scrollFrame = CreateFrame("ScrollFrame", "MyScrollFrame", content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(420)
    scrollFrame:SetHeight(250)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -83)

    local scrollContent = CreateFrame("Frame", "MyScrollFrameContent", scrollFrame)
    scrollContent:SetWidth(300)
    scrollContent:SetHeight(800)
    scrollFrame:SetScrollChild(scrollContent) -- Attach the content frame to the scroll frame

    WHC.Frames.Achievements = {}
    for i, achievement in ipairs(sortedAchievements) do
        local y = -10 - 53 * (i-1)

        itemSlot(scrollContent, 10, y, achievement);
    end

    local desc2 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc2:SetPoint("BOTTOM", scrollFrame, "BOTTOM", 10, -50) -- Adjust y-offset based on logo size
    desc2:SetText(
        "A new WOW-HC button is available when you inspect other players.\n\nAchievements are secured once you hit level 60")
    desc2:SetWidth(450)
    desc2:SetFont("Fonts\\FRIZQT__.TTF", 10)

    if RETAIL == 1 then
        initializeAchievementItemLinks()
    end

    return content;
end
