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

    -- 1.14: right-clicking a player in chat to report them fills the chat input
    -- with ".report PLAYERNAME" so it can be sent as a server command.
    if (RETAIL == 1) then
        local reportReasons = {
            ["REPORT_SPAM"] = true,
            ["REPORT_BAD_LANGUAGE"] = true,
            ["REPORT_BAD_NAME"] = true,
            ["REPORT_CHEATING"] = true,
        }

        -- Remember the player whose name was last clicked in chat
        local reportName
        WHC.HookSecureFunc("ChatFrame_OnHyperlinkShow", function(chatFrame, linkData, link, button)
            local _, _, name = string.find(linkData or "", "^player:([^:]+)")
            if name then
                reportName = name
            end
        end)

        local blizzardFunction_UnitPopup_OnClick = UnitPopup_OnClick
        UnitPopup_OnClick = function(self)
            if not (self and reportReasons[self.value]) or not reportName or reportName == "" then
                return blizzardFunction_UnitPopup_OnClick(self)
            end

            local editBox = (ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend())
                or ChatFrameEditBox
            if editBox then
                if ChatEdit_ActivateChat then
                    ChatEdit_ActivateChat(editBox)
                else
                    editBox:Show()
                end
                editBox:SetText(".report " .. reportName)
                editBox:SetFocus()
            end
        end
    end
end
