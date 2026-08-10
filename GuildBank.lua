-- WOW_HC Guild Bank window. Talks to the server exclusively through
-- ".whc gb ..." commands and "::whc::gb:" system-message pushes (see
-- src/game/GuildBank/ server-side). Works on 1.12 (Lua 5.0) and 1.14.
-- Layout replicates the WotLK guild bank (769x444, 7 columns x 14 slots,
-- 6 side tabs) using the extracted Blizzard textures in Images\guildbank\.

WHC.GB = {}
local GB = WHC.GB

local TEX = "Interface\\AddOns\\WOW_HC\\Images\\guildbank\\"
local ICONS = "Interface\\Icons\\"
local MAX_TABS = 6
local SLOTS = 98
local MONEY_TAB = 6
local OP_THROTTLE = 0.4

local QUALITY_COLORS = {
    [0] = "|cff9d9d9d", [1] = "|cffffffff", [2] = "|cff1eff00",
    [3] = "|cff0070dd", [4] = "|cffa335ee", [5] = "|cffff8000", [6] = "|cffe6cc80",
}

local GB_ERRORS = {
    [1]  = "You are not in a guild.",
    [2]  = "You must be at a banker to do that.",
    [3]  = "You don't have permission to do that.",
    [4]  = "That guild bank tab does not exist.",
    [5]  = "Invalid slot.",
    [6]  = "Item not found.",
    [7]  = "That slot is occupied.",
    [8]  = "Those items cannot be stacked together.",
    [9]  = "Invalid amount.",
    [10] = "That item cannot be stored in the guild bank.",
    [11] = "No room.",
    [12] = "You do not have enough money.",
    [13] = "The guild bank does not hold that much money.",
    [14] = "You have reached your daily withdrawal limit.",
    [15] = "All guild bank tabs have been purchased.",
    [16] = "Please wait a moment.",
    [17] = "You cannot carry that much money.",
    [18] = "Internal error.",
    [19] = "You must be at a banker to deposit, withdraw or move items.",
    [20] = "Guild bank session expired. Reopen the guild bank.",
    [21] = "You must be at a guild banker. (Tier 3 Supporters can view the guild bank remotely.)",
    [22] = "Guild banks are currently disabled.",
    [23] = "You cannot change the permissions of your own rank or a higher one.",
    [24] = "Items cannot be moved between guild bank tabs.",
}

-- ---------------------------------------------------------------------------
-- state
-- ---------------------------------------------------------------------------
GB.state = {
    mode = "closed",            -- closed | full | ro
    money = 0,
    numTabs = 0,
    isManager = false,
    grights = 0,
    goldRemain = 0,
    nextTabCost = 0,
    tabs = {},                  -- [tabId] = {view, dep, move, stacksRemain, icon, name}
    items = {},                 -- [tabId][slot] = {id, count, quality, maxStack, rand, ench, icon, name}
    tabText = {},               -- [tabId] = string
    logs = {},                  -- [tabId] = { {type, itemOrMoney, count, destTab, age, icon, who}, ... }
    ranks = {},                 -- [rid] = {rights, goldPerDay, tabs={[t]={rights, stacks}}, name}
    rankOrder = {},
    curTab = 0,
    view = "bank",              -- bank | log | moneylog | info
}
GB.pendingTabs = nil
GB.pendingItems = nil
GB.pendingLogs = nil
GB.pendingRanks = nil
GB.pendingText = nil
GB.cursorBag = nil              -- last real bag pickup {bag, slot} (1.12 has no GetCursorInfo)
GB.picked = nil                 -- virtual bank cursor {tab, slot, count, icon}
GB.lastOp = 0
GB.rows = {}
GB.slotButtons = {}
GB.tabButtons = {}

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function Send(cmd)
    SendChatMessage(".whc gb " .. cmd, "WHISPER", GetDefaultLanguage(), UnitName("player"))
end

local function Throttled()
    local now = GetTime()
    if now - GB.lastOp < OP_THROTTLE then
        return true
    end
    GB.lastOp = now
    return false
end

-- no addon prefix; normal guild-bank messages are yellow, errors are red
local function Msg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00" .. text .. "|r")
end

local function ErrMsg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff2020" .. text .. "|r")
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(text, 1.0, 0.1, 0.1, 1.0)
    end
end

-- coin icon textures shipped with the addon (Images\guildbank\ui-*icon.blp)
local COIN_TEX = {
    gold   = TEX .. "ui-goldicon",
    silver = TEX .. "ui-silvericon",
    copper = TEX .. "ui-coppericon",
}

-- inline coin icons work on 1.14 only; 1.12 has no |T escapes, falls back to letters
local function FormatMoney(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - gold * 10000) / 100)
    local c = copper - gold * 10000 - silver * 100
    local out = ""
    if WHC.client and WHC.client.is1_14 then
        if gold > 0 then out = out .. gold .. "|T" .. COIN_TEX.gold .. ":12:12:2:0|t " end
        if silver > 0 or gold > 0 then out = out .. silver .. "|T" .. COIN_TEX.silver .. ":12:12:2:0|t " end
        out = out .. c .. "|T" .. COIN_TEX.copper .. ":12:12:2:0|t"
        return out
    end
    if gold > 0 then out = out .. "|cffffd700" .. gold .. "g|r " end
    if silver > 0 or gold > 0 then out = out .. "|cffc7c7cf" .. silver .. "s|r " end
    out = out .. "|cffeda55f" .. c .. "c|r"
    return out
end

-- money display with REAL coin textures (works on both clients): "147 [g] 1 [s] 46 [c]"
local function CreateMoneyDisplay(parent, rightAligned)
    local md = CreateFrame("Frame", nil, parent)
    md:SetWidth(150); md:SetHeight(16)
    local function coin(tex)
        local t = md:CreateTexture(nil, "OVERLAY")
        t:SetTexture(COIN_TEX[tex])
        t:SetWidth(14); t:SetHeight(14)
        return t
    end
    local function num()
        return md:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    end
    md.g, md.s, md.c = num(), num(), num()
    md.gi, md.si, md.ci = coin("gold"), coin("silver"), coin("copper")
    if rightAligned then
        md.ci:SetPoint("RIGHT", md, "RIGHT", 0, 0)
        md.c:SetPoint("RIGHT", md.ci, "LEFT", -1, 0)
        md.si:SetPoint("RIGHT", md.c, "LEFT", -5, 0)
        md.s:SetPoint("RIGHT", md.si, "LEFT", -1, 0)
        md.gi:SetPoint("RIGHT", md.s, "LEFT", -5, 0)
        md.g:SetPoint("RIGHT", md.gi, "LEFT", -1, 0)
    else
        md.g:SetPoint("LEFT", md, "LEFT", 0, 0)
        md.gi:SetPoint("LEFT", md.g, "RIGHT", 1, 0)
        md.s:SetPoint("LEFT", md.gi, "RIGHT", 5, 0)
        md.si:SetPoint("LEFT", md.s, "RIGHT", 1, 0)
        md.c:SetPoint("LEFT", md.si, "RIGHT", 5, 0)
        md.ci:SetPoint("LEFT", md.c, "RIGHT", 1, 0)
    end
    md.SetMoney = function(self2, copper)
        copper = tonumber(copper) or 0
        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper - gold * 10000) / 100)
        local c = copper - gold * 10000 - silver * 100
        md.g:SetText(gold)
        md.s:SetText(silver)
        md.c:SetText(c)
    end
    return md
end

-- tab prices are always whole gold: no silver/copper noise.
-- 1.14 embeds the real gold-coin icon; 1.12 has no |T texture escapes, so it
-- falls back to the colored "g" suffix.
local function FormatGold(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    if WHC.client and WHC.client.is1_14 then
        return "|cffffd700" .. gold .. "|r|T" .. COIN_TEX.gold .. ":14:14:2:0|t"
    end
    return "|cffffd700" .. gold .. "g|r"
end

local function FormatAge(secs)
    secs = tonumber(secs) or 0
    if secs < 60 then return secs .. " sec ago" end
    if secs < 3600 then return math.floor(secs / 60) .. " min ago" end
    if secs < 86400 then return math.floor(secs / 3600) .. " hours ago" end
    return math.floor(secs / 86400) .. " days ago"
end

-- split a separator-delimited payload; keeps empty fields.
-- sep is the LITERAL separator character (e.g. "^"), escaped internally.
-- 1.12 (Lua 5.0) only has string.gfind; 1.14 keeps string.gfind as an
-- error-throwing deprecation stub, so gmatch MUST win when both exist
local strGmatch = string.gmatch or string.gfind
local function Split(payload, sep)
    local out = {}
    local esc = "%" .. sep
    local pattern = "([^" .. esc .. "]*)" .. esc
    local rest = payload .. sep
    for field in strGmatch(rest, pattern) do
        table.insert(out, field)
    end
    return out
end

local function IsFull()
    return GB.state.mode == "full"
end

local function OpenSplit(count, owner)
    if StackSplitFrame and StackSplitFrame.OpenStackSplitFrame then
        StackSplitFrame:OpenStackSplitFrame(count, owner, "BOTTOMLEFT", "TOPLEFT")
    else
        OpenStackSplitFrame(count, owner, "BOTTOMLEFT", "TOPLEFT")
    end
end

local function CheckFull()
    if not IsFull() then
        ErrMsg(GB_ERRORS[19])
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- window construction
-- ---------------------------------------------------------------------------
function WHC.InitializeGuildBank()
    local f = CreateFrame("Frame", "WhcGuildBank", UIParent, RETAIL_BACKDROP)
    GB.frame = f
    f:SetWidth(769)
    f:SetHeight(444)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -60)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:SetScript("OnHide", function()
        Send("close")
        GB.state.mode = "closed"
        GB.ClearPicked()
        GB.RefreshBagHooks()        -- restore protected container fns (untaint 1.14)
    end)
    f:Hide()
    tinsert(UISpecialFrames, "WhcGuildBank")

    -- background art: two 512x512 halves, right offset y -11 (WotLK layout)
    local left = f:CreateTexture(nil, "ARTWORK")
    left:SetTexture(TEX .. "ui-guildbankframe-left")
    left:SetWidth(512); left:SetHeight(512)
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    local right = f:CreateTexture(nil, "ARTWORK")
    right:SetTexture(TEX .. "ui-guildbankframe-right")
    right:SetWidth(512); right:SetHeight(512)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, -11)

    -- title in a WotLK-style name banner (ui-tabnameborder: caps 8px, center stretches)
    local bannerL = f:CreateTexture(nil, "OVERLAY")
    bannerL:SetTexture(TEX .. "ui-tabnameborder")
    bannerL:SetWidth(8); bannerL:SetHeight(18)
    bannerL:SetTexCoord(0, 0.0625, 0, 0.5625)
    local bannerC = f:CreateTexture(nil, "OVERLAY")
    bannerC:SetTexture(TEX .. "ui-tabnameborder")
    bannerC:SetHeight(18)
    bannerC:SetTexCoord(0.0625, 0.546875, 0, 0.5625)
    local bannerR = f:CreateTexture(nil, "OVERLAY")
    bannerR:SetTexture(TEX .. "ui-tabnameborder")
    bannerR:SetWidth(8); bannerR:SetHeight(18)
    bannerR:SetTexCoord(0.546875, 0.609375, 0, 0.5625)

    -- static window title on the top header line
    GB.headerText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GB.headerText:SetPoint("TOP", f, "TOP", 0, -18)
    GB.headerText:SetText("Guild Bank")

    GB.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GB.title:SetPoint("TOP", f, "TOP", 0, -45)
    GB.title:SetText("Guild Bank")
    bannerC:SetPoint("CENTER", GB.title, "CENTER", 0, -1)   -- text sits 1px above banner center
    bannerL:SetPoint("RIGHT", bannerC, "LEFT", 0, 0)
    bannerR:SetPoint("LEFT", bannerC, "RIGHT", 0, 0)
    GB.titleBanner = bannerC

    -- close button, flush with the frame corner (WotLK placement)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 3, -8)
    close:SetScript("OnClick", function() f:Hide() end)

    GB.BuildColumns(f)
    GB.BuildEmptyPanel(f)
    GB.BuildSideTabs(f)
    GB.BuildMoneyBar(f)
    GB.BuildViewTabs(f)
    GB.BuildLogView(f)
    GB.BuildNoViewOverlay()     -- needs both the columns and the log panel
    GB.BuildInfoView(f)
    GB.BuildMoneyPopup(f)
    GB.BuildTabEditPopup(f)
    GB.BuildCursorFrame()
    GB.InitBagHook()
    GB.SetView("bank")

    SLASH_WHCGUILDBANK1 = "/guildbank"
    SLASH_WHCGUILDBANK2 = "/gbank"
    SlashCmdList["WHCGUILDBANK"] = function()
        GB.Toggle()
    end
end

-- 7 columns x 14 buttons (two stacks of 7 per column)
function GB.BuildColumns(f)
    GB.columns = {}
    for c = 1, 7 do
        local col = CreateFrame("Frame", "WhcGBColumn" .. c, f)
        col:SetWidth(100); col:SetHeight(311)
        if c == 1 then
            col:SetPoint("TOPLEFT", f, "TOPLEFT", 26, -70)
        else
            col:SetPoint("TOPLEFT", GB.columns[c - 1], "TOPRIGHT", 3, 0)
        end
        local bg = col:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(TEX .. "ui-guildbankframe-slots")
        bg:SetTexCoord(0, 0.78125, 0, 0.607421875)
        GB.columns[c] = col
        col.slotsBg = bg    -- anchored to the buttons below, once they exist

        for i = 1, 14 do
            local slotIndex = (c - 1) * 14 + i          -- 1..98
            local b = CreateFrame("Button", "WhcGBSlot" .. slotIndex, col)
            -- sized to the art's well pitch (49 x 44) so icons fill the wells;
            -- no normal texture: empty slots show ONLY the background art (WotLK look)
            b:SetWidth(44); b:SetHeight(40)
            if i == 1 then
                b:SetPoint("TOPLEFT", col, "TOPLEFT", 7, -3)
            elseif i == 8 then
                b:SetPoint("TOPLEFT", getglobal("WhcGBSlot" .. (slotIndex - 7)), "TOPRIGHT", 5, 0)
            else
                b:SetPoint("TOPLEFT", getglobal("WhcGBSlot" .. (slotIndex - 1)), "BOTTOMLEFT", 0, -4)
            end
            b.slot = slotIndex - 1                      -- server slots are 0-based

            b.icon = b:CreateTexture(nil, "BORDER")
            b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
            b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
            b.countText = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            b.countText:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
            b.qborder = b:CreateTexture(nil, "OVERLAY")
            b.qborder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            b.qborder:SetBlendMode("ADD")
            b.qborder:SetWidth(68); b.qborder:SetHeight(64)
            b.qborder:SetPoint("CENTER", b, "CENTER", 0, 1)
            b.qborder:Hide()
            -- NO pushed texture: a drag that releases off-button never delivers the
            -- mouse-up to this button, leaving the depress visual stuck forever
            -- hover glow is managed manually (OnEnter/OnLeave): the engine highlight
            -- can get stuck in its locked state when a drag releases off-button
            b.hover = b:CreateTexture(nil, "OVERLAY")
            b.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            b.hover:SetBlendMode("ADD")
            b.hover:SetAllPoints(b)
            b.hover:Hide()

            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:RegisterForDrag("LeftButton")
            b:SetScript("OnClick", function(self, button)
                local btn = self or this
                button = button or arg1
                GB.OnSlotClick(btn, button)
            end)
            b:SetScript("OnDragStart", function(self)
                GB.OnSlotClick(self or this, "LeftButton")
            end)
            b:SetScript("OnReceiveDrag", function(self)
                GB.OnSlotClick(self or this, "LeftButton")
            end)
            b:SetScript("OnEnter", function(self)
                local btn = self or this
                btn.hover:Show()
                GB.OnSlotEnter(btn)
            end)
            b:SetScript("OnLeave", function(self)
                local btn = self or this
                btn.hover:Hide()
                GameTooltip:Hide()
            end)
            b.SplitStack = function(owner, split)
                GB.OnSplitStack(owner, split)
            end
            GB.slotButtons[slotIndex - 1] = b

            if i == 1 then
                col.firstBtn = b
            elseif i == 14 then
                col.lastBtn = b
            end
        end

        -- stretch the slot-well art so its borders frame the buttons instead of
        -- cutting through them (the live texture's well pitch differs slightly
        -- from the button layout, so the art is anchored to the buttons)
        col.slotsBg:SetPoint("TOPLEFT", col.firstBtn, "TOPLEFT", -4.5, 2.5)
        col.slotsBg:SetPoint("BOTTOMRIGHT", col.lastBtn, "BOTTOMRIGHT", 2.5, -4.5)
    end
end

-- blackout shown when the current tab denies VIEW for our rank; one covers the
-- slot grid (parented to column 1 so it hides with the grid on other views,
-- RepaintGrid toggles it), one covers the log panel (UpdateLogList toggles it)
local function MakeNoViewOverlay(name, parent, anchorTL, xTL, yTL, anchorBR, xBR, yBR, level)
    local no = CreateFrame("Frame", name, parent)
    no:SetPoint("TOPLEFT", anchorTL, "TOPLEFT", xTL, yTL)
    no:SetPoint("BOTTOMRIGHT", anchorBR, "BOTTOMRIGHT", xBR, yBR)
    no:SetFrameLevel(level)
    no:EnableMouse(true)                    -- swallow clicks on covered content
    local bg = no:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(no)
    if bg.SetColorTexture then
        bg:SetColorTexture(0, 0, 0, 0.85)   -- 1.14
    else
        bg:SetTexture(0, 0, 0)              -- 1.12
        bg:SetAlpha(0.85)
    end
    no.text = no:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    no.text:SetPoint("CENTER", no, "CENTER", 0, 0)
    no.text:SetText("You do not have permission to view this tab.")
    no:Hide()
    return no
end

function GB.BuildNoViewOverlay()
    GB.noViewOverlay = MakeNoViewOverlay("WhcGBNoView", GB.columns[1],
        GB.columns[1], 4, 0, GB.columns[7], 4, 0,
        GB.columns[1]:GetFrameLevel() + 3)                  -- above every slot button
    GB.noViewLogOverlay = MakeNoViewOverlay("WhcGBNoViewLog", GB.logPanel,
        GB.logPanel, 0, 0, GB.logPanel, 0, 0,
        GB.logPanel:GetFrameLevel() + 3)                    -- above rows + scrollbar
end

-- shown instead of the slot grid while the guild owns no bank tab yet
function GB.BuildEmptyPanel(f)
    local panel = CreateFrame("Frame", "WhcGBEmptyPanel", f)
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -70)
    panel:SetWidth(718); panel:SetHeight(311)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    if bg.SetColorTexture then
        bg:SetColorTexture(0, 0, 0, 0.85)   -- 1.14
    else
        bg:SetTexture(0, 0, 0)              -- 1.12
        bg:SetAlpha(0.85)
    end

    panel.text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.text:SetPoint("CENTER", panel, "CENTER", 0, 30)
    panel.text:SetText("Your guild does not own a guild bank tab yet.")

    local buy = CreateFrame("Button", "WhcGBEmptyBuyBtn", panel, "UIPanelButtonTemplate")
    buy:SetWidth(240); buy:SetHeight(28)
    buy:SetPoint("CENTER", panel, "CENTER", 0, -10)
    buy:SetText("Buy first tab")
    buy:SetScript("OnClick", function() GB.OnBuyTabClick() end)
    panel.buyBtn = buy

    panel.hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.hint:SetPoint("CENTER", panel, "CENTER", 0, -40)
    panel.hint:SetText("Anyone in the guild can buy a tab for the guild.")

    panel:Hide()
    GB.emptyPanel = panel
end

-- decides what fills the main area: slot grid, empty-state panel, or neither
function GB.UpdateBankPanels()
    local bankView = (GB.state.view == "bank")
    local noTabs = (GB.state.numTabs == 0)
    for c = 1, 7 do
        if GB.columns and GB.columns[c] then
            if bankView and not noTabs then GB.columns[c]:Show() else GB.columns[c]:Hide() end
        end
    end
    -- the money strip (limit label + withdraw/deposit buttons) belongs to the bank view
    if GB.limitText then
        if bankView and not noTabs then GB.limitText:Show() else GB.limitText:Hide() end
        if GB.limitBannerParts then
            for _, part in ipairs(GB.limitBannerParts) do
                if bankView and not noTabs then part:Show() else part:Hide() end
            end
        end
    end
    if GB.withdrawBtn then
        if bankView then GB.withdrawBtn:Show() GB.depositBtn:Show() else GB.withdrawBtn:Hide() GB.depositBtn:Hide() end
    end
    if GB.emptyPanel then
        if bankView and noTabs then
            GB.emptyPanel.buyBtn:SetText("Buy first tab for " .. FormatGold(GB.state.nextTabCost))
            GB.emptyPanel.buyBtn:Enable()
            GB.emptyPanel.hint:SetText("Anyone in the guild can buy a tab for the guild.")
            GB.emptyPanel:Show()
        else
            GB.emptyPanel:Hide()
        end
    end
end

-- 6 side tabs + buy button, stacked down the right edge
function GB.BuildSideTabs(f)
    for t = 1, MAX_TABS do
        local tabF = CreateFrame("Frame", "WhcGBTab" .. t, f)
        tabF:SetWidth(42); tabF:SetHeight(50)
        if t == 1 then
            tabF:SetPoint("TOPLEFT", f, "TOPRIGHT", -2, -32)
        else
            tabF:SetPoint("TOPLEFT", getglobal("WhcGBTab" .. (t - 1)), "BOTTOMLEFT", 0, 0)
        end
        local bg = tabF:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(TEX .. "ui-guildbankframe-tab")
        bg:SetWidth(64); bg:SetHeight(64)
        bg:SetPoint("TOPLEFT", tabF, "TOPLEFT", 0, 0)

        local b = CreateFrame("Button", "WhcGBTab" .. t .. "Button", tabF)
        b:SetWidth(36); b:SetHeight(34)
        b:SetPoint("TOPLEFT", tabF, "TOPLEFT", 2, -8)
        b.tabId = t - 1
        -- no quickslot normal texture: the tab flange art provides the well
        b.icon = b:CreateTexture(nil, "BORDER")
        b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
        b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
        -- NO pushed/highlight textures: same stuck-visual issue as the item slots
        -- (a drag released off-button never delivers the mouse-up) — hover is manual
        b.hover = b:CreateTexture(nil, "OVERLAY")
        b.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        b.hover:SetBlendMode("ADD")
        b.hover:SetAllPoints(b)
        b.hover:Hide()
        b.checked = b:CreateTexture(nil, "OVERLAY")
        b.checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        b.checked:SetBlendMode("ADD")
        b.checked:SetAllPoints(b)
        b.checked:Hide()
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("OnClick", function(self, button)
            local btn = self or this
            button = button or arg1
            if button == "RightButton" then
                if GB.state.isManager then
                    GB.OpenTabEdit(btn.tabId)
                end
                return
            end
            GB.SelectTab(btn.tabId)
        end)
        b:SetScript("OnEnter", function(self)
            local btn = self or this
            btn.hover:Show()
            local tabInfo = GB.state.tabs[btn.tabId]
            if tabInfo then
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:SetText(tabInfo.name or "", 1, 1, 1)
                if tabInfo.view ~= 1 then
                    GameTooltip:AddLine("You cannot view this tab", 1, 0.2, 0.2)
                else
                    if tabInfo.stacksRemain and tabInfo.stacksRemain ~= -1 then
                        GameTooltip:AddLine("Withdrawals left today: " .. tabInfo.stacksRemain, 0.8, 0.8, 0.8)
                    end
                end
                if GB.state.isManager then
                    GameTooltip:AddLine("Right-click to edit name and icon", 0.6, 0.6, 0.6)
                end
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function(self)
            local btn = self or this
            btn.hover:Hide()
            GameTooltip:Hide()
        end)
        b:Hide()
        tabF:Hide()
        GB.tabButtons[t - 1] = { frame = tabF, button = b }
    end

    -- buy-tab button (shows on the first unpurchased tab position)
    local buyF = CreateFrame("Frame", "WhcGBBuyTab", f)
    buyF:SetWidth(42); buyF:SetHeight(50)
    local bg = buyF:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(TEX .. "ui-guildbankframe-tab")
    bg:SetWidth(64); bg:SetHeight(64)
    bg:SetPoint("TOPLEFT", buyF, "TOPLEFT", 0, 0)
    local b = CreateFrame("Button", "WhcGBBuyTabButton", buyF)
    b:SetWidth(36); b:SetHeight(34)
    b:SetPoint("TOPLEFT", buyF, "TOPLEFT", 2, -8)
    local icon = b:CreateTexture(nil, "BORDER")
    icon:SetTexture(TEX .. "ui-guildbankframe-newtab")
    icon:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    -- manual hover, same stuck-visual reasoning as the side tabs
    b.hover = b:CreateTexture(nil, "OVERLAY")
    b.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    b.hover:SetBlendMode("ADD")
    b.hover:SetAllPoints(b)
    b.hover:Hide()
    b:SetScript("OnClick", function()
        GB.OnBuyTabClick()
    end)
    b:SetScript("OnEnter", function(self)
        local btn = self or this
        btn.hover:Show()
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Buy Guild Bank Tab", 1, 1, 1)
        GameTooltip:AddLine("Cost: " .. FormatGold(GB.state.nextTabCost), 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Anyone in the guild can buy a tab for the guild.", 0.6, 0.6, 0.6, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        local btn = self or this
        btn.hover:Hide()
        GameTooltip:Hide()
    end)
    buyF:Hide()
    GB.buyTab = buyF
end

function GB.BuildMoneyBar(f)
    -- strip just under the grid (WotLK layout): centered daily-withdrawal label,
    -- [Withdraw] [Deposit] at its right end
    local deposit = CreateFrame("Button", "WhcGBDepositBtn", f, "UIPanelButtonTemplate")
    deposit:SetWidth(90); deposit:SetHeight(21)
    deposit:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 37)
    deposit:SetText("Deposit")
    deposit:SetScript("OnClick", function() GB.OpenMoneyPopup("deposit") end)
    GB.depositBtn = deposit

    local withdraw = CreateFrame("Button", "WhcGBWithdrawBtn", f, "UIPanelButtonTemplate")
    withdraw:SetWidth(90); withdraw:SetHeight(21)
    withdraw:SetPoint("RIGHT", deposit, "LEFT", -3, 0)
    withdraw:SetText("Withdraw")
    withdraw:SetScript("OnClick", function() GB.OpenMoneyPopup("withdraw") end)
    GB.withdrawBtn = withdraw

    -- nudge both button labels 1px up
    local depText = getglobal("WhcGBDepositBtnText")
    if depText then
        depText:ClearAllPoints()
        depText:SetPoint("CENTER", deposit, "CENTER", 0, 1)
    end
    local wdrText = getglobal("WhcGBWithdrawBtnText")
    if wdrText then
        wdrText:ClearAllPoints()
        wdrText:SetPoint("CENTER", withdraw, "CENTER", 0, 1)
    end

    -- WotLK-style name banner behind the daily-withdrawals label
    local lbL = f:CreateTexture(nil, "OVERLAY")
    lbL:SetTexture(TEX .. "ui-tabnameborder")
    lbL:SetWidth(8); lbL:SetHeight(18)
    lbL:SetTexCoord(0, 0.0625, 0, 0.5625)
    local lbC = f:CreateTexture(nil, "OVERLAY")
    lbC:SetTexture(TEX .. "ui-tabnameborder")
    lbC:SetHeight(18)
    lbC:SetTexCoord(0.0625, 0.546875, 0, 0.5625)
    local lbR = f:CreateTexture(nil, "OVERLAY")
    lbR:SetTexture(TEX .. "ui-tabnameborder")
    lbR:SetWidth(8); lbR:SetHeight(18)
    lbR:SetTexCoord(0.546875, 0.609375, 0, 0.5625)

    GB.limitText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    GB.limitText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 43, 42)
    GB.limitText:SetText("")
    lbC:SetPoint("CENTER", GB.limitText, "CENTER", 0, 0)
    lbL:SetPoint("RIGHT", lbC, "LEFT", 0, 0)
    lbR:SetPoint("LEFT", lbC, "RIGHT", 0, 0)
    GB.limitBanner = lbC
    GB.limitBannerParts = { lbL, lbC, lbR }

    -- bottom bar: available (withdrawable) amount left, total guild funds right,
    -- both with real coin icon textures (WotLK look, works on 1.12 too)
    GB.availLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    GB.availLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 25, 18)
    GB.availLabel:SetText("Available Amount:")
    GB.availMoney = CreateMoneyDisplay(f, false)
    GB.availMoney:SetPoint("LEFT", GB.availLabel, "RIGHT", 6, 0)
    GB.availMoney:SetMoney(0)

    GB.fundsMoney = CreateMoneyDisplay(f, true)
    GB.fundsMoney:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 15)
    GB.fundsMoney:SetMoney(0)
    GB.fundsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    GB.fundsLabel:SetPoint("RIGHT", GB.fundsMoney.g, "LEFT", -6, 0)
    GB.fundsLabel:SetText("Guild Funds:")
end

-- bottom tabs hanging below the frame (same hand-made style as the main WHC window)
function GB.BuildViewTabs(f)
    local defs = {
        { key = "bank",     label = "Bank",        width = 80 },
        { key = "log",      label = "Log",         width = 70 },
        { key = "moneylog", label = "Money Log",   width = 100 },
        { key = "info",     label = "Permissions", width = 104 },
    }
    GB.viewButtons = {}
    local x = 16
    for i = 1, 4 do
        local d = defs[i]
        local b = CreateFrame("Button", "WhcGBViewTab" .. i, f)
        b:SetWidth(d.width); b:SetHeight(30)
        b:SetPoint("TOPLEFT", f, "BOTTOMLEFT", x, 9)
        x = x + d.width - 10    -- uniform gap between tabs
        b:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-InActiveTab")
        b:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
        b:EnableMouse(true)
        local tabText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tabText:SetPoint("CENTER", b, "CENTER", 0, 3)
        tabText:SetText(d.label)
        b.tabText = tabText
        b.viewKey = d.key
        b:SetScript("OnClick", function(self)
            local btn = self or this
            GB.SetView(btn.viewKey)
            PlaySound(WHC.SOUNDS.selectTab)
        end)
        GB.viewButtons[d.key] = b
    end
end

-- shared scrolling list used by log / money log views
function GB.BuildLogView(f)
    local NUM_ROWS = 14
    GB.NUM_LOG_ROWS = NUM_ROWS
    GB.logRowH = 20

    local panel = CreateFrame("Frame", "WhcGBLogPanel", f)
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -70)
    panel:SetWidth(700); panel:SetHeight(300)
    panel:Hide()
    GB.logPanel = panel

    local scroll = CreateFrame("ScrollFrame", "WhcGBLogScroll", panel, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, -10)   -- scrollbar hugs the right edge, 10px taller
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        if WHC.client.is1_12 then
            FauxScrollFrame_OnVerticalScroll(GB.logRowH, GB.UpdateLogList)
        else
            FauxScrollFrame_OnVerticalScroll(self or this, offset or arg1, GB.logRowH, GB.UpdateLogList)
        end
    end)
    GB.logScroll = scroll

    for i = 1, NUM_ROWS do
        local row = panel:CreateFontString("WhcGBLogRow" .. i, "OVERLAY", "GameFontHighlightSmall")
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -(i - 1) * GB.logRowH - 2)
        row:SetWidth(675)
        row:SetHeight(GB.logRowH)
        row:SetJustifyH("LEFT")
        row:SetText("")
        GB.rows[i] = row
    end
end

-- permissions editor (guild master / managers)
function GB.BuildInfoView(f)
    local panel = CreateFrame("Frame", "WhcGBInfoPanel", f, RETAIL_BACKDROP)
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -70)
    panel:SetWidth(700); panel:SetHeight(300)
    panel:Hide()
    GB.infoPanel = panel

    panel.hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.hint:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    panel.hint:SetWidth(690)
    panel.hint:SetJustifyH("LEFT")
    panel.hint:SetText("Guild bank permissions per guild rank. Select a rank, adjust its rights, then Save. The Guild Master rank always has full access.")

    -- rank selector (same init pattern as the GroupFinder dropdowns: this.value
    -- in the click func + direct Text widget updates, both verified on 1.12)
    local dd = CreateFrame("Frame", "WhcGBRankDD", panel, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", panel, "TOPLEFT", -10, -24)
    GB.rankDD = dd
    GB.SetRankDDText = function(txt)
        local t = getglobal("WhcGBRankDDText")
        if t then t:SetWidth(0); t:SetText(txt) end
    end
    if WHC.client.is1_12 then
        UIDropDownMenu_SetWidth(150, dd)
    else
        UIDropDownMenu_SetWidth(dd, 150)
    end
    UIDropDownMenu_Initialize(dd, function()
        for _, rid in ipairs(GB.state.rankOrder) do
            if GB.CanEditRank(rid) then     -- own/higher ranks are not offered at all
            local r = GB.state.ranks[rid]
            local val = rid
            local info = {}
            info.text = rid .. " - " .. (r and r.name or "?")
            info.value = val
            info.checked = (GB.selectedRank == val)
            info.func = function()
                local target = (this and this.value) or val
                if target ~= GB.selectedRank and GB.RankFormDirty() then
                    -- unsaved edits on the current rank: confirm before discarding
                    GB.pendingRankSwitch = target
                    GB.RefreshRankDD()          -- keep the closed dropdown on the old rank
                    StaticPopup_Show("WHC_GB_DISCARD_RANK")
                    return
                end
                GB.SelectRank(target)
            end
            UIDropDownMenu_AddButton(info)
            end
        end
    end)

    StaticPopupDialogs["WHC_GB_DISCARD_RANK"] = {
        text = "You have unsaved changes to this rank. Discard them?",
        button1 = "Discard",
        button2 = "Cancel",
        OnAccept = function()
            if GB.pendingRankSwitch ~= nil then
                GB.SelectRank(GB.pendingRankSwitch)
            end
            GB.pendingRankSwitch = nil
        end,
        OnCancel = function()
            GB.pendingRankSwitch = nil
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    }

    -- global rights, on the same line as the rank dropdown
    local function MakeCheck(name, label, x, y, parent)
        local cb = CreateFrame("CheckButton", name, parent or panel, "UICheckButtonTemplate")
        cb:SetWidth(22); cb:SetHeight(22)
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        local text = getglobal(name .. "Text")
        if text then
            text:SetText(label)
            text:SetFontObject("GameFontHighlightSmall")
        end
        return cb
    end

    -- gold deposits are open to everyone, so there is no "Deposit gold" right
    GB.cbManage   = MakeCheck("WhcGBcbManage", "Manage bank rights", 200, -29)
    GB.cbWdrGold  = MakeCheck("WhcGBcbWdrGold", "Withdraw gold", 370, -29)

    local goldLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 500, -36)
    goldLabel:SetText("Gold/day:")
    GB.ebGold = CreateFrame("EditBox", "WhcGBebGold", panel, "InputBoxTemplate")
    GB.ebGold:SetWidth(60); GB.ebGold:SetHeight(18)
    GB.ebGold:SetPoint("TOPLEFT", panel, "TOPLEFT", 560, -31)
    GB.ebGold:SetAutoFocus(false)
    GB.ebGold:SetNumeric(true)
    GB.ebGold:SetMaxLetters(7)

    -- per-tab grid: 6 rows of (label + view/dep/move checkboxes + stacks editbox)
    -- header labels are anchored per-column (centered over their checkbox column)
    -- instead of one space-padded string, so they can't drift out of alignment
    GB.tabRights = {}
    local tabHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -84)
    tabHeader:SetText("Tab")
    local function ColHeader(label, cbX)
        local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOP", panel, "TOPLEFT", cbX + 11, -84)   -- centered over the 22px checkbox
        h:SetText(label)
    end
    ColHeader("View", 120)
    ColHeader("Deposit", 185)
    ColHeader("Move Items", 255)
    local stacksHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stacksHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 333, -84)
    stacksHeader:SetText("Stacks withdrawable/day (-1 = unlimited)")
    for t = 0, MAX_TABS - 1 do
        local y = -104 - t * 26
        local row = {}
        row.label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, y - 4)
        row.label:SetWidth(110)
        row.label:SetJustifyH("LEFT")
        row.label:SetText("Tab " .. (t + 1))
        row.view = MakeCheck("WhcGBtr" .. t .. "View", "", 120, y)
        row.dep  = MakeCheck("WhcGBtr" .. t .. "Dep", "", 185, y)
        row.move = MakeCheck("WhcGBtr" .. t .. "Move", "", 255, y)
        row.stacks = CreateFrame("EditBox", "WhcGBtr" .. t .. "Stacks", panel, "InputBoxTemplate")
        row.stacks:SetWidth(50); row.stacks:SetHeight(18)
        row.stacks:SetPoint("TOPLEFT", panel, "TOPLEFT", 340, y - 2)
        row.stacks:SetAutoFocus(false)
        row.stacks:SetMaxLetters(4)
        GB.tabRights[t] = row
    end

    local save = CreateFrame("Button", "WhcGBRightsSave", panel, "UIPanelButtonTemplate")
    save:SetWidth(150); save:SetHeight(32)
    save:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, -2)
    save:SetText("Save Rank Changes")
    save:SetScript("OnClick", function() GB.SaveRank() end)
    GB.rightsSave = save

end

-- the stock dialog backdrop is fairly see-through; lay a solid dark fill inside
-- the border insets so popup content doesn't compete with the bank grid below
local function AddPopupFill(p)
    local fill = p:CreateTexture(nil, "BACKGROUND")
    fill:SetTexture(0, 0, 0)
    fill:SetAlpha(0.82)
    fill:SetPoint("TOPLEFT", p, "TOPLEFT", 11, -12)
    fill:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -12, 11)
end

function GB.BuildMoneyPopup(f)
    local p = CreateFrame("Frame", "WhcGBMoneyPopup", f, RETAIL_BACKDROP)
    p:SetWidth(280); p:SetHeight(120)
    p:SetPoint("CENTER", f, "CENTER", 0, 0)
    p:SetFrameStrata("DIALOG")
    p:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    AddPopupFill(p)
    p:EnableMouse(true)
    p:Hide()
    GB.moneyPopup = p

    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.title:SetPoint("TOP", p, "TOP", 0, -16)
    p.title:SetText("Deposit money")

    local function MakeBox(name, coinTex, x)
        local eb = CreateFrame("EditBox", name, p, "InputBoxTemplate")
        eb:SetWidth(50); eb:SetHeight(20)
        eb:SetPoint("TOPLEFT", p, "TOPLEFT", x, -44)
        eb:SetAutoFocus(false)
        eb:SetNumeric(true)
        eb:SetMaxLetters(6)
        local icon = p:CreateTexture(nil, "OVERLAY")
        icon:SetTexture(coinTex)
        icon:SetWidth(14); icon:SetHeight(14)
        icon:SetPoint("LEFT", eb, "RIGHT", 1, 0)
        return eb
    end
    p.gold   = MakeBox("WhcGBMoneyG", COIN_TEX.gold, 30)
    p.silver = MakeBox("WhcGBMoneyS", COIN_TEX.silver, 110)
    p.copper = MakeBox("WhcGBMoneyC", COIN_TEX.copper, 190)

    local ok = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    ok:SetWidth(90); ok:SetHeight(22)
    ok:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 30, 16)
    ok:SetText("Okay")
    ok:SetScript("OnClick", function()
        local copper = (tonumber(p.gold:GetText()) or 0) * 10000
                     + (tonumber(p.silver:GetText()) or 0) * 100
                     + (tonumber(p.copper:GetText()) or 0)
        p:Hide()
        if copper > 0 and not Throttled() then
            if p.mode == "deposit" then
                Send("dmoney " .. copper)
            else
                Send("wmoney " .. copper)
            end
        end
    end)
    local cancel = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    cancel:SetWidth(90); cancel:SetHeight(22)
    cancel:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -30, 16)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function() p:Hide() end)
end

function GB.OpenMoneyPopup(mode)
    if not CheckFull() then return end
    local p = GB.moneyPopup
    p.mode = mode
    p.title:SetText(mode == "deposit" and "Deposit money" or "Withdraw money")
    p.gold:SetText(""); p.silver:SetText(""); p.copper:SetText("")
    p:Show()
    p.gold:SetFocus()
end

-- ---------------------------------------------------------------------------
-- tab edit popup (right-click a side tab): rename + icon picker
-- ---------------------------------------------------------------------------
-- every name below is verified against the 1.12 client's ItemDisplayInfo/SpellIcon
-- string blocks (tools: scratchpad check_icons.py) — do not add unverified names
local TAB_ICONS = {
    -- bags / containers
    "INV_Misc_Bag_08", "INV_Misc_Bag_09", "INV_Misc_Bag_10", "INV_Misc_Bag_11",
    "INV_Misc_Bag_12", "INV_Misc_Bag_14", "INV_Misc_Bag_17",
    "INV_Box_01", "INV_Box_02", "INV_Box_03",
    "INV_Crate_01", "INV_Crate_02", "INV_Crate_03", "INV_Crate_04", "INV_Crate_05",
    -- coins / gems / jewelry
    "INV_Misc_Coin_03", "INV_Misc_Coin_04", "INV_Misc_Coin_05", "INV_Misc_Coin_06",
    "INV_Misc_Gem_Ruby_02", "INV_Misc_Gem_Sapphire_02", "INV_Misc_Gem_Emerald_02",
    "INV_Misc_Gem_Topaz_02", "INV_Misc_Gem_Opal_02", "INV_Misc_Gem_Amethyst_02",
    "INV_Misc_Gem_Diamond_02", "INV_Misc_Gem_Pearl_03", "INV_Misc_Gem_Crystal_02",
    "INV_Jewelry_Ring_03", "INV_Jewelry_Ring_05", "INV_Jewelry_Ring_14",
    "INV_Jewelry_Necklace_07", "INV_Jewelry_Talisman_03", "INV_Jewelry_Talisman_07",
    -- weapons
    "INV_Sword_04", "INV_Sword_27", "INV_Sword_39", "INV_Sword_48",
    "INV_Weapon_ShortBlade_05", "INV_Weapon_ShortBlade_25",
    "INV_Axe_06", "INV_Axe_09", "INV_Axe_12", "INV_Mace_01", "INV_Mace_02", "INV_Hammer_05",
    "INV_Spear_05", "INV_Weapon_Halberd_10", "INV_Weapon_Bow_07", "INV_Weapon_Crossbow_02",
    "INV_Weapon_Rifle_01", "INV_Weapon_Rifle_07", "INV_ThrowingKnife_02",
    "INV_Staff_13", "INV_Wand_07",
    -- armor
    "INV_Shield_04", "INV_Shield_05", "INV_Shield_06", "INV_Shield_09",
    "INV_Helmet_01", "INV_Helmet_03", "INV_Helmet_20", "INV_Helmet_29",
    "INV_Chest_Cloth_17", "INV_Chest_Leather_01", "INV_Chest_Leather_08",
    "INV_Chest_Chain_05", "INV_Chest_Plate04",
    "INV_Boots_02", "INV_Boots_05", "INV_Boots_07", "INV_Bracer_02", "INV_Bracer_07",
    "INV_Gauntlets_04", "INV_Belt_03", "INV_Shoulder_09",
    "INV_Misc_Cape_02", "INV_Misc_Cape_11", "INV_Misc_Cape_18",
    -- consumables
    "INV_Potion_01", "INV_Potion_17", "INV_Potion_20", "INV_Potion_35", "INV_Potion_43",
    "INV_Potion_51", "INV_Potion_54", "INV_Potion_62", "INV_Potion_76", "INV_Potion_87",
    "INV_Potion_93",
    "INV_Misc_Food_01", "INV_Misc_Food_02", "INV_Misc_Food_14", "INV_Misc_Food_15",
    "INV_Misc_Food_19", "INV_Misc_Food_23",
    "INV_Misc_Fish_01", "INV_Misc_Fish_02", "INV_Misc_Fish_04", "INV_Misc_Fish_24",
    "INV_Drink_05", "INV_Drink_07", "INV_Drink_10", "INV_Drink_16", "INV_Drink_17",
    "INV_Scroll_01", "INV_Scroll_02", "INV_Scroll_03", "INV_Scroll_05", "INV_Scroll_06",
    "INV_Misc_Bandage_08", "INV_Misc_Bandage_12",
    -- trade goods
    "INV_Fabric_Linen_01", "INV_Fabric_Wool_01", "INV_Fabric_Silk_01",
    "INV_Fabric_MageWeave_01", "INV_Fabric_PurpleFire_01", "INV_Fabric_MoonRag_01",
    "INV_Ore_Copper_01", "INV_Ore_Tin_01", "INV_Ore_Iron_01", "INV_Ore_Mithril_02",
    "INV_Ore_TrueSilver_01", "INV_Ore_Thorium_02", "INV_Stone_12",
    "INV_Ingot_02", "INV_Ingot_03", "INV_Ingot_04", "INV_Ingot_05", "INV_Ingot_06",
    "INV_Ingot_07", "INV_Ingot_08", "INV_Ingot_Mithril", "INV_Ingot_Thorium",
    "INV_Misc_LeatherScrap_02", "INV_Misc_LeatherScrap_03", "INV_Misc_LeatherScrap_05",
    "INV_Misc_LeatherScrap_08", "INV_Misc_Pelt_Wolf_01", "INV_Misc_Pelt_Bear_03",
    "INV_Misc_Herb_01", "INV_Misc_Herb_03", "INV_Misc_Herb_07", "INV_Misc_Herb_09",
    "INV_Misc_Flower_01", "INV_Misc_Flower_02", "INV_Misc_Flower_04",
    "INV_Misc_Root_01", "INV_Mushroom_11",
    "INV_Enchant_DustIllusion", "INV_Enchant_ShardBrilliantLarge",
    "INV_Enchant_ShardGlimmeringLarge", "INV_Enchant_ShardRadientLarge",
    "INV_Enchant_EssenceEternalLarge", "INV_Enchant_EssenceMagicLarge",
    "INV_Misc_Dust_02", "INV_Misc_Dust_06", "INV_Misc_Rune_01",
    -- engineering
    "INV_Misc_Gear_01", "INV_Misc_Gear_02", "INV_Misc_Gear_08",
    "INV_Misc_Bomb_02", "INV_Misc_Bomb_04", "INV_Misc_Bomb_05",
    "INV_Battery_02", "INV_Gizmo_02", "INV_Misc_EngGizmos_01",
    -- professions
    "Trade_Alchemy", "Trade_BlackSmithing", "Trade_Engineering", "Trade_Engraving",
    "Trade_Fishing", "Trade_Herbalism", "Trade_LeatherWorking", "Trade_Mining",
    "Trade_Tailoring", "INV_Misc_ArmorKit_17", "Ability_Repair",
    -- ammo
    "INV_Ammo_Arrow_01", "INV_Ammo_Arrow_02", "INV_Ammo_Bullet_01", "INV_Ammo_Bullet_02",
    "INV_Musket_03",
    -- spell schools
    "Spell_Fire_FlameBolt", "Spell_Fire_Fireball02", "Spell_Frost_FrostBolt02",
    "Spell_Frost_IceStorm", "Spell_Nature_Lightning", "Spell_Nature_StarFall",
    "Spell_Nature_MoonKey", "Spell_Holy_HolyBolt", "Spell_Holy_PrayerOfHealing",
    "Spell_Shadow_ShadowWordPain",
    -- misc
    "INV_Misc_Book_01", "INV_Misc_Book_05", "INV_Misc_Book_09", "INV_Misc_Book_11",
    "INV_Misc_Note_01", "INV_Misc_Note_02", "INV_Misc_Note_05",
    "INV_Misc_Key_01", "INV_Misc_Key_03", "INV_Misc_Key_04", "INV_Misc_Key_06",
    "INV_Misc_Key_10", "INV_Misc_Map_01", "INV_Misc_Bone_HumanSkull_01",
    "INV_Misc_Head_Dragon_01", "INV_Misc_Horn_01", "INV_Misc_Shell_01",
    "INV_Egg_01", "INV_Misc_ShadowEgg", "INV_Feather_04", "INV_Misc_Orb_01",
    "INV_Misc_MonsterClaw_04", "INV_Misc_MonsterScales_02", "INV_Misc_MonsterScales_08",
    "INV_Misc_Gift_01", "INV_Misc_Gift_05", "INV_Hammer_20",
    "INV_Banner_01", "INV_Banner_02", "INV_Banner_03",
    "INV_BannerPVP_01", "INV_BannerPVP_02", "INV_Misc_QuestionMark",
}

local ICON_COLS, ICON_ROWS, ICON_PITCH = 7, 4, 26

function GB.BuildTabEditPopup(f)
    local p = CreateFrame("Frame", "WhcGBTabEdit", f, RETAIL_BACKDROP)
    p:SetWidth(240); p:SetHeight(230)
    p:SetPoint("CENTER", f, "CENTER", 0, 0)
    p:SetFrameStrata("DIALOG")
    p:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    AddPopupFill(p)
    p:EnableMouse(true)
    p:Hide()
    GB.tabEditPopup = p

    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.title:SetPoint("TOP", p, "TOP", 0, -16)
    p.title:SetText("Edit Tab")

    local nameLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 22, -40)
    nameLabel:SetText("Name:")
    p.name = CreateFrame("EditBox", "WhcGBTabEditName", p, "InputBoxTemplate")
    p.name:SetWidth(140); p.name:SetHeight(18)
    p.name:SetPoint("TOPLEFT", p, "TOPLEFT", 72, -37)
    p.name:SetAutoFocus(false)
    p.name:SetMaxLetters(16)

    -- scrollable icon grid (FauxScrollFrame over TAB_ICONS)
    local scroll = CreateFrame("ScrollFrame", "WhcGBTabEditScroll", p, "FauxScrollFrameTemplate")
    scroll:SetWidth(ICON_COLS * ICON_PITCH); scroll:SetHeight(ICON_ROWS * ICON_PITCH)
    scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 22, -64)
    -- signature differs by client: 1.12 = (itemHeight, updateFunc), 1.14 = (frame, offset, itemHeight, updateFunc)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        if WHC.client.is1_12 then
            FauxScrollFrame_OnVerticalScroll(ICON_PITCH, GB.UpdateTabEditIcons)
        else
            FauxScrollFrame_OnVerticalScroll(self or this, offset or arg1, ICON_PITCH, GB.UpdateTabEditIcons)
        end
    end)
    p.scroll = scroll

    p.iconBtns = {}
    for r = 0, ICON_ROWS - 1 do
        for c = 0, ICON_COLS - 1 do
            local i = r * ICON_COLS + c + 1
            local b = CreateFrame("Button", "WhcGBTabEditIcon" .. i, p)
            b:SetWidth(24); b:SetHeight(24)
            b:SetPoint("TOPLEFT", p, "TOPLEFT", 22 + c * ICON_PITCH, -64 - r * ICON_PITCH)
            b.icon = b:CreateTexture(nil, "BORDER")
            b.icon:SetAllPoints(b)
            b.sel = b:CreateTexture(nil, "OVERLAY")
            b.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            b.sel:SetBlendMode("ADD")
            b.sel:SetAllPoints(b)
            b.sel:Hide()
            b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
            b:SetScript("OnClick", function(self)
                local btn = self or this
                if btn.iconName then
                    GB.tabEdit.icon = btn.iconName
                    GB.UpdateTabEditIcons()
                end
            end)
            p.iconBtns[i] = b
        end
    end

    local ok = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    ok:SetWidth(90); ok:SetHeight(22)
    ok:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 20, 16)
    ok:SetText("Okay")
    ok:SetScript("OnClick", function()
        local name = p.name:GetText()
        if not name or name == "" then
            local tabInfo = GB.state.tabs[GB.tabEdit.tab]
            name = (tabInfo and tabInfo.name) or ("Tab " .. (GB.tabEdit.tab + 1))
        end
        p:Hide()
        if not Throttled() then
            Send("settab " .. GB.tabEdit.tab .. " " .. (GB.tabEdit.icon or "INV_Misc_Bag_10") .. " " .. name)
        end
    end)
    local cancel = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    cancel:SetWidth(90); cancel:SetHeight(22)
    cancel:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -20, 16)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function() p:Hide() end)
end

function GB.UpdateTabEditIcons()
    local p = GB.tabEditPopup
    if not p or not p:IsVisible() then return end
    local numRows = math.ceil(table.getn(TAB_ICONS) / ICON_COLS)
    FauxScrollFrame_Update(p.scroll, numRows, ICON_ROWS, ICON_PITCH)
    local offset = FauxScrollFrame_GetOffset(p.scroll)
    for r = 0, ICON_ROWS - 1 do
        for c = 0, ICON_COLS - 1 do
            local b = p.iconBtns[r * ICON_COLS + c + 1]
            local iconName = TAB_ICONS[(offset + r) * ICON_COLS + c + 1]
            b.iconName = iconName
            if iconName then
                b.icon:SetTexture(ICONS .. iconName)
                if iconName == GB.tabEdit.icon then b.sel:Show() else b.sel:Hide() end
                b:Show()
            else
                b:Hide()
            end
        end
    end
end

function GB.OpenTabEdit(tabId)
    local p = GB.tabEditPopup
    local tabInfo = GB.state.tabs[tabId]
    GB.tabEdit = { tab = tabId, icon = (tabInfo and tabInfo.icon) or "INV_Misc_Bag_10" }
    p.title:SetText("Edit Tab " .. (tabId + 1))
    p.name:SetText((tabInfo and tabInfo.name) or "")
    p:Show()
    -- scroll so the currently selected icon is visible
    local selRow = 0
    for i = 1, table.getn(TAB_ICONS) do
        if TAB_ICONS[i] == GB.tabEdit.icon then
            selRow = math.floor((i - 1) / ICON_COLS)
            break
        end
    end
    local maxOffset = math.max(0, math.ceil(table.getn(TAB_ICONS) / ICON_COLS) - ICON_ROWS)
    local wantOffset = math.min(selRow, maxOffset)
    FauxScrollFrame_SetOffset(p.scroll, wantOffset)
    local bar = getglobal("WhcGBTabEditScrollScrollBar")
    if bar then bar:SetValue(wantOffset * ICON_PITCH) end
    GB.UpdateTabEditIcons()
end

-- virtual cursor frame (bank->bank moves)
function GB.BuildCursorFrame()
    local c = CreateFrame("Frame", "WhcGBCursor", UIParent)
    c:SetWidth(30); c:SetHeight(30)
    c:SetFrameStrata("TOOLTIP")
    c.icon = c:CreateTexture(nil, "OVERLAY")
    c.icon:SetAllPoints(c)
    c:Hide()
    c:SetScript("OnUpdate", function()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        c:ClearAllPoints()
        c:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + 12, y / scale - 12)
    end)
    GB.cursorFrame = c
end

function GB.ClearPicked()
    GB.picked = nil
    if GB.cursorFrame then
        GB.cursorFrame:Hide()
    end
    GB.HighlightPicked()
end

function GB.HighlightPicked()
    for slot = 0, SLOTS - 1 do
        local b = GB.slotButtons[slot]
        if b then
            if GB.picked and GB.picked.tab == GB.state.curTab and GB.picked.slot == slot then
                b.icon:SetVertexColor(0.5, 0.5, 1)
            else
                b.icon:SetVertexColor(1, 1, 1)
                -- safety: never let the manual hover glow stick on a repainted slot
                if b.hover and not MouseIsOver(b) then b.hover:Hide() end
            end
        end
    end
end

-- container/cursor API compat: 1.14 moved the container getters under C_Container
local GetBagItemLink = GetContainerItemLink or (C_Container and C_Container.GetContainerItemLink)
local function CursorHoldsItem()
    if GetCursorInfo then return (GetCursorInfo()) == "item" end
    return CursorHasItem()
end

-- 1.14 taint-free withdraw-to-bag: HookScript (append, no taint) on each bag item
-- button so we observe a click/drop regardless of how the button stored its handler.
-- Inert unless a bank item is virtually picked and the bank window is open.
function GB.Install114WithdrawHook()
    if GB.withdrawHookInstalled then return end
    GB.withdrawHookInstalled = true

    local function onBagClick(self, button)
        local slot = self and self.GetID and self:GetID()
        local bag = self and self.GetBagID and self:GetBagID()
        if bag == nil then
            local p = self and self.GetParent and self:GetParent()
            bag = p and p.GetID and p:GetID()
        end
        if bag == nil or slot == nil or bag < 0 or bag > 4 then return end   -- real bags only

        if button == "RightButton" then
            -- Alt+right-click a bag item = deposit into the current tab (taint-free:
            -- this is a post-hook, we don't replace the protected click handler)
            if IsAltKeyDown() then GB.TryAutoDeposit(bag, slot) end
            return                                           -- plain right-click = Blizzard use
        end
        -- left-click / drag-drop of a virtually-picked bank item = withdraw here
        if not GB.picked then return end
        if not (GB.frame and GB.frame:IsVisible()) then return end
        GB.TryWithdrawTo(bag, slot)                          -- guards cursor-empty itself
    end
    local function onBagDrag(self) onBagClick(self, "LeftButton") end

    local function hookButton(b)
        if not b or b.gbWdHooked or not b.HookScript then return end
        if not (b.IsObjectType and b:IsObjectType("Button") and b.GetID) then return end
        b.gbWdHooked = true
        b:HookScript("OnClick", onBagClick)
        b:HookScript("OnReceiveDrag", onBagDrag)
    end
    -- hook every child button of a container frame (buttons exist by the time it updates)
    GB.hookBagButtons = function(frame)
        if not frame or not frame.GetChildren then return end
        local kids = { frame:GetChildren() }
        for i = 1, table.getn(kids) do hookButton(kids[i]) end
    end

    -- ContainerFrame_Update fires whenever a bag redraws → hook its buttons then
    if type(ContainerFrame_Update) == "function" then
        hooksecurefunc("ContainerFrame_Update", function(frame) GB.hookBagButtons(frame) end)
    end
    -- also the global click handler (harmless duplicate; ClearPicked makes it idempotent)
    if type(ContainerFrameItemButton_OnClick) == "function" then
        hooksecurefunc("ContainerFrameItemButton_OnClick", onBagClick)
    end
    -- initial scan of any bag frames already built
    for i = 1, 13 do GB.hookBagButtons(getglobal("ContainerFrame" .. i)) end
end

-- track real bag pickups so a drop on a bank slot knows the source (1.12 has no GetCursorInfo)
function GB.InitBagHook()
    -- PERMANENT, non-tainting: hooksecurefunc only observes, it doesn't replace the
    -- protected function, so this is safe on 1.14. Used to remember the drop source.
    WHC.HookSecureFunc("PickupContainerItem", function(bag, slot)
        GB.cursorBag = { bag = bag, slot = slot }
    end)
    if WHC.client.is1_14 and C_Container and C_Container.PickupContainerItem then
        WHC.HookSecureFunc(C_Container, "PickupContainerItem", function(bag, slot)
            GB.cursorBag = { bag = bag, slot = slot }
        end)
    end
    -- 1.14 (with OR without C_Container): taint-free withdraw. We can't replace the
    -- protected container fns to intercept a drop on a bag slot, but HookScript on each
    -- bag button OBSERVES the click without taint. When a bank item is virtually picked
    -- and the user clicks an (empty) bag slot, we withdraw there.
    if WHC.client and WHC.client.is1_14 then
        GB.Install114WithdrawHook()
    end

    -- The click-INTERCEPTION hooks (right-click bag item = auto-deposit, picked bank
    -- item dropped on a bag slot = withdraw) must REPLACE the container functions so
    -- they can cancel the default action. On 1.14 those functions are PROTECTED, and
    -- replacing them permanently taints them → the client blocks any later use of a
    -- bag item / disenchant ("action only available to Blizzard UI"). So we install
    -- them only while the bank is open AT A BANKER and restore the originals on close
    -- (see GB.RefreshBagHooks, wired to OnShow/OnHide/OnOpenReply). On 1.12 the
    -- functions are plain insecure FrameXML, so this scoping is harmless there too.

    -- SetBlockEquipItems (AchievementHelpers.lua) reassigns the GLOBAL UseContainerItem
    -- at login and on every settings toggle. If it fires while our hook is live we must
    -- re-wrap the new function; harmless (no-op) when our hooks aren't installed.
    if WHC.SetBlockEquipItems and not GB.setBlockWrapped then
        GB.setBlockWrapped = true
        local origSet = WHC.SetBlockEquipItems
        WHC.SetBlockEquipItems = function()
            origSet()
            if GB.bagHooksInstalled and not (WHC.client and WHC.client.is1_14) then
                GB.hookedUse = nil          -- force re-hook of the freshly-assigned global
                GB.InstallUseHook()
            end
        end
    end
end

-- install the click-interception hooks (only called while open at a banker)
function GB.InstallBagHooks()
    if GB.bagHooksInstalled then return end
    GB.bagHooksInstalled = true

    -- CRITICAL (any 1.14 client): the container functions are PROTECTED. Replacing
    -- them — whether the C_Container table entry OR the _G global — permanently TAINTS
    -- that slot for the whole session, after which the client BLOCKS every bag-item
    -- USE ("action only available to Blizzard UI"). Restoring the original reference
    -- on close does NOT clear it (taint is on the table/global slot, not the value).
    -- So on 1.14 we NEVER wrap: right-click-in-bag-to-deposit is unavailable there;
    -- deposit by dragging a bag item onto a bank slot, withdraw by right-clicking a
    -- bank slot. The taint-safe hooksecurefunc trackers (InitBagHook) still run.
    if WHC.client and WHC.client.is1_14 then return end

    -- 1.12 only: plain insecure global functions, safe to wrap
    GB.savedPickup = PickupContainerItem
    PickupContainerItem = function(bag, slot, a3)
        if GB.TryWithdrawTo(bag, slot) then return end
        return GB.savedPickup(bag, slot, a3)
    end
    GB.InstallUseHook()
end

-- restore the untouched originals so normal use / disenchant works outside the bank
function GB.RemoveBagHooks()
    if not GB.bagHooksInstalled then return end
    GB.bagHooksInstalled = false

    if GB.savedPickup then
        PickupContainerItem = GB.savedPickup
        GB.savedPickup = nil
    end
    if GB.savedUse then
        UseContainerItem = GB.savedUse
        GB.savedUse = nil
    end
    GB.hookedUse = nil
end

-- install only when the window is open AND we have full (at-banker) access, since
-- read-only/remote sessions can't deposit anyway; keeps the protected functions
-- pristine (untainted) the rest of the time
function GB.RefreshBagHooks()
    if GB.frame and GB.frame:IsVisible() and GB.state.mode == "full" then
        GB.InstallBagHooks()
    else
        GB.RemoveBagHooks()
    end
end

-- returns true if the click was consumed as a bank->bag withdrawal
function GB.TryWithdrawTo(bag, slot)
    if not GB.picked then return false end
    if not (GB.frame and GB.frame:IsVisible()) then return false end
    if bag == nil or bag < 0 or bag > 4 then return false end   -- real bags only (bank/keyring use other ids)
    if CursorHoldsItem() then return false end                  -- real item on the cursor: normal behavior
    local picked = GB.picked
    GB.ClearPicked()
    if Throttled() then return true end                         -- swallow, pick already cleared
    -- client coords (bag 0-4, slot 1-based); server places there, auto-falls-back if it can't
    Send("withdraw " .. picked.tab .. " " .. picked.slot .. " " .. (picked.count or 0) .. " " .. bag .. " " .. slot)
    return true
end

-- returns true if the click was consumed as a guild bank deposit
function GB.TryAutoDeposit(bag, slot)
    if not (GB.frame and GB.frame:IsVisible()) then return false end
    if GB.picked then GB.ClearPicked() return true end      -- right-click cancels a picked bank item
    if GB.state.mode ~= "full" then return false end        -- must be at the banker
    if GB.state.numTabs == 0 then return false end
    -- let the default handlers win when another right-click target is open
    if BankFrame and BankFrame:IsVisible() then return false end
    if MerchantFrame and MerchantFrame:IsVisible() then return false end
    if MailFrame and MailFrame:IsVisible() then return false end
    if TradeFrame and TradeFrame:IsVisible() then return false end
    if AuctionFrame and AuctionFrame:IsVisible() then return false end
    if not GetBagItemLink(bag, slot) then return false end
    if Throttled() then return true end                     -- swallow, don't use/equip
    Send("deposit " .. GB.state.curTab .. " 255 " .. bag .. " " .. slot .. " 0")
    return true
end

function GB.InstallUseHook()
    if UseContainerItem == GB.hookedUse then return end     -- already ours
    local orig = UseContainerItem
    GB.savedUse = orig                                      -- restored by RemoveBagHooks
    GB.hookedUse = function(bagId, slot, onSelf)
        if GB.TryAutoDeposit(bagId, slot) then return end
        return orig(bagId, slot, onSelf)
    end
    UseContainerItem = GB.hookedUse
end

-- ---------------------------------------------------------------------------
-- slot interaction
-- ---------------------------------------------------------------------------
function GB.OnSlotClick(btn, button)
    local tab = GB.state.curTab
    local slot = btn.slot
    local items = GB.state.items[tab] or {}
    local item = items[slot]

    if button == "RightButton" then
        if GB.picked then
            GB.ClearPicked()
            return
        end
        if not item then return end
        if not CheckFull() then return end
        if Throttled() then return end
        if IsShiftKeyDown() and item.count and item.count > 1 then
            GB.splitContext = { action = "withdraw", tab = tab, slot = slot }
            OpenSplit(item.count, btn)
        else
            Send("withdraw " .. tab .. " " .. slot .. " 0")
        end
        return
    end

    -- left click
    if GB.picked then
        -- drop virtual cursor here (move / merge / swap / split-move)
        if not CheckFull() then GB.ClearPicked() return end
        if Throttled() then return end
        local count = GB.picked.count or 0
        Send("move " .. GB.picked.tab .. " " .. GB.picked.slot .. " " .. tab .. " " .. slot .. " " .. count)
        GB.ClearPicked()
        return
    end

    if CursorHoldsItem() and GB.cursorBag then
        -- deposit the real bag item on the cursor into this slot
        if not CheckFull() then return end
        if Throttled() then return end
        Send("deposit " .. tab .. " " .. slot .. " " .. GB.cursorBag.bag .. " " .. GB.cursorBag.slot .. " 0")
        ClearCursor()
        GB.cursorBag = nil
        return
    end

    if not item then return end
    if not CheckFull() then return end

    if IsShiftKeyDown() and item.count and item.count > 1 then
        GB.splitContext = { action = "pickup", tab = tab, slot = slot }
        OpenSplit(item.count, btn)
        return
    end

    -- virtual pickup (full stack)
    GB.picked = { tab = tab, slot = slot, count = 0, icon = item.icon }
    GB.cursorFrame.icon:SetTexture(ICONS .. (item.icon or "INV_Misc_QuestionMark"))
    GB.cursorFrame:Show()
    GB.HighlightPicked()
end

function GB.OnSplitStack(owner, split)
    local ctx = GB.splitContext
    GB.splitContext = nil
    if not ctx or not split or split <= 0 then return end
    if ctx.action == "withdraw" then
        if Throttled() then return end
        Send("withdraw " .. ctx.tab .. " " .. ctx.slot .. " " .. split)
    elseif ctx.action == "pickup" then
        local items = GB.state.items[ctx.tab] or {}
        local item = items[ctx.slot]
        if not item then return end
        GB.picked = { tab = ctx.tab, slot = ctx.slot, count = split, icon = item.icon }
        GB.cursorFrame.icon:SetTexture(ICONS .. (item.icon or "INV_Misc_QuestionMark"))
        GB.cursorFrame:Show()
        GB.HighlightPicked()
    end
end

function GB.OnSlotEnter(btn)
    local items = GB.state.items[GB.state.curTab] or {}
    local item = items[btn.slot]
    if not item then return end
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    local link = "item:" .. item.id .. ":" .. (item.ench or 0) .. ":" .. (item.rand or 0) .. ":0"
    local ok = true
    if GameTooltip.SetHyperlink then
        local res
        if pcall then
            res = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
        else
            GameTooltip:SetHyperlink(link)
            res = true
        end
        ok = res
    end
    -- uncached items on 1.12 may produce an empty tooltip: show a minimal one
    if not ok or GameTooltip:NumLines() == 0 then
        local color = QUALITY_COLORS[item.quality or 1] or "|cffffffff"
        GameTooltip:SetText(color .. (item.name or "?") .. "|r")
    end
    if item.count and item.count > 1 then
        GameTooltip:AddLine("Stack: " .. item.count, 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
end

function GB.OnBuyTabClick()
    if Throttled() then return end
    -- simple confirm
    StaticPopupDialogs["WHC_GB_BUYTAB"] = {
        text = "Buy the next guild bank tab for " .. FormatGold(GB.state.nextTabCost) .. "?",
        button1 = OKAY or "Okay",
        button2 = CANCEL or "Cancel",
        OnAccept = function() Send("buytab") end,
        timeout = 30,
        whileDead = 1,
        hideOnEscape = 1,
    }
    StaticPopup_Show("WHC_GB_BUYTAB")
end

-- ---------------------------------------------------------------------------
-- views / rendering
-- ---------------------------------------------------------------------------
function GB.SetView(view)
    GB.state.view = view
    GB.UpdateBankPanels()
    if GB.logPanel then
        if view == "log" or view == "moneylog" then GB.logPanel:Show() else GB.logPanel:Hide() end
    end
    if GB.infoPanel then
        if view == "info" then GB.infoPanel:Show() else GB.infoPanel:Hide() end
    end
    -- tab active/inactive states (same visuals as the main WHC window tabs)
    for key, b in pairs(GB.viewButtons or {}) do
        if key == view then
            b:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-ActiveTab")
            b.tabText:SetTextColor(1, 1, 1)
            b:Disable()
        else
            b:SetNormalTexture("Interface/PaperDollInfoFrame/UI-Character-InActiveTab")
            b.tabText:SetTextColor(0.933, 0.765, 0)
            b:Enable()
        end
    end
    if view == "log" then
        Send("log " .. GB.state.curTab)
    elseif view == "moneylog" then
        Send("log " .. MONEY_TAB)
    elseif view == "info" then
        if GB.state.isManager then
            Send("rights")
        end
    end
    GB.UpdateLogList()
end

function GB.SelectTab(tabId)
    GB.state.curTab = tabId
    for t = 0, MAX_TABS - 1 do
        local tb = GB.tabButtons[t]
        if tb then
            if t == tabId then tb.button.checked:Show() else tb.button.checked:Hide() end
        end
    end
    GB.ClearPicked()
    GB.RepaintGrid()
    GB.UpdateHeader()           -- refresh the per-tab "Remaining Daily Withdrawals" label
    Send("tab " .. tabId)
    local info = GB.state.tabs[tabId]
    if GB.state.view == "log" and info and info.view == 1 then
        Send("log " .. tabId)       -- skipped for unviewable tabs: blackout instead of a server error
    end
    -- re-evaluate the log blackout right away: a denied log request never
    -- replies, so the overlay must not wait on server data
    if GB.state.view == "log" or GB.state.view == "moneylog" then
        GB.UpdateLogList()
    end
end

function GB.RepaintGrid()
    local tab = GB.state.curTab
    local tabInfo = GB.state.tabs[tab]
    local canView = tabInfo and tabInfo.view == 1
    if GB.noViewOverlay then
        -- only when the tab is known AND denied; no overlay while data loads
        if tabInfo and not canView then GB.noViewOverlay:Show() else GB.noViewOverlay:Hide() end
    end
    local items = GB.state.items[tab] or {}
    for slot = 0, SLOTS - 1 do
        local b = GB.slotButtons[slot]
        local item = items[slot]
        if item and canView then
            b.icon:SetTexture(ICONS .. (item.icon or "INV_Misc_QuestionMark"))
            b.icon:Show()
            if item.count and item.count > 1 then
                b.countText:SetText(item.count)
            else
                b.countText:SetText("")
            end
            local q = item.quality or 1
            if q >= 2 then
                local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
                if color then
                    b.qborder:SetVertexColor(color.r, color.g, color.b, 0.8)
                    b.qborder:Show()
                else
                    b.qborder:Hide()
                end
            else
                b.qborder:Hide()
            end
        else
            b.icon:Hide()
            b.countText:SetText("")
            b.qborder:Hide()
        end
    end
    GB.UpdateTitle()
    GB.HighlightPicked()
end

-- WotLK-style banner title: "<Tab Name> (Full Access)" etc.
function GB.UpdateTitle()
    local tabInfo = GB.state.tabs[GB.state.curTab]
    local name
    if GB.state.numTabs == 0 then
        name = "Guild Bank"
    else
        name = (tabInfo and tabInfo.name) or ("Tab " .. (GB.state.curTab + 1))
    end
    local suffix = ""
    if GB.state.numTabs > 0 then
        if tabInfo and tabInfo.view ~= 1 then
            suffix = " |cffff2020(Locked)|r"
        elseif GB.state.mode == "full" then
            suffix = " |cff20ff20(Full Access)|r"
        else
            suffix = " |cffa0a0a0(View Only)|r"
        end
    end
    GB.title:SetText(name .. suffix)
    if GB.titleBanner then
        GB.titleBanner:SetWidth(GB.title:GetStringWidth() + 20)
    end
end

function GB.UpdateHeader()
    -- bottom bar: withdrawable amount left, total funds right
    local money = tonumber(GB.state.money) or 0
    local gr = tonumber(GB.state.goldRemain) or 0
    local avail
    if gr == -1 then
        avail = money
    else
        avail = gr < money and gr or money
    end
    GB.availMoney:SetMoney(avail)
    GB.fundsMoney:SetMoney(money)

    -- centered strip label: remaining item withdrawals for the current tab
    local tabInfo = GB.state.tabs[GB.state.curTab]
    if GB.state.numTabs == 0 or not tabInfo then
        GB.limitText:SetText("")
    else
        local tabName = "|cffffffff" .. (tabInfo.name or ("Tab " .. (GB.state.curTab + 1))) .. "|r"
        local remain = tabInfo.stacksRemain or 0
        local unit = (remain == 1) and " Stack" or " Stacks"
        if remain == -1 then
            GB.limitText:SetText("Remaining Daily Withdrawals for " .. tabName .. ":  |cff20ff20Unlimited|r")
        elseif remain > 0 then
            GB.limitText:SetText("Remaining Daily Withdrawals for " .. tabName .. ":  |cff20ff20" .. remain .. unit .. "|r")
        else
            GB.limitText:SetText("Remaining Daily Withdrawals for " .. tabName .. ":  |cffff2020" .. remain .. unit .. "|r")
        end
    end
    if GB.limitBanner then
        GB.limitBanner:SetWidth(GB.limitText:GetStringWidth() + 20)
    end
    GB.UpdateTitle()

    -- side tabs
    for t = 0, MAX_TABS - 1 do
        local tb = GB.tabButtons[t]
        if tb then
            if t < GB.state.numTabs then
                tb.frame:Show()
                tb.button:Show()
                local info = GB.state.tabs[t]
                tb.button.icon:SetTexture(ICONS .. ((info and info.icon) or "INV_Misc_Bag_10"))
                if info and info.view ~= 1 then
                    tb.button.icon:SetVertexColor(0.4, 0.4, 0.4)
                else
                    tb.button.icon:SetVertexColor(1, 1, 1)
                end
                -- safety: never let the manual hover glow stick on a repainted tab
                if tb.button.hover and not MouseIsOver(tb.button) then tb.button.hover:Hide() end
            else
                tb.frame:Hide()
            end
        end
    end
    -- buy tab button placement
    if GB.state.numTabs < MAX_TABS then
        GB.buyTab:ClearAllPoints()
        if GB.state.numTabs == 0 then
            GB.buyTab:SetPoint("TOPLEFT", GB.frame, "TOPRIGHT", -2, -32)
        else
            GB.buyTab:SetPoint("TOPLEFT", GB.tabButtons[GB.state.numTabs - 1].frame, "BOTTOMLEFT", 0, 0)
        end
        GB.buyTab:Show()
    else
        GB.buyTab:Hide()
    end

    -- permissions view only for managers
    if GB.viewButtons and GB.viewButtons.info then
        if GB.state.isManager then
            GB.viewButtons.info:Show()
        else
            GB.viewButtons.info:Hide()
        end
    end
    -- money buttons
    if GB.state.mode == "full" then
        GB.depositBtn:Enable()
        GB.withdrawBtn:Enable()
    else
        GB.depositBtn:Disable()
        GB.withdrawBtn:Disable()
    end

    GB.UpdateBankPanels()
end

function GB.UpdateLogList()
    if GB.state.view ~= "log" and GB.state.view ~= "moneylog" then
        for i = 1, GB.NUM_LOG_ROWS or 0 do
            GB.rows[i]:SetText("")
        end
        return
    end
    local tab = (GB.state.view == "moneylog") and MONEY_TAB or GB.state.curTab
    -- selected side tab not viewable: blackout (item log AND money log) and
    -- blank the rows so stale lines from the previous tab can't shine through
    if GB.noViewLogOverlay then
        local curInfo = GB.state.tabs[GB.state.curTab]
        if curInfo and curInfo.view ~= 1 then
            GB.noViewLogOverlay:Show()
            for i = 1, GB.NUM_LOG_ROWS or 0 do
                GB.rows[i]:SetText("")
            end
            FauxScrollFrame_Update(GB.logScroll, 0, GB.NUM_LOG_ROWS, GB.logRowH)
            return
        end
        GB.noViewLogOverlay:Hide()
    end
    local data = GB.state.logs[tab] or {}
    local total = table.getn(data)
    local shown = GB.NUM_LOG_ROWS
    FauxScrollFrame_Update(GB.logScroll, total, shown, GB.logRowH)
    local offset = FauxScrollFrame_GetOffset(GB.logScroll)
    for i = 1, shown do
        local e = data[i + offset]
        local row = GB.rows[i]
        if e then
            row:SetText(GB.FormatLogLine(e, tab))
        else
            row:SetText("")
        end
    end
    if total == 0 and GB.rows[1] then
        GB.rows[1]:SetText("|cff808080No transactions recorded.|r")
    end
end

-- deposits/buys in green, withdrawals in red; player names stay white;
-- item names in their quality color with [brackets]
function GB.FormatLogLine(e, tab)
    local GREEN, RED, NEUTRAL = "|cff20ff20", "|cffff2020", "|cffffd100"
    local who = "|cffffffff" .. (e.who or "?") .. "|r"
    local when = "  |cff009999" .. FormatAge(e.age) .. "|r"
    if tab == MONEY_TAB then
        local amount = FormatMoney(e.itemOrMoney)
        if e.type == 4 then
            return who .. GREEN .. " deposited |r" .. amount .. when
        elseif e.type == 5 then
            return who .. RED .. " withdrew |r" .. amount .. when
        elseif e.type == 6 then
            return who .. GREEN .. " bought bank tab " .. ((e.destTab or 0) + 1) .. " for |r" .. amount .. when
        end
        return who .. " ? " .. amount .. when
    end
    local qcolor = QUALITY_COLORS[e.quality or 1] or "|cffffffff"
    local rawName = (e.itemName and e.itemName ~= "") and e.itemName or ("item " .. (e.itemOrMoney or "?"))
    local itemStr = qcolor .. "[" .. rawName .. "]|r"
    local countStr = ""
    if e.count and e.count > 1 then
        countStr = " x" .. e.count
    end
    if e.type == 1 then
        return who .. GREEN .. " deposited |r" .. itemStr .. GREEN .. countStr .. "|r" .. when
    elseif e.type == 2 then
        return who .. RED .. " withdrew |r" .. itemStr .. RED .. countStr .. "|r" .. when
    elseif e.type == 3 then
        return who .. NEUTRAL .. " moved |r" .. itemStr .. NEUTRAL .. countStr .. " to tab " .. ((e.destTab or 0) + 1) .. "|r" .. when
    end
    return who .. " ?" .. when
end

-- only rank 0 edits everything; a manager edits only ranks strictly below their
-- own (mirrors GbCanEditRank server-side). Unknown own-rank: let the server decide.
function GB.CanEditRank(rid)
    local my = GB.state.myRank
    if my == nil or my == 0 then return true end
    return rid > my
end

-- serialized snapshot of every widget on the permissions form; taken when a rank
-- is painted (and after Save) so a dropdown switch can detect unsaved edits
function GB.RankFormState()
    local s = (GB.cbManage:GetChecked() and "1" or "0")
           .. (GB.cbWdrGold:GetChecked() and "1" or "0")
           .. "|" .. GB.ebGold:GetText()
    for t = 0, MAX_TABS - 1 do
        local row = GB.tabRights[t]
        s = s .. "|" .. (row.view:GetChecked() and "1" or "0")
              .. (row.dep:GetChecked() and "1" or "0")
              .. (row.move:GetChecked() and "1" or "0")
              .. "," .. row.stacks:GetText()
    end
    return s
end

function GB.RankFormDirty()
    return GB.rankSnapshot ~= nil and GB.RankFormState() ~= GB.rankSnapshot
end

-- reassert the dropdown's displayed selection from GB.selectedRank
function GB.RefreshRankDD()
    local rid = GB.selectedRank
    local r = (rid ~= nil) and GB.state.ranks[rid] or nil
    if not r then return end
    UIDropDownMenu_SetSelectedValue(GB.rankDD, rid)
    GB.SetRankDDText(rid .. " - " .. r.name)
end

function GB.SelectRank(rid)
    GB.selectedRank = rid
    local r = GB.state.ranks[rid]
    if not r then return end
    UIDropDownMenu_SetSelectedValue(GB.rankDD, rid)
    GB.SetRankDDText(rid .. " - " .. r.name)
    local isGM = (rid == 0)
    GB.cbManage:SetChecked(WHC.CheckedValue(GB.HasBit(r.rights, 1) and 1 or 0))
    GB.cbWdrGold:SetChecked(WHC.CheckedValue(GB.HasBit(r.rights, 4) and 1 or 0))
    GB.ebGold:SetText(tostring(math.floor((r.goldPerDay or 0) / 10000)))
    for t = 0, MAX_TABS - 1 do
        local row = GB.tabRights[t]
        local tr = r.tabs[t] or { rights = 0, stacks = 0 }
        row.view:SetChecked(WHC.CheckedValue(GB.HasBit(tr.rights, 1) and 1 or 0))
        row.dep:SetChecked(WHC.CheckedValue(GB.HasBit(tr.rights, 2) and 1 or 0))
        row.move:SetChecked(WHC.CheckedValue(GB.HasBit(tr.rights, 4) and 1 or 0))
        row.stacks:SetText(tostring(tr.stacks or 0))
        local info = GB.state.tabs[t]
        row.label:SetText((info and info.name) or ("Tab " .. (t + 1)))
    end
    if isGM then
        GB.rightsSave:Disable()
    else
        GB.rightsSave:Enable()
    end
    GB.rankSnapshot = GB.RankFormState()
end

function GB.HasBit(value, bit)
    value = tonumber(value) or 0
    return math.floor(value / bit) - 2 * math.floor(value / (bit * 2)) == 1
end

function GB.SaveRank()
    local rid = GB.selectedRank
    if not rid or rid == 0 then return end
    if not GB.CanEditRank(rid) then
        ErrMsg(GB_ERRORS[23])
        return
    end
    local rights = 0
    if GB.cbManage:GetChecked() then rights = rights + 1 end
    if GB.cbWdrGold:GetChecked() then rights = rights + 4 end
    local gold = (tonumber(GB.ebGold:GetText()) or 0) * 10000
    Send("setrank " .. rid .. " " .. rights .. " " .. gold)
    -- update the local rank cache as we go: without this, reselecting the rank
    -- before the server re-push repaints the pre-save values ("save didn't work")
    local r = GB.state.ranks[rid]
    if r then
        r.rights = rights
        r.goldPerDay = gold
    end
    for t = 0, MAX_TABS - 1 do
        local row = GB.tabRights[t]
        local tr = 0
        if row.view:GetChecked() then tr = tr + 1 end
        if row.dep:GetChecked() then tr = tr + 2 end
        if row.move:GetChecked() then tr = tr + 4 end
        local stacks = tonumber(row.stacks:GetText()) or 0
        Send("setranktab " .. rid .. " " .. t .. " " .. tr .. " " .. stacks)
        if r then
            r.tabs[t] = { rights = tr, stacks = stacks }
        end
    end
    -- the server broadcasts the authoritative rank block to all open managers
    -- (incl. us) ~750ms after the burst above; the optimistic cache covers the gap
    GB.rankSnapshot = GB.RankFormState()
    Msg("Rank permissions saved.")
end

-- ---------------------------------------------------------------------------
-- open / close
-- ---------------------------------------------------------------------------
function GB.Toggle()
    if GB.frame:IsVisible() then
        GB.frame:Hide()
    else
        -- try full access first; the server replies gb:err^2 if no banker,
        -- and the error handler falls back to browse
        GB.openFallback = true
        Send("open")
    end
end

function GB.OnOpenReply(payload)
    local f = Split(payload, "^")
    GB.state.mode = f[1] or "ro"
    GB.state.money = tonumber(f[2]) or 0
    GB.state.numTabs = tonumber(f[3]) or 0
    GB.state.isManager = (f[4] == "1")
    GB.state.grights = tonumber(f[5]) or 0
    GB.state.goldRemain = tonumber(f[6]) or 0
    GB.state.nextTabCost = tonumber(f[7]) or 0
    GB.state.myRank = tonumber(f[8])            -- own rank id (nil on old servers)
    GB.openFallback = nil
    if not GB.frame:IsVisible() then
        GB.frame:Show()
        PlaySound(WHC.SOUNDS.openFrame)
    end
    GB.RefreshBagHooks()            -- full mode → intercept bag clicks; ro → leave fns pristine
    GB.UpdateHeader()
    GB.RepaintGrid()
end

-- ---------------------------------------------------------------------------
-- server message dispatch (called from Events.lua)
-- ---------------------------------------------------------------------------
function GB.OnServerLine(line)
    -- strip "::whc::gb:"
    local body = string.gsub(line, "^::whc::gb:", "")

    if string.find(body, "^open%^") then
        GB.OnOpenReply(string.gsub(body, "^open%^", ""))
        return
    end

    if string.find(body, "^tab%^") then
        local f = Split(string.gsub(body, "^tab%^", ""), "^")
        GB.pendingTabs = GB.pendingTabs or {}
        local t = tonumber(f[1])
        if t then
            GB.pendingTabs[t] = {
                view = tonumber(f[2]) or 0,
                dep = tonumber(f[3]) or 0,
                move = tonumber(f[4]) or 0,
                stacksRemain = tonumber(f[5]) or 0,
                icon = f[6],
                name = f[7],
            }
        end
        return
    end
    if string.find(body, "^tabsend%^") then
        GB.state.tabs = GB.pendingTabs or {}
        GB.pendingTabs = nil
        GB.state.numTabs = tonumber((string.gsub(body, "^tabsend%^", ""))) or GB.state.numTabs
        GB.UpdateHeader()
        if GB.state.numTabs > 0 then
            local cur = GB.state.curTab
            if cur >= GB.state.numTabs then cur = 0 end
            GB.SelectTab(cur)
        else
            GB.RepaintGrid()
        end
        return
    end

    if string.find(body, "^item%^") then
        local f = Split(string.gsub(body, "^item%^", ""), "^")
        local t = tonumber(f[1])
        local slot = tonumber(f[2])
        if not t or not slot then return end
        GB.pendingItems = GB.pendingItems or {}
        GB.pendingItems[t] = GB.pendingItems[t] or {}
        local id = tonumber(f[3]) or 0
        if id > 0 then
            GB.pendingItems[t][slot] = {
                id = id,
                count = tonumber(f[4]) or 1,
                quality = tonumber(f[5]) or 1,
                maxStack = tonumber(f[6]) or 1,
                rand = tonumber(f[7]) or 0,
                ench = tonumber(f[8]) or 0,
                icon = f[9],
                name = f[10],
            }
        end
        return
    end
    if string.find(body, "^itemend%^") then
        local t = tonumber((string.gsub(body, "^itemend%^", "")))
        if t then
            GB.state.items[t] = (GB.pendingItems and GB.pendingItems[t]) or {}
            if GB.pendingItems then GB.pendingItems[t] = nil end
            if t == GB.state.curTab then
                GB.RepaintGrid()
            end
        end
        return
    end

    if string.find(body, "^slot%^") then
        local f = Split(string.gsub(body, "^slot%^", ""), "^")
        local t = tonumber(f[1])
        local slot = tonumber(f[2])
        local id = tonumber(f[3]) or 0
        if t and slot then
            GB.state.items[t] = GB.state.items[t] or {}
            if id > 0 then
                GB.state.items[t][slot] = {
                    id = id,
                    count = tonumber(f[4]) or 1,
                    quality = tonumber(f[5]) or 1,
                    maxStack = tonumber(f[6]) or 1,
                    rand = tonumber(f[7]) or 0,
                    ench = tonumber(f[8]) or 0,
                    icon = f[9],
                    name = f[10],
                }
            else
                GB.state.items[t][slot] = nil
            end
            if t == GB.state.curTab then
                GB.RepaintGrid()
            end
        end
        return
    end

    if string.find(body, "^money%^") then
        GB.state.money = tonumber((string.gsub(body, "^money%^", ""))) or 0
        GB.UpdateHeader()
        return
    end

    if string.find(body, "^wmoneyok%^") then
        local copper = tonumber((string.gsub(body, "^wmoneyok%^", ""))) or 0
        Msg("You withdrew " .. FormatMoney(copper) .. " from the guild bank.")
        return
    end

    if string.find(body, "^remain%^") then
        local f = Split(string.gsub(body, "^remain%^", ""), "^")
        GB.state.goldRemain = tonumber(f[1]) or 0
        local stacks = Split(f[2] or "", ";")
        for t = 0, MAX_TABS - 1 do
            if GB.state.tabs[t] then
                GB.state.tabs[t].stacksRemain = tonumber(stacks[t + 1]) or GB.state.tabs[t].stacksRemain
            end
        end
        GB.UpdateHeader()
        return
    end

    if string.find(body, "^tabbought%^") then
        local f = Split(string.gsub(body, "^tabbought%^", ""), "^")
        GB.state.numTabs = tonumber(f[1]) or GB.state.numTabs
        GB.state.nextTabCost = tonumber(f[2]) or 0
        Msg("Guild bank tab purchased!")
        GB.UpdateHeader()
        return
    end

    if string.find(body, "^rank%^") then
        local f = Split(string.gsub(body, "^rank%^", ""), "^")
        local rid = tonumber(f[1])
        if rid then
            GB.pendingRanks = GB.pendingRanks or { order = {}, ranks = {} }
            local tabs = {}
            local tabParts = Split(f[4] or "", ";")
            for t = 0, MAX_TABS - 1 do
                local pair = Split(tabParts[t + 1] or "0,0", ",")
                tabs[t] = { rights = tonumber(pair[1]) or 0, stacks = tonumber(pair[2]) or 0 }
            end
            GB.pendingRanks.ranks[rid] = {
                rights = tonumber(f[2]) or 0,
                goldPerDay = tonumber(f[3]) or 0,
                tabs = tabs,
                name = f[5] or ("Rank " .. rid),
            }
            table.insert(GB.pendingRanks.order, rid)
        end
        return
    end
    if string.find(body, "^rankend") then
        if GB.pendingRanks then
            GB.state.ranks = GB.pendingRanks.ranks
            GB.state.rankOrder = GB.pendingRanks.order
            GB.pendingRanks = nil
            -- server also broadcasts this block when another manager saves; if
            -- this form has unsaved edits, keep them (cache is fresh regardless)
            if GB.RankFormDirty() then
                return
            end
            -- default to the LOWEST rank (last in order) that we may edit;
            -- keep the current selection across refreshes while it stays valid
            local order = GB.state.rankOrder
            local first = nil
            for i = table.getn(order), 1, -1 do
                if GB.CanEditRank(order[i]) then
                    first = order[i]
                    break
                end
            end
            if GB.selectedRank and GB.state.ranks[GB.selectedRank] and GB.CanEditRank(GB.selectedRank) then
                first = GB.selectedRank
            end
            if first ~= nil then
                GB.SelectRank(first)
            end
        end
        return
    end

    if string.find(body, "^log%^") then
        local f = Split(string.gsub(body, "^log%^", ""), "^")
        local t = tonumber(f[1])
        if t then
            GB.pendingLogs = GB.pendingLogs or {}
            GB.pendingLogs[t] = GB.pendingLogs[t] or {}
            local entry = {
                type = tonumber(f[2]) or 0,
                itemOrMoney = tonumber(f[3]) or 0,
                count = tonumber(f[4]) or 0,
                destTab = tonumber(f[5]) or 0,
                age = tonumber(f[6]) or 0,
                quality = tonumber(f[7]) or 1,
                icon = f[8],
                itemName = f[9],
                who = f[10],
            }
            -- newest first
            table.insert(GB.pendingLogs[t], 1, entry)
        end
        return
    end
    if string.find(body, "^logend%^") then
        local t = tonumber((string.gsub(body, "^logend%^", "")))
        if t then
            GB.state.logs[t] = (GB.pendingLogs and GB.pendingLogs[t]) or {}
            if GB.pendingLogs then GB.pendingLogs[t] = nil end
            GB.UpdateLogList()
        end
        return
    end

    if string.find(body, "^tabtextc%^") then
        local f = Split(string.gsub(body, "^tabtextc%^", ""), "^")
        local t = tonumber(f[1])
        if t then
            GB.pendingText = GB.pendingText or {}
            GB.pendingText[t] = (GB.pendingText[t] or "") .. (f[2] or "")
        end
        return
    end
    if string.find(body, "^tabtextend%^") then
        local t = tonumber((string.gsub(body, "^tabtextend%^", "")))
        if t then
            GB.state.tabText[t] = (GB.pendingText and GB.pendingText[t]) or ""
            if GB.pendingText then GB.pendingText[t] = nil end
        end
        return
    end

    if string.find(body, "^err%^") then
        local code = tonumber((string.gsub(body, "^err%^", "")))
        if code == 2 and GB.openFallback then
            -- no banker in range: fall back to read-only browsing
            GB.openFallback = nil
            Send("browse")
            return
        end
        GB.openFallback = nil
        ErrMsg(GB_ERRORS[code] or ("Guild bank error " .. tostring(code)))
        return
    end

    if string.find(body, "^closed") then
        GB.state.mode = "closed"
        if GB.frame:IsVisible() then
            GB.frame:Hide()
        end
        return
    end
end
