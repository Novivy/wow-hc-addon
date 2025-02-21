local originalHelpButton_OnClick = HelpMicroButton:GetScript("OnClick")

HelpMicroButton:SetScript("OnClick", function()
    if UIframe:IsVisible() then
        UIShowTabContent(0)
    else
        UIShowTabContent("Support")
    end
end)

