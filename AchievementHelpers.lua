local ACHIEVEMENT_COLOR_CODE = "|cffff8000";
local addonPrefix = ACHIEVEMENT_COLOR_CODE.."[WOW-HC.com]: "..FONT_COLOR_CODE_CLOSE

local function achievementLink(achievement)
    return ACHIEVEMENT_COLOR_CODE.."|Hitem:"..achievement.itemId..":0:0:0|h["..achievement.name.."]|h"..FONT_COLOR_CODE_CLOSE
end

local function printAchievementInfo(link, message)
    local achievementMsg = link..HIGHLIGHT_FONT_COLOR_CODE.." Achievement active. "
    DEFAULT_CHAT_FRAME:AddMessage(addonPrefix..achievementMsg..message..FONT_COLOR_CODE_CLOSE)
end

local _G = getfenv(0);
local function hooksecurefunc(arg1, arg2, arg3)
    if type(arg1) == "string" then
        arg1, arg2, arg3 = _G, arg1, arg2
    end
    local orig = arg1[arg2]
    arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        if arg2 ~= "UnitPopup_OnUpdate" and arg2 ~= "SetBagItem" then
            WHC.DebugPrint("Original "..arg2)
        end
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        if arg2 ~= "UnitPopup_OnUpdate" and arg2 ~= "SetBagItem" then
            WHC.DebugPrint("Hook "..arg2)
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

local onlyFanAllowedItems = {}
onlyFanAllowedItems.INVTYPE_WEAPON = true
onlyFanAllowedItems.INVTYPE_2HWEAPON = true
onlyFanAllowedItems.INVTYPE_WEAPONMAINHAND = true
onlyFanAllowedItems.INVTYPE_WEAPONOFFHAND = true
onlyFanAllowedItems.INVTYPE_SHIELD = true
onlyFanAllowedItems.INVTYPE_THROWN = true
onlyFanAllowedItems.INVTYPE_RANGED = true
onlyFanAllowedItems.INVTYPE_AMMO = true
onlyFanAllowedItems.INVTYPE_RANGEDRIGHT = true -- Wands
onlyFanAllowedItems.INVTYPE_HOLDABLE = true -- Held in offhand
onlyFanAllowedItems.INVTYPE_TABARD = true
onlyFanAllowedItems.INVTYPE_BAG = true

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
-- This can fail is player 1 is named "Dave" and player 2 is named "Davedos"
-- The player "Dave" will get a false positive match on an item from "Davedos"
-- To correctly handle this I need to know the format of the <Made by ...> text in every translation.
local function isSelfMade()
    for i=1, GameTooltip:NumLines() do
        local left = getglobal("GameTooltipTextLeft"..i)
        local lineText = left:GetText()
        local nameMatch = string.find(lineText, "<.*("..WHC.player.name..").*>")
        if nameMatch then
            return true
        end
    end

    return false
end

local function setEquipmentInfo(itemLink)
    local itemId = getItemIDFromLink(itemLink)
    if itemId == nil then
        return
    end

    -- 1.12
    local _, _, itemRarity, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
    if RETAIL == 1 then
        _, _, itemRarity, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
    end

    if itemEquipLoc == "" then
        return
    end

    if WhcAddonSettings.blockMagicItems == 1 and itemRarity > 1 then
        if itemEquipLoc == "INVTYPE_BAG" then
            GameTooltip:AddLine("<Mister White: Bags of any quality can be equipped>", 0, 1, 0)
        else
            GameTooltip:AddLine("<Mister White: Cannot equip magic items>", 1, 0, 0)
        end
    end

    if WhcAddonSettings.blockArmorItems == 1 and not onlyFanAllowedItems[itemEquipLoc] then
        GameTooltip:AddLine("<Only Fan: Cannot equip armor items>", 1, 0, 0)
    end

    if WhcAddonSettings.blockNonSelfMadeItems == 1 and not isSelfMade() then
        if itemSubType == "Fishing Pole" then -- localized according to documentation. Will need a static value for proper matching
            GameTooltip:AddLine("<Self-made: Fishing Poles can be equipped>", 0, 1, 0)
        elseif itemEquipLoc == "INVTYPE_BAG" then
            GameTooltip:AddLine("<Self-made: All bags from everywhere can be equipped>", 0, 1, 0)
        else
            GameTooltip:AddLine("<Self-made: Cannot equip items you did not craft>", 1, 0, 0)
        end
    end

    -- Resize the tooltip to match the new lines added
    GameTooltip:Show()
end

-- Update bag items
hooksecurefunc(GameTooltip, "SetBagItem", function(tip, bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    setEquipmentInfo(itemLink)
end)

-- Update bank items
hooksecurefunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
    if slot > 19 then
        local itemLink = GetInventoryItemLink(unit, slot)
        setEquipmentInfo(itemLink)
    end
end)

-- Update trade window items
hooksecurefunc(GameTooltip, "SetTradePlayerItem", function(tip, tradeSlot)
    local itemLink = GetTradePlayerItemLink(tradeSlot)
    setEquipmentInfo(itemLink)
end)

hooksecurefunc(GameTooltip, "SetTradeTargetItem", function(tip, tradeSlot)
    local itemLink = GetTradeTargetItemLink(tradeSlot)
    setEquipmentInfo(itemLink)
end)

hooksecurefunc("AutoEquipCursorItem", function()  end)
hooksecurefunc("EquipCursorItem", function()  end)
hooksecurefunc("EquipPendingItem", function()  end)
hooksecurefunc("UseContainerItem", function()  end)
hooksecurefunc("PickupContainerItem", function()  end)
hooksecurefunc("CursorHasItem", function()  end)

BlizzardFunctions.AutoEquipCursorItem = AutoEquipCursorItem
BlizzardFunctions.EquipCursorItem = EquipCursorItem
BlizzardFunctions.EquipPendingItem = EquipPendingItem
BlizzardFunctions.UseContainerItem = UseContainerItem
function WHC.SetBlockEquipItems()

end

function WHC.SetBlockMagicItems()

end

function WHC.SetBlockArmorItems()

end

-- bag, bank, trade
function WHC.SetBlockNonSelfMadeItems()

end
--endregion
