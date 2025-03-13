local function itemSlot(block, x, y, name, desc, icon, id)
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
    labelTitle:SetText(name)
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
    labelDesc:SetText(desc)
    labelDesc:SetJustifyH("LEFT")
    labelDesc:SetWidth(350)
    labelDesc:SetHeight(30)
    labelDesc:SetPoint("LEFT", SlotTexture, "RIGHT", -5, -5)
    labelDesc:SetTextColor(0.874, 0.874, 0.874)
    MerchantItemTemplate.labelDesc = labelDesc


    local iconFrame = MerchantItemTemplate:CreateTexture("$parentNameFrame", "BACKGROUND")
    iconFrame:SetTexture("Interface\\Icons\\" .. icon) -- INV_Misc_QuestionMark")
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



    UIachievements[id] = MerchantItemTemplate;
end


function toggleAchievement(itemAch, failed)
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

UIachievements = {}

ACHIEVEMENT_DEMON_SLAYER           = 16384
ACHIEVEMENT_GROUNDED               = 4096
ACHIEVEMENT_HELP_YOURSELF          = 64
ACHIEVEMENT_IRON_BONES             = 1
ACHIEVEMENT_KILLER_TRADER          = 4
ACHIEVEMENT_LIGHTBRINGER           = 32768
ACHIEVEMENT_LONE_WOLF              = 2048
ACHIEVEMENT_MARATHON_RUNNER        = 256
ACHIEVEMENT_MISTER_WHITE           = 128
ACHIEVEMENT_MY_PRECIOUS            = 8
ACHIEVEMENT_ONLY_FAN               = 32
ACHIEVEMENT_SELF_MADE              = 8192
ACHIEVEMENT_SOFT_HANDS             = 1024
ACHIEVEMENT_SPECIAL_DELIVERIES     = 16
ACHIEVEMENT_THAT_WHICH_HAS_NO_LIFE = 512
ACHIEVEMENT_TIME_IS_MONEY          = 2
TabAchievements = {
    [16384] = { icon = "spell_shadow_unsummonbuilding",       itemId = "707016", name = "Demon Slayer",           desc = "Reach level 60 only by killing demons." },
    [4096]  = { icon = "spell_nature_strengthofearthtotem02", itemId = "707014", name = "Grounded",               desc = "Reach level 60 without ever using flying services." },
    [64]    = { icon = "inv_misc_note_02",                    itemId = "707006", name = "Help Yourself",          desc = "Reach level 60 without ever turning in a quest (class and profession quests allowed)." },
    [1]     = { icon = "trade_blacksmithing",                 itemId = "707000", name = "Iron Bones",             desc = "Reach level 60 without ever repairing the durability of an item." },
    [4]     = { icon = "inv_misc_coin_03",                    itemId = "707002", name = "Killer Trader",          desc = "Reach level 60 without ever using the auction house to sell an item." },
    [32768] = { icon = "spell_holy_holynova",                 itemId = "707017", name = "Lightbringer",           desc = "Reach level 60 only by killing undead creatures." },
    [2048]  = { icon = "spell_nature_spiritwolf",             itemId = "707013", name = "Lone Wolf",              desc = "Reach level 60 without ever grouping with other players." },
    [256]   = { icon = "inv_gizmo_rocketboot_01",             itemId = "707010", name = "Marathon Runner",        desc = "Reach level 60 without ever learning a riding skill." },
    [128]   = { icon = "inv_shirt_white_01",                  itemId = "707007", name = "Mister White",           desc = "Reach level 60 without ever equipping an uncommon or greater quality item (only white/grey items allowed. All ammunition and bags allowed)." },
    [8]     = { icon = "inv_box_01",                          itemId = "707003", name = "My precious!",           desc = "Reach level 60 without ever trading goods or money with another player." },
    [32]    = { icon = "inv_pants_wolf",                      itemId = "707005", name = "Only Fan",               desc = "Reach level 60 without ever equipping anything other than weapons, shields, ammos, shirts, tabards or bags." },
    [8192]  = { icon = "inv_hammer_20",                       itemId = "707015", name = "Self-made",              desc = "Reach level 60 without ever equipping items that you did not craft yourself (all fishing poles, ammunition, and bags allowed)" },
    [1024]  = { icon = "spell_holy_layonhands",               itemId = "707012", name = "Soft Hands",             desc = "Reach level 60 without ever learning any primary profession." },
    [16]    = { icon = "inv_crate_03",                        itemId = "707004", name = "Special Deliveries",     desc = "Reach level 60 without ever getting goods or money from the mail (Simple letters and NPC quest/items are allowed)." },
    [512]   = { icon = "ability_hunter_pet_boar",             itemId = "707011", name = "That Which Has No Life", desc = "Reach level 60 only by killing boars or quilboars." },
    [2]     = { icon = "inv_misc_coin_05",                    itemId = "707001", name = "Time is money",          desc = "Reach level 60 without ever using the auction house to buy an item." },
}
local sortedAchievements = {}
for id, data in pairs(TabAchievements) do
    table.insert(sortedAchievements, { id = id, data = data })
end
table.sort(sortedAchievements, function(a, b)
    return a.data.name < b.data.name  -- Sort alphabetically by name
end)

function WHC.Tab_Achievements(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", content, "TOP", 0, -10) -- Adjust y-offset based on logo size
    title:SetText("Achievements")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetTextColor(0.933, 0.765, 0)

    local desc1 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc1:SetPoint("TOP", title, "TOP", 0, -25) -- Adjust y-offset based on logo size
    desc1:SetText("Loading...")
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

    for i, value in ipairs(sortedAchievements) do
        local y = -10 - 53 * (i-1)

        itemSlot(scrollContent, 10, y, value.data.name, value.data.desc, value.data.icon, value.id);
    end

    local desc2 = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc2:SetPoint("BOTTOM", scrollFrame, "BOTTOM", 10, -50) -- Adjust y-offset based on logo size
    desc2:SetText(
        "A new WOW-HC button is available when you inspect other players.\n\nAchievements are secured once you hit level 60")
    desc2:SetWidth(450)
    desc2:SetFont("Fonts\\FRIZQT__.TTF", 10)


    return content;
end
