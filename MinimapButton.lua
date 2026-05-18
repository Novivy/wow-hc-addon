local BG_ZONES = {
    ["Warsong Gulch"] = true,
    ["Arathi Basin"] = true,
    ["Alterac Valley"] = true,
}

local function IsInBattleground()
    if RETAIL == 1 then
        if IsInInstance then
            local inInstance, instanceType = IsInInstance()
            return inInstance and instanceType == "pvp"
        end
        return false
    end
    return BG_ZONES[GetRealZoneText()] == true
end

local MINIMAP_RADIUS = 80

local function SetMinimapIconPosition(minimapIcon, angle)
    local rad = math.rad(angle)
    minimapIcon:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * MINIMAP_RADIUS, math.sin(rad) * MINIMAP_RADIUS)
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
        if (WHC:IsVisible()) then
            WHC.UIShowTabContent(0)
        else
            WHC.UIShowTabContent(WHC.lastTab)
        end
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
                if clickedButton == "LeftButton" and not IsInBattleground() then
                    if WHC:IsVisible() then
                        WHC.UIShowTabContent(0)
                    else
                        WHC.UIShowTabContent(WHC.TAB.PVP)
                    end
                end
            end)
        else
            local origBGClick = MiniMapBattlefieldFrame:GetScript("OnClick")
            MiniMapBattlefieldFrame:SetScript("OnClick", function()
                if origBGClick then origBGClick() end
                if arg1 == "LeftButton" and not IsInBattleground() then
                    if WHC:IsVisible() then
                        WHC.UIShowTabContent(0)
                    else
                        WHC.UIShowTabContent(WHC.TAB.PVP)
                    end
                end
            end)
        end
    end
end
