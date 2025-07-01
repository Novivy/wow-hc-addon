local originalHelpButton_OnClick = HelpMicroButton:GetScript("OnClick")

HelpMicroButton:SetScript("OnClick", function()
    if WHC:IsVisible() then
        WHC.UIShowTabContent(0)
    else
        WHC.UIShowTabContent("Support")
    end
end)

