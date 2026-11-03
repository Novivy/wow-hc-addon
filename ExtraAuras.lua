-- 1.14 only. The server lists the player's own auras that got no 1.12 aura slot (31 buffs / 16 debuffs
-- full) and HermesProxy shows them in 1.14 aura slots 48+, so UnitAura returns more auras than the
-- default buff frame draws (BUFF_MAX_DISPLAY 32, DEBUFF_MAX_DISPLAY 16 in FrameXML\BuffFrame.lua).
-- After every BuffFrame_Update, draw the rest with Blizzard's own AuraButton_Update (same template,
-- timer, tooltip, right click). Blizzard's globals, its first 32 / 16 buttons and DebuffButton1.offsetY
-- are never written here, so the secure buff frame code stays untainted.
-- Must stay Lua 5.0 parseable (the 1.12 client loads this file too): no % and no # operators.
if RETAIL ~= 1 or not hooksecurefunc or not UnitAura or not AuraButton_Update or not BuffFrame_Update then
    return
end

local EXTRA_BUFF_LAST = 80   -- BuffButton33 .. BuffButton80
local EXTRA_DEBUFF_LAST = 40 -- DebuffButton17 .. DebuffButton40

local function UpdateExtraAuras()
    -- Buffs past the 32 Blizzard draws, on the same grid (rows of BUFFS_PER_ROW, right to left)
    local extraBuffs = 0
    local i = BUFF_MAX_DISPLAY + 1
    while i <= EXTRA_BUFF_LAST do
        if AuraButton_Update("BuffButton", i, "HELPFUL") then
            extraBuffs = extraBuffs + 1
            local buff = _G["BuffButton" .. i]
            buff:ClearAllPoints()
            if mod(i + BuffFrame.numEnchants, BUFFS_PER_ROW) == 1 then
                -- new row: under the button one row up, same column (as BuffFrame_UpdateAllBuffAnchors)
                buff:SetPoint("TOPRIGHT", _G["BuffButton" .. (i - BUFFS_PER_ROW)], "BOTTOMRIGHT", 0, -BUFF_ROW_SPACING)
            else
                buff:SetPoint("RIGHT", _G["BuffButton" .. (i - 1)], "LEFT", BUFF_HORIZ_SPACING, 0)
            end
        elseif not _G["BuffButton" .. i] then
            break -- buttons are created in order: nothing shown or left to hide past this one
        end
        i = i + 1
    end

    -- Push the debuffs below the extra buff rows (Blizzard places them under its own rows only)
    if extraBuffs > 0 and DebuffButton1 and DEBUFF_ACTUAL_DISPLAY > 0 then
        local rows = ceil((BUFF_ACTUAL_DISPLAY + extraBuffs + BuffFrame.numEnchants) / BUFFS_PER_ROW)
        DebuffButton1:ClearAllPoints()
        DebuffButton1:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -rows * (BUFF_ROW_SPACING + BUFF_BUTTON_HEIGHT))
    end

    -- Debuffs past the 16 Blizzard draws; AuraButton_Update anchors them itself (DebuffButton_UpdateAnchors)
    i = DEBUFF_MAX_DISPLAY + 1
    while i <= EXTRA_DEBUFF_LAST do
        if not AuraButton_Update("DebuffButton", i, "HARMFUL") and not _G["DebuffButton" .. i] then
            break
        end
        i = i + 1
    end
end

hooksecurefunc("BuffFrame_Update", UpdateExtraAuras)
