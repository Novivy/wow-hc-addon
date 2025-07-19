local function createAppealFrame()
    local appealFrame = CreateFrame("Frame", "AppealFrame", UIParent, RETAIL_BACKDROP)
    appealFrame:SetWidth(300)
    appealFrame:SetHeight(150)
    appealFrame:SetPoint("TOP", UIParent, "TOP", 0, -128)
    appealFrame:SetBackdrop({
        bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 300,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    appealFrame:SetFrameStrata("HIGH")
    appealFrame:SetFrameLevel(10)

    -- Title
    local title = appealFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", appealFrame, "TOP", 0, -20)
    title:SetText("Copy and paste the following URL to your browser to appeal")
    title:SetWidth(200)

    -- URL input box
    local appealEditBox = CreateFrame("EditBox", "AppealInputBox", appealFrame)
    appealEditBox:SetWidth(250)
    appealEditBox:SetHeight(20)
    appealEditBox:SetPoint("TOP", title, "BOTTOM", 0, -20)
    appealEditBox:SetFontObject("ChatFontNormal")
    appealEditBox:SetText("https://wow-hc.com/appeal")
    appealEditBox:SetJustifyH("CENTER")
    appealEditBox:SetAutoFocus(false)
    appealEditBox:HighlightText()
    appealEditBox:SetFocus()
    appealEditBox:SetTextColor(1, 0.631, 0.317)
    appealEditBox:SetScript("OnMouseDown", function(self)
        appealEditBox:HighlightText()
        appealEditBox:SetFocus()
    end)

    -- Create a container for the buttons to manage their positioning
    local buttonContainer = CreateFrame("Frame", nil, appealFrame)
    buttonContainer:SetWidth(250) -- Width enough to fit both buttons
    buttonContainer:SetHeight(30) -- Height of the buttons
    buttonContainer:SetPoint("TOP", appealEditBox, "BOTTOM", 0, -20)

    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    cancelButton:SetWidth(80)
    cancelButton:SetHeight(30)
    cancelButton:SetPoint("CENTER", buttonContainer, "CENTER", 5, 0) -- Position relative to container's center
    cancelButton:SetText("Back")
    cancelButton:SetScript("OnClick", function()
        appealFrame:Hide()
        StaticPopup_Show("DEATH");
    end)

    appealFrame:Hide()

    return appealFrame
end

local function addDeathPopupAppealButton()
    local appealFrame = createAppealFrame()

    local deathOverride = function (data, reason)
        if (reason == "override") then
            return
        end
        if (reason == "timeout") then
            return
        end

        appealFrame:Show()
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
        local _, instanceType = IsInInstance()
        if (instanceType == "pvp") then
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
