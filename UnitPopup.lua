-- Extra entries in the right-click menu of a player (target frame, party/raid frames).
-- Every WHC entry goes through this registry: one place inserts them into Blizzard's
-- UnitPopupMenus tables, one post-hook on UnitPopup_HideButtons decides if they show, one
-- post-hook on UnitPopup_OnClick dispatches the click. Post-hooks only: replacing
-- UnitPopup_OnClick would taint the whole menu on 1.14 and get Blizzard's protected
-- actions (Set Focus, Duel, Follow) blocked. Entries are always inserted after DUEL so the
-- taint our values carry on 1.14 only reaches what follows them (nothing protected there).
--
-- Cross-faction: Blizzard hides Whisper/Invite/Trade/Follow/Duel (and Inspect) when
-- UnitCanCooperate is false, but this server allows all of it (AllowTwoSide.*). We add our
-- own copies for opposite-faction players, calling the same client APIs, except Duel
-- which goes through ".whc duel <name>" (the client refuses to cast the Duel spell on a
-- non-cooperable target). Trade and Follow are 1.12 only: that client trades with and
-- follows an opposite-faction player natively, while the 1.14 client protects FollowUnit
-- and cancels any trade window with a non-cooperable partner itself (even one the partner
-- proposed). No Inspect: both clients keep the gear of a non-cooperable player hidden from
-- the inspect frame even when the server answers the inspect request.
-- 1.12 opens the PLAYER menu for any
-- player; 1.14 opens ENEMY_PLAYER (move frames / report / cancel) for a non-cooperable
-- one, so every entry is also registered there (that menu does not exist on 1.12).
local UP = {}
WHC.UnitPopup = UP

local hook = hooksecurefunc or WHC.HookSecureFunc

-- value -> { onClick = function(unit, name), isShown = function(unit, name) or nil }
local buttons = {}

-- Our entries sit right after `after` (at the top when the menu has no such entry) and
-- after any WHC_ entry already there, so the order of registration is the order in the
-- menu. Skips menus a client does not have.
local function InsertMenuButton(which, after, value)
    local menu = UnitPopupMenus[which]
    if not menu then
        return
    end
    local position = 1
    for index, entry in ipairs(menu) do
        if entry == value then
            return
        end
        if entry == after then
            position = index + 1
        end
    end
    while menu[position] and string.find(menu[position], "^WHC_") do
        position = position + 1
    end
    table.insert(menu, position, value)
end

-- opts: text, dist (CheckInteractDistance index, 0 = none), menus (list of menu keys),
-- after (entry to insert behind), onClick(unit, name), isShown(unit, name) (nil = always)
function UP.AddButton(value, opts)
    UnitPopupButtons[value] = { text = opts.text, dist = opts.dist or 0 }
    for _, which in ipairs(opts.menus) do
        InsertMenuButton(which, opts.after or "DUEL", value)
    end
    buttons[value] = { onClick = opts.onClick, isShown = opts.isShown }
end

-- 1.12: UIDROPDOWNMENU_INIT_MENU is a frame name, 1.14: the frame
local function GetMenuFrame()
    local menu = UIDROPDOWNMENU_INIT_MENU
    if type(menu) == "string" then
        menu = getglobal(menu)
    end
    return menu
end

local function GetUnitAndName(menu)
    local unit = menu and menu.unit
    local name = menu and (menu.name or (unit and UnitName(unit)))
    return unit, name
end

local function IsOppositeFactionPlayer(unit)
    return unit and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitCanCooperate("player", unit)
end

local function SendWhc(cmd, name)
    SendChatMessage(".whc " .. cmd .. " " .. name, "WHISPER", GetDefaultLanguage(), UnitName("player"))
end

function WHC.InitializeUnitPopup()
    -- Cross-faction copies of the Blizzard entries, same text/distance as the originals
    local crossFaction = {
        { value = "WHC_WHISPER", copy = "WHISPER", menus = { "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" },
          onClick = function(unit, name) ChatFrame_SendTell(name) end },
        { value = "WHC_INVITE", copy = "INVITE", menus = { "PLAYER", "ENEMY_PLAYER" },
          onClick = function(unit, name)
              if InviteUnit then InviteUnit(name) else InviteByName(name) end
          end },
        { value = "WHC_TRADE", copy = "TRADE", menus = { "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" },
          onClick = function(unit, name) InitiateTrade(unit) end,
          only1_12 = true },
        { value = "WHC_FOLLOW", copy = "FOLLOW", menus = { "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" },
          onClick = function(unit, name) FollowUnit(unit) end,
          only1_12 = true },
        { value = "WHC_DUEL", copy = "DUEL", menus = { "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" },
          onClick = function(unit, name) SendWhc("duel", name) end },
    }
    for _, entry in ipairs(crossFaction) do
        local original = UnitPopupButtons[entry.copy]
        if original and not (entry.only1_12 and not WHC.client.is1_12) then
            UP.AddButton(entry.value, {
                text = original.text,
                dist = original.dist,
                menus = entry.menus,
                onClick = entry.onClick,
                isShown = IsOppositeFactionPlayer,
            })
        end
    end

    -- 1.12 keeps one flat UnitPopupShown[index], 1.14 nests it per menu level
    hook("UnitPopup_HideButtons", function()
        local menu = GetMenuFrame()
        if not menu or not menu.which then
            return
        end
        local entries = UnitPopupMenus[UIDROPDOWNMENU_MENU_VALUE] or UnitPopupMenus[menu.which]
        if not entries then
            return
        end
        local shown = UnitPopupShown
        if type(shown[1]) == "table" then
            shown = shown[UIDROPDOWNMENU_MENU_LEVEL or 1]
        end
        local unit, name = GetUnitAndName(menu)
        for index, value in ipairs(entries) do
            local button = buttons[value]
            if button and button.isShown then
                shown[index] = button.isShown(unit, name) and 1 or 0
            end
        end
    end)

    -- 1.12 calls UnitPopup_OnClick() with `this`, 1.14 UnitPopup_OnClick(self)
    hook("UnitPopup_OnClick", function(self)
        local clicked = self or this
        local button = clicked and buttons[clicked.value]
        if not button then
            return
        end
        local unit, name = GetUnitAndName(GetMenuFrame())
        if name then
            button.onClick(unit, name)
        end
    end)
end
