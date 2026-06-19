-- WOW-HC Group Finder
-- Standalone group-finder window (its own minimap Eye button), talking to the
-- server over the existing .whc / ::whc:: channel.
-- The window reproduces the "Looking For Turtles" (LFT) look: the stone LFG
-- frame art, round Tank/Heal/DPS role icons, a Type dropdown, a color-coded
-- dungeon list, a red "Find Group" button, and Dungeons / Browse bottom tabs.

WHC.GF = WHC.GF or {}
local GF = WHC.GF

local ART = "Interface\\AddOns\\WOW_HC\\Images\\groupfinder\\"

GF.ROLE = { TANK = 1, HEALER = 2, DPS = 4 }

local function hasRole(mask, bit)
    mask = tonumber(mask) or 0
    local q = math.floor(mask / bit)
    return (q - math.floor(q / 2) * 2) == 1
end

-- WoW class id -> English token (for RAID_CLASS_COLORS)
local CLASS_TOKEN = {
    [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST",
    [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID",
}
local function classColor(classId)
    local token = CLASS_TOKEN[tonumber(classId) or 0]
    local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 1, 0.82, 0
end
local function classHex(classId)
    local r, g, b = classColor(classId)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local ROLE_ICON_FILE = { [1] = "tank2", [2] = "healer2", [4] = "damage2" }

-- ============================================================================
-- dungeon data
-- ============================================================================
GF.dungeons = {
    { id = 389, name = "Ragefire Chasm",     min = 13, max = 18, t = "dungeon", icon = nil },
    { id = 36,  name = "The Deadmines",      min = 17, max = 26, t = "dungeon", icon = "deadmines" },
    { id = 43,  name = "Wailing Caverns",    min = 17, max = 24, t = "dungeon", icon = "wailingcaverns" },
    { id = 33,  name = "Shadowfang Keep",    min = 22, max = 30, t = "dungeon", icon = "shadowfangkeep" },
    { id = 34,  name = "The Stockade",       min = 24, max = 32, t = "dungeon", icon = "stormwindstockades" },
    { id = 48,  name = "Blackfathom Deeps",  min = 24, max = 32, t = "dungeon", icon = "blackfathomdeeps" },
    { id = 90,  name = "Gnomeregan",         min = 29, max = 38, t = "dungeon", icon = "gnomeregan" },
    { id = 47,  name = "Razorfen Kraul",     min = 29, max = 38, t = "dungeon", icon = "razorfenkraul" },
    { id = 189, name = "Scarlet Monastery",  min = 34, max = 45, t = "dungeon", icon = "scarletmonastery" },
    { id = 129, name = "Razorfen Downs",     min = 37, max = 46, t = "dungeon", icon = "razorfendowns" },
    { id = 70,  name = "Uldaman",            min = 41, max = 51, t = "dungeon", icon = "uldaman" },
    { id = 209, name = "Zul'Farrak",         min = 44, max = 54, t = "dungeon", icon = "zulfarak" },
    { id = 349, name = "Maraudon",           min = 46, max = 55, t = "dungeon", icon = "maraudon" },
    { id = 109, name = "Sunken Temple",      min = 50, max = 60, t = "dungeon", icon = "sunkentemple" },
    { id = 230, name = "Blackrock Depths",   min = 52, max = 60, t = "dungeon", icon = "blackrockdepths" },
    { id = 229, name = "Blackrock Spire",    min = 55, max = 60, t = "dungeon", icon = "blackrockspire" },
    { id = 289, name = "Scholomance",        min = 58, max = 60, t = "dungeon", icon = "scholomance" },
    { id = 329, name = "Stratholme",         min = 58, max = 60, t = "dungeon", icon = "stratholme" },
    { id = 429, name = "Dire Maul",          min = 56, max = 60, t = "dungeon", icon = "diremaul" },
    { id = 249, name = "Onyxia's Lair",      min = 60, max = 60, t = "raid",    icon = nil },
    { id = 409, name = "Molten Core",        min = 60, max = 60, t = "raid",    icon = "moltencore" },
    { id = 469, name = "Blackwing Lair",     min = 60, max = 60, t = "raid",    icon = "blackwinglair" },
    { id = 309, name = "Zul'Gurub",          min = 60, max = 60, t = "raid",    icon = "zulgurub" },
    { id = 509, name = "Ruins of Ahn'Qiraj", min = 60, max = 60, t = "raid",    icon = "aqtemple" },
    { id = 531, name = "Ahn'Qiraj Temple",   min = 60, max = 60, t = "raid",    icon = "aqtemple" },
    { id = 533, name = "Naxxramas",          min = 60, max = 60, t = "raid",    icon = "naxxramas" },
    -- pvp (synthetic ids; not real instance maps)
    { id = 9003, name = "Warsong Gulch",           min = 1, max = 60, t = "pvp",      icon = nil },
    { id = 9002, name = "Arathi Basin",            min = 1, max = 60, t = "pvp",      icon = nil },
    { id = 9001, name = "Alterac Valley",          min = 1, max = 60, t = "pvp",      icon = nil },
    { id = 9004, name = "Mak'gora",                min = 1, max = 60, t = "pvp",      icon = nil },
    { id = 9005, name = "Duels",                   min = 1, max = 60, t = "pvp",      icon = nil },
    -- questing
    { id = 9006, name = "Leveling",                min = 1, max = 60, t = "questing", icon = nil },
    { id = 9007, name = "Duo-Leveling",            min = 1, max = 60, t = "questing", icon = nil },
    { id = 9008, name = "Looking for friends",     min = 1, max = 60, t = "questing", icon = nil },
}
GF.dungeonById = {}
for _, d in ipairs(GF.dungeons) do GF.dungeonById[d.id] = d end

local function DungeonName(id)
    local d = GF.dungeonById[tonumber(id)]
    return d and d.name or ("Map " .. tostring(id))
end
local function DungeonIcon(id)
    local d = GF.dungeonById[tonumber(id)]
    if d and d.icon then return ART .. "icon\\lfgicon-" .. d.icon end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- per-listing background art (file = ui-lfg-background-<name>.blp); nil -> no art
local DUNGEON_BG = {
    [389] = "ragefirechasm", [36] = "deadmines", [43] = "wailingcaverns", [33] = "shadowfangkeep",
    [34] = "stormwindstockades", [48] = "blackfathomdeeps", [90] = "gnomeregan", [47] = "razorfenkraul",
    [189] = "scarletmonastery", [129] = "razorfendowns", [70] = "uldaman", [209] = "zulfarak",
    [349] = "maraudon", [109] = "sunkentemple", [230] = "blackrockdepths", [229] = "blackrockspire",
    [289] = "scholomance", [329] = "stratholme", [429] = "diremaul",
    -- raids
    [249] = "onyxiaslair", [309] = "zulgurub", [509] = "ruinsofahnqiraj", [409] = "moltencore",
    [469] = "blackwinglair", [531] = "ahnqirajtemple", [533] = "naxxramas",
    -- pvp + questing (entries without art fall back to nil)
    [9001] = "alteracvalley", [9002] = "arathibasin", [9003] = "warsonggulch", [9004] = "makgora",
    [9006] = "questing", [9007] = "questingduo",
}
local function DungeonBg(id)
    local n = DUNGEON_BG[tonumber(id)]
    if n then return ART .. "background\\ui-lfg-background-" .. n end
    return nil
end

-- LFT difficulty coloring: red too-low, orange hard, yellow on-level, green outleveled
local function diffColorRGB(d)
    local lvl = UnitLevel("player") or 1
    if lvl < d.min then return 1.0, 0.25, 0.25 end
    if lvl <= d.min + 2 then return 1.0, 0.5, 0.0 end
    if lvl <= d.max then return 1.0, 0.82, 0.0 end
    return 0.25, 0.75, 0.25
end

-- ============================================================================
-- helpers
-- ============================================================================
local function gfSplit(s, sep)
    local out = {}
    local start = 1
    if s == nil then return out end
    while true do
        local i = string.find(s, sep, start, true)
        if not i then table.insert(out, string.sub(s, start)); break end
        table.insert(out, string.sub(s, start, i - 1))
        start = i + 1
    end
    return out
end

local function Send(cmd)
    SendChatMessage(".whc gf " .. cmd, "WHISPER", GetDefaultLanguage(), UnitName("player"))
end
GF.Send = Send

-- party invite is a different global per client (1.12 = InviteByName, 1.14 = InviteUnit)
local function GFInvite(name)
    if WHC.client and WHC.client.is1_12 then
        if InviteByName then InviteByName(name) end
    elseif InviteUnit then
        InviteUnit(name)
    end
end
local function GFWhisper(name)
    ChatFrame_OpenChat("/w " .. name .. " ")
end

-- UIDropDownMenu_SetWidth arg order differs by client:
--   1.12 = (width, frame[, padding])   1.14 = (frame, width[, padding])
local function GFSetDDWidth(dd, width)
    if WHC.client and WHC.client.is1_12 then
        UIDropDownMenu_SetWidth(width, dd)
    else
        UIDropDownMenu_SetWidth(dd, width)
    end
end

-- group/leader checks differ by client: 1.12 has GetNumPartyMembers/IsPartyLeader,
-- 1.14 (Classic) uses IsInGroup/UnitIsGroupLeader (the vanilla ones don't exist there)
local function GFInGroup()
    if WHC.client and WHC.client.is1_12 then
        return (GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)
    end
    return IsInGroup() and true or false
end
local function GFIsLeader()
    if WHC.client and WHC.client.is1_12 then
        -- truthiness, not "== 1": IsPartyLeader may return a boolean on this client,
        -- which would make a real party leader fail the check
        return (IsPartyLeader() or IsRaidLeader()) and true or false
    end
    return UnitIsGroupLeader("player") and true or false
end

local function RoleText(mask)
    mask = tonumber(mask) or 0
    -- always render all three slots in fixed order so every row stays aligned;
    -- roles the player doesn't have are dimmed instead of omitted
    local dim = "|cff3a3a3a"
    local tank = hasRole(mask, GF.ROLE.TANK)   and "|cff4a90d9Tank|r" or (dim .. "Tank|r")
    local heal = hasRole(mask, GF.ROLE.HEALER) and "|cff40c040Heal|r" or (dim .. "Heal|r")
    local dps  = hasRole(mask, GF.ROLE.DPS)    and "|cffd04040DPS|r"  or (dim .. "DPS|r")
    return tank .. " " .. heal .. " " .. dps
end

-- sort priority by primary role: Tank > Heal > DPS > none
local function roleRank(mask)
    mask = tonumber(mask) or 0
    if hasRole(mask, GF.ROLE.TANK) then return 1 end
    if hasRole(mask, GF.ROLE.HEALER) then return 2 end
    if hasRole(mask, GF.ROLE.DPS) then return 3 end
    return 4
end

local function FmtReturn(returnIn, online)
    if online == "1" then return "" end
    returnIn = tonumber(returnIn) or 0
    if returnIn <= 0 then return "|cff888888offline|r" end
    local mins = math.floor(returnIn / 60)
    if mins >= 60 then local h = math.floor(mins / 60); return string.format("|cffd0a020back %dh%02dm|r", h, mins - h * 60) end
    return string.format("|cffd0a020back %dm|r", mins)
end

-- red "in Xh Ym" / "offline" for a disconnected member ("" if online)
-- short duration: "Xh Ym" / "Xm" / "Xs"
local function fmtDur(s)
    s = math.max(0, math.floor(tonumber(s) or 0))
    if s >= 3600 then local h = math.floor(s / 3600); return string.format("%dh%02dm", h, math.floor((s - h * 3600) / 60))
    elseif s >= 60 then return string.format("%dm", math.floor(s / 60))
    else return string.format("%ds", s) end
end

local function returnRed(m)
    if not m or m.online == "1" then return "" end
    local ri = tonumber(m.returnIn) or 0
    local base
    if ri <= 0 then
        -- no return time set (disconnected): show how long until the listing is
        -- auto-removed for inactivity
        base = "Offline"
        local exp = tonumber(m.expireIn) or 0
        if exp > 0 then base = base .. ". Listing expires in " .. fmtDur(exp) end
    else
        local mins = math.floor(ri / 60)
        if mins >= 60 then
            local h = math.floor(mins / 60)
            base = string.format("Player will be back in %dh%02dm", h, mins - h * 60)
        else
            base = string.format("Player will be back in %dm", mins)
        end
    end
    return "|cffff3030" .. base .. "|r"
end

local function dungeonsSummary(csv)
    local names = {}
    for _, idStr in ipairs(gfSplit(csv, ",")) do
        if idStr ~= "" then table.insert(names, DungeonName(idStr)) end
    end
    return table.concat(names, ", ")
end

-- ============================================================================
-- state
-- ============================================================================
GF.listings = {}
GF.pending = {}
GF.mine = { state = 0, id = 0, dungeons = "", role = 0, note = "" }
GF.view = "browse"             -- "browse" | "create"
GF.filterType = "all"          -- activity selector: all | pve | pvp | questing
GF.selected = {}               -- dungeon id -> true (your selection for Find Group)
GF.roleSel = { TANK = false, HEALER = false, DPS = false }
GF.lastListReq = -100
GF.lastPost = -100
local LIST_CD, POST_CD = 10, 10

-- ============================================================================
-- networking
-- ============================================================================
function GF.RequestList(force, wipe)
    local now = GetTime()
    if not force and (now - GF.lastListReq) < LIST_CD then return end
    GF.lastListReq = now
    GF.pending = {}
    GF.loading = true
    if wipe then
        -- manual Refresh: briefly blank the list for visible feedback; the reply
        -- is held back until wipeUntil so the blank always shows
        GF.listings = {}
        GF.wipeUntil = now + 0.25
    else
        -- keep the current list visible until the reply replaces it, so a dropped
        -- reply (server cooldown) never leaves an empty list
        GF.wipeUntil = 0
    end
    if GF.frame and GF.frame:IsVisible() and GF.view == "browse" then GF.UpdateList() end
    Send("list")
end
function GF.RequestMine() Send("mine") end
-- fetch only your own listing (full roster). No cooldown; used on open, activity
-- change, your own role change, and a light poll while waiting in a forming group.
function GF.RequestMyListing() Send("mylisting") end

-- parse a "<id>^<leader>^<dungeons>^<note>^<members>" payload into a listing table
local function parseListing(payload)
    local f = gfSplit(payload, "^")
    local l = { id = tonumber(f[1]) or 0, leader = f[2] or "", dungeons = f[3] or "", note = f[4] or "", members = {} }
    for _, rec in ipairs(gfSplit(f[5] or "", ";")) do
        if rec ~= "" then
            local mf = gfSplit(rec, ",")
            table.insert(l.members, {
                name = mf[1] or "", roles = tonumber(mf[2]) or 0, online = mf[3] or "0",
                returnIn = tonumber(mf[4]) or 0, classId = tonumber(mf[5]) or 0, level = tonumber(mf[6]) or 0,
                expireIn = tonumber(mf[7]) or 0,
            })
        end
    end
    return l
end

function GF.OnListingLine(payload)
    table.insert(GF.pending, parseListing(payload))
end
local function listingLeader(l)
    for _, m in ipairs(l.members) do if m.name == l.leader then return m end end
    return l.members and l.members[1] or nil
end
-- is this the listing the player belongs to (as leader or as a member)?
local function isMineListing(l)
    local me = UnitName("player")
    if l.leader == me then return true end
    for _, m in ipairs(l.members) do if m.name == me then return true end end
    return false
end
-- own listing pinned first, then online leaders before offline, then level desc
local function sortListings(t)
    table.sort(t, function(a, b)
        local am = isMineListing(a) and 1 or 0
        local bm = isMineListing(b) and 1 or 0
        if am ~= bm then return am > bm end
        local la, lb = listingLeader(a), listingLeader(b)
        local oa = (la and la.online == "1") and 1 or 0
        local ob = (lb and lb.online == "1") and 1 or 0
        if oa ~= ob then return oa > ob end
        local va = (la and tonumber(la.level)) or 0
        local vb = (lb and tonumber(lb.level)) or 0
        if va ~= vb then return va > vb end
        return (a.leader or "") < (b.leader or "")
    end)
end

function GF.ApplyListings()
    if not GF.incoming then return end
    GF.listings = GF.incoming
    GF.incoming = nil
    GF.loading = false
    GF.activityStale = false   -- fresh data arrived; the nudge no longer applies
    sortListings(GF.listings)
    GF.lastRefreshed = GetTime()
    if GF.frame and GF.frame:IsVisible() and GF.view == "browse" then GF.UpdateList() end
end
function GF.OnListEnd()
    GF.incoming = GF.pending
    GF.pending = {}
    -- hold the refill until the brief wipe window elapses (see refresher OnUpdate)
    if (GF.wipeUntil or 0) <= GetTime() then GF.ApplyListings() end
end
function GF.OnMine(payload)
    GF.mineReceived = true   -- server answered; stop the post-login retry
    local f = gfSplit(payload, "^")
    GF.mine.state = tonumber(f[1]) or 0
    GF.mine.id = tonumber(f[2]) or 0
    GF.mine.dungeons = f[3] or ""
    GF.mine.role = tonumber(f[4]) or 0
    GF.mine.note = f[5] or ""
    -- reflect an existing listing (state 1) or your member role (state 2) back
    -- into the role controls so they show your current selection
    if GF.mine.state == 1 then
        GF.selected = {}
        for _, idStr in ipairs(gfSplit(GF.mine.dungeons, ",")) do GF.selected[tonumber(idStr)] = true end
    end
    if GF.mine.state == 1 or GF.mine.state == 2 then
        GF.roleSel.TANK = hasRole(GF.mine.role, GF.ROLE.TANK)
        GF.roleSel.HEALER = hasRole(GF.mine.role, GF.ROLE.HEALER)
        GF.roleSel.DPS = hasRole(GF.mine.role, GF.ROLE.DPS)
    end
    if GF.frame and GF.frame:IsVisible() then GF.RefreshControls() end
end
-- targeted update of just your own listing (leader or member). Replaces your cached
-- listing in place (other players' listings are left untouched) and re-derives your
-- state/role. Driven by the no-cooldown "mylisting" fetch and the server's push.
function GF.OnMyListing(payload)
    GF.mineReceived = true   -- server answered; stop the post-login retry
    local me = UnitName("player")
    -- drop my previous cached listing (as leader or member); keep everyone else's
    local kept = {}
    for _, l in ipairs(GF.listings or {}) do
        if not isMineListing(l) then table.insert(kept, l) end
    end
    GF.listings = kept

    if payload == "0" then
        GF.mine.state = 0
        GF.mine.id = 0
    else
        local l = parseListing(payload)
        table.insert(GF.listings, l)
        GF.mine.id = l.id
        GF.mine.dungeons = l.dungeons
        GF.mine.note = l.note
        GF.mine.state = (l.leader == me) and 1 or 2
        for _, m in ipairs(l.members) do
            if m.name == me then
                GF.mine.role = m.roles
                GF.roleSel.TANK = hasRole(m.roles, GF.ROLE.TANK)
                GF.roleSel.HEALER = hasRole(m.roles, GF.ROLE.HEALER)
                GF.roleSel.DPS = hasRole(m.roles, GF.ROLE.DPS)
            end
        end
    end
    sortListings(GF.listings)
    if GF.frame and GF.frame:IsVisible() then
        GF.RefreshControls()
        if GF.view == "browse" then GF.UpdateList() end
    end
end
function GF.OnRolePick(payload)
    local f = gfSplit(payload, "^")
    GF.ShowRolePick(tonumber(f[1]) or 0, f[2] or "", f[3] or "")
end
-- patch your own member record in the cached listings to a new role mask and
-- re-render, so changing role is instant and cooldown-free (server still gets the
-- setrole for persistence + so other players see it on their next refresh)
function GF.ApplyLocalRole(mask)
    local me = UnitName("player")
    for _, l in ipairs(GF.listings or {}) do
        for _, m in ipairs(l.members) do
            if m.name == me then m.roles = mask end
        end
    end
    if GF.frame and GF.frame:IsVisible() and GF.view == "browse" then GF.UpdateList() end
end
function GF.OnCreated()
    -- add the new listing via the targeted own-listing fetch (no bulk refresh)
    GF.RequestMyListing()
    -- jump back to the browse list so the new listing is visible right away
    if GF.frame and GF.frame:IsVisible() then GF.SetView("browse") end
end
function GF.OnDeleted()
    GF.mine.state = 0
    -- optimistically drop our own listing so the view is correct immediately
    local me = UnitName("player")
    local kept = {}
    for _, l in ipairs(GF.listings or {}) do
        if l.leader ~= me then table.insert(kept, l) end
    end
    GF.listings = kept
    if GF.frame and GF.frame:IsVisible() and GF.view == "browse" then GF.UpdateList() end
    -- confirm via the targeted fetch (returns "0" -> clears state); no bulk refresh
    GF.RequestMyListing()
end

local GF_ERRORS = {
    [1] = "You already have an active listing.",
    [2] = "Only the group leader can do that.",
    [3] = "Please wait a few seconds before trying again.",
    [4] = "Select at least one valid dungeon.",
    [5] = "You must be the party leader to post a listing.",
    [6] = "You don't have a listing.",
}
-- show an error both in chat and in the red combat-error notification area
function GF.ShowError(msg)
    DEFAULT_CHAT_FRAME:AddMessage(WHC.ADDON_PREFIX .. msg)
    if UIErrorsFrame then UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0) end
end
function GF.OnError(code)
    GF.ShowError(GF_ERRORS[tonumber(code)] or "Group Finder error.")
end

-- ============================================================================
-- window
-- ============================================================================
local CREATE_ROWS = 8       -- compact dungeon checklist rows on the create form
local BROWSE_ROWS = 4       -- taller group rows on browse (2 lines + role icons + bg)
local NUM_ROWS = 8          -- row pool size (max of the two)
local DUNGEON_ROW_H = 18.375  -- 8 rows: trims the list height (~13px shorter than 20)
local BROWSE_ROW_H = 57

local function makeRoleIcon(parent, file, x)
    -- whole 64x64 icon is the clickable target
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(51); btn:SetHeight(51)   -- 64 - 20%
    btn:SetPoint("TOP", parent, "TOP", x, -65)
    btn:SetNormalTexture(ART .. file)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(ART .. file)
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.4)
    hl:SetAllPoints(btn)

    -- small checkbox at the icon's bottom-left as the selected indicator
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetWidth(20); cb:SetHeight(20)
    cb:SetPoint("TOPRIGHT", btn, "BOTTOMLEFT", 17, 17)  -- bottom-left of icon, overlapping only the corner
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb.iconBtn = btn
    return cb
end

-- keep the icon highlighted (hover look) while its role is selected
local function updateRoleHighlight(cb)
    if not cb.iconBtn then return end
    if cb:GetChecked() then cb.iconBtn:LockHighlight() else cb.iconBtn:UnlockHighlight() end
end

-- grey/restore a checkbox + its big icon (Disable() alone doesn't dim a custom texture)
local function setCheckEnabled(cb, enabled)
    if enabled then
        cb:Enable(); cb:SetAlpha(1.0)
        if cb.iconBtn then cb.iconBtn:Enable(); cb.iconBtn:SetAlpha(1.0) end
    else
        cb:Disable(); cb:SetAlpha(0.35)
        if cb.iconBtn then cb.iconBtn:Disable(); cb.iconBtn:SetAlpha(0.35) end
    end
end

function WHC.InitializeGroupFinder()
    if GF.frame then return end

    local f = CreateFrame("Frame", "WhcGroupFinder", UIParent)
    GF.frame = f
    f:SetWidth(384); f:SetHeight(512)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")   -- above the HIGH-strata WOW_HC addon buttons
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:Hide()
    tinsert(UISpecialFrames, "WhcGroupFinder")

    -- black circular backing behind the animated eye (created before the portrait so
    -- it draws behind it). Kept at 64 @ (9,-5) — the size bump is what bled/vanished.
    -- use the round portrait art itself, tinted solid black, as the backing: same
    -- shape, and it renders reliably (unlike the minimap/mask circle textures)
    local portraitBg = f:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetTexture(ART .. "ui-lfg-portrait")
    portraitBg:SetVertexColor(0, 0, 0, 1)
    portraitBg:SetWidth(64); portraitBg:SetHeight(64)
    portraitBg:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -4)

    -- portrait/eye on BORDER so it sits ABOVE the black bg AND the stone wall (both
    -- BACKGROUND), and below the ornate ring (ARTWORK)
    local portrait = f:CreateTexture(nil, "BORDER")
    portrait:SetTexture(ART .. "ui-lfg-portrait")
    portrait:SetWidth(64); portrait:SetHeight(64)
    portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -4)

    -- animate the portrait eye while you're in a listing (same as the minimap eye),
    -- resting on the static portrait otherwise. Only runs while the window is shown.
    do
        local IDLE = ART .. "ui-lfg-portrait"
        local EYE_PATH = ART .. "eye\\battlenetworking"
        local EYE_FRAMES = { 0,1,2,3,4,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28 }
        local EYE_FRAME_TIME = 1 / 9
        local elapsed, idx, animating = 0, 0, false
        local animator = CreateFrame("Frame")
        animator:SetScript("OnUpdate", function(self, dt)
            dt = dt or arg1 or 0   -- 1.14 param vs 1.12 global
            if not f:IsVisible() then return end
            local inListing = GF.mine and GF.mine.state ~= 0
            if not inListing then
                if animating then animating = false; idx = 0; elapsed = 0; portrait:SetTexture(IDLE) end
                return
            end
            elapsed = elapsed + dt
            if elapsed < EYE_FRAME_TIME then return end
            elapsed = 0
            idx = idx + 1
            if idx > table.getn(EYE_FRAMES) then idx = 1 end
            animating = true
            portrait:SetTexture(EYE_PATH .. EYE_FRAMES[idx])
        end)
    end

    local wall = f:CreateTexture(nil, "BACKGROUND")
    wall:SetTexture(ART .. "ui-lfg-background-dungeonwall")
    wall:SetWidth(512); wall:SetHeight(256)
    wall:SetPoint("TOP", f, "TOP", 85, -155)

    -- artwork: ornate LFG frame border
    local border = f:CreateTexture(nil, "ARTWORK")
    border:SetTexture(ART .. "ui-lfg-frame")
    border:SetWidth(512); border:SetHeight(512)
    border:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -18)
    title:SetText("Group Finder")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -27, -8)
    close:SetScript("OnClick", function() GF.Toggle() end)

    -- dev convenience Reload button removed (was just outside the window)

    -- role icons + checkboxes (offsets match LFT)
    GF.roleChecks = {}
    GF.roleChecks.TANK   = makeRoleIcon(f, "tank2",   -81)
    GF.roleChecks.HEALER = makeRoleIcon(f, "healer2",   -5)
    GF.roleChecks.DPS    = makeRoleIcon(f, "damage2",   71)
    local function bindMainRole(key)
        local cb = GF.roleChecks[key]
        local function sync()
            GF.roleSel[key] = cb:GetChecked() and true or false
            updateRoleHighlight(cb)
            -- once you're in a listing (leader or member), the same icons double as
            -- a live role editor in the browse view
            if GF.mine.state ~= 0 and GF.view == "browse" then
                local mask = 0
                if GF.roleSel.TANK then mask = mask + GF.ROLE.TANK end
                if GF.roleSel.HEALER then mask = mask + GF.ROLE.HEALER end
                if GF.roleSel.DPS then mask = mask + GF.ROLE.DPS end
                -- role is optional: mask 0 (cleared all) is allowed
                Send("setrole " .. mask); GF.mine.role = mask
                -- reflect the change instantly by patching the cached listing in
                -- place: no refresh, no cooldown, no server round-trip
                GF.ApplyLocalRole(mask)
            end
        end
        cb:SetScript("OnClick", sync)
        cb.iconBtn:SetScript("OnClick", function() cb:SetChecked(not cb:GetChecked()); sync() end)
    end
    bindMainRole("TANK"); bindMainRole("HEALER"); bindMainRole("DPS")

    GF.roleHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GF.roleHeader:SetPoint("TOP", f, "TOP", 0, -45)
    GF.roleHeader:SetText("Select your role(s)")

    -- Type dropdown (moved to the left)
    local typeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 31, -133)
    typeLabel:SetText("Activity:")

    local typeDD = CreateFrame("Frame", "WhcGFTypeDD", f, "UIDropDownMenuTemplate")
    typeDD:SetPoint("TOPLEFT", f, "TOPLEFT", 69, -126)
    GF.typeDD = typeDD
    GF.SetTypeText = function(txt)
        local t = getglobal("WhcGFTypeDDText")
        if t then t:SetWidth(0); t:SetText(txt) end
    end
    UIDropDownMenu_Initialize(typeDD, function()
        for _, e in ipairs(GF.ACTIVITIES) do
            local val = e.v
            local info = {}
            info.text = e.t; info.value = val; info.checked = (GF.filterType == val)
            info.func = function() GF.SetActivity((this and this.value) or val) end
            UIDropDownMenu_AddButton(info)
        end
    end)
    GFSetDDWidth(typeDD, 100)
    UIDropDownMenu_SetSelectedValue(typeDD, GF.filterType)
    GF.SetTypeText(GF.ActivityLabel(GF.filterType))

    -- dungeon/raid filter dropdown (browse page only, no label, on the right)
    local filterDD = CreateFrame("Frame", "WhcGFFilterDD", f, "UIDropDownMenuTemplate")
    filterDD:SetPoint("TOPLEFT", f, "TOPLEFT", 190, -126)
    GF.filterDD = filterDD
    GF.SetFilterText = function(txt)
        local t = getglobal("WhcGFFilterDDText")
        if t then t:SetWidth(0); t:SetText(txt) end
    end
    -- 1.12 has no UIDropDownMenu_Disable/EnableDropDown, so toggle the button + text
    GF.SetFilterEnabled = function(enabled)
        local btn = getglobal("WhcGFFilterDDButton")
        local t = getglobal("WhcGFFilterDDText")
        if btn then if enabled then btn:Enable() else btn:Disable() end end
        if t then
            if enabled then t:SetTextColor(1, 1, 1) else t:SetTextColor(0.5, 0.5, 0.5) end
        end
    end
    UIDropDownMenu_Initialize(filterDD, function()
        local function add(text, val)
            local info = {}
            info.text = text; info.value = val
            info.checked = ((GF.filterDungeon or 0) == val)
            info.func = function()
                -- filter the already-cached list in place (no server re-fetch);
                -- render first so a cosmetic error below can't skip the update
                GF.filterDungeon = (this and this.value) or val
                GF.UpdateList()
                UIDropDownMenu_SetSelectedValue(filterDD, GF.filterDungeon)
                GF.SetFilterText(text)
            end
            UIDropDownMenu_AddButton(info)
        end
        add(GF.ActivityAllLabel(GF.filterType), 0)
        -- "All Activities" spans every activity, so there's no single dungeon list to
        -- sub-filter by; the only entry is "All Activities"
        if GF.filterType ~= "all" then
            for _, d in ipairs(GF.VisibleDungeons()) do add(d.name, d.id) end
        end
    end)
    GFSetDDWidth(filterDD, 120)
    UIDropDownMenu_SetSelectedValue(filterDD, 0)
    GF.SetFilterText(GF.ActivityAllLabel(GF.filterType))
    -- disabled while the activity is "All" (nothing to sub-filter)
    GF.SetFilterEnabled(GF.filterType ~= "all")

    -- section title above the intro (browse view only)
    GF.introTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    GF.introTitle:SetPoint("TOP", f, "TOP", -5, -52)
    GF.introTitle:SetText("Group Listings")

    -- intro blurb (browse view only, fills the empty header area)
    GF.intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    GF.intro:SetPoint("TOP", f, "TOP", -5, -74)
    GF.intro:SetWidth(297)
    GF.intro:SetJustifyH("CENTER")
    GF.intro:SetText("Browse or create a listing to group up with other players")

    -- second line, narrower than the first
    GF.intro2 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    GF.intro2:SetPoint("TOP", GF.intro, "BOTTOM", 0, -7)
    GF.intro2:SetWidth(238)
    GF.intro2:SetJustifyH("CENTER")
    GF.intro2:SetTextColor(0.6, 0.6, 0.6)
    local i2f, i2s, i2ff = GF.intro2:GetFont()
    if i2f then GF.intro2:SetFont(i2f, (i2s or 10) - 2, i2ff) end   -- smaller
    GF.intro2:SetText("You can set your return time on logout, so others know when to catch you online.")

    -- list heading
    GF.heading = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GF.heading:SetPoint("TOP", f, "TOP", 0, -169)
    GF.heading:SetText("Available Dungeons")

    -- grey "Last refreshed Xs ago" centered just below the (shorter) list
    GF.refreshedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    GF.refreshedLabel:SetPoint("TOP", f, "TOP", 0, -393)
    GF.refreshedLabel:SetJustifyH("CENTER")
    GF.refreshedLabel:SetTextColor(0.5, 0.5, 0.5)

    -- grey empty-state message centered in the list area (No listings / Loading)
    GF.emptyLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    GF.emptyLabel:SetPoint("TOP", f, "TOP", 0, -270)
    GF.emptyLabel:SetJustifyH("CENTER")
    GF.emptyLabel:SetTextColor(0.55, 0.55, 0.55)
    GF.emptyLabel:Hide()

    -- scroll list
    local scroll = CreateFrame("ScrollFrame", "WhcGFScroll", f, "FauxScrollFrameTemplate")
    scroll:SetWidth(316); scroll:SetHeight(BROWSE_ROWS * BROWSE_ROW_H)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 25, -188)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        if WHC.client and WHC.client.is1_12 then
            FauxScrollFrame_OnVerticalScroll(GF.rowH or BROWSE_ROW_H, GF.UpdateList)
        else
            FauxScrollFrame_OnVerticalScroll(self or this, offset or arg1, GF.rowH or BROWSE_ROW_H, GF.UpdateList)
        end
    end)
    GF.scroll = scroll

    -- FauxScrollFrameTemplate anchors the scrollbar's LEFT edge to the scroll's
    -- right edge, pushing it off-window. Re-anchor its RIGHT edge to the scroll's
    -- right edge so it sits in the gap reserved to the right of the rows.
    local sb = getglobal("WhcGFScrollScrollBar")
    if sb then
        sb:ClearAllPoints()
        sb:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 5, -18)
        sb:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 5, 14)
    end

    GF.rows = {}
    for i = 1, NUM_ROWS do
        GF.rows[i] = GF.BuildRow(f, scroll, i)
    end

    -- short note (create form only), in its own bordered box below the list
    local noteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteLabel:SetPoint("TOP", f, "TOP", 0, -348)
    noteLabel:SetText("Listing message (optional):")
    GF.noteLabel = noteLabel

    -- fixed-height bordered container (a multiline EditBox auto-sizes to its text
    -- and ignores SetHeight, so the visible 2-row box must be its own frame)
    local noteFrame = CreateFrame("Frame", "WhcGFNoteBox", f, RETAIL_BACKDROP)
    noteFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -364)
    noteFrame:SetWidth(312); noteFrame:SetHeight(41)  -- ~2 rows (was 46, -10%)
    if noteFrame.SetBackdrop then
        noteFrame:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        noteFrame:SetBackdropColor(0, 0, 0, 0.6)
    end
    noteFrame:EnableMouse(true)
    GF.noteFrame = noteFrame

    local noteBox = CreateFrame("EditBox", "WhcGFNote", noteFrame)
    noteBox:SetPoint("TOPLEFT", noteFrame, "TOPLEFT", 7, -6)
    noteBox:SetPoint("RIGHT", noteFrame, "RIGHT", -7, 0)
    noteBox:SetMultiLine(true)
    noteBox:SetFontObject(ChatFontNormal)
    noteBox:SetMaxLetters(64)
    noteBox:SetAutoFocus(false)
    noteBox:SetScript("OnEscapePressed", function() noteBox:ClearFocus() end)
    noteFrame:SetScript("OnMouseDown", function() noteBox:SetFocus() end)
    GF.noteBox = noteBox

    -- cap the note at 2 lines (typed wrap or Enter): measure wrapped height, revert overflow
    local measure = f:CreateFontString(nil, "ARTWORK")
    measure:SetFontObject(ChatFontNormal)
    measure:SetWidth(298)            -- same usable width as the editbox
    measure:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -364)
    measure:SetAlpha(0)              -- invisible, used only for measuring
    measure:SetText("X")
    local lineH = measure:GetHeight()
    local maxNoteH = lineH * 2 + 2
    GF.noteLastText = ""
    local noteGuard = false
    noteBox:SetScript("OnTextChanged", function()
        if noteGuard then return end
        local txt = noteBox:GetText() or ""
        -- prevent line breaks: strip any newline the user types/pastes
        if string.find(txt, "\n") then
            noteGuard = true
            local clean = string.gsub(txt, "\n", "")
            noteBox:SetText(clean)
            noteGuard = false
        end
    end)

    -- UIPanelButtonTemplate2 exists on 1.12 but not 1.14; UIPanelButtonTemplate is on
    -- both. Keep the Template2 look on 1.12, fall back to the plain one on 1.14.
    local BTN2 = (WHC.client and WHC.client.is1_12) and "UIPanelButtonTemplate2" or "UIPanelButtonTemplate"

    -- BROWSE view buttons: Refresh (left) + Create Listing / Cancel Listing (right)
    local createBtn = CreateFrame("Button", "WhcGFCreate", f, BTN2)
    createBtn:SetWidth(115); createBtn:SetHeight(23)
    createBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 78)
    createBtn:SetText("Create Listing")
    createBtn:SetScript("OnClick", function() GF.OnCreateButton() end)
    GF.createBtn = createBtn

    local refreshBtn = CreateFrame("Button", "WhcGFRefresh", f, BTN2)
    refreshBtn:SetWidth(115); refreshBtn:SetHeight(23)
    refreshBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 78)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function() GF.RequestList(false, true) end)  -- respects the 10s cooldown; wipes for feedback
    GF.refreshBtn = refreshBtn

    -- CREATE view buttons: Post + Back
    local postBtn = CreateFrame("Button", "WhcGFPost", f, BTN2)
    postBtn:SetWidth(115); postBtn:SetHeight(23)
    postBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 78)
    postBtn:SetText("Post Listing")
    postBtn:SetScript("OnClick", function() GF.PostListing() end)
    GF.postBtn = postBtn

    local backBtn = CreateFrame("Button", "WhcGFBack", f, "UIPanelButtonTemplate")
    backBtn:SetWidth(115); backBtn:SetHeight(23)
    backBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 78)
    backBtn:SetText("Back")
    backBtn:SetScript("OnClick", function() GF.SetView("browse") end)
    GF.backBtn = backBtn

    GF.BuildRolePick()
    GF.BuildListMenu()
end

-- right-click context menu on a listing row: Invite to group / Whisper
function GF.BuildListMenu()
    if GF.listMenu then return end
    GF.listMenu = CreateFrame("Frame", "WhcGFListMenu", UIParent, "UIDropDownMenuTemplate")
end
function GF.ShowListingMenu(leader)
    if not GF.listMenu or not leader or leader == "" then return end
    GF.menuTarget = leader
    UIDropDownMenu_Initialize(GF.listMenu, function()
        local info
        info = {}; info.text = GF.menuTarget; info.isTitle = 1; info.notCheckable = 1
        UIDropDownMenu_AddButton(info)
        info = {}; info.text = "Invite to group"; info.notCheckable = 1
        info.func = function() GFInvite(GF.menuTarget) end
        UIDropDownMenu_AddButton(info)
        info = {}; info.text = "Whisper"; info.notCheckable = 1
        info.func = function() GFWhisper(GF.menuTarget) end
        UIDropDownMenu_AddButton(info)
        info = {}; info.text = CANCEL or "Cancel"; info.notCheckable = 1
        info.func = function() end
        UIDropDownMenu_AddButton(info)
    end, "MENU")
    ToggleDropDownMenu(1, nil, GF.listMenu, "cursor", 0, 0)
end

-- a list row that can render either a dungeon-pick line or a group line
function GF.BuildRow(f, scroll, i)
    local row = CreateFrame("Button", "WhcGFRow" .. i, f)
    row:SetWidth(298); row:SetHeight(BROWSE_ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")   -- right-click opens the listing menu
    if i == 1 then
        row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 2, -2)
    else
        row:SetPoint("TOPLEFT", GF.rows[i - 1], "BOTTOMLEFT", 0, 0)
    end

    -- dungeon background art (browse view), dimmed and fading to transparent at
    -- the left/right edges. Two halves so the side-fade is symmetric.
    -- "cover" the row without stretching: art is 512x64 (8:1), wider than the BG
    -- area, so show full height and crop the width, centered (widthFrac).
    local IMG_ASPECT = 512 / 64
    local bgW, bgH = 298 - 2, BROWSE_ROW_H - 2
    local wFrac = (bgW / bgH) / IMG_ASPECT
    if wFrac > 1 then wFrac = 1 end   -- safety: never sample past the image
    local m = (1 - wFrac) / 2
    local mid = (m + (1 - m)) / 2      -- center of the cropped region (0.5)
    local BG_A = 0.29
    row.bgL = row:CreateTexture(nil, "BACKGROUND")
    row.bgL:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    row.bgL:SetPoint("BOTTOMRIGHT", row, "BOTTOM", 0, 1)
    row.bgL:SetTexCoord(m, mid, 0, 1)
    row.bgL:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0, 1, 1, 1, BG_A)
    row.bgL:Hide()
    row.bgR = row:CreateTexture(nil, "BACKGROUND")
    row.bgR:SetPoint("TOPLEFT", row, "TOP", 0, -1)
    row.bgR:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
    row.bgR:SetTexCoord(mid, 1 - m, 0, 1)
    row.bgR:SetGradientAlpha("HORIZONTAL", 1, 1, 1, BG_A, 1, 1, 1, 0)
    row.bgR:Hide()

    -- decorations marking the player's own listing; all fade to transparent at the
    -- left/right edges via two-half horizontal gradients. Collected in row.ownDecor
    -- for one-shot show/hide.
    row.ownDecor = {}
    local function ownTex(layer)
        local t = row:CreateTexture(nil, layer)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:Hide()
        table.insert(row.ownDecor, t)
        return t
    end
    -- #436ca0 fill tint (over art, under text)
    local fR, fG, fB, fA = 0.263, 0.424, 0.627, 0.5
    local fillL = ownTex("BORDER")
    fillL:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    fillL:SetPoint("BOTTOMRIGHT", row, "BOTTOM", 0, 1)
    fillL:SetGradientAlpha("HORIZONTAL", fR, fG, fB, 0, fR, fG, fB, fA)
    local fillR = ownTex("BORDER")
    fillR:SetPoint("TOPLEFT", row, "TOP", 0, -1)
    fillR:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
    fillR:SetGradientAlpha("HORIZONTAL", fR, fG, fB, fA, fR, fG, fB, 0)

    -- #7096bd top + bottom border lines
    local bR, bG, bB, bA = 0.439, 0.588, 0.741, 0.85
    local THICK = 1
    local topL = ownTex("ARTWORK"); topL:SetHeight(THICK)
    topL:SetPoint("TOPLEFT", row, "TOPLEFT", 1, 0)
    topL:SetPoint("TOPRIGHT", row, "TOP", 0, 0)
    topL:SetGradientAlpha("HORIZONTAL", bR, bG, bB, 0, bR, bG, bB, bA)
    local topR = ownTex("ARTWORK"); topR:SetHeight(THICK)
    topR:SetPoint("TOPLEFT", row, "TOP", 0, 0)
    topR:SetPoint("TOPRIGHT", row, "TOPRIGHT", -1, 0)
    topR:SetGradientAlpha("HORIZONTAL", bR, bG, bB, bA, bR, bG, bB, 0)
    -- bottom border anchored by its TOP edge (grows down), same as the top border,
    -- so both round to the same pixel height
    local botL = ownTex("ARTWORK"); botL:SetHeight(THICK)
    botL:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 1, THICK)
    botL:SetPoint("TOPRIGHT", row, "BOTTOM", 0, THICK)
    botL:SetGradientAlpha("HORIZONTAL", bR, bG, bB, 0, bR, bG, bB, bA)
    local botR = ownTex("ARTWORK"); botR:SetHeight(THICK)
    botR:SetPoint("TOPLEFT", row, "BOTTOM", 0, THICK)
    botR:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", -1, THICK)
    botR:SetGradientAlpha("HORIZONTAL", bR, bG, bB, bA, bR, bG, bB, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints(row)

    -- dungeon-pick widgets
    row.check = CreateFrame("CheckButton", nil, row)
    row.check:SetWidth(18); row.check:SetHeight(18)
    row.check:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    row.check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    row.check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    row.check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetJustifyH("LEFT")

    -- grey dungeon line (browse view, under the leader name)
    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.sub:SetJustifyH("LEFT")
    row.sub:Hide()

    -- small grey "Lvl. X" shown next to the leader name (browse view)
    row.lvl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.lvl:Hide()

    -- red "back in Xh Ym" for an offline leader, under the name line
    row.ret = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.ret:SetJustifyH("LEFT")
    row.ret:Hide()

    row.level = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.level:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.level:SetJustifyH("RIGHT")

    row.rIcons = {}  -- per-member role icon pool (browse view), created lazily

    -- grey "+X" shown after the 5th icon when a listing has more than 5 members
    row.more = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.more:SetJustifyH("RIGHT")
    row.more:Hide()

    return row
end

-- show/hide the header area: the Tank/Heal/DPS role icons appear while creating a
-- listing AND while you're in a listing (leader or member) browsing, so you can
-- change your role live. The intro blurb fills that space only when you have no
-- listing yet; once a listing exists the intro is replaced by the role editor.
function GF.UpdateHeaderArea()
    local creating = (GF.view == "create")
    local listedBrowse = (not creating) and (GF.mine.state ~= 0)  -- leader (1) or member (2)
    local showRoles = creating or listedBrowse

    if GF.roleChecks then
        for _, k in ipairs({ "TANK", "HEALER", "DPS" }) do
            local cb = GF.roleChecks[k]
            if showRoles then cb:Show(); cb.iconBtn:Show() else cb:Hide(); cb.iconBtn:Hide() end
            setCheckEnabled(cb, showRoles)
        end
    end
    if GF.roleHeader then
        if showRoles then
            GF.roleHeader:SetText(listedBrowse and "Your role (click to change)" or "Select your role(s)")
            GF.roleHeader:Show()
        else
            GF.roleHeader:Hide()
        end
    end

    -- intro texts only on the plain browse view with no active listing (hidden while
    -- creating or while you're in a listing, since the role icons take that space)
    local showIntro = (not creating) and (not listedBrowse)
    if GF.intro then if showIntro then GF.intro:Show() else GF.intro:Hide() end end
    if GF.intro2 then if showIntro then GF.intro2:Show() else GF.intro2:Hide() end end
    if GF.introTitle then if showIntro then GF.introTitle:Show() else GF.introTitle:Hide() end end
end

-- browse-view button reflects whether you already have a listing, and is disabled
-- when you're in a group but not its leader (only the leader can post a listing)
function GF.UpdateCreateButton()
    if not GF.createBtn then return end
    if GF.mine.state == 1 then
        GF.createBtn:SetText("Cancel Listing"); GF.createBtn:Enable()
    elseif GF.mine.state == 2 then
        GF.createBtn:SetText("In a group"); GF.createBtn:Disable()
    else
        GF.createBtn:SetText("Create Listing")
        if GFInGroup() and not GFIsLeader() then GF.createBtn:Disable() else GF.createBtn:Enable() end
    end
end

-- recolor / repopulate the (always-visible) role + note controls
function GF.RefreshControls()
    if not GF.roleChecks then return end
    for _, k in ipairs({ "TANK", "HEALER", "DPS" }) do
        GF.roleChecks[k]:SetChecked(GF.roleSel[k])
        updateRoleHighlight(GF.roleChecks[k])
    end

    GF.UpdateCreateButton()
    GF.UpdateHeaderArea()
end

-- ============================================================================
-- list rendering (FauxScrollFrame), per tab
-- ============================================================================
-- which GF.dungeons entries belong to the selected activity (pve = dungeons+raids,
-- all = everything)
local function activityMatch(d, ft)
    if ft == "all" then return true end
    if ft == "pve" then return d.t == "dungeon" or d.t == "raid" end
    return d.t == ft
end
-- "All ..." label for the sub-dropdown, per activity
function GF.ActivityAllLabel(ft)
    if ft == "all" then return "All Activities" end
    if ft == "pvp" then return "All PvP" end
    if ft == "questing" then return "All Questing" end
    return "All dungeons"
end
-- does a listing belong to the selected activity (by its dungeon ids)?
local function listingMatchesActivity(l, ft)
    for _, idStr in ipairs(gfSplit(l.dungeons, ",")) do
        local d = GF.dungeonById[tonumber(idStr)]
        if d and activityMatch(d, ft) then return true end
    end
    return false
end

-- create checklist (and sub-dropdown source): entries for the selected activity
function GF.VisibleDungeons()
    local out = {}
    for _, d in ipairs(GF.dungeons) do
        if activityMatch(d, GF.filterType) then table.insert(out, d) end
    end
    return out
end
local visibleDungeons = GF.VisibleDungeons

local function visibleListings()
    local ft = GF.filterType
    local fd = GF.filterDungeon
    local out = {}
    for _, l in ipairs(GF.listings) do
        if isMineListing(l) then
            -- your own group always shows (and sorts first), regardless of the
            -- selected activity or dungeon filter
            table.insert(out, l)
        elseif listingMatchesActivity(l, ft) then
            if not fd or fd == 0 then
                table.insert(out, l)
            else
                for _, idStr in ipairs(gfSplit(l.dungeons, ",")) do
                    if tonumber(idStr) == fd then table.insert(out, l); break end
                end
            end
        end
    end
    return out
end

GF.ACTIVITIES = { { v = "all", t = "All" }, { v = "pve", t = "Dungeons" }, { v = "pvp", t = "PvP" }, { v = "questing", t = "Questing" } }
function GF.ActivityLabel(ft)
    for _, e in ipairs(GF.ACTIVITIES) do if e.v == ft then return e.t end end
    return "Dungeons"
end
-- switch the active activity: resets the sub-filter + create selections, syncs the
-- two dropdowns' text, and refreshes the list/checklist
function GF.SetActivity(ft)
    GF.filterType = ft
    GF.filterDungeon = 0
    GF.selected = {}
    if GF.typeDD then UIDropDownMenu_SetSelectedValue(GF.typeDD, ft) end
    if GF.SetTypeText then GF.SetTypeText(GF.ActivityLabel(ft)) end
    if GF.filterDD then
        UIDropDownMenu_SetSelectedValue(GF.filterDD, 0)
        -- "All" spans everything, so there's nothing to sub-filter: disable the dropdown
        if GF.SetFilterEnabled then GF.SetFilterEnabled(ft ~= "all") end
    end
    if GF.SetFilterText then GF.SetFilterText(GF.ActivityAllLabel(ft)) end
    -- always keep your own listing fresh (no cooldown), even when the bulk list is cached
    GF.RequestMyListing()
    -- pull fresh listings for the new activity; if the refresh is still on cooldown
    -- we keep the cached list and flag it so the empty state nudges a manual refresh
    if (GetTime() - GF.lastListReq) >= LIST_CD then
        GF.activityStale = false
        GF.RequestList(false)
    else
        GF.activityStale = true
    end
    GF.UpdateList()
end

function GF.UpdateList()
    if not GF.scroll then return end
    local creating = (GF.view == "create")
    local data = creating and visibleDungeons() or visibleListings()
    local total = table.getn(data)
    local shown = creating and CREATE_ROWS or BROWSE_ROWS
    GF.rowH = creating and DUNGEON_ROW_H or BROWSE_ROW_H
    FauxScrollFrame_Update(GF.scroll, total, shown, GF.rowH)
    local sb = getglobal("WhcGFScrollScrollBar")  -- keep the scrollbar always visible
    if sb then sb:Show() end
    local offset = FauxScrollFrame_GetOffset(GF.scroll)

    for i = 1, NUM_ROWS do
        local row = GF.rows[i]
        if i > shown then
            row:Hide()
        else
            row:SetHeight(GF.rowH)  -- relative anchors restack the rows
            local dataIndex = i + offset
            if dataIndex > total then
                row:Hide()
            else
                row:Show()
                if creating then GF.RenderDungeonRow(row, data[dataIndex]) else GF.RenderGroupRow(row, data[dataIndex]) end
            end
        end
    end

    -- empty-state message (browse only): "Loading..." while a refresh is in flight,
    -- otherwise "No listings found."
    if GF.emptyLabel then
        if not creating and total == 0 then
            local msg
            if GF.loading then msg = "Loading..."
            elseif GF.activityStale then msg = "Please click refresh to see the listings"
            else msg = "No listings found." end
            GF.emptyLabel:SetText(msg)
            GF.emptyLabel:Show()
        else
            GF.emptyLabel:Hide()
        end
    end

    -- after a scroll/refresh the mouse hasn't moved but the row under it now holds a
    -- different listing, so its OnEnter never re-fires and a stale tooltip lingers.
    -- Refresh the tooltip for whatever row is actually under the cursor (or clear it).
    local hovered
    for i = 1, shown do
        local row = GF.rows[i]
        if row:IsVisible() and MouseIsOver(row) then hovered = row; break end
    end
    if hovered and hovered.listing then
        GF.ShowListingTooltip(hovered, hovered.listing)
    elseif GF.tooltipRow then
        GameTooltip:Hide()
        GF.tooltipRow = nil
    end
end

function GF.RenderDungeonRow(row, d)
    row.check:Show()
    row.level:Show()
    row.sub:Hide()
    row.lvl:Hide()
    row.ret:Hide()
    row.bgL:Hide(); row.bgR:Hide()
    for _, t in ipairs(row.ownDecor) do t:Hide() end
    for _, t in ipairs(row.rIcons) do t:Hide() end
    row.more:Hide()
    row.listing = nil   -- dungeon-pick rows have no listing tooltip
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)

    local r, g, b = diffColorRGB(d)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", 22, 0)
    row.name:SetWidth(190)
    row.name:SetText(d.name)
    row.name:SetTextColor(r, g, b)
    row.level:SetText(string.format("(%d-%d)", d.min, d.max))
    row.level:SetTextColor(r, g, b)

    row.check:SetChecked(GF.selected[d.id] and true or false)
    setCheckEnabled(row.check, GF.mine.state == 0)  -- grey out while you already have a listing
    local id = d.id
    row.check:SetScript("OnClick", function()
        GF.selected[id] = row.check:GetChecked() and true or nil
    end)
    -- clicking the row (instance name) toggles its checkbox too (left-click only)
    row:SetScript("OnClick", function(self, button)
        if (button or arg1) == "RightButton" then return end
        if GF.mine.state ~= 0 then return end  -- locked while you already have a listing
        local v = not row.check:GetChecked()
        row.check:SetChecked(v)
        GF.selected[id] = v and true or nil
    end)
end

local function listingIsRaid(l)
    for _, idStr in ipairs(gfSplit(l.dungeons, ",")) do
        local d = GF.dungeonById[tonumber(idStr)]
        if d and d.t == "raid" then return true end
    end
    return false
end

-- show a fixed 5-man comp [tank, dps, dps, dps, heal]; filled slots get the role
-- icon, unfilled slots get a placeholder dot. Raids reuse the same 5 slots but
-- keep a "+X" for members beyond the core 5.
function GF.LayoutRoleIcons(row, l)
    for _, t in ipairs(row.rIcons) do t:Hide() end

    local total = table.getn(l.members)

    local size, gap = 22, 22   -- role icons -10%, slot pitch +10%
    local dotSize = 15         -- placeholder dot, ~30% smaller than a role icon
    local half = size / 2

    -- raids keep a "+X" for members beyond the 5-slot core
    local extra = (listingIsRaid(l) and total > 5) and (total - 5) or 0

    -- comp capacities in priority order Tank > Heal > DPS. Raids drop one dps slot
    -- to make room for the "+X" (4 icons instead of 5).
    local capTank, capHeal, capDps = 1, 1, (extra > 0) and 2 or 3

    -- Assign members to slots so the most important roles get filled first. Process
    -- the least-flexible members first (a tank-only player claims tank before a
    -- tank/heal/dps player), then each member takes the highest-priority slot that's
    -- still open among the roles they signed up for (Tank > Heal > DPS). e.g. if a
    -- tank is already filled, a tank/dps/heal player fills heal next, else dps.
    -- Members who haven't picked a role (roles == 0) stay empty dots.
    local function roleCount(mask)
        local n = 0
        if hasRole(mask, GF.ROLE.TANK)   then n = n + 1 end
        if hasRole(mask, GF.ROLE.HEALER) then n = n + 1 end
        if hasRole(mask, GF.ROLE.DPS)    then n = n + 1 end
        return n
    end
    local roled = {}
    for _, m in ipairs(l.members) do
        if (tonumber(m.roles) or 0) ~= 0 then table.insert(roled, m) end
    end
    table.sort(roled, function(a, b) return roleCount(a.roles) < roleCount(b.roles) end)

    local fTank, fHeal, fDps = 0, 0, 0
    for _, m in ipairs(roled) do
        if     hasRole(m.roles, GF.ROLE.TANK)   and fTank < capTank then fTank = fTank + 1
        elseif hasRole(m.roles, GF.ROLE.HEALER) and fHeal < capHeal then fHeal = fHeal + 1
        elseif hasRole(m.roles, GF.ROLE.DPS)    and fDps  < capDps  then fDps  = fDps  + 1 end
    end

    -- comp slots; with a "+X" we drop to 4 icons (tank, dps, dps, heal) to make
    -- room for it, otherwise the full 5 (tank, dps, dps, dps, heal)
    local slots
    if extra > 0 then
        slots = {
            (fTank > 0) and "tank" or false,
            (fDps >= 1) and "dps"  or false,
            (fDps >= 2) and "dps"  or false,
            (fHeal > 0) and "heal" or false,
        }
    else
        slots = {
            (fTank > 0) and "tank" or false,
            (fDps >= 1) and "dps"  or false,
            (fDps >= 2) and "dps"  or false,
            (fDps >= 3) and "dps"  or false,
            (fHeal > 0) and "heal" or false,
        }
    end
    -- explicit count (don't use table.getn: trailing `false` entries make it
    -- under-report in 1.12 Lua, which would drop the placeholder dots)
    local nSlots = (extra > 0) and 4 or 5

    if extra > 0 then
        row.more:Show()
        row.more:ClearAllPoints()
        row.more:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.more:SetText("+" .. extra)
        row.more:SetTextColor(0.6, 0.6, 0.6)
    else
        row.more:Hide()
    end

    -- center each slot on a fixed grid so the smaller dot stays aligned
    for i = 1, nSlots do
        local t = row.rIcons[i]
        if not t then t = row:CreateTexture(nil, "OVERLAY"); row.rIcons[i] = t end
        if slots[i] then
            t:SetTexture(ART .. slots[i]); t:SetWidth(size); t:SetHeight(size)
        else
            t:SetTexture(ART .. "dot"); t:SetWidth(dotSize); t:SetHeight(dotSize)
        end
        t:ClearAllPoints()
        if extra > 0 then
            t:SetPoint("CENTER", row.more, "LEFT", -5 - half - (nSlots - i) * gap, 0)
        else
            t:SetPoint("CENTER", row, "RIGHT", -6 - half - (nSlots - i) * gap, 0)
        end
        t:Show()
    end
end

function GF.ShowListingTooltip(row, l)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GF.tooltipRow = row   -- track ownership (1.12 GameTooltip has no GetOwner)
    -- leader's "Player will be back in…" on top of the roster when offline
    local leaderM
    for _, m in ipairs(l.members) do if m.name == l.leader then leaderM = m; break end end
    local rr = returnRed(leaderM)
    if rr ~= "" then
        GameTooltip:AddLine(rr)
        GameTooltip:AddLine(" ")
    end
    -- show members ordered by role: Tank > Heal > DPS (ties by name, stable-ish)
    local sorted = {}
    for _, m in ipairs(l.members) do table.insert(sorted, m) end
    table.sort(sorted, function(a, b)
        local ra, rb = roleRank(a.roles), roleRank(b.roles)
        if ra ~= rb then return ra < rb end
        return (a.name or "") < (b.name or "")
    end)
    for _, m in ipairs(sorted) do
        local lead = (m.name == l.leader) and " |cffffd100(leader)|r" or ""
        -- pad single-digit levels with a leading space so they line up with 2-digit
        local lvl = (m.level and m.level > 0) and m.level or "??"
        if type(lvl) == "number" and lvl < 10 then lvl = "  " .. lvl end
        local right = "Lvl. " .. lvl .. "  " .. RoleText(m.roles)
        GameTooltip:AddDoubleLine(classHex(m.classId) .. m.name .. "|r" .. lead, right, 1, 1, 1, 1, 1, 1)
    end
    if l.note ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(l.note, 0.9, 0.9, 0.6, true)
    end
    GameTooltip:AddLine(" ")
    for _, id in ipairs(gfSplit(l.dungeons, ",")) do
        local dn = DungeonName(id)
        if dn and dn ~= "" then GameTooltip:AddLine(dn, 0.7, 0.85, 1.0) end
    end
    -- GameTooltip styles its first line as a larger header; force it back to the
    -- body font so the first member/return row matches the rest (no empty spacer)
    if GameTooltipTextLeft1 then GameTooltipTextLeft1:SetFontObject(GameTooltipText) end
    if GameTooltipTextRight1 then GameTooltipTextRight1:SetFontObject(GameTooltipText) end
    GameTooltip:Show()
end

function GF.RenderGroupRow(row, l)
    row.check:Hide()
    row.level:Hide()

    -- fill + border decorations when this is the listing you belong to, as the
    -- leader ("(You)") or as a member ("(Your Group)")
    local me = UnitName("player")
    local own = (l.leader == me)          -- you're the leader of this listing
    local member = false
    if not own then
        for _, m in ipairs(l.members) do if m.name == me then member = true; break end end
    end
    local mineRow = own or member
    for _, t in ipairs(row.ownDecor) do if mineRow then t:Show() else t:Hide() end end

    -- leader (class-colored) on top, dungeon name in grey under it
    local leaderM
    for _, m in ipairs(l.members) do if m.name == l.leader then leaderM = m; break end end
    -- when the leader is online there's no return-time line, so center the 2 lines vertically
    local rr = returnRed(leaderM)
    row.name:ClearAllPoints()
    row.name:SetWidth(0)   -- auto-size so the level can sit right after it
    -- mark the listing you belong to: "(You)" as leader, "(Your Group)" as a member
    local tag = ""
    if own then tag = " |cffffd100(You)|r"
    elseif member then tag = " |cffffd100(Your Group)|r" end
    row.name:SetText(l.leader .. tag)
    row.name:SetTextColor(classColor(leaderM and leaderM.classId or 0))

    local lvl = (leaderM and leaderM.level and leaderM.level > 0) and leaderM.level or "?"
    row.lvl:Show()
    row.lvl:ClearAllPoints()
    row.lvl:SetPoint("BOTTOMLEFT", row.name, "BOTTOMRIGHT", 8, 0)
    row.lvl:SetText("Lvl. " .. lvl)
    row.lvl:SetTextColor(0.55, 0.55, 0.55)

    row.sub:Show()
    row.sub:ClearAllPoints()
    row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.sub:SetWidth(170)
    local ids = gfSplit(l.dungeons, ",")

    -- primary dungeon = the filtered one (when a filter is active and this listing
    -- has it), otherwise the first; it drives the row's background + name
    local primary = ids[1]
    local fd = GF.filterDungeon
    if fd and fd ~= 0 then
        for _, idStr in ipairs(ids) do
            if tonumber(idStr) == fd then primary = idStr; break end
        end
    end

    local bgPath = DungeonBg(primary)
    if bgPath then
        row.bgL:SetTexture(bgPath); row.bgL:Show()
        row.bgR:SetTexture(bgPath); row.bgR:Show()
    else
        row.bgL:Hide(); row.bgR:Hide()
    end

    local dn = DungeonName(primary)
    local extra = table.getn(ids) - 1
    if extra > 0 then dn = dn .. "  +" .. extra end   -- same font/color as the name
    row.sub:SetText(dn)
    row.sub:SetTextColor(0.6, 0.6, 0.6)

    -- leader return time (red) under the name/dungeon lines when offline
    if rr ~= "" then
        row.ret:Show()
        row.ret:ClearAllPoints()
        row.ret:SetPoint("TOPLEFT", row.sub, "BOTTOMLEFT", 0, -2)
        row.ret:SetText(rr)
    else
        row.ret:Hide()
    end

    -- vertically center the whole text block (2 lines online, 3 when offline)
    -- using the real rendered line heights so it sits dead-center in the row
    -- (GetStringHeight doesn't exist on 1.12 FontStrings; GetHeight does)
    local function lineH(fs, dflt)
        local h = fs.GetHeight and fs:GetHeight() or 0
        if not h or h < 1 then return dflt end
        return h
    end
    local gap = 2
    local blockH = lineH(row.name, 14) + gap + lineH(row.sub, 12)
    if rr ~= "" then blockH = blockH + gap + lineH(row.ret, 12) end
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -math.floor((BROWSE_ROW_H - blockH) / 2 + 0.5))

    GF.LayoutRoleIcons(row, l)

    -- hover shows the full roster + note + dungeons; click whispers the leader.
    -- row.listing lets UpdateList refresh the tooltip after a scroll (see below).
    row.listing = l
    row:SetScript("OnEnter", function() GF.ShowListingTooltip(row, l) end)
    row:SetScript("OnLeave", function() GameTooltip:Hide(); GF.tooltipRow = nil end)
    if mineRow then
        row:SetScript("OnClick", nil)   -- no point inviting/whispering your own group
    else
        local leader = l.leader
        -- left-click whispers the leader; right-click opens an Invite / Whisper menu
        row:SetScript("OnClick", function(self, button)
            local b = button or arg1
            if b == "RightButton" then
                GF.ShowListingMenu(leader)
            else
                GFWhisper(leader)
            end
        end)
    end
end

-- ============================================================================
-- actions / tabs
-- ============================================================================
-- browse-view button: open the create form, or cancel an existing listing
function GF.OnCreateButton()
    if GF.mine.state == 1 then
        -- cancel listing: shares the 10s create/delete cooldown (separate from refresh)
        local now = GetTime()
        if (now - GF.lastPost) < POST_CD then
            GF.ShowError(string.format("Please wait %d seconds.", math.ceil(POST_CD - (now - GF.lastPost))))
            return
        end
        GF.lastPost = now
        Send("delete")
        return
    end
    if GF.mine.state == 2 then return end
    -- only the party/raid leader (or a solo player) can post a listing
    if GFInGroup() and not GFIsLeader() then
        GF.ShowError("You must be the party leader to post a listing.")
        return
    end
    GF.SetView("create")
end

-- submit the create form
function GF.PostListing()
    local now = GetTime()
    if (now - GF.lastPost) < POST_CD then
        GF.ShowError(string.format("Please wait %d seconds.", math.ceil(POST_CD - (now - GF.lastPost))))
        return
    end

    local ids = {}
    -- only the current activity's entries, so a stale cross-activity prefill
    -- (e.g. a dungeon left selected) can't get bundled into the listing
    for _, d in ipairs(GF.VisibleDungeons()) do if GF.selected[d.id] then table.insert(ids, d.id) end end
    if table.getn(ids) == 0 then
        if GF.filterType == "all" then
            GF.ShowError("Select at least one option.")
        else
            GF.ShowError("Select at least one " .. GF.ActivityLabel(GF.filterType) .. " option.")
        end
        return
    end
    local mask = 0
    if GF.roleSel.TANK then mask = mask + GF.ROLE.TANK end
    if GF.roleSel.HEALER then mask = mask + GF.ROLE.HEALER end
    if GF.roleSel.DPS then mask = mask + GF.ROLE.DPS end
    -- role is optional: mask 0 (no role chosen) is allowed

    local note = GF.noteBox and GF.noteBox:GetText() or ""
    WhcAddonSettings.gfLastListing = { dungeons = table.concat(ids, ","), role = mask, note = note }
    GF.lastPost = now
    Send("create " .. table.concat(ids, ",") .. " " .. mask .. " " .. note)
end

function GF.SetView(view)
    GF.view = view
    local creating = (view == "create")

    -- shrink the list on the create form so it doesn't run under the note
    -- browse list sits higher (no heading) and taller; create keeps its spot
    if GF.scroll then
        GF.scroll:ClearAllPoints()
        if creating then
            GF.scroll:SetPoint("TOPLEFT", GF.frame, "TOPLEFT", 25, -188)
            GF.scroll:SetHeight(CREATE_ROWS * DUNGEON_ROW_H)
        else
            GF.scroll:SetPoint("TOPLEFT", GF.frame, "TOPLEFT", 23, -159)
            GF.scroll:SetHeight(BROWSE_ROWS * BROWSE_ROW_H)
        end
    end

    -- role icons + intro visibility is owned by GF.UpdateHeaderArea (called via
    -- RefreshControls below), since it depends on member state too
    if GF.refreshedLabel then if creating then GF.refreshedLabel:Hide() else GF.refreshedLabel:Show() end end
    if GF.filterDD then if creating then GF.filterDD:Hide() else GF.filterDD:Show() end end
    if GF.noteFrame then if creating then GF.noteFrame:Show() else GF.noteFrame:Hide() end end
    if GF.noteLabel then if creating then GF.noteLabel:Show() else GF.noteLabel:Hide() end end

    if creating then
        GF.heading:SetText("Select your role(s) and dungeons/raids")
        GF.heading:Show()
        GF.createBtn:Hide(); GF.refreshBtn:Hide(); GF.postBtn:Show(); GF.backBtn:Show()
        -- prefill from last listing for convenience
        local last = WhcAddonSettings.gfLastListing
        GF.selected = {}
        GF.roleSel = { TANK = false, HEALER = false, DPS = false }
        if last then
            -- only prefill entries that belong to the current activity
            for _, idStr in ipairs(gfSplit(last.dungeons or "", ",")) do
                local d = GF.dungeonById[tonumber(idStr)]
                if d and activityMatch(d, GF.filterType) then GF.selected[tonumber(idStr)] = true end
            end
            GF.roleSel.TANK = hasRole(last.role, GF.ROLE.TANK)
            GF.roleSel.HEALER = hasRole(last.role, GF.ROLE.HEALER)
            GF.roleSel.DPS = hasRole(last.role, GF.ROLE.DPS)
        end
        if GF.noteBox then GF.noteBox:SetText(last and last.note or "") end
    else
        GF.heading:Hide()
        GF.createBtn:Show(); GF.refreshBtn:Show(); GF.postBtn:Hide(); GF.backBtn:Hide()
        -- no bulk refresh here: switching back to browse shows the cached list (the
        -- bulk list refreshes only on open + activity change). Own listing stays fresh
        -- via the mylisting poll/push.
    end

    GF.RefreshControls()
    GF.UpdateList()
end

function GF.Toggle()
    if not GF.frame then return end
    if GF.frame:IsVisible() then
        GF.frame:Hide()
        PlaySound(WHC.SOUNDS.closeFrame)
    else
        GF.frame:Show()
        PlaySound(WHC.SOUNDS.openFrame)
        GF.RequestMine()
        GF.RequestMyListing()   -- own listing fresh on open (no cooldown)
        GF.RequestList(true)    -- bulk list: only on open + activity change
        GF.SetView("browse")
    end
end

-- no auto-refresh: the list only refreshes on first open and on Refresh click.
-- this ticker just shows the cooldown countdown on the Refresh button.
local function refreshedAgoText()
    if not GF.lastRefreshed then return "" end
    local d = GetTime() - GF.lastRefreshed
    if d < 60 then return string.format("Last refreshed %ds ago", math.max(0, math.floor(d)))
    elseif d < 3600 then return string.format("Last refreshed %dm ago", math.floor(d / 60))
    else return string.format("Last refreshed %dh ago", math.floor(d / 3600)) end
end

local refresher = CreateFrame("Frame")
refresher:SetScript("OnUpdate", function()
    -- apply a held-back refill once the brief wipe window has elapsed
    if GF.incoming and (GF.wipeUntil or 0) <= GetTime() then GF.ApplyListings() end

    -- a dropped list reply (the server's 8s cooldown still active after a /reload,
    -- say) leaves us "loading" with no data. The server always sends a "listend" when
    -- it actually answers (even for an empty list), so the ONLY reason for no reply is
    -- that cooldown. Keep showing "Loading..." and re-request every couple seconds
    -- until the cooldown lifts and a real reply arrives, instead of giving up and
    -- showing "No listings found." (a throttled request doesn't push the cooldown back).
    if GF.loading and not GF.incoming and GF.frame and GF.frame:IsVisible() and GF.view == "browse" then
        if (GetTime() - (GF.lastListReq or 0)) >= 2 then
            GF.lastListReq = GetTime()
            GF.pending = {}
            Send("list")
        end
    end

    if not (GF.frame and GF.frame:IsVisible() and GF.view == "browse" and GF.refreshBtn) then return end

    GF.UpdateCreateButton()   -- keep the Create button in sync with live leadership changes
    local remain = LIST_CD - (GetTime() - GF.lastListReq)
    if remain > 0 then
        GF.refreshBtn:Disable()
        GF.refreshBtn:SetText(string.format("Refresh (%d)", math.ceil(remain)))
    else
        GF.refreshBtn:Enable()
        GF.refreshBtn:SetText("Refresh")
    end
    if GF.refreshedLabel then GF.refreshedLabel:SetText(refreshedAgoText()) end
end)

-- ============================================================================
-- role pick dialog (shown when you join a listing leader's group)
-- ============================================================================
function GF.BuildRolePick()
    local d = CreateFrame("Frame", "WhcGFRolePick", UIParent, RETAIL_BACKDROP)
    d:SetWidth(340); d:SetHeight(170)
    d:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:EnableMouse(true)
    d:Hide()
    GF.rolePick = d
    if d.SetBackdrop then
        d:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end

    local t = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("TOP", d, "TOP", 0, -16); t:SetWidth(300); t:SetJustifyH("CENTER")
    GF.rolePickTitle = t

    GF.rolePickChecks = {}
    GF.rolePickChecks.TANK   = makeRoleIcon(d, "tank2",   -90)
    GF.rolePickChecks.HEALER = makeRoleIcon(d, "healer2",   0)
    GF.rolePickChecks.DPS    = makeRoleIcon(d, "damage2",  90)
    for _, k in ipairs({ "TANK", "HEALER", "DPS" }) do
        local cb = GF.rolePickChecks[k]
        cb:SetScript("OnClick", function() updateRoleHighlight(cb) end)
        cb.iconBtn:SetScript("OnClick", function() cb:SetChecked(not cb:GetChecked()); updateRoleHighlight(cb) end)
    end

    local ok = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    ok:SetWidth(120); ok:SetHeight(22)
    ok:SetPoint("BOTTOM", d, "BOTTOM", 0, 14)
    ok:SetText("Confirm role")
    ok:SetScript("OnClick", function()
        local mask = 0
        if GF.rolePickChecks.TANK:GetChecked() then mask = mask + GF.ROLE.TANK end
        if GF.rolePickChecks.HEALER:GetChecked() then mask = mask + GF.ROLE.HEALER end
        if GF.rolePickChecks.DPS:GetChecked() then mask = mask + GF.ROLE.DPS end
        -- role is optional: confirming with nothing selected (mask 0) is allowed
        Send("setrole " .. mask)
        d:Hide()
        -- you just joined: pull your own listing (no cooldown) so your group shows
        -- highlighted right away; the bulk list stays cached
        GF.roleSel.TANK = hasRole(mask, GF.ROLE.TANK)
        GF.roleSel.HEALER = hasRole(mask, GF.ROLE.HEALER)
        GF.roleSel.DPS = hasRole(mask, GF.ROLE.DPS)
        GF.RequestMyListing()
    end)
end

function GF.ShowRolePick(id, leader, dungeons)
    if not GF.rolePick then return end
    GF.rolePickTitle:SetText(string.format("You joined %s's group.\nPick your role for %s:", leader, dungeonsSummary(dungeons)))
    for _, k in ipairs({ "TANK", "HEALER", "DPS" }) do
        GF.rolePickChecks[k]:SetChecked(false)
        updateRoleHighlight(GF.rolePickChecks[k])
    end
    GF.rolePick:Show()
end

-- ============================================================================
-- logout / exit interception
-- ============================================================================
-- only the listing leader is prompted for a return time on logout; members logging
-- out don't matter (we don't track when members come back)
-- the logout prompt is for the listing LEADER only. A GF listing leader is always
-- the party leader (or solo), so if we're in a group but not its leader, a stale
-- state==1 (our listing was dropped when we joined someone else's group, before the
-- client refreshed) must NOT count — verify live party leadership too.
local function playerHasListing()
    if not (GF.mine and GF.mine.state == 1) then return false end
    if GFInGroup() and not GFIsLeader() then return false end
    return true
end

-- Leader-only. `proceed` is set on 1.12 (blocking: the action buttons call it to
-- actually log out) and nil on 1.14 (non-blocking: shown on top of the countdown,
-- logout proceeds on its own).
-- 1.14: hide the menu-button catchers so the real Logout/Exit button is clickable
function GF.HideLogoutOverlays()
    if not GF.logoutOverlays then return end
    for _, b in ipairs(GF.logoutOverlays) do b:Hide() end
end

function GF.ShowLogoutDialog(proceed)
    GF.logoutProceed = proceed
    local is112 = WHC.client and WHC.client.is1_12
    if not GF.logoutFrame then
        local d = CreateFrame("Frame", "WhcGFLogout", UIParent, RETAIL_BACKDROP)
        d:SetWidth(311); d:SetHeight(282)
        d:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        d:SetFrameStrata("FULLSCREEN_DIALOG")
        d:EnableMouse(true)
        if d.SetBackdrop then
            d:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
        end
        -- much darker interior: near-black fill over the stone backdrop, under the content
        local dark = d:CreateTexture(nil, "BORDER")
        dark:SetTexture("Interface/Buttons/WHITE8x8")
        dark:SetVertexColor(0, 0, 0, 0.85)
        dark:SetPoint("TOPLEFT", d, "TOPLEFT", 11, -11)
        dark:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -11, 11)
        GF.logoutFrame = d

        -- yellow title (no trailing dot)
        local title = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", d, "TOP", 0, -16); title:SetWidth(228); title:SetJustifyH("CENTER")
        title:SetTextColor(1, 0.82, 0)
        d.title = title
        -- body, with spacing under the title
        local body = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        body:SetPoint("TOP", title, "BOTTOM", 0, -12); body:SetWidth(228); body:SetJustifyH("CENTER")
        d.body = body

        -- preAction sends the return time / delete. Then: 1.12 logs out via `proceed`
        -- (Logout() is callable there). 1.14 can't call Logout() (protected), so instead
        -- we HIDE our menu-button overlays and close the form, leaving the real Logout/
        -- Exit button uncovered for the player to click themselves.
        local function makeLogoutBtn(w, h, text, preAction)
            local btn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            btn:SetWidth(w); btn:SetHeight(h); btn:SetText(text)
            btn:SetScript("OnClick", function()
                preAction()
                d:Hide()
                if GF.logoutProceed then GF.logoutProceed()
                else GF.HideLogoutOverlays() end
            end)
            return btn
        end

        -- single "Back in 1h" preset (50% taller)
        local b1 = makeLogoutBtn(120, 33, "Back in 1h", function() Send("back 60") end)
        b1:SetPoint("TOP", body, "BOTTOM", 0, -14)

        -- "or will be back in" + hours input + Set (all 50% taller)
        local orLabel = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        orLabel:SetPoint("TOP", b1, "BOTTOM", 0, -12); orLabel:SetText("or will be back in")
        local olf, ols, olff = orLabel:GetFont()
        if olf then orLabel:SetFont(olf, (ols or 10) + 2, olff) end   -- bigger

        local hours = CreateFrame("EditBox", "WhcGFLogoutHours", d, RETAIL_BACKDROP)
        hours:SetWidth(38); hours:SetHeight(27); hours:SetPoint("TOP", orLabel, "BOTTOM", -66, -8)
        hours:SetAutoFocus(false); hours:SetNumeric(true); hours:SetMaxLetters(2)
        hours:SetFontObject(ChatFontNormal); hours:SetTextInsets(4, 4, 2, 2); hours:SetJustifyH("RIGHT")
        if hours.SetBackdrop then hours:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }); hours:SetBackdropColor(0, 0, 0) end
        local hl = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hl:SetPoint("LEFT", hours, "RIGHT", 4, 0); hl:SetText("hrs")
        local function setReturnPre()
            local h = tonumber(hours:GetText()) or 0; if h < 1 then h = 1 end; if h > 24 then h = 24 end
            Send("back " .. (h * 60))
        end
        local hb = makeLogoutBtn(103, 30, "Set", setReturnPre)
        hb:SetPoint("LEFT", hl, "RIGHT", 6, 0)
        -- Enter in the hours box = click Set
        hours:SetScript("OnEnterPressed", function()
            setReturnPre(); d:Hide()
            if GF.logoutProceed then GF.logoutProceed() else GF.HideLogoutOverlays() end
        end)
        d.hours = hours

        -- bottom: del + cancel stacked, a bit wider
        local del = makeLogoutBtn(180, 32, "Delete listing", function() Send("delete") end)
        del:SetPoint("TOP", hours, "BOTTOM", 66, -16)
        d.del = del

        -- cancel the in-progress logout countdown (CancelLogout is callable; only the
        -- Logout/Quit *override* is the protected/tainting path we dropped)
        local cancel = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        cancel:SetWidth(140); cancel:SetHeight(32); cancel:SetPoint("TOP", del, "BOTTOM", 0, -8); cancel:SetText("Stay logged in")
        cancel:SetScript("OnClick", function() if CancelLogout then CancelLogout() end; d:Hide() end)
    end

    local d = GF.logoutFrame
    d.title:SetText("You have an active group listing")
    d.body:SetText("Let your group know when you'll be back, or delete the listing.")
    d.del:SetText("Delete listing")
    d:Show()
    if d.hours then d.hours:SetFocus() end   -- focus the input by default
end

-- 1.14: stack invisible click-catchers over the ESC-menu Logout AND Exit buttons
-- (found by LOG_OUT/EXIT_GAME text). Shown only while you're the listing leader; a
-- leader's click opens our form (whose SECURE button does the actual /logout). Non-
-- leaders never see the catchers, so the real buttons work. Returns true if installed.
function GF.InstallLogoutMenuButton()
    if GF.logoutOverlaysDone then return true end
    if not GameMenuFrame then return false end

    -- locate the Logout and Exit buttons (global names differ on this client, so also
    -- match by the localized LOG_OUT / EXIT_GAME text among the menu's children)
    local logoutBtn = GameMenuButtonLogout
    local exitBtn   = GameMenuButtonQuit
    local wantLogout = LOG_OUT or "Log Out"
    local wantExit   = EXIT_GAME or "Exit Game"
    if not logoutBtn or not exitBtn then
        local kids = { GameMenuFrame:GetChildren() }
        for _, kid in ipairs(kids) do
            if kid and kid.GetText then
                local t = kid:GetText()
                if t == wantLogout then logoutBtn = logoutBtn or kid
                elseif t == wantExit then exitBtn = exitBtn or kid end
            end
        end
    end
    if not logoutBtn and not exitBtn then return false end

    -- stack an invisible click-catcher over a menu button. PARENT TO UIParent (not
    -- GameMenuFrame) so we don't taint the protected menu, and use a high strata so it
    -- catches the click. It JUST opens our form (no Logout()/Hide() -> no "action
    -- blocked"). After the player sets a return time we hide the catchers so they can
    -- click the real Logout/Exit button themselves.
    local overlays = {}
    GF.logoutOverlays = overlays
    local function makeOverlay(target)
        if not target then return end
        local b = CreateFrame("Button", nil, UIParent)
        b:SetFrameStrata("FULLSCREEN_DIALOG")
        b:SetAllPoints(target)
        b:RegisterForClicks("LeftButtonUp")
        b:Hide()
        b:SetScript("OnClick", function() GF.ShowLogoutDialog() end)
        table.insert(overlays, b)
    end
    makeOverlay(logoutBtn)
    makeOverlay(exitBtn)

    -- show the catchers ONLY while the menu is open AND you're the listing leader
    -- (so non-leaders click the real buttons untouched)
    local function refresh()
        local show = GameMenuFrame:IsShown() and playerHasListing()
        for _, b in ipairs(overlays) do if show then b:Show() else b:Hide() end end
    end
    if GameMenuFrame.HookScript then
        GameMenuFrame:HookScript("OnShow", refresh)
        GameMenuFrame:HookScript("OnHide", refresh)
    end
    refresh()

    GF.logoutOverlaysDone = true
    return true
end

function GF.InitLogoutHooks()
    local is112 = WHC.client and WHC.client.is1_12

    if is112 then
        -- 1.12: replace Logout/Quit so the prompt appears even for an INSTANT logout
        -- (rested/city, where PLAYER_CAMPING gives no countdown). Buttons call `proceed`.
        GF.origLogout = Logout
        GF.origQuit = Quit
        Logout = function()
            if playerHasListing() then GF.ShowLogoutDialog(function() GF.origLogout() end) else GF.origLogout() end
        end
        Quit = function()
            if playerHasListing() then GF.ShowLogoutDialog(function() GF.origQuit() end) else GF.origQuit() end
        end
    else
        -- 1.14: logout can't be cancelled/replaced from an addon (taint/block), so we
        -- intercept the CLICK before Logout() ever runs: stack an invisible catcher on
        -- the ESC-menu Logout button (found by its LOG_OUT text, since the button's name
        -- differs on this client). Leader's click -> our form; the form then calls
        -- Logout() (allowed from a hardware click). Non-leaders pass straight through.
        if not GF.InstallLogoutMenuButton() and GameMenuFrame and GameMenuFrame.HookScript then
            -- buttons may not exist yet at init; (re)try when the ESC menu opens
            GameMenuFrame:HookScript("OnShow", function() GF.InstallLogoutMenuButton() end)
        end
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    if is112 then
        watcher:RegisterEvent("PLAYER_CAMPING")
        watcher:RegisterEvent("PLAYER_QUITING")
    end
    -- keep GF.mine fresh on party changes (event names differ by client: 1.12 uses
    -- PARTY_MEMBERS_CHANGED/PARTY_LEADER_CHANGED, 1.14/Classic uses GROUP_ROSTER_UPDATE)
    if is112 then
        watcher:RegisterEvent("PARTY_MEMBERS_CHANGED")
        watcher:RegisterEvent("PARTY_LEADER_CHANGED")
    else
        watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
    end
    watcher:SetScript("OnEvent", function(self, ev)
        ev = ev or event
        if ev == "PLAYER_ENTERING_WORLD" then
            Send("cancelaway"); GF.StartMineRetry(); return
        end
        if ev == "PARTY_MEMBERS_CHANGED" or ev == "PARTY_LEADER_CHANGED" or ev == "GROUP_ROSTER_UPDATE" then
            GF.RequestMine(); return
        end
        -- PLAYER_CAMPING / PLAYER_QUITING (registered 1.12 only): block the countdown,
        -- prompt, then proceed via the buttons. (1.14 uses the menu-button overlay.)
        if not playerHasListing() then return end
        CancelLogout()
        GF.ShowLogoutDialog(function() if ev == "PLAYER_QUITING" then GF.origQuit() else GF.origLogout() end end)
    end)

    -- A single RequestMine at login often arrives too early (chat/world not ready) and
    -- is dropped -> GF.mine.state stays 0 -> the logout prompt only worked after opening
    -- the window. Retry every 2s until the server answers (GF.mineReceived) so the
    -- leader state is known well before the player logs out.
    if not GF.mineRetryFrame then
        local r = CreateFrame("Frame")
        r.elapsed, r.tries = 0, 0
        r:Hide()
        r:SetScript("OnUpdate", function(self, dt)
            self = self or this   -- 1.12 passes neither; uses globals this/arg1
            dt = dt or arg1 or 0
            self.elapsed = self.elapsed + dt
            if self.elapsed < 2 then return end
            self.elapsed = 0
            if GF.mineReceived or self.tries >= 10 then self:Hide(); return end
            self.tries = self.tries + 1
            GF.RequestMine()
        end)
        GF.mineRetryFrame = r
        GF.StartMineRetry = function()
            GF.mineReceived = false
            r.elapsed, r.tries = 1.9, 0   -- first retry almost immediately
            r:Show()
            GF.RequestMine()
        end
    end
    GF.StartMineRetry()
end
