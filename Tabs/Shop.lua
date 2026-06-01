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
    { key = "noggenfogger",     name = "Noggenfogger",               category = "Services",   image = "noggen",            price = 50 },
    { key = "noggenfogger-mnt", name = "Noggenfogger",               category = "Mounts",     image = "noggen",            price = 50 },
    { key = "noggenfogger-pet", name = "Noggenfogger",               category = "Companions", image = "noggen",            price = 50 },
}

local categoryOrder = { "Subscriptions", "Bags", "Mounts", "Companions", "Services" }

-- Per-category blurb
local categoryDesc = {
    Mounts = "Mount speed adjusts to your riding skill (60% or 100%).\nDelivered to your spellbook (no bag space).\nYou still need the Riding skill to use it.",
    Companions = "A passive companion that follows you around. Delivered to your spellbook (no bag space), works like any other spell.",
    Bags = "Extra bag space for your character, delivered to your mailbox.",
    Services = "Account services: rename, character & account transfer, realm clone and appearance customization.",
    Subscriptions = "",
}

-- Card grid metrics (3 per row)
local CARD_W = 132
local CARD_H = 188
local IMG_H = 124 -- = CARD_W - 8 (insets) so the square art is not stretched
local COL_STEP = 142
local ROW_STEP = 202

local GOLD = { 0.631, 0.459, 0 }

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

    card.category = item.category
    return card
end

function WHC.Tab_Shop(content)
    -- Per-category description (replaces the static title/disclaimer)
    local catDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    catDesc:SetPoint("TOP", content, "TOP", 0, -3)
    catDesc:SetWidth(390)
    catDesc:SetHeight(50)
    catDesc:SetJustifyH("CENTER")
    catDesc:SetTextColor(0.874, 0.835, 0.776)

    -- Card panel background
    local panel = CreateFrame("Frame", nil, content, RETAIL_BACKDROP)
    panel:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -57)
    panel:SetWidth(486)
    panel:SetHeight(344)
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
    scrollFrame:SetHeight(331)
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

    local placeholder = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    placeholder:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    placeholder:SetText("Coming soon")
    placeholder:Hide()

    -- Build one card per catalog item (positioned per category below)
    local itemFrames = {}
    for _, item in ipairs(catalog) do
        local card = CreateCard(scrollChild, item)
        card:Hide()
        table.insert(itemFrames, card)
    end

    local menuButtons = {}

    local function ShowCategory(cat)
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
        placeholder:Hide()

        if cat == "Subscriptions" then
            placeholder:Show()
            scrollChild:SetHeight(1)
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
    menu:SetHeight(178)
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

    local menuTitle = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    menuTitle:SetPoint("TOP", menu, "TOP", 0, -14)
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
            ShowCategory(category)
            PlaySound(WHC.sounds.selectTab)
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
