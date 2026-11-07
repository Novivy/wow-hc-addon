-- Legacy Challenges preview: the 1.60 classic beta Challenges page rebuilt with 1.12 / 1.14 frames, our challenge list
-- (tools/legacy-challenges/legacy_challenges.def).
-- /whclegacy toggles the window, /whctoast shows the completion toast. No server calls yet: progress is local only.
-- Anchors, sizes and fonts follow Blizzard_LegacySystem + the camelot PortraitFrameTemplate of build 1.60.1.70532;
-- the few values that come from the beta screenshots instead of the code say so where they are used.

local LP = {}
WHC_LegacyPreview = LP

local ART_PATH = "Interface\\AddOns\\WOW_HC\\Images\\legacy\\"
local FONT = "Fonts\\FRIZQT__.TTF"
local NUMBER_FONT = "Fonts\\ARIALN.TTF"

local FRAME_W, FRAME_H = 920, 575                               -- LegacySystemFrame
-- ours: Blizzard's 920x575 is sized for the 1.60 UI and is wider than the 1.12 Auction House (832x447), the largest
-- stock panel. The whole window is drawn at 0.8 (736x460 on screen); the small texts are raised so they still
-- land at ~10 on screen (vanilla's smallest standard font, GameFontNormalSmall).
local WINDOW_SCALE = 0.8
local LIST_X, LIST_Y, LIST_W = 6, -80, 330                       -- LegacyChallengeCategoryListTemplate
local PANE_W, PANE_H, PANE_RIGHT, PANE_BOTTOM = 560, 490, 24, 8  -- LegacyChallengeDetailPaneTemplate
local CARD_W = PANE_W - 4                                        -- ScrollBox TOPLEFT 4,-3, linear view without padding
local CARD_H, CARD_GAP = 122, 5                                  -- collapsedHeight, elementSpacing
local ROW_H, ROW_GAP, ROW_INDENT, ROW_PAD = 34, 1, 10, 5         -- tree list view (indent, pads, spacing); Blizzard rows are 25, ours 34
local CRIT_ROW_H, CRIT_GAP_X, CRIT_GAP_Y, CRIT_OFFSET_X, CRIT_OFFSET_Y = 30, 10, 5, 20, -23
local DESC_W, DESC_FONT_SIZE, DESC_LINE_H = 400, 13, 15          -- SystemFont_Shadow_Med1 is 12/14, +1 for WINDOW_SCALE
-- ours: the description wraps before the shield (its art starts at CARD_W + SHIELD_X - 66 = 480), DESC_GAP short of it;
-- it starts at ribbon 5 + 72, or + 95 next to the +/- of a card with criteria
local DESC_GAP = 50                                              -- ours: narrower so descriptions wrap and fill the card
local SHIELD_X = -15
local DESCRIPTIONHEIGHT = 20                                     -- ACHIEVEMENTBUTTON_DESCRIPTIONHEIGHT
local SCROLL_STEP = 40
local SEARCH_FONT_SIZE = 14                                      -- ours: search text + hint
local SEARCH_VISIBLE_H = 30                                      -- search box 20 + its 5 px border top and bottom
local FILTER_W, SEARCH_FILTER_GAP = 76, 6                        -- ours: narrower filter button, gap to the search border
local FILTER_DROP = 2                                            -- ours: the filter button sits 2 px lower than the search box
-- Legacy points come from a server trait currency, the DB2 rows all say 0. Every card in the beta screenshots shows 1.
local CHALLENGE_POINTS = 1
LP.CARD_H = CARD_H                                              -- read by the harness
local REWARD_H, REWARD_INSET = 22, 8                             -- ours: reward band at the card bottom
local SUMMARY_W = 526                                            -- header points bar (Blizzard: 520 + 6)
local CARDS_TOP_PAD = 5                                          -- ours: gap above the first card (scroll top 75 -> was 80)
local LONE_BAR_W = math.floor((CARD_W - 2 * CRIT_OFFSET_X) / 2)  -- ours: a card's single progress bar, half width

local NORMAL_COLOR = { 1, 0.82, 0 }
local WHITE_COLOR = { 1, 1, 1 }
local GRAY_COLOR = { 0.5, 0.5, 0.5 }
local UNEARNED_POINTS_COLOR = { 0.7, 0.7, 0.7 }                  -- ours: points on the grey (not earned) shield
local DATE_COLOR = { 1, 0.6, 0.15 }                              -- ours: retail AchievementDateFont is orange
-- inner field centre vs shield texture centre: earned field x 21-43, not earned 20-42 (art px of 64), y = retail's +4
local SHIELD_FIELD_EARNED, SHIELD_FIELD_UNEARNED = { 0, 4 }, { -0.5, 4 }
local POINTS_NUDGE_X, POINTS_NUDGE_Y = -1.5, -1                  -- Friz digits + shadow sit ~1.5 right of their box; -1 = user

local function setArt(tex, key)
    local a = WHC_LegacyArt[key]
    tex:SetTexture(ART_PATH .. a.file)
    tex:SetTexCoord(0, a.u, 0, a.v)
end

local function artTexture(parent, layer, key, w, h)
    local a = WHC_LegacyArt[key]
    local tex = parent:CreateTexture(nil, layer)
    setArt(tex, key)
    tex:SetWidth(w or a.w)
    tex:SetHeight(h or a.h)
    return tex
end

-- three textures filling `owner`: fixed caps, stretched middle (the client slices these atlases, a plain stretch smears the caps)
local function hslice(owner, layer, key, cap, dispCap)
    local a = WHC_LegacyArt[key]
    local pw = a.w / a.u
    dispCap = dispCap or cap
    local l = owner:CreateTexture(nil, layer)
    local m = owner:CreateTexture(nil, layer)
    local r = owner:CreateTexture(nil, layer)
    l:SetTexture(ART_PATH .. a.file)
    m:SetTexture(ART_PATH .. a.file)
    r:SetTexture(ART_PATH .. a.file)
    l:SetTexCoord(0, cap / pw, 0, a.v)
    m:SetTexCoord(cap / pw, (a.w - cap) / pw, 0, a.v)
    r:SetTexCoord((a.w - cap) / pw, a.u, 0, a.v)
    l:SetWidth(dispCap)
    r:SetWidth(dispCap)
    l:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    l:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    r:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    r:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    m:SetPoint("TOPLEFT", l, "TOPRIGHT", 0, 0)
    m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT", 0, 0)
    return { l, m, r }
end

-- eight textures around `owner` (no centre): fixed corners, edges stretched along their length only
local function nslice(owner, layer, key, cap)
    local a = WHC_LegacyArt[key]
    local pw, ph = a.w / a.u, a.h / a.v
    local u1, u2 = cap / pw, (a.w - cap) / pw
    local v1, v2 = cap / ph, (a.h - cap) / ph
    local pieces = {}
    local function piece(l, r, t, b)
        local tex = owner:CreateTexture(nil, layer)
        tex:SetTexture(ART_PATH .. a.file)
        tex:SetTexCoord(l, r, t, b)
        table.insert(pieces, tex)
        return tex
    end
    local tl = piece(0, u1, 0, v1)
    local tr = piece(u2, a.u, 0, v1)
    local bl = piece(0, u1, v2, a.v)
    local br = piece(u2, a.u, v2, a.v)
    for _, c in ipairs({ tl, tr, bl, br }) do
        c:SetWidth(cap)
        c:SetHeight(cap)
    end
    tl:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    tr:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    bl:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    br:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    local top = piece(u1, u2, 0, v1)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT", 0, 0)
    local bottom = piece(u1, u2, v2, a.v)
    bottom:SetPoint("TOPLEFT", bl, "TOPRIGHT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    local left = piece(0, u1, v1, v2)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT", 0, 0)
    local right = piece(u2, a.u, v1, v2)
    right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    return pieces
end

local function setShown(pieces, shown)
    for _, t in ipairs(pieces) do
        if shown then t:Show() else t:Hide() end
    end
end

local function setSliceArt(slice, key, cap)
    local a = WHC_LegacyArt[key]
    local pw = a.w / a.u
    for _, t in ipairs(slice) do
        t:SetTexture(ART_PATH .. a.file)
    end
    slice[1]:SetTexCoord(0, cap / pw, 0, a.v)
    slice[2]:SetTexCoord(cap / pw, (a.w - cap) / pw, 0, a.v)
    slice[3]:SetTexCoord((a.w - cap) / pw, a.u, 0, a.v)
end

local function setFont(fs, size, shadow, path, flags)
    fs:SetFont(path or FONT, size, flags)
    if shadow then
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    end
end

local function setColor(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end

local function setDesaturated(tex, desaturate)
    if tex.SetDesaturated then
        tex:SetDesaturated(desaturate)
    end
    if desaturate then
        tex:SetVertexColor(0.6, 0.6, 0.6)
    else
        tex:SetVertexColor(1, 1, 1)
    end
end

-- ours: the red cross of something that can no longer be earned. A frame (textures take no mouse) holding the
-- ready check "not ready" mark: hovering it shows why, clicking it clicks `clickTarget` (the row / card under it).
-- Set .text to the reason before showing it.
local function createRedX(parent, size, clickTarget)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(size)
    f:SetHeight(size)
    f:EnableMouse(true)
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(f)
    setArt(tex, "redx")
    f:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetText("Not eligible anymore", 1, 0.25, 0.25)
        if f.text then
            GameTooltip:AddLine(f.text, 1, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    if clickTarget then
        f:SetScript("OnMouseUp", function()
            clickTarget:Click()
        end)
    end
    f:Hide()
    return f
end

local function playSound(sound)
    if sound then
        PlaySound(sound)
    end
end


-- [[ Data ]] --
-- Categories and challenges are OUR list (tools/legacy-challenges/legacy_challenges.def -> Legacy\LegacyData.lua):
-- character achievements only, ids = bits of the per-character completion mask. Progress is read from the character
-- where the client has an API for it (level, skills, PvP rank, reputation); req types the client cannot see (explore,
-- dungeon, raid, campfire, meta) show as not started until the server protocol exists. Feats of Strength are our
-- WHC.Achievements, ACTIVE / FAILED as the Achievements tab last saw them.

local CLASS_ICON = "Interface\\AddOns\\WOW_HC\\Images\\legacy\\icons\\classicon_"
local PRIMARY_PROFESSIONS = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Leatherworking",
                              "Mining", "Skinning", "Tailoring" }
local SECONDARY_PROFESSIONS = { "Cooking", "First Aid", "Fishing" }
local WEAPON_SKILLS = { "Axes", "Two-Handed Axes", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "Maces",
                        "Two-Handed Maces", "Polearms", "Staves", "Swords", "Two-Handed Swords", "Thrown", "Wands" }
local EXALTED = 8
local EXALTED_VALUE = 42000                                      -- GetFactionInfo barValue where Exalted starts

local CATEGORIES = {}
local CHALLENGES = {}
local categoryById = {}

local function playerSkills()
    local skills = {}
    if not GetNumSkillLines then return skills end
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank = GetSkillLineInfo(i)
        if name and not isHeader then
            skills[name] = rank
        end
    end
    return skills
end

-- exalted set + every faction's reputation value (barValue: 0 neutral ... 42000 exalted) + the exalted count
local function exaltedFactions()
    local out, value, count = {}, {}, 0
    if not GetNumFactions then return out, value, count end
    for i = 1, GetNumFactions() do
        local name, _, standingId, _, _, barValue = GetFactionInfo(i)
        if name then
            value[name] = tonumber(barValue) or 0
            if standingId == EXALTED then
                out[name] = true
                count = count + 1
            end
        end
    end
    return out, value, count
end

-- GetPVPLifetimeStats: honorable kills, dishonorable kills, highest rank
local function lifetimeHonorableKills()
    if not GetPVPLifetimeStats then return 0 end
    local hk = GetPVPLifetimeStats()
    return tonumber(hk) or 0
end

-- GetPVPRankInfo takes the rank id (5 = rank 1 ... 18 = rank 14); 1.12 takes a unit, 1.14 may not
local function rankName(rankId)
    if not GetPVPRankInfo then return nil end
    local ok, name = pcall(GetPVPRankInfo, rankId, "player")
    if not ok or type(name) ~= "string" or name == "" then
        ok, name = pcall(GetPVPRankInfo, rankId)
    end
    if ok and type(name) == "string" and name ~= "" then
        return name
    end
    return nil
end

local function highestRankNumber()
    local highest = 0
    if GetPVPLifetimeStats then
        local _, _, h = GetPVPLifetimeStats()
        if type(h) == "number" then highest = h end
    end
    if UnitPVPRank then
        local cur = UnitPVPRank("player")
        if type(cur) == "number" and cur > highest then highest = cur end
    end
    if highest >= 5 then
        return highest - 4
    end
    return 0
end

local function countAt(skills, list, value)
    local n = 0
    for _, name in ipairs(list) do
        if (skills[name] or 0) >= value then n = n + 1 end
    end
    return n
end

-- "skill:First Aid:150" -> { "skill", "First Aid", "150" } (Lua 5.0: no gmatch)
local function splitReq(req)
    local parts = {}
    local start = 1
    while true do
        local s = string.find(req, ":", start, true)
        if not s then
            table.insert(parts, string.sub(req, start))
            return parts
        end
        table.insert(parts, string.sub(req, start, s - 1))
        start = s + 1
    end
end

local function bonusState(ach)
    local frames = WHC.Frames and WHC.Frames.Achievements
    local frame = frames and frames[ach.id]
    if frame and frame.labelLost and frame.labelLost:GetText() == "ACTIVE" then
        return "ACTIVE"
    end
    return "FAILED"
end

-- UnitFactionGroup reads the unit's faction template: nil when that template has no faction group (a GM / test character
-- with a modified faction), which would hide every faction= card. The race decides then.
local RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance", Gnome = "Alliance",
    Orc = "Horde", Scourge = "Horde", Undead = "Horde", Tauren = "Horde", Troll = "Horde",
}

local function playerFaction()
    local group = UnitFactionGroup("player")
    if group == "Alliance" or group == "Horde" then
        return group, "UnitFactionGroup"
    end
    local _, raceFile = UnitRace("player")
    return RACE_FACTION[raceFile or ""], "race " .. tostring(raceFile) .. " (UnitFactionGroup = " .. tostring(group) .. ")"
end

-- [[ Server state ]] -- `.whc challenges` (PLAN_LEGACY_CHALLENGES.md "Phase 3 landed"): 24 words, 8 hex digits each.
-- Words 0-15 = completion bits (word 0 = the Feats flags as they are), 16 quests completed, 17 lifetime honorable
-- kills, 18-19 ever-exalted factions, 20 skills at 300 (15 weapons, Unarmed, 9 primary, 3 secondary), 21-22 reserved (always 0),
-- 23 critters 0-15 / keys 19-24 / races 25-28 / fishing zones 29-30. Bits are read with WHC.HasBit / HasWordBit
-- (Util.lua, arithmetic only).
local WORDS = 24
local LIST_BIT = { critters = 0, keys = 19, races = 25, fishzones = 29 }

local POW2 = WHC.POW2
local wordBit = WHC.HasWordBit

local function popRange(word, first, n)
    local c = 0
    for b = first, first + n - 1 do
        if WHC.HasBit(word, POW2[b]) then c = c + 1 end
    end
    return c
end

local function parseWords(hex, n)
    if not hex or string.len(hex) ~= n * 8 then return nil end
    local t = {}
    for i = 0, n - 1 do
        local v = tonumber(string.sub(hex, i * 8 + 1, i * 8 + 8), 16)
        if not v then return nil end
        t[i] = v
    end
    return t
end

LP.state = {}               -- target key ("0" = yourself, else the name the server answered) -> words 0-23
LP.exploreState = {}        -- target key -> exploration area words
LP.taken = nil              -- realm first ids someone holds (set), from `.whc challenges taken`
LP.viewKey = "0"            -- whose achievements the window shows
LP.exploreCount = 0         -- exploration criteria in reply order (card id, then criterion)

local function buildData()
    local className, classFile = UnitClass("player")
    local faction, factionSource = playerFaction()
    LP.faction, LP.factionSource = faction, factionSource
    local classCategory

    for i, c in ipairs(WHC_LegacyCategories) do
        local name = c.name
        if name == "@class" then
            name = className or "Class"
            classCategory = c.id
        end
        categoryById[c.id] = { id = c.id, parent = c.parent, order = i, name = name, own = 0, children = nil,
                               points = c.points }
    end

    -- points=N on a root (def "# Name | points=0") applies to every card under it
    local function rootPoints(catId)
        local cat = categoryById[catId]
        while cat and cat.parent ~= -1 do
            cat = categoryById[cat.parent]
        end
        if cat and cat.points then
            return cat.points
        end
        return CHALLENGE_POINTS
    end

    -- class= / race= cards (realm firsts, Atiesh) only show for that class / race, like faction=
    local _, raceFile = UnitRace("player")

    for _, src in ipairs(WHC_LegacyChallenges) do
        if (not src.faction or src.faction == faction) and (not src.class or src.class == classFile)
                and (not src.race or src.race == raceFile) then
            local cat = categoryById[src.cat]
            local req = splitReq(src.req or "")
            local kind = req[1]
            local name = src.name
            local icon = src.icon
            if icon == "@class" then
                icon = CLASS_ICON .. string.lower(classFile or "warrior")
            elseif src.iconA then
                icon = (faction == "Horde") and src.iconH or src.iconA
            end

            if kind == "rank" then
                name = rankName(tonumber(req[2] or "0") + 4) or name
            end

            local points = src.points
            if points == nil then points = rootPoints(src.cat) end
            -- static part only: done / progress / missed are computed by computeAll (client reads, then server words)
            local ch = { id = src.id, cat = src.cat, name = name, desc = src.desc, points = points,
                         icon = icon, reward = src.reward, criteria = {}, req = req, kind = kind,
                         untilLevel = src.untilLevel }
            for _, crit in ipairs(src.criteria) do
                local text, amount, isBar = crit[1], crit[2], crit[3]
                if isBar and amount > 0 then
                    table.insert(ch.criteria, { text, false, 0, amount })
                else
                    table.insert(ch.criteria, { text, false })
                end
            end

            table.insert(CHALLENGES, ch)
            if cat then cat.own = cat.own + 1 end
        end
    end

    -- META / dungeon tier rows -> their member cards, by name (the server's rule: "<name>" or "Explore <name>"; two
    -- raid cards share a name, the META's description says Dynamic or Normal)
    for _, ch in ipairs(CHALLENGES) do
        if ch.kind == "meta" or ch.kind == "dungeon" then
            for _, crit in ipairs(ch.criteria) do
                local want = string.lower(crit[1])
                local hits = {}
                for _, m in ipairs(CHALLENGES) do
                    local n = string.lower(m.name)
                    if m ~= ch and (n == want or n == "explore " .. want) then table.insert(hits, m) end
                end
                if table.getn(hits) > 1 then
                    local diff = string.find(string.lower(ch.desc or ""), "dynamic", 1, true) and "dynamic" or "normal"
                    local keep = {}
                    for _, m in ipairs(hits) do
                        if m.req[3] == diff then table.insert(keep, m) end
                    end
                    hits = keep
                end
                crit.member = hits[1]
            end
        end
    end

    -- exploration rows in the `.whc challenges explore` order: card id, then criterion
    local explore = {}
    for _, ch in ipairs(CHALLENGES) do
        if ch.kind == "explore" then table.insert(explore, ch) end
    end
    table.sort(explore, function(a, b) return a.id < b.id end)
    local offset = 0
    for _, ch in ipairs(explore) do
        ch.exploreOffset = offset
        offset = offset + table.getn(ch.criteria)
    end
    LP.exploreCount = offset

    for _, f in ipairs(WHC_LegacyFeats) do
        local ach = WHC.Achievements and WHC.Achievements[f.key]
        local cat = categoryById[f.cat]
        if ach and cat then
            -- the feat's PlayerAchievements flag -> its bit in word 0
            local bit = 0
            while bit < 31 and POW2[bit] < ach.id do bit = bit + 1 end
            table.insert(CHALLENGES, {
                cat = f.cat, name = ach.name, icon = "Interface\\Icons\\" .. ach.icon, points = 0, desc = ach.desc,
                criteria = {}, reward = f.reward, ach = ach, featBit = bit,
                missedReason = "This feat was failed: it can no longer be secured at level 60.",
            })
            cat.own = cat.own + 1
        end
    end

    local byOrder = function(a, b) return a.order < b.order end
    for _, cat in pairs(categoryById) do
        local parent = categoryById[cat.parent]
        if parent and cat.own > 0 then
            parent.children = parent.children or {}
            table.insert(parent.children, cat)
        end
    end
    for _, cat in pairs(categoryById) do
        if cat.parent == -1 and (cat.own > 0 or cat.children) then
            table.insert(CATEGORIES, cat)
        end
        if cat.children then table.sort(cat.children, byOrder) end
    end
    -- roots in the order of legacy_challenges.def
    table.sort(CATEGORIES, byOrder)

    -- open on the @class category if the def has one, else the first root with cards of its own (or its first child)
    local first = CATEGORIES[1]
    if first and first.own == 0 and first.children then
        first = first.children[1]
    end
    LP.defaultCategory = classCategory or (first and first.id)
end

-- the unit token of a name we are looking at (target / inspect frame), for its level and class
local function unitOf(name)
    if not name then return "player" end
    if UnitName("target") == name then return "target" end
    if InspectFrame and InspectFrame.unit and UnitName(InspectFrame.unit) == name then return InspectFrame.unit end
    return nil
end

-- what the cards are computed from: the server words of the viewed character when they arrived, plus, for your own
-- character, what the client can read (live bars, and everything before the first reply)
local function buildContext()
    local key = LP.viewKey or "0"
    local own = key == "0"
    local ctx = { own = own, words = LP.state[key], explore = LP.exploreState[key], taken = LP.taken }
    local unit = unitOf(not own and key or nil)
    ctx.level = unit and UnitLevel(unit) or nil
    if ctx.level and ctx.level <= 0 then ctx.level = nil end
    if own then
        ctx.skills = playerSkills()
        ctx.exalted, ctx.repValue, ctx.exaltedCount = exaltedFactions()
        ctx.hk = lifetimeHonorableKills()
        ctx.rank = highestRankNumber()
    end
    return ctx
end

local function computeCard(ch, ctx)
    local req, kind, w = ch.req, ch.kind, ctx.words
    local need = tonumber(req[3] or req[2] or "")
    local cur
    if kind == "level" then
        cur = ctx.level
    elseif kind == "skill" then
        cur = ctx.skills and (ctx.skills[req[2]] or 0)
    elseif kind == "prof300" then
        local secondary = req[2] == "secondary"
        if w then
            cur = popRange(w[20], secondary and 25 or 16, secondary and 3 or 9)
        elseif ctx.skills then
            cur = countAt(ctx.skills, secondary and SECONDARY_PROFESSIONS or PRIMARY_PROFESSIONS, 300)
        end
    elseif kind == "weapons300" then
        if w then
            cur = popRange(w[20], 0, 15)
        elseif ctx.skills then
            cur = countAt(ctx.skills, WEAPON_SKILLS, 300)
        end
    elseif kind == "rank" then
        cur = ctx.rank
    elseif kind == "rep" then
        -- bar = reputation value up to Exalted (42000), full once exalted
        need = EXALTED_VALUE
        if ctx.repValue then
            cur = ctx.exalted[req[2]] and EXALTED_VALUE or math.max(math.min(ctx.repValue[req[2]] or 0, EXALTED_VALUE), 0)
        end
    elseif kind == "hk" then
        -- yourself: the client's lifetime total (PLAYER_FIELD_LIFETIME_HONORABLE_KILLS, the server's word 17 value,
        -- no push per kill); someone else: their word 17
        cur = ctx.hk or (w and w[17])
    elseif kind == "quests" then
        cur = w and w[16]
    elseif kind == "exalted" then
        cur = w and (popRange(w[18], 0, 32) + popRange(w[19], 0, 32)) or ctx.exaltedCount
    else
        need = nil
    end

    -- the server bit decides once the words are there; before that (own character only) what the client reads
    local done
    if w and ch.id then
        done = wordBit(w, ch.id)
    elseif ctx.own and need and cur then
        done = cur >= need
    else
        done = false
    end
    if kind == "exaltedset" and not w and ctx.own then
        done = true
        for _, c in ipairs(ch.criteria) do
            if not ctx.exalted[c[1]] then done = false end
        end
    end
    ch.done = done

    local base = LIST_BIT[kind]
    for i, c in ipairs(ch.criteria) do
        if c[4] then
            -- a bar: the value the server stored or the client reads; full once the card is done
            local v = math.min(cur or 0, c[4])
            if done then v = c[4] end
            c[3], c[2] = v, v >= c[4]
        elseif kind == "exaltedset" then
            c[2] = done or (ctx.exalted ~= nil and ctx.exalted[c[1]] == true)
        elseif base then
            c[2] = done or wordBit(w, 23 * 32 + base + (i - 1))
        elseif kind == "explore" then
            c[2] = done or wordBit(ctx.explore, ch.exploreOffset + (i - 1))
        else
            c[2] = done
        end
    end

    -- missed = can no longer be earned (red cross): a dungeon above its last valid speedrun level, a class / race
    -- "level 60" realm first not held at 60, a realm first someone else holds
    ch.missed, ch.missedReason = nil, nil
    if not done then
        local level = ctx.level
        if ch.untilLevel and level and level > ch.untilLevel then
            ch.missed = true
            ch.missedReason = (ctx.own and "You are above level " or "Above level ") .. ch.untilLevel ..
                ": a speedrun of this dungeon no longer counts" .. (ctx.own and " for you." or ".")
        end
        local rf = string.sub(req[2] or "", 1, 2)
        if kind == "realmfirst" and (rf == "C_" or rf == "R_") and level and level >= 60 then
            ch.missed = true
            ch.missedReason = "Only granted when reaching level 60 first" .. (ctx.own and ", and you are already 60." or ".")
        end
        if kind == "realmfirst" and ctx.taken and ctx.taken[ch.id] then
            ch.missed = true
            ch.missedReason = "Someone else already holds this realm first."
        end
    end
end

local function computeAll()
    local ctx = buildContext()
    for _, ch in ipairs(CHALLENGES) do
        if ch.ach then
            -- Feats: word 0 = the PlayerAchievements flags (active below 60, secured at 60); before the reply, the
            -- Achievements tab state
            local active
            if ctx.words then
                active = wordBit(ctx.words, ch.featBit)
            elseif ctx.own then
                active = bonusState(ch.ach) == "ACTIVE"
            else
                active = false
            end
            ch.bonusState = active and "ACTIVE" or "FAILED"
            ch.done = active
            ch.missed = not active and (ctx.words ~= nil or ctx.own) or nil
        else
            computeCard(ch, ctx)
        end
    end
    -- META / dungeon tier rows mirror their member card; a tier is lost as soon as one of its dungeons is
    for _, ch in ipairs(CHALLENGES) do
        if ch.kind == "meta" or ch.kind == "dungeon" then
            for _, crit in ipairs(ch.criteria) do
                local m = crit.member
                if m then
                    crit[2] = m.done == true
                    crit.missed = m.missed and not m.done
                    crit.missedReason = m.missedReason
                    if ch.kind == "dungeon" and crit.missed and not ch.done then
                        ch.missed = true
                        ch.missedReason = ch.missedReason or (m.name .. " can no longer be earned.")
                    end
                end
            end
        end
    end
end

function LP.Recompute()
    if LP.dataBuilt then computeAll() end
end

function LP._challenges() return CHALLENGES end                -- read by the offline harness

function LP.EnsureData()
    if not LP.dataBuilt then
        LP.dataBuilt = true
        WHC_LoadLegacyData()                                     -- LegacyData.lua: the tables exist from here on
        buildData()
        computeAll()
        -- buildData copied what it needs into CHALLENGES: free the loader and the source rows (the categories stay,
        -- /whclegacy debug reads them)
        WHC_LoadLegacyData, WHC_LegacyChallenges, WHC_LegacyFeats = nil, nil, nil
    end
end

-- [[ Filters ]] -- LegacyChallengeFilters: completed / incomplete, both on by default, plus the search box

LP.showCompleted = true
LP.showIncomplete = true
LP.searchText = ""

local function contains(text, needle)
    return text ~= nil and string.find(string.lower(text), needle, 1, true) ~= nil
end

-- ours: the search matches the card's title or the name of its category / parent category (so "lev" finds the
-- Leveling cards, whose titles are Fresh Blood, Still Breathing...); descriptions are not searched
local function matchesSearch(ch)
    local needle = LP.searchText
    if contains(ch.name, needle) then return true end
    local cat = categoryById[ch.cat]
    while cat do
        if contains(cat.name, needle) then return true end
        cat = categoryById[cat.parent]
    end
    return false
end

local function isVisibleChallenge(ch)
    if ch.done and not LP.showCompleted then return false end
    if not ch.done and not LP.showIncomplete then return false end
    if LP.searchText ~= "" and not matchesSearch(ch) then
        return false
    end
    return true
end

local function visibleCount(catId)
    local n = 0
    for _, ch in ipairs(CHALLENGES) do
        if ch.cat == catId and isVisibleChallenge(ch) then n = n + 1 end
    end
    return n
end

-- [[ Minimal scroll bar ]] -- MinimalScrollBar: 8 wide track inset 19 top/bottom, 17x11 arrows at TOP and BOTTOM

local function vslice(owner, topKey, midKey, botKey)
    local top = artTexture(owner, "ARTWORK", topKey, 8, 8)
    top:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    local bot = artTexture(owner, "ARTWORK", botKey, 8, 8)
    bot:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    local mid = owner:CreateTexture(nil, "ARTWORK")
    setArt(mid, midKey)
    mid:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0)
    mid:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT", 0, 0)
end

local function createArrow(parent, key, overKey, point)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(17)
    b:SetHeight(11)
    b:SetPoint(point, parent, point, 0, 0)
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints(b)
    setArt(t, key)
    local h = b:CreateTexture(nil, "HIGHLIGHT")
    h:SetAllPoints(b)
    setArt(h, overKey)
    return b
end

-- sizes are passed in: anchor-derived sizes can read 0 before the window has been drawn once
local function createScrollBar(parent, scroll, child, viewH, barH)
    local sb = CreateFrame("Frame", nil, parent)
    sb:SetWidth(8)
    sb:SetHeight(barH)
    local trackH = barH - 38

    local track = CreateFrame("Frame", nil, sb)
    track:SetWidth(8)
    track:SetHeight(trackH)
    track:SetPoint("TOP", sb, "TOP", 0, -19)
    vslice(track, "sb_track_top", "sb_track_mid", "sb_track_bot")

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(8)
    vslice(thumb, "sb_thumb_top", "sb_thumb_mid", "sb_thumb_bot")

    local function range()
        return math.max(child:GetHeight() - viewH, 0)
    end

    function sb.Update()
        local r = range()
        if r <= 0 then
            thumb:Hide()
            return
        end
        local thumbH = math.max(trackH * viewH / child:GetHeight(), 16)
        local cur = scroll:GetVerticalScroll()
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -(trackH - thumbH) * cur / r)
        thumb:Show()
    end

    function sb.ScrollTo(value)
        local r = range()
        if value < 0 then value = 0 end
        if value > r then value = r end
        scroll:SetVerticalScroll(value)
        sb.Update()
    end

    local up = createArrow(sb, "sb_up", "sb_up_over", "TOP")
    up:SetScript("OnClick", function() sb.ScrollTo(scroll:GetVerticalScroll() - SCROLL_STEP) end)
    local down = createArrow(sb, "sb_down", "sb_down_over", "BOTTOM")
    down:SetScript("OnClick", function() sb.ScrollTo(scroll:GetVerticalScroll() + SCROLL_STEP) end)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        delta = delta or arg1
        sb.ScrollTo(scroll:GetVerticalScroll() - delta * SCROLL_STEP)
    end)

    -- thumb drag: follow the cursor while dragged. The per-frame script runs from OnDragStart to OnDragStop, which
    -- WoW fires wherever the button is released (OnMouseUp only reaches the thumb when released over it); hiding the
    -- thumb or the bar (window closed, nothing to scroll) stops it too, so it never outlives the drag
    local function stopDrag()
        thumb:SetScript("OnUpdate", nil)
    end
    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnMouseDown", function()
        local _, y = GetCursorPosition()
        thumb.dragStartY = y
        thumb.dragStartScroll = scroll:GetVerticalScroll()
    end)
    thumb:SetScript("OnDragStart", function()
        thumb:SetScript("OnUpdate", function()
            local _, cy = GetCursorPosition()
            local scale = (sb.GetEffectiveScale and sb:GetEffectiveScale()) or UIParent:GetScale()
            local free = trackH - thumb:GetHeight()
            if free <= 0 then return end
            local moved = (thumb.dragStartY - cy) / scale
            sb.ScrollTo(thumb.dragStartScroll + moved * range() / free)
        end)
    end)
    thumb:SetScript("OnDragStop", stopDrag)
    thumb:SetScript("OnMouseUp", stopDrag)
    thumb:SetScript("OnHide", stopDrag)
    sb:SetScript("OnHide", stopDrag)

    return sb
end

-- [[ Window ]] --

local function createChrome(f)
    -- camelot PortraitFrameTemplate nine-slice (frameLevel 500 in NineSlicePanelTemplate, above the page),
    -- -c60-2x pieces drawn at half their pixel size, camelot offsets from NineSliceLayoutOverrides
    local c = CreateFrame("Frame", nil, f)
    c:SetAllPoints(f)
    c:SetFrameLevel(f:GetFrameLevel() + 50)

    local function piece(key, w, h)
        local t = c:CreateTexture(nil, "OVERLAY")
        setArt(t, key)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end

    local tl = piece("frame_tl", 95, 95)
    tl:SetPoint("TOPLEFT", f, "TOPLEFT", -13, 16)
    local tr = piece("frame_tr", 95, 95)
    tr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 16)
    local bl = piece("frame_bl", 95, 100)
    bl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -13, -8)
    local br = piece("frame_br", 95, 100)
    br:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -8)

    local top = piece("frame_t", nil, 95)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    local bottom = piece("frame_b", nil, 100)
    bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    local left = piece("frame_l", 95, nil)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    local right = piece("frame_r", 95, nil)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)

    -- portrait (PortraitContainer frameLevel 400, under the ring): ours = the WOW-HC skull instead of Legacy-up. The
    -- ring's opening in frame_tl (transparent centre + its dark shadow band) is ~50 across, centred at 24.75,-21.75 from
    -- the window's top left; the skull is 50 so its own gold rim meets the metal ring
    local p = CreateFrame("Frame", nil, f)
    p:SetAllPoints(f)
    p:SetFrameLevel(f:GetFrameLevel() + 40)
    -- (the Dawnrest realm shows its round logo instead, WHC.BRAND.legacyPortrait)
    local portrait = artTexture(p, "OVERLAY", WHC.BRAND and WHC.BRAND.legacyPortrait or "portrait_hc", 50, 50)
    portrait:SetPoint("CENTER", f, "TOPLEFT", 24.75, -21.75)

    -- title (TitleContainer frameLevel 510), text TOP -5, GameFontNormal. Blizzard's container runs from 58 to -24,
    -- which puts the text 17 right of centre; ours spans the full width so the title is centred on the window
    local t = CreateFrame("Frame", nil, f)
    t:SetFrameLevel(f:GetFrameLevel() + 51)
    t:SetHeight(20)
    t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -1)
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -1)
    local title = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", t, "TOP", 0, -4)                         -- Blizzard -5, ours 1 up
    title:SetText("Achievements")
    LP.titleText = title

    -- close button: camelot UIPanelCloseButtonDefaultAnchors 28x28 at TOPRIGHT 0,3, RedButton-Exit art
    local close = CreateFrame("Button", nil, f)
    close:SetFrameLevel(f:GetFrameLevel() + 51)
    close:SetWidth(28)
    close:SetHeight(28)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 3)
    local normal = close:CreateTexture(nil, "ARTWORK")
    normal:SetAllPoints(close)
    setArt(normal, "close")
    close:SetScript("OnMouseDown", function() setArt(normal, "close_down") end)
    close:SetScript("OnMouseUp", function() setArt(normal, "close") end)
    close:SetScript("OnClick", function()
        f:Hide()
        PlaySoundFile(WHC.SOUND_FILES.achievementMenuClose)
    end)
end

-- [[ Window position ]] -- saved (account wide) as the window's top left in its own (scaled) coordinates; restored
-- on every open unless a corner would be off screen (resolution / UI scale changed), then back to the default spot
local DEFAULT_X, DEFAULT_Y = 0, 20

function LP.SaveWindowPosition()
    local f = LP.frame
    if not (f and WhcAddonSettings) then return end
    local left, top = f:GetLeft(), f:GetTop()
    if left and top then
        WhcAddonSettings.legacyWindowPos = { left = left, top = top }
    end
end

local function placeDefault(f)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)
end

function LP.RestoreWindowPosition()
    local f = LP.frame
    local pos = WhcAddonSettings and WhcAddonSettings.legacyWindowPos
    if not (pos and pos.left and pos.top) then
        placeDefault(f)
        return
    end
    -- corners in UIParent units: frame coordinates times the frame's scale over UIParent's
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local l, t = pos.left * k, pos.top * k
    local r, b = l + FRAME_W * k, t - FRAME_H * k
    if l < 0 or b < 0 or r > UIParent:GetWidth() or t > UIParent:GetHeight() then
        WhcAddonSettings.legacyWindowPos = nil
        placeDefault(f)
        return
    end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
end

local function createWindow()
    local f = CreateFrame("Frame", "WHCLegacyChallengesFrame", UIParent)
    f:SetScale(WINDOW_SCALE)
    f:SetWidth(FRAME_W)
    f:SetHeight(FRAME_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetFrameStrata("HIGH")
    if f.SetToplevel then f:SetToplevel(true) end
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        if f.SetUserPlaced then f:SetUserPlaced(false) end        -- ours saves it, not the client's layout cache
        LP.SaveWindowPosition()
    end)
    f:Hide()
    tinsert(UISpecialFrames, "WHCLegacyChallengesFrame")
    LP.frame = f

    -- the page: Legacy-Challenge-BG at TOPLEFT 1,-10 to BOTTOMRIGHT -2,4, the 813x510 art is two 512 wide tiles
    local page = CreateFrame("Frame", nil, f)
    page:SetAllPoints(f)
    page:SetFrameLevel(f:GetFrameLevel() + 10)
    LP.page = page
    local bg = WHC_LegacyArt.bg
    local bgW, bgH = FRAME_W - 3, FRAME_H - 14
    local x = 1
    for _, tile in ipairs(bg.tiles) do
        local tex = page:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(ART_PATH .. tile.file)
        tex:SetTexCoord(0, tile.u, 0, tile.v)
        local w = bgW * tile.w / bg.w
        tex:SetWidth(w)
        tex:SetHeight(bgH)
        tex:SetPoint("TOPLEFT", f, "TOPLEFT", x, -10)
        x = x + w
    end

    -- VerticalDivider TOPLEFT 328,-72, 12x503
    local divider = artTexture(page, "ARTWORK", "divider", 12, 503)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", 328, -72)

    createChrome(f)
    LP.CreatePointSummary(page)
    LP.CreateCategoryList(page)
    LP.CreateDetailPane(page)
end

-- LegacyChallengePointSummaryTemplate at TOPLEFT 280,-25, 520x36. The beta shows no text on this bar.
function LP.CreatePointSummary(page)
    local f = LP.frame
    -- ours: the bar is centred on the window (Blizzard's sat at x 280, 80 px right of centre)
    local summary = CreateFrame("Frame", nil, page)
    summary:SetWidth(SUMMARY_W)
    summary:SetHeight(36)
    summary:SetPoint("TOP", f, "TOP", 0, -25)

    local barBg = summary:CreateTexture(nil, "ARTWORK")
    setArt(barBg, "bar_bg")
    barBg:SetHeight(16)
    barBg:SetPoint("LEFT", summary, "LEFT", 0, -3)
    barBg:SetPoint("RIGHT", summary, "RIGHT", 0, -3)

    -- PointsBar: TOPLEFT of the background to its BOTTOMRIGHT + 3 (13 high)
    local bar = CreateFrame("Frame", nil, summary)
    bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", 0, 3)
    local fill = bar:CreateTexture(nil, "ARTWORK")
    setArt(fill, "bar_fill")
    fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    LP.summaryFill = fill
    LP.summaryBar = bar

    local frameHolder = CreateFrame("Frame", nil, bar)
    frameHolder:SetPoint("TOPLEFT", bar, "TOPLEFT", -8, 7)
    frameHolder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 8, -10)
    hslice(frameHolder, "OVERLAY", "bar_frame", 12)

    -- earned / total in the middle of the bar, on its own frame above the bar frame art (number font like the
    -- criteria bars: ARIALN 14 outline)
    local textHolder = CreateFrame("Frame", nil, frameHolder)
    textHolder:SetAllPoints(bar)
    textHolder:SetFrameLevel(frameHolder:GetFrameLevel() + 2)
    local text = textHolder:CreateFontString(nil, "OVERLAY")
    setFont(text, 14, false, NUMBER_FONT, "OUTLINE")
    setColor(text, WHITE_COLOR)
    text:SetPoint("CENTER", bar, "CENTER", 0, 1)                    -- ours: 1 px up (user)
    LP.summaryText = text
end

local function setBarRatio(tex, key, fullWidth, ratio)
    local a = WHC_LegacyArt[key]
    if ratio <= 0 then
        tex:Hide()
        return
    end
    if ratio > 1 then ratio = 1 end
    tex:Show()
    tex:SetWidth(fullWidth * ratio)
    tex:SetTexCoord(0, a.u * ratio, 0, a.v)
end

function LP.UpdatePointSummary()
    local earned, total = 0, 0
    for _, ch in ipairs(CHALLENGES) do
        if not ch.bonusState then
            total = total + ch.points
            if ch.done then earned = earned + ch.points end
        end
    end
    -- two spaces before the slash: ARIALN's "/" leans left into a single space and touches the digit
    LP.summaryText:SetText(earned .. "  / " .. total)
    setBarRatio(LP.summaryFill, "bar_fill", SUMMARY_W, total > 0 and earned / total or 0)
end

-- [[ Category list ]] --

local function createSearchBox(list)
    local box = CreateFrame("EditBox", "WHCLegacySearchBox", list)
    box:SetAutoFocus(false)
    box:SetHeight(20)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetFont(FONT, SEARCH_FONT_SIZE)                              -- ours: bigger than GameFontHighlightSmall
    box:SetTextInsets(19, 20, 0, 0)

    -- InputBoxTemplate border: Common-Input-Border pieces, 8x8 corners at -5,5 outside the box
    local function piece(key)
        local t = box:CreateTexture(nil, "BACKGROUND")
        setArt(t, key)
        return t
    end
    local tl, tr, bl, br = piece("input_tl"), piece("input_tr"), piece("input_bl"), piece("input_br")
    for _, t in ipairs({ tl, tr, bl, br }) do
        t:SetWidth(8)
        t:SetHeight(8)
    end
    tl:SetPoint("TOPLEFT", box, "TOPLEFT", -5, 5)
    tr:SetPoint("TOPRIGHT", box, "TOPRIGHT", 5, 5)
    bl:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", -5, -5)
    br:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 5, -5)
    local t = piece("input_t")
    t:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    t:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT", 0, 0)
    local b = piece("input_b")
    b:SetPoint("TOPLEFT", bl, "TOPRIGHT", 0, 0)
    b:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    local l = piece("input_l")
    l:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    l:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT", 0, 0)
    local r = piece("input_r")
    r:SetPoint("TOPLEFT", tr, "BOTTOMLEFT", 0, 0)
    r:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    local m = piece("input_m")
    m:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT", 0, 0)
    m:SetPoint("BOTTOMRIGHT", br, "TOPLEFT", 0, 0)

    -- SearchBoxTemplate: 10x10 magnifier at LEFT 1,-1, "Search" instructions while empty
    local icon = artTexture(box, "OVERLAY", "search_icon", 13, 13)
    icon:SetPoint("LEFT", box, "LEFT", 1, -1)
    local hint = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    setFont(hint, SEARCH_FONT_SIZE)
    setColor(hint, GRAY_COLOR)
    hint:SetPoint("LEFT", box, "LEFT", 19, 0)
    hint:SetText("Search")

    box:SetScript("OnTextChanged", function()
        local text = box:GetText() or ""
        if text == "" then hint:Show() else hint:Hide() end
        LP.searchText = string.lower(text)
        LP.Refresh()
    end)
    box:SetScript("OnEscapePressed", function() box:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
    return box
end

local function createFilter(list)
    -- WowStyle1FilterDropdownTemplate; the beta draws the text gold. Ours: the button is the art's visible body
    -- (common-dropdown-b-button 97x26: solid rows 4-23, columns 2-94, arrow at columns 81-85), scaled evenly so the
    -- body is the search box's visible 30 high (k = 30 / 20); only a plain middle strip (columns 20-70) stretches to
    -- reach FILTER_W. No arrow: the right end is the left end (columns 0-20) mirrored, both keep their proportions
    local b = CreateFrame("Button", nil, list)
    b:SetHeight(SEARCH_VISIBLE_H)
    b:SetWidth(FILTER_W)
    local k = SEARCH_VISIBLE_H / 20
    local holder = CreateFrame("Frame", nil, b)
    holder:SetPoint("TOPLEFT", b, "TOPLEFT", -2 * k, 4 * k)
    holder:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2 * k, -2 * k)   -- art margins: 2 cols each side, 4 rows top, 2 bottom
    holder:SetFrameLevel(b:GetFrameLevel())
    local L, R = 20, 70                                          -- art columns: left end | stretched | right end
    local pieces = {}
    for i = 1, 3 do
        pieces[i] = holder:CreateTexture(nil, "BACKGROUND")
        pieces[i]:SetPoint("TOP", holder, "TOP", 0, 0)
        pieces[i]:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
    end
    pieces[1]:SetPoint("LEFT", holder, "LEFT", 0, 0)
    pieces[1]:SetWidth(L * k)
    pieces[3]:SetPoint("RIGHT", holder, "RIGHT", 0, 0)
    pieces[3]:SetWidth(L * k)
    pieces[2]:SetPoint("LEFT", pieces[1], "RIGHT", 0, 0)
    pieces[2]:SetPoint("RIGHT", pieces[3], "LEFT", 0, 0)
    local function setFilterArt(key)
        local a = WHC_LegacyArt[key]
        local pw = a.w / a.u                                     -- the padded texture width (128)
        for i = 1, 3 do pieces[i]:SetTexture(ART_PATH .. a.file) end
        pieces[1]:SetTexCoord(0, L / pw, 0, a.v)
        pieces[2]:SetTexCoord(L / pw, R / pw, 0, a.v)
        pieces[3]:SetTexCoord(L / pw, 0, 0, a.v)                 -- the left end, mirrored
    end
    setFilterArt("filter")
    local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", b, "CENTER", 0, 2)                     -- ours: 2 up
    text:SetText("Filter")
    b:SetScript("OnEnter", function() setFilterArt("filter_hover") end)
    b:SetScript("OnLeave", function() setFilterArt("filter") end)

    -- the menu: Completed / Incomplete checkboxes under the button (menuRelativePoint BOTTOMLEFT, 6, 2)
    local menu = CreateFrame("Frame", nil, b, RETAIL_BACKDROP)
    menu:SetWidth(140)
    menu:SetHeight(58)
    menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 6, 2)
    menu:SetFrameStrata("DIALOG")
    menu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    menu:SetBackdropColor(0, 0, 0, 0.9)
    menu:Hide()

    local function option(label, y, get, set)
        -- named: the 1.12 template builds "$parentText" from the name
        local cb = CreateFrame("CheckButton", "WHCLegacyFilter" .. label, menu, "UICheckButtonTemplate")
        cb:SetWidth(22)
        cb:SetHeight(22)
        cb:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, y)
        cb:SetChecked(get())
        local fs = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        fs:SetText(label)
        cb:SetScript("OnClick", function()
            set(cb:GetChecked() and true or false)
            playSound(WHC.SOUNDS.checkBoxOn)
            LP.Refresh()
        end)
    end
    option("Completed", -6, function() return LP.showCompleted end, function(v) LP.showCompleted = v end)
    option("Incomplete", -30, function() return LP.showIncomplete end, function(v) LP.showIncomplete = v end)

    b:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else menu:Show() end
        playSound(WHC.SOUNDS.checkBoxOn)
    end)
    return b
end

function LP.CreateCategoryList(page)
    local f = LP.frame
    local list = CreateFrame("Frame", nil, page)
    list:SetWidth(LIST_W)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", LIST_X, LIST_Y)
    list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LIST_X, 8)
    LP.categoryList = list

    -- FilterDropdown TOPRIGHT -8,-9; SearchBox TOPLEFT 13,-8, RIGHT on the filter's LEFT -4
    local filter = createFilter(list)
    filter:SetPoint("TOPRIGHT", list, "TOPRIGHT", -8, -3 - FILTER_DROP)   -- the search border's top (-8 + 5), FILTER_DROP lower
    local search = createSearchBox(list)
    LP.searchBox = search
    search:SetPoint("TOPLEFT", list, "TOPLEFT", 13, -8)
    -- the box border sticks out 5 px; +FILTER_DROP keeps the box's own height (its RIGHT anchor also sets its centre)
    search:SetPoint("RIGHT", filter, "LEFT", -(5 + SEARCH_FILTER_GAP), FILTER_DROP)

    -- ScrollBox TOPLEFT 8,-35 to BOTTOMRIGHT -20,5 (Blizzard: list down to 8 above the frame bottom, so 13). Ours: down
    -- to the inner edge of the bottom frame border, 6 above the frame bottom, like the cards
    local viewH = (FRAME_H + LIST_Y) - 35 - 6
    local scroll = CreateFrame("ScrollFrame", nil, list)
    scroll:SetWidth(LIST_W - 28)
    scroll:SetHeight(viewH)
    scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -35)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(LIST_W - 28)
    child:SetHeight(10)
    scroll:SetScrollChild(child)
    -- ScrollBar TOPLEFT on the ScrollBox TOPRIGHT, BOTTOMLEFT on its BOTTOMRIGHT
    local sb = createScrollBar(list, scroll, child, viewH, viewH)
    sb:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 0, 0)

    LP.categoryScroll = scroll
    LP.categoryChild = child
    LP.categoryBar = sb
    LP.categoryButtons = {}
    LP.expanded = {}
end

local function createCategoryButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(ROW_H)

    -- parent rows: common-button-list-collapseExpand (sliced), leaves: Legacy-Challenge-Left-Sub-Tab (stretched).
    -- Both live on the button itself: a child frame would draw over the button's text.
    b.headerSlice = hslice(b, "BACKGROUND", "header", 10)
    b.leaf = b:CreateTexture(nil, "BACKGROUND")
    b.leaf:SetAllPoints(b)

    -- leaf highlight: one stretched texture like the leaf art
    b.highlight = b:CreateTexture(nil, "HIGHLIGHT")
    b.highlight:SetAllPoints(b)
    b.highlight:SetBlendMode("ADD")
    b.highlight:SetAlpha(0.4)
    -- parent highlight: ListHeaderVisualTemplate uses the collapseExpand atlas itself (ADD, alpha 0.4), which the client
    -- slices; one stretched texture smears the rounded ends, so it is sliced like the normal art
    b.headerHighlight = hslice(b, "HIGHLIGHT", "header", 10)
    for _, t in ipairs(b.headerHighlight) do
        t:SetBlendMode("ADD")
        t:SetAlpha(0.4)
    end

    -- ButtonText LEFT 8, Game15Font_Shadow
    b.text = b:CreateFontString(nil, "OVERLAY")
    setFont(b.text, 15, true)
    b.text:SetPoint("LEFT", b, "LEFT", 9, 0)          -- ours: +1 px horizontal padding (Blizzard: 8)
    b.text:SetJustifyH("LEFT")

    -- CollapseButton 20x20 at RIGHT -6, icon common-button-list-plus 13x13 / -minus 13x4 at its center
    b.collapse = b:CreateTexture(nil, "OVERLAY")
    b.collapse:SetPoint("CENTER", b, "RIGHT", -17, 0)

    -- ours: the card's green check when every challenge of the category (and of its sub categories) is done.
    -- Anchored in RefreshCategoryList: at the right edge on a leaf, left of the +/- on a parent.
    b.check = artTexture(b, "OVERLAY", "check", 16, 14)
    -- ours: red cross (ready check "not ready") when what is left of the category can no longer be earned
    b.redx = createRedX(b, 16, b)
    return b
end

-- Category totals ignore filters and search: total, done, and open = can still be earned. An ACTIVE feat is "done"
-- for the green check but still open: it is only secured at 60.
-- ONE pass over the challenges per list refresh (user 2026-11-01): visible count (filters + search) and total / done /
-- open per category, own cards only; the list reads these instead of rescanning every challenge per row
local function categoryCounts()
    local visible, stats = {}, {}
    for _, ch in ipairs(CHALLENGES) do
        local id = ch.cat
        if isVisibleChallenge(ch) then
            visible[id] = (visible[id] or 0) + 1
        end
        local s = stats[id]
        if not s then
            s = { total = 0, done = 0, open = 0 }
            stats[id] = s
        end
        s.total = s.total + 1
        if ch.done then
            s.done = s.done + 1
            if ch.bonusState == "ACTIVE" then s.open = s.open + 1 end
        elseif not ch.missed then
            s.open = s.open + 1
        end
    end
    return visible, stats
end

-- "complete" = every challenge done (green check), "missed" = not complete and nothing left that can still be earned
-- (red cross): one ACTIVE feat keeps Hard Chores / Feats of Strength without a cross. Sub categories included.
local function categoryState(cat, stats)
    local total, done, open = 0, 0, 0
    local function add(c)
        local s = stats[c.id]
        if s then
            total, done, open = total + s.total, done + s.done, open + s.open
        end
        if c.children then
            for _, child in ipairs(c.children) do add(child) end
        end
    end
    add(cat)
    if total == 0 then return nil end
    if done == total then return "complete" end
    if open == 0 then return "missed" end
    return nil
end

local function isCategorySelected(cat)
    if LP.selectedCategory == cat.id then return true end
    return cat.children ~= nil and LP.activeParent == cat.id
end

function LP.RefreshCategoryList()
    local visible, stats = categoryCounts()
    local rows = {}
    for _, cat in ipairs(CATEGORIES) do
        local hasVisibleChild = false
        if cat.children then
            for _, child in ipairs(cat.children) do
                if (visible[child.id] or 0) > 0 then hasVisibleChild = true end
            end
        end
        if (visible[cat.id] or 0) > 0 or hasVisibleChild then
            table.insert(rows, { cat = cat, depth = 0, isParent = hasVisibleChild })
            if hasVisibleChild and LP.expanded[cat.id] then
                for _, child in ipairs(cat.children) do
                    if (visible[child.id] or 0) > 0 then
                        table.insert(rows, { cat = child, depth = 1 })
                    end
                end
            end
        end
    end

    local rowW = LIST_W - 28 - ROW_PAD
    local y = -ROW_PAD
    for i, row in ipairs(rows) do
        local b = LP.categoryButtons[i]
        if not b then
            b = createCategoryButton(LP.categoryChild)
            LP.categoryButtons[i] = b
        end
        local cat = row.cat
        local selected = isCategorySelected(cat)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", LP.categoryChild, "TOPLEFT", row.depth * ROW_INDENT, y)
        b:SetWidth(rowW - row.depth * ROW_INDENT)

        for _, t in ipairs(b.headerSlice) do
            if row.isParent then t:Show() else t:Hide() end
        end
        if row.isParent then
            b.leaf:Hide()
            b.highlight:Hide()
            setShown(b.headerHighlight, true)
            b.collapse:Show()
            if LP.expanded[cat.id] then
                setArt(b.collapse, "header_minus")                -- ours: the + without its vertical bar, 13x13 like it
                b.collapse:SetWidth(13)
                b.collapse:SetHeight(13)
            else
                setArt(b.collapse, "header_plus")
                b.collapse:SetWidth(13)
                b.collapse:SetHeight(13)
            end
        else
            b.leaf:Show()
            setArt(b.leaf, selected and "cat_sel" or "cat")
            setArt(b.highlight, "cat_sel")
            b.highlight:Show()
            setShown(b.headerHighlight, false)
            b.collapse:Hide()
        end
        -- RefreshTitleColorState: white when selected, NORMAL_FONT_COLOR otherwise
        setColor(b.text, selected and WHITE_COLOR or NORMAL_COLOR)
        b.text:SetText(cat.name)

        b.check:ClearAllPoints()
        b.check:SetPoint("RIGHT", b, "RIGHT", row.isParent and -27 or -9, 0)
        b.redx:ClearAllPoints()
        b.redx:SetPoint("RIGHT", b, "RIGHT", row.isParent and -27 or -9, 0)
        local state = categoryState(cat, stats)
        if state == "complete" then b.check:Show() else b.check:Hide() end
        b.redx.text = "Nothing left to earn here: everything not done yet can no longer be earned."
        if state == "missed" then b.redx:Show() else b.redx:Hide() end

        -- Lua 5.0 (1.12): a closure sees the for loop's own variables at their final value (nil), so copy first
        local isParent = row.isParent
        b:SetScript("OnClick", function()
            playSound(WHC.SOUNDS.checkBoxOn)
            if isParent then
                -- a parent toggles; with META cards of its own it shows them, without any, opening it selects
                -- its first sub category that has cards
                LP.expanded[cat.id] = not LP.expanded[cat.id]
                local firstChild
                if LP.expanded[cat.id] and visibleCount(cat.id) == 0 then
                    for _, child in ipairs(cat.children) do
                        if not firstChild and visibleCount(child.id) > 0 then firstChild = child.id end
                    end
                end
                if visibleCount(cat.id) > 0 then
                    LP.SelectCategory(cat.id)
                elseif firstChild then
                    LP.SelectCategory(firstChild)
                else
                    LP.selectedCategory = nil
                    LP.activeParent = cat.id
                    LP.RefreshCategoryList()
                end
            else
                LP.SelectCategory(cat.id)
            end
        end)
        b:Show()
        y = y - ROW_H - ROW_GAP
    end
    for i = table.getn(rows) + 1, table.getn(LP.categoryButtons) do
        LP.categoryButtons[i]:Hide()
    end

    LP.categoryChild:SetHeight(math.max(-y + ROW_PAD, 1))
    LP.categoryBar.ScrollTo(LP.categoryScroll:GetVerticalScroll())
end

function LP.SelectCategory(catId)
    LP.selectedCategory = catId
    LP.activeParent = nil
    LP.cardsCategory = catId
    LP.OnCategorySelected(catId)                                 -- first Exploration / Realm First click asks the server
    -- a category holding a single card opens with it selected (= expanded when it has criteria)
    LP.selectedChallenge = nil
    local only, n = nil, 0
    for _, ch in ipairs(CHALLENGES) do
        if ch.cat == catId and isVisibleChallenge(ch) then
            only = ch
            n = n + 1
        end
    end
    if n == 1 then
        LP.selectedChallenge = only
    end
    local cat = categoryById[catId]
    if cat and categoryById[cat.parent] then
        LP.expanded[cat.parent] = true
    end
    LP.RefreshCategoryList()
    LP.RefreshChallenges()
    LP.detailBar.ScrollTo(0)
end

-- [[ Challenge cards ]] --

function LP.CreateDetailPane(page)
    local f = LP.frame
    local pane = CreateFrame("Frame", nil, page)
    pane:SetWidth(PANE_W)
    pane:SetHeight(PANE_H)
    pane:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PANE_RIGHT, PANE_BOTTOM)

    -- ScrollBox (Blizzard: TOPLEFT 4,-3 to BOTTOMRIGHT 0,5, which stops short of both borders). Ours: from the header
    -- separator line (bg art rows 54-58, bg stretched 510 -> 561 from y -10: its bottom edge at y -75) down to the
    -- inner edge of the bottom frame border (frame_b metal from row 173 of 200, drawn at half: 5.5 above the bottom)
    local scrollTop, scrollBottom = 75, 6
    local viewH = FRAME_H - scrollTop - scrollBottom
    local scroll = CreateFrame("ScrollFrame", nil, pane)
    scroll:SetWidth(CARD_W)
    scroll:SetHeight(viewH)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_W - PANE_RIGHT - PANE_W + 4, -scrollTop)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(CARD_W)
    child:SetHeight(10)
    scroll:SetScrollChild(child)

    -- ScrollBar TOPLEFT on the pane's TOPRIGHT +6,-8, BOTTOMLEFT on its BOTTOMRIGHT +6,+6
    local sb = createScrollBar(pane, scroll, child, viewH, PANE_H - 8 - 6)
    sb:SetPoint("TOPLEFT", pane, "TOPRIGHT", 6, -8)

    LP.scroll = scroll
    LP.scrollChild = child
    LP.detailBar = sb
    LP.cards = {}
end

local function createCriterion(card)
    local c = CreateFrame("Frame", nil, card)
    c:SetHeight(CRIT_ROW_H)

    -- text row: Legacy-Challenge-Cards-Bar, SystemFont_Small2 at LEFT 6 / RIGHT -24, check (0.4 scale) at RIGHT -6
    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints(c)
    setArt(c.bg, "crit_bar")
    c.name = c:CreateFontString(nil, "ARTWORK")
    setFont(c.name, 13)   -- SystemFont_Small2 is 11, +2 for WINDOW_SCALE
    c.name:SetPoint("LEFT", c, "LEFT", 6, 0)
    c.name:SetPoint("RIGHT", c, "RIGHT", -24, 0)
    c.name:SetJustifyH("LEFT")
    c.check = artTexture(c, "ARTWORK", "check", 16, 14)
    c.check:SetPoint("RIGHT", c, "RIGHT", -6, 0)
    -- ours: red cross in the check's place when the criterion can no longer be earned (a lost dungeon on a tier META)
    c.redx = createRedX(c, 16, nil)
    c.redx:SetPoint("RIGHT", c, "RIGHT", -6, 0)

    -- counted row: ProgressBarBackground 16 high across the row, bar 13 high on top of it, frame -8,7 / 8,-10
    c.barBg = c:CreateTexture(nil, "BORDER")
    setArt(c.barBg, "bar_bg")
    c.barBg:SetHeight(16)
    c.barBg:SetPoint("LEFT", c, "LEFT", 0, 0)
    c.barBg:SetPoint("RIGHT", c, "RIGHT", 0, 0)
    c.bar = CreateFrame("Frame", nil, c)
    c.bar:SetPoint("TOPLEFT", c.barBg, "TOPLEFT", 0, 0)
    c.bar:SetPoint("BOTTOMRIGHT", c.barBg, "BOTTOMRIGHT", 0, 3)
    c.barFill = c.bar:CreateTexture(nil, "ARTWORK")
    setArt(c.barFill, "bar_fill")
    c.barFill:SetPoint("TOPLEFT", c.bar, "TOPLEFT", 0, 0)
    c.barFill:SetPoint("BOTTOMLEFT", c.bar, "BOTTOMLEFT", 0, 0)
    c.barFrame = CreateFrame("Frame", nil, c.bar)
    c.barFrame:SetPoint("TOPLEFT", c.bar, "TOPLEFT", -8, 7)
    c.barFrame:SetPoint("BOTTOMRIGHT", c.bar, "BOTTOMRIGHT", 8, -10)
    hslice(c.barFrame, "ARTWORK", "bar_frame", 12)
    -- NumberFontNormal (ARIALN 14 outline), GENERIC_FRACTION_STRING_WITH_SPACING
    c.barText = c.barFrame:CreateFontString(nil, "OVERLAY")
    setFont(c.barText, 14, false, NUMBER_FONT, "OUTLINE")
    c.barText:SetPoint("CENTER", c.bar, "CENTER", 0, 0)
    return c
end

local function createCard(parent)
    local card = CreateFrame("Button", nil, parent)
    card:SetWidth(CARD_W)
    card:SetHeight(CARD_H)

    -- collapsed: one piece; expanded: top / middle / bottom. Blizzard puts the middle on texture sublevel -1 under the
    -- caps; 1.12 has no sublevels, so the middle is BACKGROUND, the caps BORDER and the selection border ARTWORK.
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetAllPoints(card)
    card.mid = card:CreateTexture(nil, "BACKGROUND")
    card.mid:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -10)
    card.mid:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 10)
    card.top = card:CreateTexture(nil, "BORDER")
    card.top:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card.top:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card.top:SetHeight(34)
    card.bottom = card:CreateTexture(nil, "BORDER")
    card.bottom:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    card.bottom:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 0)
    card.bottom:SetHeight(83)

    -- the ~4px yellow border with ~6px rounded corners: nine-sliced, a plain stretch thickens it on tall cards
    card.selected = nslice(card, "ARTWORK", "card_sel", 12)

    -- TitleBar TOPLEFT 5,-4 to TOPRIGHT -80,-4, 46 high
    card.ribbon = card:CreateTexture(nil, "ARTWORK")
    card.ribbon:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -4)
    card.ribbon:SetPoint("TOPRIGHT", card, "TOPRIGHT", -80, -4)
    card.ribbon:SetHeight(46)

    -- Icon frame 60x60 at TOPLEFT 12,-18, Legacy-Tree-Frame-icon-frame on top. Blizzard draws a 50x50 icon clipped by
    -- UI-Frame-IconMask; 1.12 has no masks and the square corners poke out past the frame's bevelled corners. The bevel
    -- is solid from 8px in on the diagonal, so the icon is 44x44 with texcoords 0.06-0.94: same on-screen scale as the
    -- 50px masked icon, corners hidden under the frame, and the stock 1.12 icons lose their own bevel.
    card.iconFrame = CreateFrame("Frame", nil, card)
    card.iconFrame:SetWidth(60)
    card.iconFrame:SetHeight(60)
    card.iconFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -18)
    card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
    card.icon:SetWidth(44)
    card.icon:SetHeight(44)
    card.icon:SetPoint("CENTER", card.iconFrame, "CENTER", 0, 0)
    card.iconBorder = artTexture(card.iconFrame, "OVERLAY", "icon_frame", 60, 60)
    card.iconBorder:SetPoint("CENTER", card.iconFrame, "CENTER", 0, 0)

    -- Label: GameFontHighlightLarge at TitleBar TOPLEFT +70,-18
    card.label = card:CreateFontString(nil, "OVERLAY")
    setFont(card.label, 16, true)
    card.label:SetPoint("TOPLEFT", card.ribbon, "TOPLEFT", 70, -18)
    card.label:SetJustifyH("LEFT")

    -- PlusMinus 20x20 at TOPLEFT 76,-49 (128-redbutton-plus / -minus)
    card.plusMinus = card:CreateTexture(nil, "OVERLAY")
    card.plusMinus:SetWidth(20)
    card.plusMinus:SetHeight(20)
    card.plusMinus:SetPoint("TOPLEFT", card, "TOPLEFT", 76, -49)

    -- Description: SystemFont_Shadow_Med1, width 400, at TitleBar BOTTOMLEFT +72 (+95 next to PlusMinus), -2
    card.desc = card:CreateFontString(nil, "OVERLAY")
    setFont(card.desc, DESC_FONT_SIZE, true)
    card.desc:SetWidth(DESC_W)
    card.desc:SetJustifyH("LEFT")
    card.desc:SetJustifyV("TOP")


    -- reward band, ours (the Legacy card has none): the retail achievement card's "Title: Jenkins" line, a darker
    -- strip across the card bottom with the text centred. The card grows by REWARD_H when it has one.
    card.rewardBg = card:CreateTexture(nil, "ARTWORK")
    if card.rewardBg.SetColorTexture then
        card.rewardBg:SetColorTexture(0, 0, 0, 0.35)   -- 1.14
    else
        card.rewardBg:SetTexture(0, 0, 0)              -- 1.12
        card.rewardBg:SetAlpha(0.35)
    end
    card.rewardBg:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", REWARD_INSET, REWARD_INSET)
    card.rewardBg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -REWARD_INSET, REWARD_INSET)
    card.rewardBg:SetHeight(REWARD_H)
    card.rewardText = card:CreateFontString(nil, "OVERLAY")
    setFont(card.rewardText, 13, true)
    card.rewardText:SetPoint("CENTER", card.rewardBg, "CENTER", 0, 0)

    -- ours, from the retail achievement card (AchievementTemplate, cata blizzard_achievementui.xml): the 66x64 shield
    -- UI-Achievement-Shields, left half = earned (gold with laurels), right half = not earned (grey), -NoPoints sheet
    -- for 0 point cards (AchievementShield_Saturate / _Desaturate). Points on the inner shield, the completion date
    -- (AchievementDateFont, orange) under it. Replaces the Legacy points icon and the top right date badge + check.
    card.shield = card:CreateTexture(nil, "OVERLAY")
    card.shield:SetWidth(66)
    card.shield:SetHeight(64)
    -- ours: the art's visible shield (rows 2-52 of 64) centred on the icon frame's centre (-18 - 30 = -48), 2 px further
    -- left than retail's -8
    card.shield:SetPoint("TOPRIGHT", card, "TOPRIGHT", SHIELD_X, -(48 - 27))
    -- a fixed centred box like retail's 42x16 points string; anchored per state in setupCard (SHIELD_FIELD)
    card.points = card:CreateFontString(nil, "OVERLAY")
    setFont(card.points, 15, true)
    card.points:SetWidth(42)
    card.points:SetHeight(16)
    card.points:SetJustifyH("CENTER")
    card.date = card:CreateFontString(nil, "OVERLAY")
    setFont(card.date, 12, true)
    setColor(card.date, DATE_COLOR)
    card.date:SetPoint("TOP", card.shield, "BOTTOM", 0, 4)
    -- ours: red cross on the shield's inner field when the card can no longer be earned (anchored in setupCard)
    card.redx = createRedX(card, 26, card)

    card.criteria = {}
    return card
end

local function descWidth(hasCriteria)
    return (CARD_W + SHIELD_X - 66) - DESC_GAP - (5 + (hasCriteria and 95 or 72))
end

local function descHeight(card)
    local lines = math.max(math.ceil(card.desc:GetStringWidth() / (card.descW or DESC_W)), 1)
    return lines * DESC_LINE_H
end

local function objectivesHeight(n)
    if n == 0 then return 0 end
    local rows = math.ceil(n / 2)
    return rows * CRIT_ROW_H + (rows - 1) * CRIT_GAP_Y
end

local function layoutCriteria(card, ch, show, top)
    local n = table.getn(ch.criteria)
    local cellW = (CARD_W - CRIT_GAP_X - 2 * CRIT_OFFSET_X) / 2
    for i = 1, n do
        local c = card.criteria[i]
        if not c then
            c = createCriterion(card)
            card.criteria[i] = c
        end
        if show then
            local crit = ch.criteria[i]
            local text, critDone, cur, max = crit[1], crit[2], crit[3], crit[4]
            local isBar = max ~= nil
            local row = math.floor((i - 1) / 2)
            local y = top - row * (CRIT_ROW_H + CRIT_GAP_Y)
            c:ClearAllPoints()
            if n == 1 and isBar then
                -- ours: a lone progress bar takes half the card, centred (Blizzard's spans the card)
                c:SetWidth(LONE_BAR_W)
                c:SetPoint("TOP", card, "TOP", 0, y)
            else
                c:SetWidth(cellW)
                if math.floor((i - 1) / 2) * 2 + 1 == i then
                    c:SetPoint("TOPLEFT", card, "TOPLEFT", CRIT_OFFSET_X, y)
                else
                    c:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CRIT_OFFSET_X, y)
                end
            end
            if isBar then
                c.bg:Hide()
                c.name:Hide()
                c.check:Hide()
                c.redx:Hide()
                c.barBg:Show()
                c.bar:Show()
                c.barText:SetText(cur .. " / " .. max)
                local w = (n == 1) and LONE_BAR_W or cellW
                setBarRatio(c.barFill, "bar_fill", w, cur / max)
            else
                c.bg:Show()
                c.name:Show()
                c.barBg:Hide()
                c.bar:Hide()
                c.name:SetText(text)
                setColor(c.name, critDone and WHITE_COLOR or GRAY_COLOR)
                if critDone then c.check:Show() else c.check:Hide() end
                c.redx.text = crit.missedReason
                if crit.missed and not critDone then c.redx:Show() else c.redx:Hide() end
            end
            c:Show()
        else
            c:Hide()
        end
    end
    for i = n + 1, table.getn(card.criteria) do
        card.criteria[i]:Hide()
    end
end

local function setupCard(card, ch)
    card.ch = ch
    local completed = ch.done == true
    local selected = LP.selectedChallenge == ch
    local expanded = selected
    -- RefreshStateArt: dimmed = not completed and not selected
    local dimmed = not completed and not selected
    local variant = completed and "" or "_off"
    local hasCriteria = table.getn(ch.criteria) > 0

    card.desc:ClearAllPoints()
    card.desc:SetPoint("TOPLEFT", card.ribbon, "BOTTOMLEFT", hasCriteria and 95 or 72, -2)
    card.descW = descWidth(hasCriteria)
    card.desc:SetWidth(card.descW)
    card.desc:SetText(ch.desc)

    local rewardH = ch.reward and (REWARD_H + 2) or 0
    if expanded and hasCriteria then
        local dh = descHeight(card)
        local objH = objectivesHeight(table.getn(ch.criteria))
        -- CalculateExpandedHeight: collapsed + objectives + description - ACHIEVEMENTBUTTON_DESCRIPTIONHEIGHT
        card:SetHeight(CARD_H + objH + dh - DESCRIPTIONHEIGHT + rewardH)
        layoutCriteria(card, ch, true, -(4 + 46 + 2 + dh) + CRIT_OFFSET_Y)
    else
        card:SetHeight(CARD_H + rewardH)
        layoutCriteria(card, ch, false, 0)
    end

    if ch.reward then
        card.rewardText:SetText(ch.reward)
        setColor(card.rewardText, dimmed and GRAY_COLOR or NORMAL_COLOR)
        card.rewardBg:Show()
        card.rewardText:Show()
    else
        card.rewardBg:Hide()
        card.rewardText:Hide()
    end

    -- ours: always the expanded (top / mid / bottom) art, so selecting a card doesn't swap its background; the single
    -- piece "card" art (Blizzard's collapsed look) stays unused
    card.bg:Hide()
    setArt(card.top, "card_top" .. variant)
    setArt(card.mid, "card_mid" .. variant)
    setArt(card.bottom, "card_bot" .. variant)
    card.top:Show()
    card.mid:Show()
    card.bottom:Show()
    setShown(card.selected, selected)

    -- GetTitleBarAtlas: blue = account wide. Ours are all per character: brown, disable variant until completed
    setArt(card.ribbon, "ribbon" .. variant)

    card.icon:SetTexture(ch.icon)
    card.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    setDesaturated(card.icon, dimmed)

    local color = dimmed and GRAY_COLOR or WHITE_COLOR
    setColor(card.label, color)
    setColor(card.desc, color)
    card.label:SetText(ch.name)

    if hasCriteria then
        setArt(card.plusMinus, expanded and "minus" or "plus")
        card.plusMinus:Show()
    else
        card.plusMinus:Hide()
    end

    -- earned: gold shield + white points + date; not earned: grey shield, greyed points, no date
    card.earned = completed
    local fx, fy = SHIELD_FIELD_EARNED[1], SHIELD_FIELD_EARNED[2]
    if not completed then fx, fy = SHIELD_FIELD_UNEARNED[1], SHIELD_FIELD_UNEARNED[2] end
    card.points:ClearAllPoints()
    card.points:SetPoint("CENTER", card.shield, "CENTER", fx + POINTS_NUDGE_X, fy + POINTS_NUDGE_Y)
    card.redx:ClearAllPoints()
    card.redx:SetPoint("CENTER", card.shield, "CENTER", fx, fy)
    card.redx.text = ch.missedReason
    if ch.missed and not completed then card.redx:Show() else card.redx:Hide() end
    card.shield:SetTexture(ART_PATH .. WHC_LegacyArt[ch.points > 0 and "shields" or "shields_nopoints"].file)
    if completed then
        card.shield:SetTexCoord(0, 0.5, 0, 0.5)
    else
        card.shield:SetTexCoord(0.5, 1, 0, 0.5)
    end
    if ch.points > 0 and not (ch.missed and not completed) then   -- a lost card shows the cross instead
        card.points:SetText(ch.points)
        setColor(card.points, completed and WHITE_COLOR or UNEARNED_POINTS_COLOR)
        card.points:Show()
    else
        card.points:Hide()
    end

    -- the completion date needs the server (phase 4)
    if completed and ch.date then
        card.date:SetText(ch.date)
        card.date:Show()
    else
        card.date:Hide()
    end


    card:SetScript("OnClick", function()
        if LP.selectedChallenge == ch then
            LP.selectedChallenge = nil
        else
            LP.selectedChallenge = ch
        end
        playSound(WHC.SOUNDS.checkBoxOn)
        LP.RefreshChallenges()
    end)
end

function LP.RefreshChallenges()
    if not LP.frame or not LP.scroll then return end
    -- the list runs up to the header line now, so the first card keeps the old 5 px gap inside the scroll child
    local y = -CARDS_TOP_PAD
    local i = 0
    for _, ch in ipairs(CHALLENGES) do
        if ch.cat == LP.cardsCategory and isVisibleChallenge(ch) then
            i = i + 1
            local card = LP.cards[i]
            if not card then
                card = createCard(LP.scrollChild)
                LP.cards[i] = card
            end
            setupCard(card, ch)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", LP.scrollChild, "TOPLEFT", 0, y)
            card.topY = y
            card:Show()
            y = y - card:GetHeight() - CARD_GAP
        end
    end
    for j = i + 1, table.getn(LP.cards) do
        LP.cards[j]:Hide()
    end

    LP.scrollChild:SetHeight(math.max(-y, 1))
    LP.detailBar.ScrollTo(LP.scroll:GetVerticalScroll())
    LP.UpdatePointSummary()
end

function LP.Refresh()
    if not LP.frame or not LP.scroll or not LP.categoryBar then return end
    LP.RefreshCategoryList()
    LP.RefreshChallenges()
end

-- [[ Server protocol ]] -- PLAN_LEGACY_CHALLENGES.md "Protocol" / "Phase 3 landed". The window asks with
-- `.whc challenges [target]` when it opens, `explore` on the first Exploration click, `taken` on the first Realm First
-- click. A command already sent for the same target within 30 s is not sent again (every chat line counts toward the
-- chat flood mute): the window keeps showing the last answer, kept per target.
local REQUEST_THROTTLE = 30
LP.sentAt = {}

local function classColoredName(name)
    local unit = unitOf(name)
    if not unit or not RAID_CLASS_COLORS then return name end
    local _, classFile = UnitClass(unit)
    local color = RAID_CLASS_COLORS[classFile or ""]
    if not color then return name end
    return string.format("|cff%02x%02x%02x%s|r", math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5),
        math.floor(color.b * 255 + 0.5), name)
end

local function sendChallengeCommand(sub, inspect)
    local who = inspect and (UnitName("target") or "?") or "0"
    local key = sub .. "|" .. who
    local now = GetTime()
    if LP.sentAt[key] and now - LP.sentAt[key] < REQUEST_THROTTLE then
        return false
    end
    LP.sentAt[key] = now
    local msg = ".whc challenges"
    if sub ~= "" then msg = msg .. " " .. sub end
    if inspect then msg = msg .. " target" end
    SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"))
    return true
end

-- whose achievements the window shows: nil / "0" = yourself, else the name
function LP.SetView(name)
    if name == "0" or name == "" then name = nil end
    LP.EnsureData()
    LP.viewKey = name or "0"
    if LP.titleText then
        LP.titleText:SetText(name and (classColoredName(name) .. "'s Achievements") or "Achievements")
    end
    computeAll()
    if LP.frame and LP.frame:IsShown() then
        LP.Refresh()
    end
end

-- kept for the old `::whc::achievement-target:` reply (`.whc achievements`): the window no longer asks with it
function LP.SetInspectTarget(name)
end

-- the window opens: show what is known at once, ask the server (inspect = the targeted player, 12 yd server side)
function LP.RequestOnOpen(inspect)
    LP.EnsureData()
    inspect = inspect and UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player")
    LP.inspecting = inspect and true or false
    LP.SetView(inspect and UnitName("target") or nil)
    sendChallengeCommand("", LP.inspecting)
end

local function rootName(catId)
    local cat = categoryById[catId]
    while cat and cat.parent ~= -1 do
        cat = categoryById[cat.parent]
    end
    return cat and cat.name
end

-- first click on Exploration (zone checklists) or Realm First (who already holds which)
function LP.OnCategorySelected(catId)
    local root = rootName(catId)
    if root == "Exploration" and not LP.exploreState[LP.viewKey or "0"] then
        sendChallengeCommand("explore", (LP.viewKey or "0") ~= "0")
    elseif root == "Realm First" and not LP.taken then
        sendChallengeCommand("taken", false)
    end
end

-- `::whc::ch:<name | 0>:<24 words>`
function LP.OnStateReply(name, hex)
    local words = parseWords(hex, WORDS)
    if not words then return end
    LP.EnsureData()
    local key = (name == "" or name == "0") and "0" or name
    LP.state[key] = words
    LP.SetView(key)
end

-- `::whc::ch-explore:<name | 0>:<area words>`
function LP.OnExploreReply(name, hex)
    LP.EnsureData()
    local n = math.ceil(LP.exploreCount / 32)
    local words = parseWords(hex, n)
    if not words then return end
    local key = (name == "" or name == "0") and "0" or name
    LP.exploreState[key] = words
    if key == (LP.viewKey or "0") then
        LP.SetView(key)
    end
end

-- `::whc::ch-taken:<ids, comma separated>`
function LP.OnTakenReply(list)
    LP.EnsureData()
    LP.taken = {}
    local start = 1
    while true do
        local s = string.find(list, ",", start, true)
        local id = tonumber(string.sub(list, start, s and s - 1 or nil))
        if id then LP.taken[id] = true end
        if not s then break end
        start = s + 1
    end
    LP.SetView(LP.viewKey)
end

local refreshOwnSoon                                             -- defined with redrawDriver below

-- `::whc::ch:<id>`: granted to you just now. Your words get the bit (the next open re-reads the counters), the
-- window refreshes if it shows you, a toast plays.
function LP.OnGranted(id)
    LP.EnsureData()
    LP.sentAt = {}                                               -- something changed: the next open asks again
    local words = LP.state["0"]
    if words then
        WHC.SetWordBit(words, id)
    end
    refreshOwnSoon()
    for _, ch in ipairs(CHALLENGES) do
        if ch.id == id and not ch.ach then
            LP.ShowToast(ch)
            return
        end
    end
end

-- recompute + redraw the window when it shows you, one frame later: a burst of changes (pushes, client events, the
-- Achievements tab replies) redraws once. Nothing is computed while the window is closed: opening it recomputes.
local redrawDriver = CreateFrame("Frame")
LP.redrawDriver = redrawDriver
redrawDriver:Hide()
redrawDriver:SetScript("OnUpdate", function()
    redrawDriver:Hide()
    if LP.dataBuilt and (LP.viewKey or "0") == "0" and LP.frame and LP.frame:IsShown() then
        computeAll()
        LP.Refresh()
    end
end)
refreshOwnSoon = function()
    if LP.frame and LP.frame:IsShown() then redrawDriver:Show() end
end

-- `::whc::ch-w:<word>:<hex>`: one of your progress words changed (quests, honorable kills, exalted mask, skills at
-- 300, critters / keys / races / fishing zones)
function LP.OnWordPush(word, hex)
    local words = LP.state["0"]
    local v = tonumber(hex, 16)
    if not words or not v or not word or word < 16 or word >= WORDS then return end
    words[word] = v
    refreshOwnSoon()
end

-- `::whc::ch-area:<index>`: an area of an exploration card was discovered (index in the explore reply order)
function LP.OnAreaPush(index)
    local ex = LP.exploreState["0"]
    if not ex or not index or index < 0 or index >= LP.exploreCount then return end
    WHC.SetWordBit(ex, index)
    refreshOwnSoon()
end

-- what the client reads itself (skill values, reputation bars, level) changes without any server line
local liveEvents = CreateFrame("Frame")
liveEvents:RegisterEvent("SKILL_LINES_CHANGED")
liveEvents:RegisterEvent("UPDATE_FACTION")
liveEvents:RegisterEvent("PLAYER_LEVEL_UP")
-- an honorable kill: the client's lifetime total moved (both events exist in the 1.12 WoW.exe and the 1.14
-- WowClassic.exe event tables)
liveEvents:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
liveEvents:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
liveEvents:SetScript("OnEvent", refreshOwnSoon)

-- `::whc::ch-feats:<n>`: reaching 60 secured n Feats of Strength, one toast for all of them
function LP.OnFeatsSecured(n)
    LP.EnsureData()
    local first
    for _, ch in ipairs(CHALLENGES) do
        if ch.ach then
            first = ch
            break
        end
    end
    if not first then return end
    LP.ShowToast({ name = n .. (n == 1 and " Feat of Strength secured" or " Feats of Strength secured"),
                   icon = first.icon, points = 0, cat = first.cat })
end

-- the Achievements tab frames still change on the old `::whc::achievement:<id>` replies (they only matter before the
-- first `.whc challenges` reply)
if WHC.ToggleAchievement then
    local toggleAchievement = WHC.ToggleAchievement
    WHC.ToggleAchievement = function(itemAch, failed)
        toggleAchievement(itemAch, failed)
        refreshOwnSoon()
    end
end

function LP.Toggle()
    LP.EnsureData()
    if not LP.frame then
        createWindow()
        LP.SelectCategory(LP.defaultCategory)
    end
    if LP.frame:IsShown() then
        LP.frame:Hide()
        PlaySoundFile(WHC.SOUND_FILES.achievementMenuClose)
    else
        computeAll()                                             -- the client reads (level, skills...) are live
        LP.RestoreWindowPosition()
        LP.frame:Show()
        LP.Refresh()
        PlaySoundFile(WHC.SOUND_FILES.achievementMenuOpen)
    end
end

-- the WOW-HC Achievements tab (and the character / inspect frame button) opens this window instead
function WHC.OpenLegacyChallenges()
    if LP.frame and LP.frame:IsShown() then
        LP.Refresh()
        return
    end
    LP.Toggle()
end

-- shows the child category under the root category, both by name (ids are generated from the def file), when the
-- window is open and the category has cards for this character
function WHC.SelectLegacyCategory(rootName, childName)
    LP.EnsureData()
    if not (LP.frame and LP.frame:IsShown()) then return end
    for id, cat in pairs(categoryById) do
        local parent = categoryById[cat.parent]
        if cat.name == childName and parent and parent.name == rootName and cat.own > 0 then
            LP.SelectCategory(id)
            return
        end
    end
end

-- toast click: open the window on the challenge's category with its card selected and scrolled into view; clears the
-- search and the Completed / Incomplete filter so the card can't be hidden
function LP.OpenToChallenge(ch)
    LP.EnsureData()
    -- toasts are your own challenges: view yourself and ask the server like every other open (before the first
    -- reply this session there are no words to hold the bit the toast just granted)
    if not (LP.frame and LP.frame:IsShown()) or (LP.viewKey or "0") ~= "0" then
        LP.RequestOnOpen(false)
    end
    if not (LP.frame and LP.frame:IsShown()) then
        LP.Toggle()
    end
    LP.showCompleted, LP.showIncomplete = true, true
    if LP.searchBox and LP.searchText ~= "" then
        LP.searchBox:SetText("")                                 -- OnTextChanged resets LP.searchText
        LP.searchText = ""
    end
    LP.SelectCategory(ch.cat)
    LP.selectedChallenge = ch
    LP.RefreshChallenges()
    for i, card in ipairs(LP.cards) do
        if card:IsShown() and card.ch == ch then
            LP.detailBar.ScrollTo(-card.topY - CARDS_TOP_PAD)
            return
        end
    end
end

-- [[ Completion toast ]] -- AchievementAlertFrameTemplate: 300x101 at BOTTOM 0,128

local TOAST_FADE_IN, TOAST_HOLD, TOAST_FADE_OUT = 0.2, 4.05, 1.5

-- Blizzard AchievementAlertSystem = AddQueuedAlertFrameSubSystem(..., 2, 6) (alertframesystems.lua:418): at most
-- TOAST_MAX_VISIBLE toasts at once, stacked upwards from the anchor, TOAST_MAX_QUEUE more waiting, the rest dropped
local TOAST_MAX_VISIBLE, TOAST_MAX_QUEUE, TOAST_SPACING = 2, 6, 10
LP.toasts = {}                                                   -- the frames (one per visible slot)
LP.toastVisible = {}                                             -- the showing ones, oldest first (bottom)
LP.toastQueue = {}

local finishToast

local function createToast(index)
    local t = CreateFrame("Button", "WHCLegacyToast" .. index, UIParent)
    t.busy = false
    t:SetWidth(300)
    t:SetHeight(101)
    t:SetFrameStrata("DIALOG")
    t:Hide()

    t.bg = artTexture(t, "BACKGROUND", "toast_bg")
    t.bg:SetPoint("CENTER", t, "CENTER", 0, 0)

    -- Unlocked: GameFontBlackTiny = SystemFont_Tiny (FRIZQT 9), black, NO shadow (a shadowed small font blurs on the
    -- gold banner)
    t.unlocked = t:CreateFontString(nil, "ARTWORK")
    setFont(t.unlocked, 9)
    t.unlocked:SetShadowOffset(0, 0)
    t.unlocked:SetShadowColor(0, 0, 0, 0)
    t.unlocked:SetWidth(200)
    t.unlocked:SetHeight(12)
    t.unlocked:SetPoint("TOP", t, "TOP", 7, -23)
    t.unlocked:SetTextColor(0, 0, 0)
    t.unlocked:SetText("Achievement Earned")

    t.name = t:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    t.name:SetWidth(155)
    t.name:SetHeight(36)
    t.name:SetPoint("TOP", t.unlocked, "BOTTOM", 0, 0)

    t.iconHolder = CreateFrame("Frame", nil, t)
    t.iconHolder:SetWidth(78)
    t.iconHolder:SetHeight(75)
    t.iconHolder:SetPoint("TOPLEFT", t, "TOPLEFT", -4, -15)
    t.icon = t.iconHolder:CreateTexture(nil, "ARTWORK")
    t.icon:SetWidth(52)
    t.icon:SetHeight(52)
    t.icon:SetPoint("CENTER", t.iconHolder, "CENTER", 0, 0)
    t.iconBorder = artTexture(t.iconHolder, "OVERLAY", "toast_iconframe")
    t.iconBorder:SetPoint("CENTER", t.iconHolder, "CENTER", -1, 1)

    t.shieldHolder = CreateFrame("Frame", nil, t)
    t.shieldHolder:SetWidth(64)
    t.shieldHolder:SetHeight(64)
    t.shieldHolder:SetPoint("TOPRIGHT", t, "TOPRIGHT", -8, -15)
    t.shield = artTexture(t.shieldHolder, "BACKGROUND", "toast_shield")
    t.shield:SetPoint("TOPRIGHT", t.shieldHolder, "TOPRIGHT", 1, -6)
    t.points = t.shieldHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.points:SetPoint("CENTER", t.shieldHolder, "CENTER", 1.5, -2)   -- measured on screen: centred on the dark field

    t.glow = artTexture(t, "OVERLAY", "toast_glow")
    t.glow:SetPoint("CENTER", t, "CENTER", 0, 0)
    t.glow:SetBlendMode("ADD")
    t.shine = artTexture(t, "OVERLAY", "toast_shine")
    t.shine:SetBlendMode("ADD")

    -- click: open the window on that challenge (Blizzard's toast opens the achievement frame to it)
    t:SetScript("OnClick", function()
        local ch = t.ch
        finishToast(t)
        if ch then LP.OpenToChallenge(ch) end
    end)

    t:SetScript("OnUpdate", function(_, elapsed)
        elapsed = elapsed or arg1
        t.elapsed = t.elapsed + elapsed
        local e = t.elapsed

        if e < TOAST_FADE_IN then
            t:SetAlpha(e / TOAST_FADE_IN)
        elseif e < TOAST_FADE_IN + TOAST_HOLD then
            t:SetAlpha(1)
        elseif e < TOAST_FADE_IN + TOAST_HOLD + TOAST_FADE_OUT then
            t:SetAlpha(1 - (e - TOAST_FADE_IN - TOAST_HOLD) / TOAST_FADE_OUT)
        else
            finishToast(t)
            return
        end

        -- glow: 0.2s in, 0.5s out
        if e < 0.2 then
            t.glow:Show()
            t.glow:SetAlpha(e / 0.2)
        elseif e < 0.7 then
            t.glow:SetAlpha(1 - (e - 0.2) / 0.5)
        else
            t.glow:Hide()
        end

        -- shine: fades in, slides 240 px over 0.85s, fades out from 0.55s
        if e < 1.05 then
            t.shine:Show()
            local slide = 0
            if e > 0.2 then slide = math.min((e - 0.2) / 0.85, 1) * 240 end
            t.shine:ClearAllPoints()
            t.shine:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", slide, 8)
            if e < 0.2 then
                t.shine:SetAlpha(e / 0.2)
            elseif e < 0.55 then
                t.shine:SetAlpha(1)
            else
                t.shine:SetAlpha(math.max(1 - (e - 0.55) / 0.5, 0))
            end
        else
            t.shine:Hide()
        end
    end)

    return t
end

-- oldest at the bottom (the anchor), each next one above it; re-run whenever one comes or goes so the rest slide down
local function anchorToasts()
    for i, t in ipairs(LP.toastVisible) do
        t:ClearAllPoints()
        if i == 1 then
            t:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 128)
        else
            t:SetPoint("BOTTOM", LP.toastVisible[i - 1], "TOP", 0, TOAST_SPACING)
        end
    end
end

local function freeToastFrame()
    for i = 1, TOAST_MAX_VISIBLE do
        local t = LP.toasts[i]
        if not t then
            t = createToast(i)
            LP.toasts[i] = t
        end
        if not t.busy then return t end
    end
    return nil
end

-- withSound: only the first toast of a burst; the second one shown beside it and the queued ones are silent
local function playToast(t, ch, withSound)
    t.busy = true
    t.ch = ch
    t.name:SetText(ch.name)
    t.icon:SetTexture(ch.icon)
    if ch.points and ch.points > 0 then
        t.points:SetText(ch.points)
        t.shield:Show()
        t.points:Show()
    else
        t.shield:Hide()
        t.points:Hide()
    end
    t.elapsed = 0
    t:SetAlpha(0)
    table.insert(LP.toastVisible, t)
    anchorToasts()
    t:Show()
    if not withSound then return end
    PlaySoundFile(WHC.SOUND_FILES.achievementEarned)
end

-- a toast is done (faded out or clicked): free its slot, let the others slide down, show the next queued one
finishToast = function(t)
    if not t.busy then return end
    t.busy = false
    t.ch = nil
    t:Hide()
    for i = table.getn(LP.toastVisible), 1, -1 do
        if LP.toastVisible[i] == t then table.remove(LP.toastVisible, i) end
    end
    anchorToasts()
    local nextCh = table.remove(LP.toastQueue, 1)
    if nextCh then
        playToast(t, nextCh, false)
    end
end

-- force: the /whctoast test ignores the "achievement notifications" setting
function LP.ShowToast(ch, force)
    if not force and WhcAddonSettings and WhcAddonSettings.achievementToast == 0 then
        return
    end
    local t = freeToastFrame()
    if t then
        playToast(t, ch, table.getn(LP.toastVisible) == 0)
    elseif table.getn(LP.toastQueue) < TOAST_MAX_QUEUE then
        table.insert(LP.toastQueue, ch)
    end
end

SLASH_WHCLEGACY1 = "/whclegacy"
SlashCmdList["WHCLEGACY"] = function(msg)
    if msg == "debug" then
        LP.EnsureData()
        DEFAULT_CHAT_FRAME:AddMessage("WHC achievements: faction " .. tostring(LP.faction) .. " from " .. tostring(LP.factionSource))
        for _, c in ipairs(WHC_LegacyCategories) do
            local cat = categoryById[c.id]
            DEFAULT_CHAT_FRAME:AddMessage("  " .. c.id .. " " .. c.name .. ": " .. (cat and cat.own or 0) .. " cards")
        end
        return
    end
    if not (LP.frame and LP.frame:IsShown()) then
        LP.RequestOnOpen(false)
    end
    LP.Toggle()
end

SLASH_WHCTOAST1 = "/whctoast"
SlashCmdList["WHCTOAST"] = function(msg)
    LP.EnsureData()
    -- /whctoast [n]: n toasts (default 3) from the default category (Leveling), 2 show stacked, up to 6 wait, rest dropped
    local want = tonumber(msg or "") or 3
    local n = 0
    for _, ch in ipairs(CHALLENGES) do
        if ch.cat == LP.defaultCategory and n < want then
            LP.ShowToast(ch, true)
            n = n + 1
        end
    end
end
