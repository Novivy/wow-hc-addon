local originalHelpButton_OnClick = HelpMicroButton:GetScript("OnClick")

HelpMicroButton:SetScript("OnClick", function()
    if UIframe:IsVisible() then
        WHC.UIShowTabContent(0)
    else
        WHC.UIShowTabContent("Support")
    end
end)

