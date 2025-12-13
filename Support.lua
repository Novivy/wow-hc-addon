function WHC.InitializeSupport()
    local supportTabIndex = "Support"

    --  Both clients: The ? button on the default UI
    HelpMicroButton:SetScript("OnClick", function()
        if WHC.Frames.UItab[supportTabIndex]:IsVisible() then
            WHC.UIShowTabContent(0)
        else
            WHC.UIShowTabContent(supportTabIndex)
        end
    end)

    -- 1.12: The active ticket button above buffs
    if (RETAIL == 1) then
        -- todo (low prio since ticket status block not displayed on retail)
    else
        StaticPopupDialogs["HELP_TICKET"].OnAccept = function()
            WHC.UIShowTabContent(supportTabIndex)
        end

        StaticPopupDialogs["HELP_TICKET"].OnCancel = function()
            local msg = ".whc ticketdelete"
            SendChatMessage(msg, "WHISPER", GetDefaultLanguage(), UnitName("player"));
        end
    end

    local reportOptions = {
        ["REPORT_SPAM"] = true,
        ["REPORT_BAD_LANGUAGE"] = true,
        ["REPORT_BAD_NAME"] = true,
        ["REPORT_CHEATING"] = true,
    }

    -- 1.14: Right-clicking on a player to report them
    local blizzardFunction_UnitPopup_OnClick = UnitPopup_OnClick
    if RETAIL == 1 then
        UnitPopup_OnClick = function(self)
            if self and reportOptions[self.value] then
                return WHC.UIShowTabContent(supportTabIndex)
            end

            return blizzardFunction_UnitPopup_OnClick(self)
        end
    end
end
