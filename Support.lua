function WHC.InitializeSupport()
    --  Both clients: The ? button on the default UI
    HelpMicroButton:SetScript("OnClick", function()
        WHC.UIShowTabContent(WHC.TAB.SUPPORT)
    end)

    -- 1.12: The active ticket button above buffs
    if (RETAIL == 1) then
        -- todo (low prio since ticket status block not displayed on retail)
    else
        StaticPopupDialogs["HELP_TICKET"].OnAccept = function()
            WHC.UIShowTabContent(WHC.TAB.SUPPORT)
        end

        StaticPopupDialogs["HELP_TICKET"].OnCancel = function()
            local msg = ".whc ticketdelete"
            SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
        end
    end

    -- 1.14: right-clicking a player in chat to report them opens the ticket form
    -- pre-filled with the player's name and the message being reported.
    if (RETAIL == 1) then
        local reportReasons = {
            ["REPORT_SPAM"] = "Spam",
            ["REPORT_BAD_LANGUAGE"] = "Bad language",
            ["REPORT_BAD_NAME"] = "Bad name",
            ["REPORT_CHEATING"] = "Cheating",
        }

        -- Remove colour/texture/link escapes so the cached text stays readable
        local function stripEscapes(message)
            if not message then return message end
            message = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
            message = string.gsub(message, "|r", "")
            message = string.gsub(message, "|T.-|t", "")
            message = string.gsub(message, "|H.-|h(.-)|h", "%1")
            return message
        end

        -- Keep the last 30 chat lines, keyed by their lineID. The player link in the
        -- report menu carries the same lineID, so we can recover the exact message
        -- that was clicked. Older lines are dropped and can no longer be reported.
        local messageByLine = {}
        local lineOrder = {}
        local maxLines = 30
        local nextSlot = 0
        -- Named params (no ... / select) and a manual wrap (no %) so the file still
        -- parses on the 1.12 client. lineID is the 11th CHAT_MSG_ argument.
        local function cacheMessage(frame, event, message, sender, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, lineID)
            if sender and sender ~= "" and lineID and lineID ~= 0 and not messageByLine[lineID] then
                nextSlot = nextSlot + 1
                if nextSlot > maxLines then nextSlot = 1 end
                if lineOrder[nextSlot] then messageByLine[lineOrder[nextSlot]] = nil end
                lineOrder[nextSlot] = lineID
                messageByLine[lineID] = stripEscapes(message)
            end
            return false
        end

        local cachedEvents = {
            "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
            "CHAT_MSG_CHANNEL", "CHAT_MSG_WHISPER",
            "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        }
        for _, chatEvent in ipairs(cachedEvents) do
            ChatFrame_AddMessageEventFilter(chatEvent, cacheMessage)
        end

        -- Remember the player and line whose name was last clicked in chat
        local reportName, reportLine
        WHC.HookSecureFunc("ChatFrame_OnHyperlinkShow", function(chatFrame, linkData, link, button)
            local _, _, name, lineID = string.find(linkData or "", "^player:([^:]+):(%d+)")
            if not name then
                _, _, name = string.find(linkData or "", "^player:([^:]+)")
            end
            if name then
                reportName = name
                reportLine = tonumber(lineID)
            end
        end)

        local blizzardFunction_UnitPopup_OnClick = UnitPopup_OnClick
        UnitPopup_OnClick = function(self)
            local reason = self and reportReasons[self.value]
            if not reason then
                return blizzardFunction_UnitPopup_OnClick(self)
            end

            local message = reportLine and messageByLine[reportLine]
            if not message or message == "" then
                UIErrorsFrame:AddMessage(
                    "This message is too old to be reported and is not available in your cache anymore. Please report manually by creating a ticket with name and message.",
                    1, 0, 0, 1, UIERRORS_HOLD_TIME)
                return
            end

            WHC.UIShowTabContent(WHC.TAB.SUPPORT)
            local issue = "Reporting " .. (reportName or "player") .. " for " .. reason .. ". Message: \"" .. message .. "\""
            WHC.Frames.UItab[WHC.TAB.SUPPORT].editBox:SetText(issue)
        end
    end
end
