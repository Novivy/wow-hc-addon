local function mathMod(a, b)
    return a - b * math.floor(a / b)
end

-- Flat solid colour fill that works on both 1.12 (SetTexture rgb) and 1.14 (SetColorTexture)
local function SolidColor(tex, r, g, b, a)
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a or 1)
    else
        tex:SetTexture(r, g, b, a or 1)
    end
end

-- Tooltip shown on hover for the Noggenfogger card(s)
local NOGGEN_TOOLTIP = "Added to your spellbook as a spell. Cast it for a permanent Skeletal Skin transformation. Lasts until you cancel the buff."

-- HC realm catalog, mirrored from services.php (realm 1, status 1).
-- image = filename in /img/services (added to Images\services as .blp/.tga); price = HC coin price.
local catalog = {
    -- Mounts
    { key = "dawnsaber",        name = "Dawnsaber",                  category = "Mounts",     image = "mount-dawnsaber",   price = 50 },
    { key = "red-raptor",       name = "Mottled Red Raptor",         category = "Mounts",     image = "mount-red-raptor",  price = 45 },
    { key = "ivory-raptor",     name = "Ivory Raptor",               category = "Mounts",     image = "mount-ivory",       price = 50 },
    { key = "tiger",            name = "Tiger",                      category = "Mounts",     image = "mount-tiger",       price = 45 },
    { key = "artic-wolf",       name = "Artic Wolf",                 category = "Mounts",     image = "mount-artic-wolf",  price = 50 },
    { key = "black-wolf",       name = "Black Wolf",                 category = "Mounts",     image = "mount-black-wolf",  price = 40 },
    { key = "violet-mech",      name = "Violet Mecha",               category = "Mounts",     image = "mount-violet-mech", price = 40 },
    { key = "green-mech",       name = "Green Mecha",                category = "Mounts",     image = "mount-fluo-mech",   price = 50 },
    { key = "palomino",         name = "Palomino",                   category = "Mounts",     image = "mount-palomino",    price = 60 },
    -- Companions
    { key = "spectral-wolf",    name = "Spectral Wolf",              category = "Companions", image = "pet-ghost",         price = 35 },
    { key = "diablo",           name = "Diablo",                     category = "Companions", image = "pet-diablo",        price = 20 },
    { key = "panda",            name = "Panda",                      category = "Companions", image = "pet-panda",         price = 20 },
    { key = "zergling",         name = "Zergling",                   category = "Companions", image = "pet-zerg",          price = 20 },
    -- Bags
    { key = "bag-20",           name = "20 Slot Bag",                category = "Bags",       image = "oneshot-bag-hc",    price = 45 },
    -- Services
    { key = "rename",           name = "Rename",                     category = "Services",   image = "rename",            price = 80 },
    { key = "account-transfer", name = "Character Account Transfer", category = "Services",   image = "account-transfer",  price = 50 },
    { key = "realm-clone",      name = "Realm Clone",                category = "Services",   image = "realm-clone",       price = "Open" },
    { key = "customization",    name = "Character Customization",    category = "Services",   image = "custom",            price = "Open" },
    { key = "noggenfogger",     name = "Noggenfogger",               category = "Services",   image = "noggen",            price = 50, tooltip = NOGGEN_TOOLTIP },
    { key = "noggenfogger-mnt", name = "Noggenfogger",               category = "Mounts",     image = "noggen",            price = 50, tooltip = NOGGEN_TOOLTIP },
    { key = "noggenfogger-pet", name = "Noggenfogger",               category = "Companions", image = "noggen",            price = 50, tooltip = NOGGEN_TOOLTIP },
}

-- Subscription tiers, mirrored from api
local subscriptions = {
    {
        level = "LEVEL 1", price = "5.90", normalPrice = nil,
        perks = {
            { icon = "murloc-green", name = "Green Murloc",       desc = "Baby murloc companion that follows you around." },
            { icon = "portal",       name = "City Teleport",      desc = "Access to your faction city portals (1h30 cooldown)." },
            { icon = "bag-1",        name = "18 Slot Bag",        desc = "Special 18 slot bag for each character (BoP, Unique)." },
            { icon = "tier-1-sub",   name = "Animated Avatar",    desc = "Special rank and animated avatar on the forums." },
        },
    },
    {
        level = "LEVEL 2", price = "12.99", normalPrice = nil,
        perks = {
            { icon = "murloc-orange", name = "2 Murlocs",          desc = "Two baby murloc companions that follow you around." },
            { icon = "portal",        name = "City Teleport",      desc = "Access to your faction city portals (1h cooldown)." },
            { icon = "dualspec",      name = "Free Dual Spec.",    desc = "Free for each character at any Innkeeper (requires Lvl 40)." },
            { icon = "trainer",       name = "Profession Trainers", desc = "Access all profession trainers, bank and mailbox on Murloc Island." },
            { icon = "bank",          name = "3 Free Bank Slots",  desc = "First 3 bank slots unlocked by default on each character." },
            { icon = "bag-1",         name = "2 x 18 Slot Bag",    desc = "Two 18 slot bags for each character." },
            { icon = "bag",           name = "20 Slot Bag",        desc = "Special 20 slot bag for each character (BoP, Unique)." },
            { icon = "tabard-frost",  name = "Tabard of Frost",    desc = "Unique tabard formerly from the WoW Trading Card Game." },
            { icon = "tier-2-sub",    name = "Animated Avatar",    desc = "Special rank and animated avatar on the forums." },
            { icon = "discount-5",    name = "+5% HC Coins",       desc = "5% bonus HC coins on every coin purchase." },
        },
    },
    {
        level = "LEVEL 3", price = "16.42", normalPrice = nil,
        perks = {
            { icon = "murloc-blue",  name = "3 Murlocs",          desc = "Three baby murloc companions that follow you around." },
            { icon = "portal",       name = "City Teleport",      desc = "Access to your faction city portals (30 min cooldown)." },
            { icon = "summon",       name = "Summon a Friend",    desc = "Summon a supporter (Tier 1 or higher) to your location (30 min cooldown)." },
            { icon = "recall",       name = "Recall",             desc = "Teleport back to your last location before using City Teleport." },
            { icon = "dualspec",     name = "Free Dual Spec.",    desc = "Free for each character at any Innkeeper (requires Lvl 40)." },
            { icon = "trainer",      name = "Profession Trainers", desc = "Access all profession trainers, bank and mailbox on Murloc Island." },
            { icon = "bank",         name = "5 Free Bank Slots",  desc = "First 5 bank slots unlocked by default on each character." },
            { icon = "bag",          name = "4 x 20 Slot Bag",    desc = "Four 20 slot bags for each character." },
            { icon = "ah",           name = "Auction House",      desc = "Access the Auction House from anywhere (read/buy only)." },
            { icon = "nightsaber",   name = "Nightsaber Mount",   desc = "Speed adapts to your riding skill (60% or 100%)." },
            { icon = "tabard-frost", name = "Tabard of Frost",    desc = "Unique tabard formerly from the WoW Trading Card Game." },
            { icon = "tabard-flame", name = "Tabard of Flame",    desc = "Unique tabard formerly from the WoW Trading Card Game." },
            { icon = "tier-3-sub",   name = "Animated Avatar",    desc = "Special rank and animated avatar on the forums." },
            { icon = "discount-10",  name = "+10% HC Coins",      desc = "10% bonus HC coins on every coin purchase." },
        },
    },
}

local categoryOrder = { "Subscriptions", "Bags", "Mounts", "Companions", "Services", "Donate" }

-- Per-category blurb
local categoryDesc = {
    Mounts = "Mount speed adjusts to your riding skill (60% or 100%).\nDelivered to your spellbook (no bag space).\nYou still need the Riding skill to use it.",
    Companions = "A passive companion that follows you around. Delivered to your spellbook (no bag space), works like any other spell.",
    Bags = "Extra bag space for your character, delivered to your mailbox.",
    Services = "Account services: rename, character & account transfer, realm clone and appearance customization.",
    Subscriptions = "Support the server each month and unlock in-game rewards for every character. Hover a perk for details.",
}

-- Card grid metrics (3 per row)
local CARD_W = 132
local CARD_H = 188
local IMG_H = 124 -- = CARD_W - 8 (insets) so the square art is not stretched
local COL_STEP = 142
local ROW_STEP = 202

local GOLD = { 0.631, 0.459, 0 }

-- Subscription tier border colours, matching the front
local TIER_BORDER = {
    { 0.298, 0.525, 0.000 }, -- #4c8600 green
    { 0.000, 0.439, 0.698 }, -- #0070b2 blue
    { 0.494, 0.000, 0.690 }, -- #7e00b0 purple
}

-- Server reply to ".whc coins" (::whc::coins:<n>) updates the coin box
function WHC.OnCoinsReceived(coins)
    WHC.player.coins = coins
    if WHC.Frames.ShopCoins then
        WHC.Frames.ShopCoins:SetText(coins)
    end
end

-- One shop card
local function CreateCard(parent, item)
    local card = CreateFrame("Frame", nil, parent, RETAIL_BACKDROP)
    card:SetWidth(CARD_W)
    card:SetHeight(CARD_H)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.129, 0.110, 0.094, 0.95) -- dark card background
    card:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])

    -- Image background (dark maroon)
    local imgBg = card:CreateTexture(nil, "BACKGROUND")
    imgBg:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    imgBg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -4, -4)
    imgBg:SetHeight(IMG_H)
    SolidColor(imgBg, 0.208, 0.086, 0.082) -- maroon

    -- Art, transparent over the maroon background
    local art = card:CreateTexture(nil, "ARTWORK")
    art:SetAllPoints(imgBg)
    art:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\services\\" .. item.image)

    -- Name bar
    local nameBar = card:CreateTexture(nil, "ARTWORK")
    nameBar:SetPoint("TOPLEFT", imgBg, "BOTTOMLEFT", 0, -3)
    nameBar:SetPoint("TOPRIGHT", imgBg, "BOTTOMRIGHT", 0, -3)
    nameBar:SetHeight(24)
    SolidColor(nameBar, 0, 0, 0, 0.3)

    local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", nameBar, "LEFT", 3, 0)
    name:SetPoint("RIGHT", nameBar, "RIGHT", -3, 0)
    name:SetText(item.name)
    name:SetTextColor(0.937, 0.886, 0.808)

    -- Buy button - standard UIPanelButtonTemplate (same style as the PVP tab)
    local buy = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    buy:SetWidth(116)
    buy:SetHeight(26)
    buy:SetPoint("BOTTOM", card, "BOTTOM", 0, 6)
    if type(item.price) == "number" then
        buy:SetText(item.price)
        local fs = buy:GetFontString()
        local coin = buy:CreateTexture(nil, "OVERLAY")
        coin:SetWidth(24)
        coin:SetHeight(24)
        coin:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\hc-coin")
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", buy, "CENTER", 9, 0)
            coin:SetPoint("RIGHT", fs, "LEFT", -7, 0)
        else
            coin:SetPoint("CENTER", buy, "CENTER", -14, 0)
        end
    else
        buy:SetText(item.price)
    end
    buy:SetScript("OnClick", function()
        WHC.ShowUrlPopup("Visit the shop to purchase", "https://wow-hc.com/shop")
    end)

    if item.tooltip then
        card:EnableMouse(true)
        card:SetScript("OnEnter", function()
            GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
            GameTooltip:SetText(item.name, 1, 0.82, 0)
            GameTooltip:AddLine(item.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    card.category = item.category
    return card
end

-- Subscriptions view: one panel per tier (name, price, Subscribe, perk list)
local function CreateSubscriptions(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(444)

    local maxHeight = 0
    for t, sub in ipairs(subscriptions) do
        local col = CreateFrame("Frame", nil, container, RETAIL_BACKDROP)
        col:SetWidth(134)
        col:SetPoint("TOPLEFT", container, "TOPLEFT", 14 + (t - 1) * 142, -4)
        col:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        col:SetBackdropColor(0.129, 0.110, 0.094, 0.95)
        col:SetBackdropBorderColor(TIER_BORDER[t][1], TIER_BORDER[t][2], TIER_BORDER[t][3])

        local lvl = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lvl:SetPoint("TOP", col, "TOP", 0, -8)
        lvl:SetText(sub.level)
        lvl:SetTextColor(0.961, 0.745, 0)

        local price = col:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        price:SetPoint("TOP", lvl, "BOTTOM", 0, -5)
        if sub.normalPrice then
            price:SetText("|cff8a8a8a" .. sub.normalPrice .. "|r  " .. sub.price .. " EUR/mo")
        else
            price:SetText(sub.price .. " EUR/mo")
        end

        local subscribe = CreateFrame("Button", nil, col, "UIPanelButtonTemplate")
        subscribe:SetWidth(120)
        subscribe:SetHeight(22)
        subscribe:SetPoint("TOP", price, "BOTTOM", 0, -6)
        subscribe:SetText("Subscribe")
        subscribe:SetScript("OnClick", function()
            WHC.ShowUrlPopup("Visit the shop to subscribe", "https://wow-hc.com/shop")
        end)

        local y = -76
        local count = 0
        for _, perk in ipairs(sub.perks) do
            local row = CreateFrame("Button", nil, col)
            row:SetWidth(124)
            row:SetHeight(19)
            row:SetPoint("TOPLEFT", col, "TOPLEFT", 5, y)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints(row)
            if mathMod(count, 2) == 0 then
                SolidColor(rowBg, 1, 1, 1, 0.05)
            else
                SolidColor(rowBg, 0, 0, 0, 0.25)
            end

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetWidth(16)
            icon:SetHeight(16)
            icon:SetPoint("LEFT", row, "LEFT", 0, 0)
            icon:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\services\\" .. perk.icon)

            local pname = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pname:SetPoint("LEFT", icon, "RIGHT", 4, 0)
            pname:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            pname:SetJustifyH("LEFT")
            pname:SetText(perk.name)
            pname:SetTextColor(0.874, 0.835, 0.776)

            local title = perk.name
            local body = perk.desc
            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(title, 1, 0.82, 0)
                GameTooltip:AddLine(body, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            count = count + 1
            y = y - 19
        end

        local colHeight = 76 + count * 19 + 8
        col:SetHeight(colHeight)
        if colHeight > maxHeight then
            maxHeight = colHeight
        end
    end

    container:SetHeight(maxHeight + 8)
    return container
end

-- "Kind Soul" donation modal
local DONATE_BODY =
    "Some of you have asked how to give back without wanting anything for it.\n\n" ..
    "There are no coins, no perks and no rewards tied to it. Just our gratitude, and a world that stays online for everyone.\n\n" ..
    "If that sounds like you, thank you."

function WHC.ShowDonatePopup()

    if WHC.Frames.DonateModal then
        WHC.Frames.DonateModal:Show()
        return
    end

    local frame = CreateFrame("Frame", "WhcDonateModal", UIParent, RETAIL_BACKDROP)
    frame:SetWidth(360)
    frame:SetHeight(220)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(20)
    frame:EnableMouse(true)

    local fill = frame:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -12)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 11)
    SolidColor(fill, 0.04, 0.04, 0.04, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetFont("Fonts\\FRIZQT__.TTF", 18)
    title:SetText("Kind Soul")
    title:SetTextColor(0.961, 0.745, 0)

    local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOP", title, "BOTTOM", 0, -14)
    body:SetWidth(308)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetText(DONATE_BODY)
    body:SetTextColor(0.874, 0.835, 0.776)

    local donate = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    donate:SetWidth(130)
    donate:SetHeight(26)
    donate:SetPoint("BOTTOM", frame, "BOTTOM", 0, 50)
    donate:SetText("I'm a Kind Soul")
    donate:SetScript("OnClick", function()
        frame:Hide()
        WHC.ShowUrlPopup("Visit the shop to donate", "https://wow-hc.com/shop")
    end)

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetWidth(130)
    close:SetHeight(26)
    close:SetPoint("BOTTOM", frame, "BOTTOM", 0, 18)
    close:SetText("Close")
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    WHC.Frames.DonateModal = frame
    frame:Show()
end

function WHC.Tab_Shop(content)
    -- Per-category description (replaces the static title/disclaimer)
    local catTitle = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    catTitle:SetPoint("TOP", content, "TOP", 0, -6)
    catTitle:SetFont("Fonts\\FRIZQT__.TTF", 16)
    catTitle:SetTextColor(0.933, 0.765, 0)

    local catDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    catDesc:SetPoint("TOP", catTitle, "BOTTOM", 0, -2)
    catDesc:SetWidth(340)
    catDesc:SetHeight(38)
    catDesc:SetJustifyH("CENTER")
    catDesc:SetTextColor(0.874, 0.835, 0.776)

    -- Card panel background
    local panel = CreateFrame("Frame", nil, content, RETAIL_BACKDROP)
    panel:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -62)
    panel:SetWidth(486)
    panel:SetHeight(339)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Scrollable card area
    local scrollFrame = CreateFrame("ScrollFrame", "WhcShopScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(450)
    scrollFrame:SetHeight(326)
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -9)

    local scrollChild = CreateFrame("Frame", "WhcShopScrollChild", scrollFrame)
    scrollChild:SetWidth(444)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Smaller mouse-wheel scroll step
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        delta = delta or arg1
        local newScroll = scrollFrame:GetVerticalScroll() - (delta * 42)
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if newScroll < 0 then
            newScroll = 0
        elseif newScroll > maxScroll then
            newScroll = maxScroll
        end
        scrollFrame:SetVerticalScroll(newScroll)
        local sb = getglobal("WhcShopScrollScrollBar")
        if sb then
            sb:SetValue(newScroll)
        end
    end)

    -- Subscriptions view (3 tiers), shown for the Subscriptions category
    local subsFrame = CreateSubscriptions(scrollChild)
    subsFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    subsFrame:Hide()

    -- Build one card per catalog item (positioned per category below)
    local itemFrames = {}
    for _, item in ipairs(catalog) do
        local card = CreateCard(scrollChild, item)
        card:Hide()
        table.insert(itemFrames, card)
    end

    local menuButtons = {}

    local function ShowCategory(cat)
        catTitle:SetText(cat)
        catDesc:SetText(categoryDesc[cat] or "")

        -- Reset the scroll back to the top when switching category
        scrollFrame:SetVerticalScroll(0)
        local scrollBar = getglobal("WhcShopScrollScrollBar")
        if scrollBar then
            scrollBar:SetValue(0)
        end

        for _, c in ipairs(categoryOrder) do
            if menuButtons[c] then
                if c == cat then
                    menuButtons[c].text:SetTextColor(1, 1, 1)
                else
                    menuButtons[c].text:SetTextColor(0.933, 0.765, 0)
                end
            end
        end

        for _, card in ipairs(itemFrames) do
            card:Hide()
        end
        subsFrame:Hide()

        if cat == "Subscriptions" then
            subsFrame:Show()
            scrollChild:SetHeight(subsFrame:GetHeight())
            return
        end

        local shown = 0
        for _, card in ipairs(itemFrames) do
            if card.category == cat then
                local col = mathMod(shown, 3)
                local row = math.floor(shown / 3)
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 16 + col * COL_STEP, -10 - (row * ROW_STEP))
                card:Show()
                shown = shown + 1
            end
        end

        local rows = math.ceil(shown / 3)
        scrollChild:SetHeight(math.max(1, rows * ROW_STEP + 20))
    end

    -- Category menu, anchored just outside the window on the left
    local menu = CreateFrame("Frame", "WhcShopCategoryMenu", content, RETAIL_BACKDROP)
    menu:SetWidth(116)
    menu:SetHeight(204)
    menu:SetPoint("TOPRIGHT", WHC, "TOPLEFT", 4, -34)
    menu:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    menu:SetBackdropColor(0, 0, 0, 1)

    local titleBg = menu:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", menu, "TOPLEFT", 9, -9)
    titleBg:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -10, -9)
    titleBg:SetHeight(24)
    SolidColor(titleBg, 0, 0, 0, 0.5)

    local titleLine = menu:CreateTexture(nil, "ARTWORK")
    titleLine:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)
    titleLine:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
    titleLine:SetHeight(1)
    SolidColor(titleLine, GOLD[1], GOLD[2], GOLD[3], 0.6)

    local menuTitle = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    menuTitle:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
    menuTitle:SetText("Shop")
    menuTitle:SetTextColor(1, 1, 1)

    for i, cat in ipairs(categoryOrder) do
        local btn = CreateFrame("Button", nil, menu)
        btn:SetWidth(104)
        btn:SetHeight(24)
        btn:SetPoint("TOP", menu, "TOP", 0, -34 - (i - 1) * 26)

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetAllPoints(btn)
        highlight:SetBlendMode("ADD")

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(cat)
        btnText:SetTextColor(0.933, 0.765, 0)
        btn.text = btnText

        local category = cat
        btn:SetScript("OnClick", function()
            PlaySound(WHC.sounds.selectTab)
            if category == "Donate" then
                WHC.ShowDonatePopup()
            else
                ShowCategory(category)
            end
        end)

        menuButtons[cat] = btn
    end

    -- Coin balance box, above the category menu (same style)
    local coinBox = CreateFrame("Frame", "WhcShopCoinBox", content, RETAIL_BACKDROP)
    coinBox:SetWidth(116)
    coinBox:SetHeight(38)
    coinBox:SetPoint("TOPRIGHT", WHC, "TOPLEFT", 4, 0)
    coinBox:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    coinBox:SetBackdropColor(0, 0, 0, 1)

    local coinIcon = coinBox:CreateTexture(nil, "ARTWORK")
    coinIcon:SetWidth(26)
    coinIcon:SetHeight(26)
    coinIcon:SetPoint("LEFT", coinBox, "LEFT", 14, 0)
    coinIcon:SetTexture("Interface\\AddOns\\WOW_HC\\Images\\hc-coin")

    local coinText = coinBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    coinText:SetPoint("LEFT", coinIcon, "RIGHT", 8, 0)
    coinText:SetText(WHC.player.coins or "...")
    coinText:SetTextColor(0.961, 0.745, 0)
    WHC.Frames.ShopCoins = coinText

    -- "+" button to buy more coins (opens the website shop)
    local addCoins = CreateFrame("Button", nil, coinBox, "UIPanelButtonTemplate")
    addCoins:SetWidth(22)
    addCoins:SetHeight(22)
    addCoins:SetPoint("RIGHT", coinBox, "RIGHT", -9, 0)
    addCoins:SetText("+")
    addCoins:SetScript("OnClick", function()
        WHC.ShowUrlPopup("Visit the shop to buy coins", "https://wow-hc.com/shop")
    end)
    addCoins:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addCoins, "ANCHOR_RIGHT")
        GameTooltip:SetText("Buy more coins", 1, 1, 1)
        GameTooltip:Show()
    end)
    addCoins:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ShowCategory("Mounts")

    return content
end
