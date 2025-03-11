local addonPrefix = ITEM_QUALITY_COLORS[5].hex.."[WOW-HC.com]: "..FONT_COLOR_CODE_CLOSE

local function achievementLink(achievement)
    return ITEM_QUALITY_COLORS[5].hex.."|Hitem:"..achievement.itemId..":0:0:0|h["..achievement.name.."]|h"..FONT_COLOR_CODE_CLOSE
end

local function achievementErrorMessage(link, message)
    local achievementMsg = link..HIGHLIGHT_FONT_COLOR_CODE.." Achievement active. "
    return addonPrefix..achievementMsg..message..FONT_COLOR_CODE_CLOSE
end

local function printAchievementInfo(link, message)
    DEFAULT_CHAT_FRAME:AddMessage(achievementErrorMessage(link, message))
end

local _G = getfenv(0);
local function hooksecurefunc(arg1, arg2, arg3)
    if type(arg1) == "string" then
        arg1, arg2, arg3 = _G, arg1, arg2
    end
    local orig = arg1[arg2]
    arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        if arg2 ~= "UnitPopup_OnUpdate" and arg2 ~= "SetBagItem" and arg2 ~= "SetInventoryItem" then
            --WHC.DebugPrint("Original "..arg2)
        end
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        if arg2 ~= "UnitPopup_OnUpdate" and arg2 ~= "SetBagItem" and arg2 ~= "SetInventoryItem" then
            --WHC.DebugPrint("Hook "..arg2)
        end
        arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
    end
end

local BlizzardFunctions = {}
-- Disables right-click menu buttons
hooksecurefunc("UnitPopup_OnUpdate", function(self, dropdownMenu, which, unit, name)
    for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList1Button" .. i]
        if button then
            if button.value == "INVITE" and WhcAddonSettings.blockInvites == 1 then
                button:Disable()
            end

            if button.value == "TRADE" and WhcAddonSettings.blockTrades == 1 then
                button:Disable()
            end
        end
    end
end)

--region ====== Lone Wolf ======
local loneWolfLink = achievementLink(TabAchievements[ACHIEVEMENT_LONE_WOLF])

-- Disables friend list "Group Invite" button
hooksecurefunc("FriendsList_Update", function()
    if WhcAddonSettings.blockInvites == 1 and FriendsFrameGroupInviteButton then
        FriendsFrameGroupInviteButton:Disable()
    end
end)

-- Disables who "Group Invite" button
hooksecurefunc("WhoList_Update", function()
    if WhcAddonSettings.blockInvites == 1 and WhoFrameGroupInviteButton then
        WhoFrameGroupInviteButton:Disable()
    end
end)

-- Disables guild details "Group Invite" button
hooksecurefunc("GuildStatus_Update", function()
    if WhcAddonSettings.blockInvites == 1 and GuildMemberGroupInviteButton then
        GuildMemberGroupInviteButton:Disable()
    end
end)

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
function WHC.SetBlockInvites()
    inviteEventHandler:UnregisterEvent("PARTY_INVITE_REQUEST")
    AcceptGroup = BlizzardFunctions.AcceptGroup
    InviteUnit = BlizzardFunctions.InviteUnit
    InviteByName = BlizzardFunctions.InviteByName

    if WhcAddonSettings.blockInvites == 1 then
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
    end
end
--endregion

--region ====== My precious! ======
local myPreciousLink = achievementLink(TabAchievements[ACHIEVEMENT_MY_PRECIOUS])

BlizzardFunctions.InitiateTrade = InitiateTrade
function WHC.SetBlockTrades()
    InitiateTrade = BlizzardFunctions.InitiateTrade

    -- Block incoming trade via Blizzard interface checkbox
    SetCVar("blockTrades", WhcAddonSettings.blockTrades)
    if WhcAddonSettings.blockTrades == 1 then
        -- Block outgoing trade
        InitiateTrade = function()
            printAchievementInfo(myPreciousLink, "Trade requests are blocked.")
        end
    end
end
--endregion


--region ====== Killer Trader ======
local killerTraderLink = achievementLink(TabAchievements[ACHIEVEMENT_KILLER_TRADER])

local killerTraderEventListener = CreateFrame("Frame")
killerTraderEventListener:RegisterEvent("ADDON_LOADED")
killerTraderEventListener:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "Blizzard_AuctionUI" then
        return
    end

    local blockAuctionSell = function()
        if WhcAddonSettings.blockAuctionSell == 1 and AuctionsCreateAuctionButton then
            AuctionsCreateAuctionButton:Disable()
        end
    end

    hooksecurefunc("AuctionsFrameAuctions_ValidateAuction", blockAuctionSell)
    hooksecurefunc("MoneyInputFrame_OnTextChanged", blockAuctionSell)
end)

BlizzardFunctions.PostAuction  = PostAuction -- Retail
BlizzardFunctions.StartAuction = StartAuction -- 1.12
function WHC.SetBlockAuctionSell()
    PostAuction  = BlizzardFunctions.PostAuction
    StartAuction = BlizzardFunctions.StartAuction

    if WhcAddonSettings.blockAuctionSell == 1 then
        local blockAuctionSell = function()
            printAchievementInfo(killerTraderLink, "Selling items on the auction house is blocked.")
        end
        PostAuction  = blockAuctionSell
        StartAuction = blockAuctionSell
    end
end
--endregion

--region ====== Time is Money ======
local timeIsMoneyLink = achievementLink(TabAchievements[ACHIEVEMENT_TIME_IS_MONEY])

local timeIsMoneyEventListener = CreateFrame("Frame")
timeIsMoneyEventListener:RegisterEvent("ADDON_LOADED")
timeIsMoneyEventListener:SetScript("OnEvent", function(self, event, addonName)
    addonName = addonName or arg1
    if addonName ~= "Blizzard_AuctionUI" then
        return
    end

    hooksecurefunc("AuctionFrameBrowse_Update", function()
        if WhcAddonSettings.blockAuctionBuy == 1 then
            if BrowseBidButton then
                BrowseBidButton:Disable()
            end
            if BrowseBuyoutButton then
                BrowseBuyoutButton:Disable()
            end
        end
    end)

    hooksecurefunc("AuctionFrameBid_Update", function()
        if WhcAddonSettings.blockAuctionBuy == 1 then
            if BidBidButton then
                BidBidButton:Disable()
            end
            if BidBuyoutButton then
                BidBuyoutButton:Disable()
            end
        end
    end)
end)

BlizzardFunctions.PlaceAuctionBid = PlaceAuctionBid
function WHC.SetBlockAuctionBuy()
    PlaceAuctionBid = BlizzardFunctions.PlaceAuctionBid

    if WhcAddonSettings.blockAuctionBuy == 1 then
        -- Block outgoing trade
        PlaceAuctionBid = function()
            printAchievementInfo(timeIsMoneyLink, "Buying items from the auction house is blocked.")
        end
    end
end
--endregion

--region ====== Iron Bones ======
local ironBonesLink = achievementLink(TabAchievements[ACHIEVEMENT_IRON_BONES])

-- Disable repair buttons from Blizzard interface
local disableRepairButtons = function()
    local repairItemIcon
    if MerchantRepairItemButton then
        repairItemIcon = MerchantRepairItemButton:GetRegions()
        SetDesaturation(repairItemIcon, nil)
        MerchantRepairItemButton:Enable()
    end

    if WhcAddonSettings.blockRepair == 1 then
        if MerchantRepairItemButton and repairItemIcon then
            SetDesaturation(repairItemIcon, 1)
            MerchantRepairItemButton:Disable()
        end

        if MerchantRepairAllButton then
            SetDesaturation(MerchantRepairAllIcon, 1)
            MerchantRepairAllButton:Disable()
        end
    end
end
hooksecurefunc("MerchantFrame_UpdateRepairButtons", disableRepairButtons) -- Retail
hooksecurefunc("MerchantFrame_OnShow", disableRepairButtons) -- 1.12

BlizzardFunctions.RepairAllItems = RepairAllItems
BlizzardFunctions.ShowRepairCursor = ShowRepairCursor
function WHC.SetBlockRepair()
    RepairAllItems = BlizzardFunctions.RepairAllItems
    ShowRepairCursor = BlizzardFunctions.ShowRepairCursor

    if WhcAddonSettings.blockRepair == 1 then
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
local groundedLink = achievementLink(TabAchievements[ACHIEVEMENT_GROUNDED])

local taxiServiceEventHandler = CreateFrame("Frame")
taxiServiceEventHandler:SetScript("OnEvent", function(self, event, name)
    TaxiFrame:Hide()
    printAchievementInfo(groundedLink, "Flying services are blocked.")
end)

BlizzardFunctions.TakeTaxiNode = TakeTaxiNode
function WHC.SetBlockTaxiService()
    taxiServiceEventHandler:UnregisterEvent("TAXIMAP_OPENED")
    TakeTaxiNode = BlizzardFunctions.TakeTaxiNode

    if WhcAddonSettings.blockTaxiService == 1 then
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
local misterWhiteLink = achievementLink(TabAchievements[ACHIEVEMENT_MISTER_WHITE])
local onlyFanLink = achievementLink(TabAchievements[ACHIEVEMENT_ONLY_FAN])
local selfMadeLink = achievementLink(TabAchievements[ACHIEVEMENT_SELF_MADE])

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
    ["钓鱼竿"] = true,          -- Chinese
}

local function getItemIDFromLink(itemLink)
    if not itemLink then
        return
    end

    local foundID, _ , itemID = string.find(itemLink, "item:(%d+)")
    if not foundID then
        return
    end

    return tonumber(itemID)
end

-- TODO Make this more robust
-- The <Made by xxx> is localized.
-- This pattern works for English, German, French, Spanish, Portuguese, Italian, Russian
-- This pattern will break for Korean, Chinese
local function isSelfMade()
    for i=1, GameTooltip:NumLines() do
        local left = _G["GameTooltipTextLeft"..i]
        local lineText = left:GetText()
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
    local itemId = getItemIDFromLink(itemLink)
    local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)

    if not itemEquipLoc or itemEquipLoc == "" then
        return
    end

    if WhcAddonSettings.blockMagicItems == 1 and itemRarity > 1 then
        if itemEquipLoc == "INVTYPE_BAG" then
            GameTooltip:AddLine("<Mister White: Bags of any quality can be equipped>", 0, 1, 0)
        else
            local msg = "Cannot equip ".._G["ITEM_QUALITY"..itemRarity.."_DESC"].." items>"
            GameTooltip:AddLine("<Mister White: "..msg, 1, 0, 0)
        end
    end

    if WhcAddonSettings.blockArmorItems == 1 and not onlyFanAllowedItems[itemEquipLoc] then
        GameTooltip:AddLine("<Only Fan: Cannot equip armor items>", 1, 0, 0)
    end

    if WhcAddonSettings.blockNonSelfMadeItems == 1 and not isSelfMade() then
        if selfMadeAllowedItems[itemSubType] then
            GameTooltip:AddLine("<Self-made: Fishing Poles can be equipped>", 0, 1, 0)
        elseif itemEquipLoc == "INVTYPE_BAG" then
            GameTooltip:AddLine("<Self-made: All bags can be equipped>", 0, 1, 0)
        elseif itemEquipLoc == "INVTYPE_AMMO" then
            GameTooltip:AddLine("<Self-made: All ammunition can be equipped>", 0, 1, 0)
        else
            GameTooltip:AddLine("<Self-made: Cannot equip items you did not craft>", 1, 0, 0)
        end
    end

    -- Resize the tooltip to match the new lines added
    GameTooltip:Show()
end

-- Update bag items
hooksecurefunc(GameTooltip, "SetBagItem", function(tip, bagId, slot)
    local itemLink = GetContainerItemLink(bagId, slot)
    setTooltipInfo(itemLink)
end)

-- Update bank items
hooksecurefunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
    if slot > 19 then
        local itemLink = GetInventoryItemLink(unit, slot)
        setTooltipInfo(itemLink)
    end
end)

-- Update vendor items
hooksecurefunc(GameTooltip, "SetMerchantItem", function(tip, index)
    local itemLink = GetMerchantItemLink(index)
    setTooltipInfo(itemLink)
end)

-- Update trade window items
hooksecurefunc(GameTooltip, "SetTradePlayerItem", function(tip, tradeSlot)
    local itemLink = GetTradePlayerItemLink(tradeSlot)
    setTooltipInfo(itemLink)
end)

hooksecurefunc(GameTooltip, "SetTradeTargetItem", function(tip, tradeSlot)
    local itemLink = GetTradeTargetItemLink(tradeSlot)
    setTooltipInfo(itemLink)
end)

local errorMessages = {}
local function canEquipItem(itemLink)
    errorMessages = {}

    local itemId = getItemIDFromLink(itemLink)
    local itemRarity, itemSubType, itemEquipLoc = getItemInfo(itemId)
    if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_BAG" then
        return
    end

    if WhcAddonSettings.blockMagicItems == 1 and itemRarity > 1 then
        local msg = "Equipping ".._G["ITEM_QUALITY"..itemRarity.."_DESC"].." items are blocked."
        table.insert(errorMessages, achievementErrorMessage(misterWhiteLink, msg))
    end

    if WhcAddonSettings.blockArmorItems == 1 and not onlyFanAllowedItems[itemEquipLoc] then
        table.insert(errorMessages, achievementErrorMessage(onlyFanLink, "Equipping armor items are blocked."))
    end

    if WhcAddonSettings.blockNonSelfMadeItems == 1 and not isSelfMade() and
            not selfMadeAllowedItems[itemSubType] and not selfMadeAllowedItems[itemEquipLoc] then
        table.insert(errorMessages, achievementErrorMessage(selfMadeLink, "Equipping items you did not craft are blocked."))
    end
end

local function printEquipBlockers()
    for _, value in ipairs(errorMessages) do
        DEFAULT_CHAT_FRAME:AddMessage(value)
    end
end

hooksecurefunc("PickupMerchantItem", function(index)
    local itemLink = GetMerchantItemLink(index)
    canEquipItem(itemLink)
end)

hooksecurefunc("PickupContainerItem", function(bagId, slot)
    if not CursorHasItem() then
        errorMessages = {}
        return
    end

    local itemLink = GetContainerItemLink(bagId, slot)
    canEquipItem(itemLink)
end)

BlizzardFunctions.AutoEquipCursorItem = AutoEquipCursorItem
BlizzardFunctions.EquipCursorItem     = EquipCursorItem
BlizzardFunctions.EquipPendingItem    = EquipPendingItem
BlizzardFunctions.PickupInventoryItem = PickupInventoryItem
BlizzardFunctions.UseContainerItem    = UseContainerItem
function WHC.SetBlockEquipItems()
    AutoEquipCursorItem = BlizzardFunctions.AutoEquipCursorItem
    EquipCursorItem     = BlizzardFunctions.EquipCursorItem
    EquipPendingItem    = BlizzardFunctions.EquipPendingItem
    PickupInventoryItem = BlizzardFunctions.PickupInventoryItem
    UseContainerItem    = BlizzardFunctions.UseContainerItem

    if WhcAddonSettings.blockMagicItems == 1 or WhcAddonSettings.blockArmorItems == 1 or WhcAddonSettings.blockNonSelfMadeItems == 1 then
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
            if not errorMessages[1] then
                return BlizzardFunctions.UseContainerItem(bagId, slot, onSelf)
            end

            printEquipBlockers()
        end

        -- Block pick up and place on character
        -- Block drag and place on character
        -- Note: This endpoint is both being used when placing an item onto the character and equipment page
        -- and when an item is being pickup from the character equipment page.
        PickupInventoryItem = function(slot)
            if not errorMessages[1] then
                return BlizzardFunctions.PickupInventoryItem(slot)
            end

            printEquipBlockers()
        end

        -- Block other addons
        AutoEquipCursorItem = function()
            if not errorMessages[1] then
                return BlizzardFunctions.AutoEquipCursorItem()
            end

            printEquipBlockers()
        end

        -- Block other addons
        EquipCursorItem = function()
            if not errorMessages[1] then
                return BlizzardFunctions.EquipCursorItem()
            end

            printEquipBlockers()
        end

        -- Block Bind-on-Equip pop up
        EquipPendingItem = function()
            if not errorMessages[1] then
                return BlizzardFunctions.EquipCursorItem()
            end

            printEquipBlockers()
        end
    end
end
--endregion
