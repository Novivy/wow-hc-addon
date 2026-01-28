local function achievementErrorMessage(link, message)
    return WHC.ADDON_PREFIX..link..HIGHLIGHT_FONT_COLOR_CODE.." Achievement active. " .. message .. FONT_COLOR_CODE_CLOSE
end

local function printAchievementInfo(link, message)
    DEFAULT_CHAT_FRAME:AddMessage(achievementErrorMessage(link, message))
end

local BlizzardFunctions = {}
-- Disables right-click menu buttons
WHC.HookSecureFunc("UnitPopup_OnUpdate", function(self, dropdownMenu, which, unit, name)
    for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = getglobal("DropDownList1Button" .. i)
        if button then
            if button.value == "INVITE" and WhcAchievementSettings.blockInvites == 1 then
                button:Disable()
            end

            if button.value == "TRADE" and WhcAchievementSettings.blockTrades == 1 then
                button:Disable()
            end
        end
    end
end)

--region ====== Lone Wolf ======
local loneWolfLink = WHC.Achievements.LONE_WOLF.itemLink

-- Disables friend list "Group Invite" button
if FriendsFrameGroupInviteButton then
    WHC.HookSecureFunc(FriendsFrameGroupInviteButton, "Enable", function()
        if WhcAchievementSettings.blockInvites == 1 then
            FriendsFrameGroupInviteButton:Disable()
        end
    end)
end

-- Disables who "Group Invite" button
if WhoFrameGroupInviteButton then
    WHC.HookSecureFunc(WhoFrameGroupInviteButton, "Enable", function()
        if WhcAchievementSettings.blockInvites == 1 then
            WhoFrameGroupInviteButton:Disable()
        end
    end)
end


-- Disables guild details "Group Invite" button
if GuildMemberGroupInviteButton then
    WHC.HookSecureFunc(GuildMemberGroupInviteButton, "Enable", function()
        if WhcAchievementSettings.blockInvites == 1 then
            GuildMemberGroupInviteButton:Disable()
        end
    end)
end

local inviteEventHandler = CreateFrame("Frame")
inviteEventHandler:SetScript("OnEvent", function(self, event, name)
    DeclineGroup()
    StaticPopup_Hide("PARTY_INVITE"); -- Needed to remove the popup
    printAchievementInfo(loneWolfLink, "Group invite auto declined.")

    name = name or arg1
    SendChatMessage("I am on the "..loneWolfLink.." achievement. I cannot group with other players.", "WHISPER", GetDefaultLanguage(), name)
end)

BlizzardFunctions.AcceptGroup = AcceptGroup
BlizzardFunctions.InviteUnit = InviteUnit -- Retail
BlizzardFunctions.InviteByName = InviteByName -- 1.12
BlizzardFunctions.InviteToParty = InviteToParty -- 1.12
function WHC.SetBlockInvites()
    inviteEventHandler:UnregisterEvent("PARTY_INVITE_REQUEST")
    AcceptGroup = BlizzardFunctions.AcceptGroup
    InviteUnit = BlizzardFunctions.InviteUnit
    InviteByName = BlizzardFunctions.InviteByName
    InviteToParty = BlizzardFunctions.InviteToParty

    if WhcAchievementSettings.blockInvites == 1 then
        -- Blocks incoming invites
        inviteEventHandler:RegisterEvent("PARTY_INVITE_REQUEST")
        -- Blocks addons like LazyPig from auto accepting invites
        AcceptGroup = function() end

        -- blocks outgoing invites via /i <char_name>
        local blockInvites = function(name)
            printAchievementInfo(loneWolfLink, "Group invites are blocked.")
        end
        InviteUnit = blockInvites
        InviteByName = blockInvites
        InviteToParty = blockInvites
    end
end
--endregion

--region ====== My precious! ======
local myPreciousLink = WHC.Achievements.MY_PRECIOUS.itemLink

BlizzardFunctions.InitiateTrade = InitiateTrade
function WHC.SetBlockTrades()
    InitiateTrade = BlizzardFunctions.InitiateTrade

    -- Block incoming trade via Blizzard interface checkbox
    SetCVar("blockTrades", WhcAchievementSettings.blockTrades)
    if WhcAchievementSettings.blockTrades == 1 then
        -- Block outgoing trade
        InitiateTrade = function()
            printAchievementInfo(myPreciousLink, "Trade requests are blocked.")
        end
    end
end
--endregion


--region ====== Killer Trader ======
local killerTraderLink = WHC.Achievements.KILLER_TRADER.itemLink

local killerTraderEventListener = CreateFrame("Frame")
killerTraderEventListener:RegisterEvent("ADDON_LOADED")
killerTraderEventListener:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "Blizzard_AuctionUI" then
        return
    end
    killerTraderEventListener:UnregisterEvent("ADDON_LOADED")

    if AuctionsCreateAuctionButton then
        WHC.HookSecureFunc(AuctionsCreateAuctionButton, "Enable", function()
            if WhcAchievementSettings.blockAuctionSell == 1 then
                AuctionsCreateAuctionButton:Disable()
            end
        end)
    end
end)

BlizzardFunctions.PostAuction  = PostAuction -- Retail
BlizzardFunctions.StartAuction = StartAuction -- 1.12
function WHC.SetBlockAuctionSell()
    PostAuction  = BlizzardFunctions.PostAuction
    StartAuction = BlizzardFunctions.StartAuction

    if WhcAchievementSettings.blockAuctionSell == 1 then
        local blockAuctionSell = function()
            printAchievementInfo(killerTraderLink, "Selling items on the auction house is blocked.")
        end
        PostAuction  = blockAuctionSell
        StartAuction = blockAuctionSell
    end
end
--endregion

--region ====== Time is Money ======
local timeIsMoneyLink = WHC.Achievements.TIME_IS_MONEY.itemLink

local timeIsMoneyEventListener = CreateFrame("Frame")
timeIsMoneyEventListener:RegisterEvent("ADDON_LOADED")
timeIsMoneyEventListener:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "Blizzard_AuctionUI" then
        return
    end
    timeIsMoneyEventListener:UnregisterEvent("ADDON_LOADED")

    if BrowseBidButton then
        WHC.HookSecureFunc(BrowseBidButton, "Enable", function()
            if WhcAchievementSettings.blockAuctionBuy == 1 then
                BrowseBidButton:Disable()
            end
        end)
    end

    if BrowseBuyoutButton then
        WHC.HookSecureFunc(BrowseBuyoutButton, "Enable", function()
            if WhcAchievementSettings.blockAuctionBuy == 1 then
                BrowseBuyoutButton:Disable()
            end
        end)
    end

    if BidBidButton then
        WHC.HookSecureFunc(BidBidButton, "Enable", function()
            if WhcAchievementSettings.blockAuctionBuy == 1 then
                BidBidButton:Disable()
            end
        end)
    end

    if BidBuyoutButton then
        WHC.HookSecureFunc(BidBuyoutButton, "Enable", function()
            if WhcAchievementSettings.blockAuctionBuy == 1 then
                BidBuyoutButton:Disable()
            end
        end)
    end
end)

BlizzardFunctions.PlaceAuctionBid = PlaceAuctionBid
function WHC.SetBlockAuctionBuy()
    PlaceAuctionBid = BlizzardFunctions.PlaceAuctionBid

    if WhcAchievementSettings.blockAuctionBuy == 1 then
        -- Block outgoing trade
        PlaceAuctionBid = function()
            printAchievementInfo(timeIsMoneyLink, "Buying items from the auction house is blocked.")
        end
    end
end
--endregion

--region ====== Iron Bones ======
local ironBonesLink = WHC.Achievements.IRON_BONES.itemLink

-- Disable repair buttons from Blizzard interface
if MerchantRepairItemButton then
    WHC.HookSecureFunc(MerchantRepairItemButton, "Show", function()
        local repairItemIcon = MerchantRepairItemButton:GetRegions()
        SetDesaturation(repairItemIcon, nil)
        MerchantRepairItemButton:Enable()

        if WhcAchievementSettings.blockRepair == 1 then
            SetDesaturation(repairItemIcon, 1)
            MerchantRepairItemButton:Disable()
        end
    end)
end

if MerchantRepairAllButton then
    WHC.HookSecureFunc(MerchantRepairAllButton, "Enable", function()
        if WhcAchievementSettings.blockRepair == 1 then
            SetDesaturation(MerchantRepairAllIcon, 1)
            MerchantRepairAllButton:Disable()
        end
    end)
end

BlizzardFunctions.RepairAllItems = RepairAllItems
BlizzardFunctions.ShowRepairCursor = ShowRepairCursor
function WHC.SetBlockRepair()
    RepairAllItems = BlizzardFunctions.RepairAllItems
    ShowRepairCursor = BlizzardFunctions.ShowRepairCursor

    if WhcAchievementSettings.blockRepair == 1 then
        local blockRepair = function()
            printAchievementInfo(ironBonesLink, "Repairing items are blocked.")
        end
        -- Block other addons like LazyPig from auto repairing
        RepairAllItems = blockRepair
        ShowRepairCursor = blockRepair
    end
end
--endregion

--region ====== Grounded ======
local groundedLink = WHC.Achievements.GROUNDED.itemLink

local taxiServiceEventHandler = CreateFrame("Frame")
taxiServiceEventHandler:SetScript("OnEvent", function(self, event, name)
    TaxiFrame:Hide()
    printAchievementInfo(groundedLink, "Flying services are blocked.")
end)

BlizzardFunctions.TakeTaxiNode = TakeTaxiNode
function WHC.SetBlockTaxiService()
    taxiServiceEventHandler:UnregisterEvent("TAXIMAP_OPENED")
    TakeTaxiNode = BlizzardFunctions.TakeTaxiNode

    if WhcAchievementSettings.blockTaxiService == 1 then
        -- block user from opening the taxi map
        taxiServiceEventHandler:RegisterEvent("TAXIMAP_OPENED")
        -- Block addons from taking flights
        TakeTaxiNode = function()
            printAchievementInfo(groundedLink, "Flying services are blocked.")
        end
    end
end
--endregion

--region ====== Mister White & Only Fan & Self-made ======
local misterWhiteLink = WHC.Achievements.MISTER_WHITE.itemLink
local onlyFanLink = WHC.Achievements.ONLY_FAN.itemLink
local selfMadeLink = WHC.Achievements.SELF_MADE.itemLink

local misterWhiteLinkAllowedItems = {
    INVTYPE_BAG = true,
    INVTYPE_AMMO = true,
}

local onlyFanAllowedItems = {
    INVTYPE_WEAPON = true,
    INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_SHIELD = true,
    INVTYPE_THROWN = true,
    INVTYPE_RANGED = true,
    INVTYPE_AMMO = true,
    INVTYPE_RANGEDRIGHT = true, -- Wands
    INVTYPE_HOLDABLE = true, -- Held in offhand
    INVTYPE_BODY = true,
    INVTYPE_TABARD = true,
    INVTYPE_BAG = true,
}

local selfMadeAllowedItems = {
    INVTYPE_BAG = true,
    INVTYPE_AMMO = true,
    ["Fishing Pole"] = true,   -- English
    ["Angelrute"] = true,      -- German
    ["Caña de pescar"] = true, -- Spanish
    ["Canne à pêche"] = true,  -- French
    ["Canna da pesca"] = true, -- Italian
    ["Vara de pescar"] = true, -- Portuguese
    ["Удочка"] = true,         -- Russian
    ["낚싯대"] = true,          -- Korean
    ["钓鱼竿"] = true,          -- Chinese (Simplified)
    ["釣魚竿"] = true,          -- Chinese (Traditional)
}

-- TODO Make this more robust
-- The <Made by xxx> is localized.
-- This pattern works for English, German, French, Spanish, Portuguese, Italian, Russian
-- This pattern will break for Korean, Chinese
local function isSelfMade(itemSubType, itemEquipLoc)
    if selfMadeAllowedItems[itemSubType] then
        return true
    end
    if selfMadeAllowedItems[itemEquipLoc] then
        return true
    end

    for i=1, GameTooltip:NumLines() do
        local lineText = getglobal("GameTooltipTextLeft"..i):GetText()
        local nameMatch = string.find(lineText, "<.* ("..WHC.player.name..")>")
        if nameMatch then
            return true
        end
    end

    return false
end

local function getItemInfo(itemId)
    if not itemId then
        return
    end

    local _, _, itemRarity, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
    if RETAIL == 1 then
        _, _, itemRarity, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
    end

    return itemRarity, itemSubType, itemEquipLoc
end

local function setTooltipInfo(itemLink)
    local itemId = WHC.GetItemIDFromLink(itemLink)
    local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)

    if not itemEquipLoc or itemEquipLoc == "" then
        return
    end

    if WhcAchievementSettings.blockMagicItemsTooltip == 1 and itemRarity > 1 and not misterWhiteLinkAllowedItems[itemEquipLoc] then
        local msg = "Cannot equip "..getglobal("ITEM_QUALITY"..itemRarity.."_DESC").." items>"
        GameTooltip:AddLine("<Mister White: "..msg, 1, 0, 0)
    end

    if WhcAchievementSettings.blockArmorItemsTooltip == 1 and not onlyFanAllowedItems[itemEquipLoc] then
        GameTooltip:AddLine("<Only Fan: Cannot equip armor items>", 1, 0, 0)
    end

    if WhcAchievementSettings.blockNonSelfMadeItemsTooltip == 1 and not isSelfMade(itemSubType, itemEquipLoc) then
        GameTooltip:AddLine("<Self-made: Cannot equip items you did not craft>", 1, 0, 0)
    end

    -- Resize the tooltip to match the new lines added
    GameTooltip:Show()
end

-- Update bag items
WHC.HookSecureFunc(GameTooltip, "SetBagItem", function(tip, bagId, slot)
    local itemLink = GetContainerItemLink(bagId, slot)
    setTooltipInfo(itemLink)
end)

-- Update inventory and bank items
WHC.HookSecureFunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
    local itemLink = GetInventoryItemLink(unit, slot)
    -- Inventory slots
    if slot < 20 then
        local itemId = WHC.GetItemIDFromLink(itemLink)
        local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)
        if not itemEquipLoc or itemEquipLoc == "" then
            return
        end

        if WhcAchievementSettings.blockArmorItemsTooltip == 1 and not onlyFanAllowedItems[itemEquipLoc] then
            GameTooltip:AddLine("<Only Fan: Unequipping this item will block you from equipping it again>", 1, 0, 0)
        end

        if WhcAchievementSettings.blockNonSelfMadeItemsTooltip == 1 and not isSelfMade(itemSubType, itemEquipLoc) then
            GameTooltip:AddLine("<Self-made: Unequipping this item will block you from equipping it again>", 1, 0, 0)
        end

        -- Resize the tooltip to match the new lines added
        GameTooltip:Show()
    end
    -- slot 20-23 are bag slots
    -- Bank slots
    if slot > 23 then
        setTooltipInfo(itemLink)
    end
end)

-- Update vendor items
WHC.HookSecureFunc(GameTooltip, "SetMerchantItem", function(tip, index)
    local itemLink = GetMerchantItemLink(index)
    setTooltipInfo(itemLink)
end)

-- Update trade window items
WHC.HookSecureFunc(GameTooltip, "SetTradePlayerItem", function(tip, tradeSlot)
    local itemLink = GetTradePlayerItemLink(tradeSlot)
    setTooltipInfo(itemLink)
end)

WHC.HookSecureFunc(GameTooltip, "SetTradeTargetItem", function(tip, tradeSlot)
    local itemLink = GetTradeTargetItemLink(tradeSlot)
    setTooltipInfo(itemLink)
end)

local equipErrorMessages = {}
local function canEquipItem(itemLink)
    equipErrorMessages = {}

    local itemId = WHC.GetItemIDFromLink(itemLink)
    local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)
    if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_BAG" then
        return
    end

    if WhcAchievementSettings.blockMagicItems == 1 and itemRarity > 1 and not misterWhiteLinkAllowedItems[itemEquipLoc] then
        local msg = "Equipping "..getglobal("ITEM_QUALITY"..itemRarity.."_DESC").." items are blocked."
        table.insert(equipErrorMessages, achievementErrorMessage(misterWhiteLink, msg))
    end

    if WhcAchievementSettings.blockArmorItems == 1 and not onlyFanAllowedItems[itemEquipLoc] then
        table.insert(equipErrorMessages, achievementErrorMessage(onlyFanLink, "Equipping armor items are blocked."))
    end

    if WhcAchievementSettings.blockNonSelfMadeItems == 1 and not isSelfMade() and
            not selfMadeAllowedItems[itemSubType] and not selfMadeAllowedItems[itemEquipLoc] then
        table.insert(equipErrorMessages, achievementErrorMessage(selfMadeLink, "Equipping items you did not craft are blocked."))
    end
end

local function printBlockers(errorMessages)
    for _, value in ipairs(errorMessages) do
        DEFAULT_CHAT_FRAME:AddMessage(value)
    end
end

WHC.HookSecureFunc("PickupContainerItem", function(bagId, slot)
    if not CursorHasItem() then
        equipErrorMessages = {}
        return
    end

    local itemLink = GetContainerItemLink(bagId, slot)
    canEquipItem(itemLink)
end)

BlizzardFunctions.AutoEquipCursorItem = AutoEquipCursorItem
BlizzardFunctions.EquipCursorItem     = EquipCursorItem
BlizzardFunctions.EquipPendingItem    = EquipPendingItem
BlizzardFunctions.PickupInventoryItem = PickupInventoryItem
BlizzardFunctions.PickupMerchantItem  = PickupMerchantItem
BlizzardFunctions.UseContainerItem    = UseContainerItem
function WHC.SetBlockEquipItems()
    AutoEquipCursorItem = BlizzardFunctions.AutoEquipCursorItem
    EquipCursorItem     = BlizzardFunctions.EquipCursorItem
    EquipPendingItem    = BlizzardFunctions.EquipPendingItem
    PickupInventoryItem = BlizzardFunctions.PickupInventoryItem
    PickupMerchantItem  = BlizzardFunctions.PickupMerchantItem
    UseContainerItem    = BlizzardFunctions.UseContainerItem

    if WhcAchievementSettings.blockMagicItems == 1 or WhcAchievementSettings.blockArmorItems == 1 or WhcAchievementSettings.blockNonSelfMadeItems == 1 then
        -- Block right-click equip
        UseContainerItem = function(bagId, slot, onSelf)
            if BankFrame:IsVisible() or MerchantFrame:IsVisible() then
                return BlizzardFunctions.UseContainerItem(bagId, slot, onSelf)
            end

            if RETAIL == 1 then
                local auctionsTabVisible = AuctionFrameAuctions and AuctionFrameAuctions:IsVisible()
                if TradeFrame:IsVisible() or SendMailFrame:IsVisible() or auctionsTabVisible then
                    return BlizzardFunctions.UseContainerItem(bagId, slot, onSelf)
                end
            end

            local itemLink = GetContainerItemLink(bagId, slot)
            canEquipItem(itemLink)
            if not equipErrorMessages[1] then
                return BlizzardFunctions.UseContainerItem(bagId, slot, onSelf)
            end

            printBlockers(equipErrorMessages)
        end

        -- Left-clicking a merchant item does not trigger CursorHasItem() to become true, so we only allow right-click buying,
        -- to prevent the user from left-clicking and immediate equipping the item.
        -- When the user tries to equip the item from the backpack, then we can validate with CursorHasItem()
        PickupMerchantItem = function(index)
            local itemLink = GetMerchantItemLink(index)
            local itemId = WHC.GetItemIDFromLink(itemLink)
            local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)
            if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_BAG" then
                return BlizzardFunctions.PickupMerchantItem(index)
            end

            if WhcAchievementSettings.blockMagicItems == 1 and itemRarity > 1 and not misterWhiteLinkAllowedItems[itemEquipLoc] then
                local msg = "Buying "..getglobal("ITEM_QUALITY"..itemRarity.."_DESC").." equipment must be done using right-click."
                printAchievementInfo(misterWhiteLink, msg)
            end

            if WhcAchievementSettings.blockArmorItems == 1 and not onlyFanAllowedItems[itemEquipLoc] then
                printAchievementInfo(onlyFanLink, "Buying armor must be done using right-click.")
            end

            if WhcAchievementSettings.blockNonSelfMadeItems == 1 and not isSelfMade() and not selfMadeAllowedItems[itemSubType] and not selfMadeAllowedItems[itemEquipLoc] then
                printAchievementInfo(selfMadeLink, "Buying equipment you did not craft must be done using right-click,")
            end
        end

        -- Block pick up and place on character
        -- Block drag and place on character
        -- Note: This endpoint is both being used when placing an item onto the character and equipment page
        -- and when an item is being pickup from the character equipment page.
        PickupInventoryItem = function(invSlot)
            if not CursorHasItem() then
                local itemLink = GetInventoryItemLink("player", invSlot)
                canEquipItem(itemLink)
                return BlizzardFunctions.PickupInventoryItem(invSlot)
            end

            if not equipErrorMessages[1] then
                return BlizzardFunctions.PickupInventoryItem(invSlot)
            end

            printBlockers(equipErrorMessages)
        end

        -- Block other addons
        AutoEquipCursorItem = function()
            if not equipErrorMessages[1] then
                return BlizzardFunctions.AutoEquipCursorItem()
            end

            printBlockers(equipErrorMessages)
        end

        -- Block other addons
        EquipCursorItem = function(invSlot)
            if not equipErrorMessages[1] then
                return BlizzardFunctions.EquipCursorItem(invSlot)
            end

            printBlockers(equipErrorMessages)
        end

        -- Block Bind-on-Equip pop up
        EquipPendingItem = function(invSlot)
            if not equipErrorMessages[1] then
                return BlizzardFunctions.EquipCursorItem(invSlot)
            end

            printBlockers(equipErrorMessages)
        end
    end
end
--endregion

--region ====== Special Deliveries ======
local specialDeliveriesLink = WHC.Achievements.SPECIAL_DELIVERIES.itemLink

local isMailAllowed = function(index, itemIndex)
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(index)
    -- All GM items and gold allowed
    if isGM then
        return true
    end

    -- Mail from NPCs, AH and GM cannot be replied to and can be looted
    -- Only player mail can be replied to
    -- Even mail that is returned back to the player can be replied to
    local isNPC = not canReply
    if isNPC then
        return true
    end

    -- Plain Letter send as item can always be looted (only works on 1.14)
    -- Making a copy of a mail works as normal
    if GetInboxItemLink and itemIndex then
        local itemLink = GetInboxItemLink(index, itemIndex)
        local itemId = WHC.GetItemIDFromLink(itemLink)
        return 8383 == itemId -- Plain Letter
    end

    return false
end


BlizzardFunctions.TakeInboxItem = TakeInboxItem
BlizzardFunctions.TakeInboxMoney = TakeInboxMoney
function WHC.SetBlockMailItems()
    TakeInboxMoney = BlizzardFunctions.TakeInboxMoney
    TakeInboxItem = BlizzardFunctions.TakeInboxItem

    if WhcAchievementSettings.blockMailItems == 1 then
        TakeInboxMoney = function(index)
            if isMailAllowed(index) then
                return BlizzardFunctions.TakeInboxMoney(index)
            end

            printAchievementInfo(specialDeliveriesLink, "Taking money mailed from another player is blocked.")
        end
        TakeInboxItem = function(index, itemIndex)
            if isMailAllowed(index, itemIndex) then
                return BlizzardFunctions.TakeInboxItem(index, itemIndex)
            end

            printAchievementInfo(specialDeliveriesLink, "Taking items mailed from another player is blocked.")
        end
    end
end
--endregion

--region ====== Marathon Runner & Soft Hands ======
local marathonRunnerLink = WHC.Achievements.MARATHON_RUNNER.itemLink
local softHandsLink = WHC.Achievements.SOFT_HANDS.itemLink

local marathonRunnerBlockedQuests = {
    [1661] = true,
    ["The Tome of Nobility"]  = true, -- English
    ["Der Foliant des Adels"] = true, -- German
    ["Libro de la nobleza"]   = true, -- Spanish
    ["Escrito sobre nobleza"] = true, -- Spanish (Mexico)
    ["Le Tome de noblesse"]   = true, -- French
    ["Il tomo della nobiltà"]  = true, -- Italian
    ["O Tomo de Nobreza"]     = true, -- Portuguese
    ["Фолиант Благородства"]  = true, -- Russian
    ["고결함의 고서"]           = true, -- Korean
    ["高贵之书"]               = true, -- Chinese (Simplified)
    ["高貴之書"]               = true, -- Chinese (Traditional)

    [4490] = true,
    ["Summon Felsteed"]               = true, -- English
    ["Teufelsross beschwören"]        = true, -- German
    ["Invoca un malignoecus"]         = true, -- Spanish
    ["Invoca un corcel vil"]          = true, -- Spanish (Mexico)
    ["Invoquer un Palefroi corrompu"] = true, -- French
    ["Summon Felsteed"]               = true, -- Italian
    ["Evocar Corcel Vil"]             = true, -- Portuguese
    ["Призывание коня Скверны"]       = true, -- Russian
    ["지옥마 소환"]                     = true, -- Korean
    ["召唤地狱战马"]                    = true, -- Chinese (Simplified)
    ["召喚地獄戰馬"]                    = true, -- Chinese (Traditional)
}

local function getTrainerServiceCost(skillIndex)
    local money, _, professionSlots = GetTrainerServiceCost(skillIndex)
    if RETAIL == 1 then
        money, professionSlots = GetTrainerServiceCost(skillIndex)
        if professionSlots then -- 1.14 returns a bool instead of an integer
            professionSlots = 1
        else
            professionSlots = 0
        end
    end

    return money, professionSlots
end

--Base cost is 80 gold (800000 cp)
--10% discount is 72 gold (720000 cp)
--20% discount is 64 gold (640000 cp)
local ridingCostInCopper = 639999

local function canTrainSkill()
    local trainSkillErrorMessages = {}

    local skillIndex = GetTrainerSelectionIndex()
    local money, professionSlots = getTrainerServiceCost(skillIndex)

    if WhcAchievementSettings.blockRidingSkill == 1 and money > ridingCostInCopper then
        table.insert(trainSkillErrorMessages, achievementErrorMessage(marathonRunnerLink, "Buying riding skill is blocked."))
    end

    if WhcAchievementSettings.blockProfessions == 1 and professionSlots > 0 then
        table.insert(trainSkillErrorMessages, achievementErrorMessage(softHandsLink, "Buying primary profession is blocked."))
    end

    return trainSkillErrorMessages
end

local trainerUIEventListener = CreateFrame("Frame")
trainerUIEventListener:RegisterEvent("ADDON_LOADED")
trainerUIEventListener:SetScript("OnEvent", function(self, eventName, addonName)
    addonName = addonName or arg1
    if addonName ~= "Blizzard_TrainerUI" then
        return
    end
    trainerUIEventListener:UnregisterEvent("ADDON_LOADED")

    if ClassTrainerTrainButton then
        WHC.HookSecureFunc(ClassTrainerTrainButton, "Enable", function()
            local trainSkillErrorsMessages = canTrainSkill()
            if trainSkillErrorsMessages[1] then
                ClassTrainerTrainButton:Disable()
            end
        end)
    end
end)

local function getQuestID()
    if GetQuestID then -- 1.14 feature
        return GetQuestID()
    end

    return 0
end

if QuestFrameAcceptButton then
    WHC.HookSecureFunc(QuestFrameAcceptButton, "Enable", function()
        if WhcAchievementSettings.blockRidingSkill == 1 then
            local questID = getQuestID()
            local questName = GetTitleText()
            if marathonRunnerBlockedQuests[questID] or marathonRunnerBlockedQuests[questName] then
                QuestFrameAcceptButton:Disable()
            end
        end
    end)
end

if QuestFrameCompleteQuestButton then
    WHC.HookSecureFunc(QuestFrameCompleteQuestButton, "Enable", function()
        if WhcAchievementSettings.blockRidingSkill == 1 then
            local questID = getQuestID()
            local questName = GetTitleText()
            if marathonRunnerBlockedQuests[questID] or marathonRunnerBlockedQuests[questName] then
                QuestFrameCompleteQuestButton:Disable()
            end
        end
    end)
end

BlizzardFunctions.BuyTrainerService = BuyTrainerService
BlizzardFunctions.AcceptQuest = AcceptQuest
BlizzardFunctions.GetQuestReward = GetQuestReward
function WHC.SetBlockTrainSkill()
    BuyTrainerService = BlizzardFunctions.BuyTrainerService
    AcceptQuest = BlizzardFunctions.AcceptQuest
    GetQuestReward = BlizzardFunctions.GetQuestReward

    if WhcAchievementSettings.blockRidingSkill == 1 then
        BuyTrainerService = function(index)
            local trainSkillErrorsMessages = canTrainSkill()
            if trainSkillErrorsMessages[1] then
                return printBlockers(trainSkillErrorsMessages)
            end

            return BlizzardFunctions.BuyTrainerService(index)
        end

        AcceptQuest = function()
            local questID = getQuestID
            local questName = GetTitleText()
            if marathonRunnerBlockedQuests[questID] or marathonRunnerBlockedQuests[questName] then
                return printAchievementInfo(marathonRunnerLink, string.format("Accepting [%s] is blocked as the reward includes riding skill.", questName))
            end

            return BlizzardFunctions.AcceptQuest()
        end
        
        GetQuestReward = function(itemChoice)
            local questID = getQuestID()
            local questName = GetTitleText()
            if marathonRunnerBlockedQuests[questID] or marathonRunnerBlockedQuests[questName] then
                return printAchievementInfo(marathonRunnerLink, string.format("Completing [%s] is blocked as the reward includes riding skill.", questName))
            end

            return BlizzardFunctions.GetQuestReward(itemChoice)
        end
    end
end

--endregion

--region ====== Help Yourself ======
local helpYourselfLink = WHC.Achievements.HELP_YOURSELF.itemLink

local secondarySkillsHeading = {
    ["Secondary Skills"] = true, -- English
    ["Nebenfertigkeiten"] = true, -- German
    ["Habilidades secundarias"] = true, -- Spanish
    ["Habilidades secundarias"] = true, -- Spanish (Mexico)
    ["Compétences secondaires"] = true, -- French
    ["Competenze Secondarie"] = true, -- Italian
    ["Habilidades secundárias"] = true, -- Portuguese
    ["Вторичные навыки"] = true, -- Russian
}

local function getHelpYourselfAllowedCategories()
    local allowedCategories = {}
    allowedCategories[WHC.player.class] = true

    ExpandSkillHeader(0) -- Ensure all skills are expanded

    local headerName
    local numSkills = GetNumSkillLines();
    for skillIndex=1, numSkills do
        local skillName, isHeader, _, _, _, _, _, isAbandonable, _, _, minLevel = GetSkillLineInfo(skillIndex)
        if isAbandonable then
            allowedCategories[skillName] = true -- Primary Proficiency
        end

        if isHeader then
            headerName = skillName
        elseif secondarySkillsHeading[headerName] and minLevel == 0 then
            allowedCategories[skillName] = true -- Secondary Proficiency, excluding riding
        end
    end

    return allowedCategories
end

local function abandonQuestSound()
    local sound = "igQuestLogAbandonQuest"
    if RETAIL == 1 then
        sound = 846
    end

    return sound
end

local checkQuests = false
local previousNumQuests = 0
local blockQuestsEventListener = CreateFrame("Frame")
blockQuestsEventListener:SetScript("OnEvent", function(self, eventName, a1)
    eventName = eventName or event

    -- prevent the handler from running before skills has been loaded
    if GetNumSkillLines() == 0 then
        return
    end

    -- This event is always fired before quest is added to the quest log
    if eventName == "UNIT_QUEST_LOG_CHANGED" then
        ExpandQuestHeader(0) -- Ensure all quest headers are expanded
        return
    end

    -- This event is fired multiple times, both before and after a quest is added to the quest log
    if eventName == "QUEST_LOG_UPDATE" then
        checkQuests = previousNumQuests ~= GetNumQuestLogEntries()
        previousNumQuests = GetNumQuestLogEntries()
    end

    if eventName == "QUEST_ACCEPTED" then
        ExpandQuestHeader(0) -- Ensure all quest headers are expanded
        checkQuests = true
    end

    if checkQuests then
        checkQuests = false

        local helpYourselfAllowedCategories = getHelpYourselfAllowedCategories()

        local headerName = ""
        local numQuests = GetNumQuestLogEntries()
        for questLogIndex = 1, numQuests do
            local questTitle, _, _, isHeader = GetQuestLogTitle(questLogIndex);
            if isHeader then
                headerName = questTitle
            elseif not helpYourselfAllowedCategories[headerName] then
                SelectQuestLogEntry(questLogIndex)
                SetAbandonQuest()
                AbandonQuest()
                PlaySound(abandonQuestSound())
                printAchievementInfo(helpYourselfLink, string.format("Abandoning [%s] as it is not a class or profession quest.", questTitle))
            end
        end
    end
end)

function WHC.SetBlockQuests()
    blockQuestsEventListener:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
    blockQuestsEventListener:UnregisterEvent("QUEST_LOG_UPDATE")
    blockQuestsEventListener:UnregisterEvent("QUEST_ACCEPTED")

    if WhcAchievementSettings.blockQuests == 1 then
        if RETAIL == 0 then
            blockQuestsEventListener:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
            blockQuestsEventListener:RegisterEvent("QUEST_LOG_UPDATE")
        else
            blockQuestsEventListener:RegisterEvent("QUEST_ACCEPTED")
        end
    end
end
--endregion

--region ====== Demon Slayer & Lightbringer & That Which Has No Life ======
local demonSlayer = WHC.Achievements.DEMON_SLAYER
local lightbringer = WHC.Achievements.LIGHTBRINGER
local thatWhichHasNoLife = WHC.Achievements.THAT_WHICH_HAS_NO_LIFE

-- Remove false positives
-- Critter are levels go all the way to 55 inside Stratholme
-- Totems summoned by Quilboars
local ignoreCreatureType = {
    ["Critter"] = true, -- English
    ["Tier"] = true, -- German
    ["Alimaña"] = true, -- Spanish
    ["Alimaña"] = true, -- Spanish (Mexico)
    ["Bestiole"] = true, -- French
    ["Animale"] = true, -- Italian
    ["Bicho"] = true, -- Portuguese
    ["Зверек"] = true, -- Russian
    ["동물"] = true, -- Korean
    ["小生物"] = true, -- Chinese (Simplified)
    ["小動物"] = true, -- Chinese (Traditional)

    ["Totem"] = true, -- English
    ["Totem"] = true, -- German
    ["Tótem"] = true, -- Spanish
    ["Tótem"] = true, -- Spanish (Mexico)
    ["Totem"] = true, -- French
    ["Totem"] = true, -- Italian
    ["Totem"] = true, -- Portuguese
    ["Тотем"] = true, -- Russian
    ["토템"] = true, -- Korean
    ["图腾"] = true, -- Chinese (Simplified)
    ["圖騰"] = true, -- Chinese (Traditional)
}

local undeadType = {
    ["Undead"] = true, -- English
    ["Untoter"] = true, -- German
    ["No-muerto"] = true, -- Spanish
    ["No-muerto"] = true, -- Spanish (Mexico)
    ["Mort-vivant"] = true, -- French
    ["Non Morto"] = true, -- Italian
    ["Morto-vivo"] = true, -- Portuguese
    ["Нежить"] = true, -- Russian
    ["언데드"] = true, -- Korean
    ["亡灵"] = true, -- Chinese (Simplified)
    ["亡靈"] = true, -- Chinese (Traditional)
}

-- Spawns from undead mobs in Duskwood. Gives 0 exp.
-- List can be generalized to more mobs if significant mobs are found.
local undeadIgnoreNpcs = {
    [2462] = true,
    ["Flesh Eating Worm"] = true, -- English
    ["Fleischfressender Wurm"] = true, -- German
    ["Gusano comecarnes"] = true, -- Spanish
    ["Gusano carnívoro"] = true, -- Spanish (Mexico)
    ["Ver mangeur de chair"] = true, -- French
    ["Verme Carnivoro"] = true, -- Italian
    ["Verme Come-carne"] = true, -- Portuguese
    ["Кусеница"] = true, -- Russian
    ["왕구더기"] = true, -- Korean
    ["食腐虫"] = true, -- Chinese (Simplified)
    ["食腐蟲"] = true, -- Chinese (Traditional)
}

local demonType = {
    ["Demon"] = true, -- English
    ["Dämon"] = true, -- German
    ["Demonio"] = true, -- Spanish
    ["Demonio"] = true, -- Spanish (Mexico)
    ["Démon"] = true, -- French
    ["Demone"] = true, -- Italian
    ["Demônio"] = true, -- Portuguese
    ["Демон"] = true, -- Russian
    ["악마"] = true, -- Korean
    ["恶魔"] = true, -- Chinese (Simplified)
    ["惡魔"] = true, -- Chinese (Traditional)
}

local boarFamily = {
    ["Boar"] = true, -- English
    ["Eber"] = true, -- German
    ["Jabalí"] = true, -- Spanish
    ["Jabalí"] = true, -- Spanish (Mexico)
    ["Sanglier"] = true, -- French
    ["Cinghiale"] = true, -- Italian
    ["Javali"] = true, -- Portuguese
    ["Вепрь"] = true, -- Russian
    ["멧돼지"] = true, -- Korean
    ["野猪"] = true, -- Chinese (Simplified)
    ["野豬"] = true, -- Chinese (Traditional)
}

local quilboarNpcs = {
    -- Bristleback clan
    [3259] = true, ["Bristleback Defender"] = true,
    [3263] = true, ["Bristleback Geomancer"] = true,
    [3258] = true, ["Bristleback Hunter"] = true,
    [3232] = true, ["Bristleback Interloper"] = true,
    [3262] = true, ["Bristleback Mystic"] = true,
    [2952] = true, ["Bristleback Quilboar"] = true,
    [2953] = true, ["Bristleback Shaman"] = true,
    [3261] = true, ["Bristleback Thornweaver"] = true,
    [3260] = true, ["Bristleback Water Seeker"] = true,

    -- Death's Head clan (Razorfen Kraul and Razorfen Downs)
    [4515] = true, ["Death's Head Acolyte"] = true,
    [4516] = true, ["Death's Head Adept"] = true,
    [7872] = true, ["Death's Head Cultist"] = true,
    [7335] = true, ["Death's Head Geomancer"] = true,
    [7337] = true, ["Death's Head Necromancer"] = true,
    [4517] = true, ["Death's Head Priest"] = true,
    [4518] = true, ["Death's Head Sage"] = true,
    [4519] = true, ["Death's Head Seer"] = true,
    [212674] = true, ["Death's Head Shaman"] = true, -- Might be Season of Discovery mob
    [4625] = true, ["Death's Head Ward Keeper"] = true,
    [218873] = true, ["Death's Head Warrior"] = true, -- Undead, Might be Season of Discovery mob

    -- Razorfen clan (Razorfen Kraul)
    [7873] = true, ["Razorfen Battleguard"] = true,
    [4531] = true, ["Razorfen Beast Trainer"] = true,
    [4532] = true, ["Razorfen Beastmaster"] = true,
    [4442] = true, ["Razorfen Defender"] = true,
    [4522] = true, ["Razorfen Dustweaver"] = true,
    [4525] = true, ["Razorfen Earthbreaker"] = true,
    [4520] = true, ["Razorfen Geomancer"] = true,
    [4523] = true, ["Razorfen Groundshaker"] = true,
    [4530] = true, ["Razorfen Handler"] = true,
    [4436] = true, ["Razorfen Quilguard"] = true,
    [6132] = true, ["Razorfen Servitor"] = true,
    [4438] = true, ["Razorfen Spearhide"] = true,
    [6035] = true, ["Razorfen Stalker"] = true,
    [7874] = true, ["Razorfen Thornweaver"] = true,
    [4440] = true, ["Razorfen Totemic"] = true,
    [4437] = true, ["Razorfen Warden"] = true,
    [4435] = true, ["Razorfen Warrior"] = true,

    -- Razormane clan
    [3114] = true, ["Razormane Battleguard"] = true,
    [3266] = true, ["Razormane Defender"] = true,
    [3113] = true, ["Razormane Dustrunner"] = true,
    [3269] = true, ["Razormane Geomancer"] = true,
    [3265] = true, ["Razormane Hunter"] = true,
    [3271] = true, ["Razormane Mystic"] = true,
    [3456] = true, ["Razormane Pathfinder"] = true,
    [208180] = true, ["Razormane Poacher"] = true, -- Might be Season of Discovery mob
    [3111] = true, ["Razormane Quilboar"] = true,
    [3112] = true, ["Razormane Scout"] = true,
    [3458] = true, ["Razormane Seer"] = true,
    [3457] = true, ["Razormane Stalker"] = true,
    [3268] = true, ["Razormane Thornweaver"] = true,
    [3459] = true, ["Razormane Warfrenzy"] = true,
    [3267] = true, ["Razormane Water Seeker"] = true,

    -- Razorfen Kraul bosses
    [6168] = true, ["Roogug"] = true,
    [4424] = true, ["Aggem Thorncurse"] = true,
    [4428] = true, ["Death Speaker Jargba"] = true,
    [4420] = true, ["Overlord Ramtusk"] = true,
    [4421] = true, ["Charlga Razorflank"] = true,

    -- Razorfen Down bosses
    [7356] = true, ["Plaguemaw the Rotting"] = true,
    [7354] = true, ["Ragglesnout"] = true,

    -- Rare and special mobs
    [3229] = true, ["\"Squealer\" Thornmantle"] = true,
    [216463] = true, ["Ailgrha Splittusk"] = true, -- Might be Season of Discovery mob
    [5824] = true, ["Captain Flat Tusk"] = true,
    [8554] = true, ["Chief Sharptusk Thornmantle"] = true,
    [3437] = true, ["Crekori Mudwater"] = true, -- Might not exist in the game
    [4842] = true, ["Earthcaller Halmgar"] = true,
    [3270] = true, ["Elder Mystic Razorsnout"] = true,
    [5826] = true, ["Geolord Mottle"] = true,
    [5863] = true, ["Geopriest Gukk'rok"] = true,
    [5859] = true, ["Hagg Taurenbane"] = true,
    [212694] = true, ["Hirzek"] = true, -- Might be Season of Discovery mob
    [3438] = true, ["Kreenig Snarlsnout"] = true,
    [3436] = true, ["Kuz"] = true,
    [3435] = true, ["Lok Orcbane"] = true,
    [3430] = true, ["Mangletooth"] = true, -- Horde quest giver. Alliance might be able to kill him
    [3434] = true, ["Nak"] = true,
    [4623] = true, ["Quilguard Champion"] = true,
    [16051] = true, ["Snokh Blackspine"] = true, -- Blackrock Depths - Jail Break event
    [5864] = true, ["Swinegart Spearhide"] = true,
    [4427] = true, ["Ward Guardian"] = true,
    [7329] = true, ["Withered Quilguard"] = true, -- Undead
    [7328] = true, ["Withered Reaver"]    = true, -- Undead
    [7332] = true, ["Withered Spearhide"] = true, -- Undead
    [7327] = true, ["Withered Warrior"]   = true, -- Undead
}

local boarNpcs = {
    [7333] = true, ["Withered Battle Boar"] = true, -- Undead
    [7334] = true, ["Battle Boar Horror"] = true, -- Undead
    [5993] = true, ["Helboar"] = true, -- Demon
}

local function getNpcID(unit)
    if UnitGUID then
        local guid = UnitGUID(unit) -- Only possible on 1.14
        local _, _, _, _, _, npcID = strsplit("-", guid)
        return tonumber(npcID)
    end

    if WHC.client.isSuperWow then
        local _, guid = UnitExists(unit) -- Superwow guid
        local npcIDHex = string.sub(guid, 9, 12)
        return tonumber(npcIDHex, 16)
    end

    return 0
end

local onlyKillFrame = CreateFrame("Frame", "OnlyKillFrame", UIParent, RETAIL_BACKDROP)
onlyKillFrame:SetWidth(500)
onlyKillFrame:SetHeight(150)
onlyKillFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
onlyKillFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
onlyKillFrame:SetBackdropColor(0, 0, 0, 1)

onlyKillFrame.logo = onlyKillFrame:CreateTexture(nil, "ARTWORK")
onlyKillFrame.logo:SetWidth(60)
onlyKillFrame.logo:SetHeight(60)
onlyKillFrame.logo:SetPoint("TOP", onlyKillFrame, "TOP", 0, 20)

onlyKillFrame.title = onlyKillFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
onlyKillFrame.title:SetPoint("TOP", onlyKillFrame, "TOP", 0, -50) -- Adjust y-offset based on logo size
onlyKillFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 18)
onlyKillFrame.title:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

onlyKillFrame.desc1 = onlyKillFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
onlyKillFrame.desc1:SetPoint("TOP", onlyKillFrame.title, "TOP", 0, -30) -- Adjust y-offset based on logo size
onlyKillFrame.desc1:SetFont("Fonts\\FRIZQT__.TTF", 16)
onlyKillFrame.desc1:SetWidth(450)

local function updateOnlyKillFrame(achievement, unitName)
    onlyKillFrame.logo:SetTexture("Interface\\Icons\\"..achievement.icon)
    onlyKillFrame.title:SetText(achievement.itemLink)
    onlyKillFrame.desc1:SetText(string.format("Killing [%s] will fail your achievement!", unitName))
    onlyKillFrame:Show()
end

onlyKillFrame:SetScript("OnEvent", function()
    onlyKillFrame:Hide()

    local creatureType = UnitCreatureType("target")
    if not UnitExists("target") or
            not UnitCanAttack("player", "target") or
            UnitIsTrivial("target") or
            ignoreCreatureType[creatureType] or
            UnitIsPlayer("target") or
            UnitIsDead("target") then
        return
    end

    local npcID = getNpcID("target")
    local unitName = UnitName("target")

    if WhcAchievementSettings.onlyKillDemons == 1 and not demonType[creatureType] then
        return updateOnlyKillFrame(demonSlayer, unitName)
    end

    local ignoreNonUndead = undeadIgnoreNpcs[npcID] or undeadIgnoreNpcs[unitName]
    if WhcAchievementSettings.onlyKillUndead == 1 and not undeadType[creatureType] and not ignoreNonUndead then
        return updateOnlyKillFrame(lightbringer, unitName)
    end

    local creatureFamily = UnitCreatureFamily("target")
    local isBoar = boarFamily[creatureFamily] or boarNpcs[npcID] or boarNpcs[unitName]
    local isQuilboar = quilboarNpcs[npcID] or quilboarNpcs[unitName]
    local isBoarOrQuilboar = isBoar or isQuilboar
    if WhcAchievementSettings.onlyKillBoars == 1 and not isBoarOrQuilboar then
        return updateOnlyKillFrame(thatWhichHasNoLife, unitName)
    end
end)

function WHC.SetWarningOnlyKill()
    onlyKillFrame:Hide()
    onlyKillFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")

    if WhcAchievementSettings.onlyKillDemons == 1 or WhcAchievementSettings.onlyKillUndead == 1 or WhcAchievementSettings.onlyKillBoars == 1 then
        onlyKillFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
end
--endregion

--region ====== Untalented ======
local untalentedLink = WHC.Achievements.UNTALENTED.itemLink

BlizzardFunctions.LearnTalent = LearnTalent
function WHC.SetBlockTalents()
    LearnTalent = BlizzardFunctions.LearnTalent

    if WhcAchievementSettings.blockTalents == 1 then
        LearnTalent = function()
            printAchievementInfo(untalentedLink, "Learning talents is blocked.")
        end
    end
end
--endregion

--region ====== Restless ======
function WHC.SendGetRestedXpStatusCommand()
    local msg = ".whc rested"
    SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
end

function WHC.OnRestedXpStatusReceived(isRestedXpEnabled)
    WhcAchievementSettings.blockRestedExp = math.abs(isRestedXpEnabled - 1)
    WHC_SETTINGS.blockRestedExpCheckbox:SetChecked(WHC.CheckedValue(WhcAchievementSettings.blockRestedExp))
end

function WHC.SendToggleRestedXpCommand()
    local msg = ".restedxp"
    SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
end
--endregion
