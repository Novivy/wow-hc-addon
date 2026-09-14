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
