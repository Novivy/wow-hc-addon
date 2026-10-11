local function addDeathPopupAppealButton()
    local deathOverride = function (data, reason)
        if (reason == "override") then
            return
        end
        if (reason == "timeout") then
            return
        end

        -- Back returns to the death popup
        WHC.ShowUrlPopup("Copy and paste the following URL to your browser to appeal", "https://wow-hc.com/appeal", function()
            StaticPopup_Show("DEATH")
        end)
    end

    if (RETAIL == 1) then
        StaticPopupDialogs["DEATH"].OnButton2 = deathOverride
    else
        StaticPopupDialogs["DEATH"].OnCancel = deathOverride
    end
    StaticPopupDialogs["DEATH"].DisplayButton2 = function() return true end
end

local function updateDeathPopupText()
    local mapChangeEventHandler = CreateFrame("Frame")
    mapChangeEventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
    mapChangeEventHandler:SetScript("OnEvent", function(self, event)
        if (WHC.IsInBattleground()) then
            DEATH_RELEASE = "Release Spirit";
            StaticPopupDialogs["DEATH"].text = "YOU DIED";
            StaticPopupDialogs["DEATH"].button1 = "Release Spirit";
            StaticPopupDialogs["DEATH"].button2 = "";
            StaticPopupDialogs["DEATH"].DisplayButton2 = function() return false end
        else
            DEATH_RELEASE = "Go again";
            StaticPopupDialogs["DEATH"].text = RED_FONT_COLOR_CODE .. "YOU DIED" .. FONT_COLOR_CODE_CLOSE;
            StaticPopupDialogs["DEATH"].button1 = "Go again";
            StaticPopupDialogs["DEATH"].button2 = "Appeal";
            StaticPopupDialogs["DEATH"].DisplayButton2 = function() return true end
        end
    end)
end

function WHC.InitializeDeathPopupAppeal()
    addDeathPopupAppealButton()
    updateDeathPopupText()
end

-- The server announces the death of any level 15+ character as a raid boss emote
-- (Unit.cpp, CHAT_MSG_RAID_BOSS_EMOTE), which the client paints in the middle of the
-- screen on top of the boss frames. Raiders want to keep the chat line but drop the
-- banner while they are fighting.
--
-- The two clients paint it through completely different code, so both are wrapped:
--  * 1.12 has no RaidNotice system at all. RaidBossEmoteFrame is a plain MessageFrame
--    and ChatFrame.lua calls RaidBossEmoteFrame:AddMessage(body, ...) from inside
--    ChatFrame_OnEvent, so the frame method is the only place to intercept.
--  * 1.14 fires the separate RAID_BOSS_EMOTE event on RaidBossEmoteFrame, whose handler
--    funnels into the global RaidNotice_AddMessage. Nothing on that path touches a
--    protected function, so replacing the global is harmless there.
-- Only the death text is matched, so raid warnings and real boss emotes are untouched.

-- The one place that recognises the server's death announcement, shared with the
-- chat-line handler in Events.lua.
function WHC.IsDeathAnnouncement(text)
    return text and string.find(string.lower(text), "has died at level", 1, true) and true or false
end

local function hideDeathNotice(text)
    return WhcAddonSettings.hideDeathNoticeInRaid == 1
            and WHC.IsDeathAnnouncement(text)
            and UnitAffectingCombat("player")
            and WHC.IsInRaid()
end

function WHC.InitializeDeathAnnouncementFilter()
    if RaidBossEmoteFrame and RaidBossEmoteFrame.AddMessage then
        local origAddMessage = RaidBossEmoteFrame.AddMessage
        RaidBossEmoteFrame.AddMessage = function(frame, text, r, g, b, a, holdTime)
            if hideDeathNotice(text) then
                return
            end

            return origAddMessage(frame, text, r, g, b, a, holdTime)
        end
    end

    if RaidNotice_AddMessage then
        local origRaidNoticeAddMessage = RaidNotice_AddMessage
        RaidNotice_AddMessage = function(noticeFrame, textString, colorInfo, displayTime)
            if hideDeathNotice(textString) then
                return
            end

            return origRaidNoticeAddMessage(noticeFrame, textString, colorInfo, displayTime)
        end
    end
end
