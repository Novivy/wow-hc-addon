function WHC.InitializeMinimapIcon()
    local minimapIcon = CreateFrame('Button', "minimapIcon", Minimap)

    minimapIcon:RegisterForDrag('LeftButton')
    minimapIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    minimapIcon:SetMovable(true)
    minimapIcon:EnableMouse(true)
    minimapIcon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minimapIcon, ANCHOR_BOTTOMLEFT)
        GameTooltip:AddLine("WOW-HC", 0.933, 0.765, 0)
        GameTooltip:AddDoubleLine("Click", "Open", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Shift + Click", "Move", 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapIcon:SetClampedToScreen(true)

    minimapIcon:SetScript("OnClick", function()
        if (WHC:IsVisible()) then
            WHC.UIShowTabContent(0)
        else
            WHC.UIShowTabContent("General")
        end
    end)

    minimapIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    minimapIcon:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            minimapIcon:StartMoving()
        end
    end)
    minimapIcon:SetScript("OnDragStop", function()
        minimapIcon:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOffset, yOffset = minimapIcon:GetPoint()
        WhcAddonSettings.minimapX = xOffset;
        WhcAddonSettings.minimapX = yOffset;
    end)

    minimapIcon:SetFrameLevel(9)
    minimapIcon:SetFrameStrata('HIGH')
    minimapIcon:SetWidth(30)
    minimapIcon:SetHeight(30)
    minimapIcon:SetNormalTexture("Interface\\AddOns\\WOW_HC\\Images\\wow-hardcore-logo-round")
    minimapIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

    local border = minimapIcon:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", minimapIcon, "CENTER", 14, -15)
    border:SetWidth(66)
    border:SetHeight(66)

    WHC.Frames.MapIcon = minimapIcon
    WHC.Frames.MapIcon:Hide()
    if (WhcAddonSettings.minimapicon == 1) then
        WHC.Frames.MapIcon:Show()
    end
end
