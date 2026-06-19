local MINIMAP_RADIUS = 80
local DEFAULT_HC_ANGLE = 225
local DEFAULT_GF_ANGLE = 195

local function SetMinimapIconPosition(minimapIcon, angle)
    local rad = math.rad(angle)
    minimapIcon:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * MINIMAP_RADIUS, math.sin(rad) * MINIMAP_RADIUS)
end

-- reset an icon back to its default spot on the minimap ring
function WHC.ResetMinimapIconPosition()
    WhcAddonSettings.minimapAngle = DEFAULT_HC_ANGLE
    if WHC.Frames.MapIcon then
        WHC.Frames.MapIcon:ClearAllPoints()
        SetMinimapIconPosition(WHC.Frames.MapIcon, DEFAULT_HC_ANGLE)
    end
end
function WHC.ResetGroupFinderIconPosition()
    WhcAddonSettings.groupFinderAngle = DEFAULT_GF_ANGLE
    if WHC.Frames.GroupFinderIcon then
        WHC.Frames.GroupFinderIcon:ClearAllPoints()
        SetMinimapIconPosition(WHC.Frames.GroupFinderIcon, DEFAULT_GF_ANGLE)
    end
end

function WHC.InitializeMinimapIcon()
    local minimapIcon = CreateFrame('Button', "minimapIcon", Minimap)

    minimapIcon:RegisterForDrag('LeftButton')
    minimapIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    minimapIcon:EnableMouse(true)
    minimapIcon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minimapIcon, ANCHOR_BOTTOMLEFT)
        GameTooltip:AddLine("WOW-HC", 0.933, 0.765, 0)
        GameTooltip:AddDoubleLine("Click", "Open", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Drag", "Move", 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    minimapIcon:SetScript("OnClick", function()
        WHC.UIShowTabContent(WHC.lastTab)
    end)

    minimapIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    minimapIcon:SetScript("OnDragStart", function()
        minimapIcon:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = UIParent:GetScale()
            local px, py = GetCursorPosition()
            local angle = math.deg(math.atan2((py / scale) - my, (px / scale) - mx))
            WhcAddonSettings.minimapAngle = angle
            minimapIcon:ClearAllPoints()
            SetMinimapIconPosition(minimapIcon, angle)
        end)
    end)
    minimapIcon:SetScript("OnDragStop", function()
        minimapIcon:SetScript("OnUpdate", nil)
    end)

    minimapIcon:SetFrameLevel(9)
    minimapIcon:SetFrameStrata('HIGH')
    minimapIcon:SetWidth(25)
    minimapIcon:SetHeight(25)
    minimapIcon:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round")
    SetMinimapIconPosition(minimapIcon, WhcAddonSettings.minimapAngle or 225)

    local border = minimapIcon:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", minimapIcon, "CENTER", 12, -13)
    border:SetWidth(56)
    border:SetHeight(56)

    WHC.Frames.MapIcon = minimapIcon
    WHC.Frames.MapIcon:Hide()
    if (WhcAddonSettings.minimapicon == 1) then
        WHC.Frames.MapIcon:Show()
    end

    if MiniMapBattlefieldFrame then
        if RETAIL == 1 then
            MiniMapBattlefieldFrame:HookScript("OnClick", function(self, button)
                local clickedButton = button or arg1
                if clickedButton == "LeftButton" and not WHC.IsInBattleground() then
                    WHC.UIShowTabContent(WHC.TAB.PVP)
                end
            end)
        else
            local origBGClick = MiniMapBattlefieldFrame:GetScript("OnClick")
            MiniMapBattlefieldFrame:SetScript("OnClick", function()
                if origBGClick then origBGClick() end
                if arg1 == "LeftButton" and not WHC.IsInBattleground() then
                    WHC.UIShowTabContent(WHC.TAB.PVP)
                end
            end)
        end
    end
end

function WHC.InitializeGroupFinderIcon()
    local icon = CreateFrame('Button', "WhcGroupFinderIcon", Minimap)

    icon:RegisterForDrag('LeftButton')
    icon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    icon:EnableMouse(true)
    icon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(icon, ANCHOR_BOTTOMLEFT)
        GameTooltip:AddLine("WOW-HC Group Finder", 0.933, 0.765, 0)
        GameTooltip:AddDoubleLine("Click", "Open Group Finder", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Drag", "Move", 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    icon:SetScript("OnClick", function()
        WHC.GF.Toggle()
    end)

    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    icon:SetScript("OnDragStart", function()
        icon:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = UIParent:GetScale()
            local px, py = GetCursorPosition()
            local angle = math.deg(math.atan2((py / scale) - my, (px / scale) - mx))
            WhcAddonSettings.groupFinderAngle = angle
            icon:ClearAllPoints()
            SetMinimapIconPosition(icon, angle)
        end)
    end)
    icon:SetScript("OnDragStop", function()
        icon:SetScript("OnUpdate", nil)
    end)

    icon:SetFrameLevel(9)
    icon:SetFrameStrata('HIGH')
    icon:SetWidth(25)
    icon:SetHeight(25)
    local EYE_PATH = "Interface\\AddOns\\WOW_HC\\Images\\groupfinder\\eye\\battlenetworking"
    -- only the frames that actually exist on disk (some indices are missing)
    local EYE_FRAMES = { 0,1,2,3,4,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28 }
    local EYE_FRAME_TIME = 1 / 9   -- ~9 fps loop

    icon:SetNormalTexture(EYE_PATH .. EYE_FRAMES[1])
    local nt = icon:GetNormalTexture()
    if nt then nt:ClearAllPoints(); nt:SetPoint("CENTER", icon, "CENTER", 0, -0.5); nt:SetWidth(38); nt:SetHeight(38) end
    SetMinimapIconPosition(icon, WhcAddonSettings.groupFinderAngle or 195)

    -- animate the eye by cycling the frames. A dedicated timer frame is used (not the
    -- icon's own OnUpdate, which the drag handler sets/clears). Swaps the texture on
    -- the existing normal-texture object so its size/anchor are kept.
    if nt then
        local animator = CreateFrame("Frame")
        local elapsed, idx = 0, 1
        animator:SetScript("OnUpdate", function(self, dt)
            dt = dt or arg1 or 0   -- 1.14 passes elapsed as a param, 1.12 via global arg1
            if not icon:IsVisible() then return end
            -- only animate while you have / are in a listing; otherwise rest on the
            -- static first frame
            local inListing = WHC.GF and WHC.GF.mine and WHC.GF.mine.state ~= 0
            if not inListing then
                if idx ~= 1 then idx = 1; elapsed = 0; nt:SetTexture(EYE_PATH .. EYE_FRAMES[1]) end
                return
            end
            elapsed = elapsed + dt
            if elapsed < EYE_FRAME_TIME then return end
            elapsed = 0
            idx = idx + 1
            if idx > table.getn(EYE_FRAMES) then idx = 1 end
            nt:SetTexture(EYE_PATH .. EYE_FRAMES[idx])
        end)
        WHC.Frames.GroupFinderIconAnimator = animator
    end

    local border = icon:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", icon, "CENTER", 12, -13)
    border:SetWidth(56)
    border:SetHeight(56)

    WHC.Frames.GroupFinderIcon = icon
    WHC.Frames.GroupFinderIcon:Hide()
    if (WhcAddonSettings.groupFinderIcon == 1) then
        WHC.Frames.GroupFinderIcon:Show()
    end
end
