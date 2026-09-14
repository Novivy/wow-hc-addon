-- Mak'gora (duel to the death) UI. Replaces the typed ".makgora" flow with a "Mak'gora"
-- entry in the right-click menu of a player and, on both sides, a confirmation popup that
-- requires typing I AGREE. Once both agreed the server starts the duel itself (see
-- HandleMakgoraCommand), the addon only closes the now stale native duel popup.
-- The server keeps sending its plain-text lines for players without the addon; we hide
-- those (WHC.HideServerLines) and render our own UI from the
-- "::whc::makgora:<kind>:<name>" lines:
--   challenge:<name>  we were challenged by <name>
--   sent:<name>       our challenge to <name> is out
--   error:<text>      request refused (duel pending, cooldown...)
--   accepted:<name>:<state>  <name> accepted our challenge
--   agreed:<name>:<state>    we accepted <name>'s challenge
-- state: 1 = countdown running, 0 = too far apart, /duel by hand.
-- Commands go out as ".whc makgora <name>" because the
-- 1.14 client protects every targeting function, so the addon cannot select the challenger.
-- The menu entry is registered through UnitPopup.lua.
local M = {}
WHC.Makgora = M

local MENU_VALUE = "WHC_MAKGORA"
local AGREE_TEXT = "I AGREE"

-- Distinctive snippets of the server's plain-text Mak'gora lines (chat and notification)
WHC.HideServerLines({
    "has challenged you in a Mak'gora duel",
    "to a Mak'gora duel to the death",
    "has accepted your Mak'gora request",
    "Mak'gora request accepted",
    "Cannot initiate a Mak'gora",
    "between each Mak'gora request",
})

local function Send(name)
    SendChatMessage(".whc makgora " .. name, "WHISPER", GetDefaultLanguage(), UnitName("player"))
end

-- Accept button of an I AGREE popup is only enabled once the box reads I AGREE
local function UpdateAcceptButton(editBox)
    local dialog = editBox:GetParent()
    local accept = getglobal(dialog:GetName() .. "Button1")
    if string.upper(editBox:GetText()) == AGREE_TEXT then
        accept:Enable()
    else
        accept:Disable()
    end
end

-- Popup with an edit box that has to read I AGREE before the first button works. `onAgree`
-- receives the name the popup was shown with. 1.12 calls the handlers with the global `this`
-- (OnAccept with the clicked button, not the dialog), 1.14 passes `self`.
local function AgreeDialog(text, button1, button2, onAgree)
    local shownFor
    local function Agree(frame)
        local dialog = frame.which and frame or frame:GetParent()
        local editBox = getglobal(dialog:GetName() .. "EditBox")
        if string.upper(editBox:GetText()) ~= AGREE_TEXT or not shownFor then
            return
        end
        local name = shownFor
        shownFor = nil
        onAgree(name)
    end

    local dialog = {
        -- leading blank line: a bit of air between the frame border and the first line
        text = "\n" .. text .. "\n\nType " .. RED_FONT_COLOR_CODE .. AGREE_TEXT .. FONT_COLOR_CODE_CLOSE .. " to confirm.",
        button1 = button1,
        button2 = button2,
        hasEditBox = 1,
        maxLetters = string.len(AGREE_TEXT),
        OnShow = function(self)
            self = self or this
            local editBox = getglobal(self:GetName() .. "EditBox")
            editBox:SetText("")
            editBox:SetFocus()
            UpdateAcceptButton(editBox)
        end,
        OnAccept = function(self)
            Agree(self or this)
        end,
        OnCancel = function()
            shownFor = nil
        end,
        EditBoxOnTextChanged = function(self)
            UpdateAcceptButton(self or this)
        end,
        EditBoxOnEnterPressed = function(self)
            self = self or this
            if string.upper(self:GetText()) == AGREE_TEXT then
                StaticPopup_OnClick(self:GetParent(), 1)
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self = self or this
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    }

    -- returns the dialog spec and a show(name) function that remembers the name
    return dialog, function(name)
        shownFor = name
        return name
    end
end

local showChallenged
StaticPopupDialogs["WHC_MAKGORA_CHALLENGED"], showChallenged = AgreeDialog(
    RED_FONT_COLOR_CODE .. "%s has challenged you to a Mak'gora." .. FONT_COLOR_CODE_CLOSE
        .. "\n\nThis is a duel to the DEATH. The loser dies for good, and fleeing the duel counts as a loss.",
    "Accept", "Decline", Send)

local showChallenge
StaticPopupDialogs["WHC_MAKGORA_CHALLENGE"], showChallenge = AgreeDialog(
    "Challenge %s to a Mak'gora?\n\n" .. RED_FONT_COLOR_CODE
        .. "This is a duel to the DEATH. If you lose or flee, your character dies for good." .. FONT_COLOR_CODE_CLOSE,
    "Challenge", CANCEL or "Cancel", Send)

-- Both agreed but the duel could not be started automatically: tell them what to do
StaticPopupDialogs["WHC_MAKGORA_DUEL"] = {
    text = "%s",
    button1 = OKAY or "Okay",
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function HideChallengePopup()
    StaticPopup_Hide("WHC_MAKGORA_CHALLENGED")
end

function M.Challenge(name)
    if not name or name == "" or name == UnitName("player") then
        return
    end
    StaticPopup_Show("WHC_MAKGORA_CHALLENGE", showChallenge(name))
end

-- state (accepted/agreed): 1 = countdown running, 0 = too far apart for the duel spell
local function OnBothAgreed(name, state, headline)
    HideChallengePopup()
    WHC.Announce(headline)
    if state == 1 then
        -- the server confirmed the duel for us, the native "accept duel" popup is stale
        StaticPopup_Hide("DUEL_REQUESTED")
        return
    end
    StaticPopup_Show("WHC_MAKGORA_DUEL", RED_FONT_COLOR_CODE .. headline .. FONT_COLOR_CODE_CLOSE
        .. "\n\nMove within 30 yards of " .. name .. " and type /duel to fight to the death.")
end

function M.OnServerMessage(kind, name, state)
    state = tonumber(state) or 0
    if kind == "challenge" then
        StaticPopup_Show("WHC_MAKGORA_CHALLENGED", showChallenged(name))
        PlaySound(WHC.SOUNDS.playerInvite)
    elseif kind == "error" then
        -- name carries the message here; nothing to confirm, the request was refused
        WHC.Announce(name)
    elseif kind == "sent" then
        WHC.Announce("You have challenged " .. name .. " to a Mak'gora. Waiting for their answer.")
    elseif kind == "accepted" then
        OnBothAgreed(name, state, name .. " has accepted your Mak'gora." .. (state == 1 and " The Mak'gora begins!" or ""))
    elseif kind == "agreed" then
        OnBothAgreed(name, state, "You have accepted " .. name .. "'s Mak'gora." .. (state == 1 and " The Mak'gora begins!" or ""))
    end
end

function WHC.InitializeMakgora()
    -- Right-click menu entry on players; dist 3 = the duel interact distance (~10 yd), the
    -- entry greys out like "Duel" does
    WHC.UnitPopup.AddButton(MENU_VALUE, {
        text = "Mak'gora",
        dist = 3,
        menus = { "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" },
        onClick = function(unit, name) M.Challenge(name) end,
    })
end
