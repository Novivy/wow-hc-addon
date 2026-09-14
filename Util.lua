SLASH_ReloadUI1 = "/reloadui"
SLASH_ReloadUI2 = "/reload"
SlashCmdList["ReloadUI"] = function(msg, editbox)
    ConsoleExec("reloadui")
end

local _G = getfenv(0);
function WHC.HookSecureFunc(arg1, arg2, arg3)
    if type(arg1) == "string" then
        arg1, arg2, arg3 = _G, arg1, arg2
    end
    local orig = arg1[arg2]
    arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
    end
end

function WHC.GetItemIDFromLink(itemLink)
    if not itemLink then
        return
    end

    local foundID, _ , itemID = string.find(itemLink, "item:(%d+)")
    if not foundID then
        return
    end

    return tonumber(itemID)
end

function WHC.GetNpcID(unit)
    if UnitGUID then
        local guid = UnitGUID(unit) -- Only possible on 1.14
        if not guid then return nil end

        local _, _, _, _, _, npcID = string.split("-", guid)
        return tonumber(npcID)
    end

    if WHC.client.isSuperWow then
        local _, guid = UnitExists(unit) -- Superwow guid
        if not guid then return nil end

        local npcIDHex = string.sub(guid, 9, 12)
        return tonumber(npcIDHex, 16)
    end

    return nil
end

function WHC.Modulus(x, y)
    if WHC.client.is1_12 then
        return math.mod(x, y)
    end

    return math.fmod(x, y)
end

function WHC.SecondsToClock(seconds)
    if seconds < 0 then
        seconds = 0
    end

    local hours = string.format("%01d", math.floor(seconds/3600))
    local mins = string.format("%02d", math.floor(WHC.Modulus(seconds, 3600) / 60))
    local secs = string.format("%02d", math.floor(WHC.Modulus(WHC.Modulus(seconds, 3600), 60)))
    return hours..":"..mins..":"..secs
end

function WHC.IsInDungeon()
    local _, instanceType = IsInInstance()
    return instanceType == "party"
end

function WHC.IsInBattleground()
    local _, instanceType = IsInInstance()
    return instanceType == "pvp"
end

-- Function to print debug messages
function WHC.DebugPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
end

-- Function to print table key values
function WHC.DebugDump(o)
    if type(o) == 'table' then
        local s = '{ '
        local idx = 0
        for k,v in pairs(o) do
            local key = k
            if type(k) ~= 'number' then
                key = '"'..key..'"'
            end

            if idx > 0 then
                s = s .. ', '
            end
            s = s .. '['..key..'] = ' .. WHC.DebugDump(v)
            idx = idx + 1
        end
        return s .. '} '
    end

    return tostring(o)
end

-- Print message when the addon is loaded
-- WHC.DebugPrint("ReleaseSpiritMod loaded.")

-- ChatFrame_AddMessageEventFilter(evt,myChatFilter)


-- UIframe:RegisterEvent("CHAT_MSG")

-- UIframe:RegisterEvent("CHAT_MSG_GUILD")


-- ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", myChatFilter)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", myChatFilter)

-- local frame=CreateFrame("Frame");-- Need a frame to capture events
-- frame:RegisterEvent("CHAT_MSG_SAY");-- Register our event

-- frame:SetScript("OnEvent",function(self,event,msg)-- OnEvent handler receives event triggers
--   	print("scr---")
--   	print(self)
--   	print(event)
--    	print(msg)
-- end);
--







-- ---------------------------------------------------------------------------
-- Server lines the addon replaces with its own UI. Features register distinctive
-- snippets of the plain-text lines the server keeps sending for players without the
-- addon; Events.lua drops matching chat lines and the UIErrorsFrame wrapper below drops
-- matching on-screen notifications (SendNotification).
local hiddenServerLines = {}
function WHC.HideServerLines(snippets)
    for _, snippet in ipairs(snippets) do
        table.insert(hiddenServerLines, snippet)
    end
end

function WHC.IsHiddenServerLine(text)
    if not text then
        return false
    end
    for _, snippet in ipairs(hiddenServerLines) do
        if string.find(text, snippet, 1, true) then
            return true
        end
    end
    return false
end

local origUIErrorsAddMessage = UIErrorsFrame.AddMessage
UIErrorsFrame.AddMessage = function(frame, text, r, g, b, a, holdTime)
    if WHC.IsHiddenServerLine(text) then
        return
    end
    return origUIErrorsAddMessage(frame, text, r, g, b, a, holdTime)
end

-- Red [WHC]: chat line plus the same text on screen (bypasses the filter above)
function WHC.Announce(msg)
    DEFAULT_CHAT_FRAME:AddMessage(WHC.ADDON_PREFIX .. RED_FONT_COLOR_CODE .. msg .. FONT_COLOR_CODE_CLOSE)
    origUIErrorsAddMessage(UIErrorsFrame, msg, 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
end

-- ---------------------------------------------------------------------------
-- Side tab hanging off the right border of a frame (guild bank tabs, talent specs):
-- a 42x50 flange with an icon button. Returns the button; button.frame is the flange
-- (anchor it), button.icon / .hover / .checked the textures. No pushed/highlight textures
-- on purpose: a drag released off-button never delivers the mouse-up and the visual
-- sticks, so hover is driven from OnEnter/OnLeave by the caller.
-- Art: WHC.SIDE_TAB_GUILDBANK (red flange, the default) or WHC.SIDE_TAB_GREY (Blizzard's
-- spellbook side tab, 64x64 art drawn at -3/+11 around a 32x32 button).
WHC.SIDE_TAB_GUILDBANK = { texture = "Interface\\AddOns\\WOW_HC\\Images\\guildbank\\ui-guildbankframe-tab", x = 2, y = -8, width = 36, height = 34 }
WHC.SIDE_TAB_GREY = { texture = "Interface\\SpellBook\\SpellBook-SkillLineTab", x = 3, y = -11, width = 32, height = 32 }
function WHC.CreateSideTab(name, parent, art)
    art = art or WHC.SIDE_TAB_GUILDBANK
    local tab = CreateFrame("Frame", name, parent)
    tab:SetWidth(42); tab:SetHeight(50)
    local bg = tab:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(art.texture)
    bg:SetWidth(64); bg:SetHeight(64)
    bg:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)

    local button = CreateFrame("Button", name .. "Button", tab)
    button:SetWidth(art.width); button:SetHeight(art.height)
    button:SetPoint("TOPLEFT", tab, "TOPLEFT", art.x, art.y)
    button.frame = tab
    button.icon = button:CreateTexture(nil, "BORDER")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    button.hover = button:CreateTexture(nil, "OVERLAY")
    button.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    button.hover:SetBlendMode("ADD")
    button.hover:SetAllPoints(button)
    button.hover:Hide()
    button.checked = button:CreateTexture(nil, "OVERLAY")
    button.checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    button.checked:SetBlendMode("ADD")
    button.checked:SetAllPoints(button)
    button.checked:Hide()
    return button
end
