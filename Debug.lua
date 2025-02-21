-- Debug.lua


SLASH_ReloadUI1 = "/reloadui"
SLASH_ReloadUI2 = "/reload"
SlashCmdList["ReloadUI"] = function(msg, editbox)
    ConsoleExec("reloadui")
end

-- Function to print debug messages
function DebugPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

-- Print message when the addon is loaded
-- DebugPrint("ReleaseSpiritMod loaded.")

-- ChatFrame_AddMessageEventFilter(evt,myChatFilter)


-- UIframe:RegisterEvent("CHAT_MSG")

-- UIframe:RegisterEvent("CHAT_MSG_GUILD")


-- ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", myChatFilter)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", myChatFilter)

-- local frame=CreateFrame("Frame");-- Need a frame to capture events
-- frame:RegisterEvent("CHAT_MSG_SAY");-- Register our event

-- frame:SetScript("OnEvent",function(self,event,msg)-- OnEvent handler receives event triggers
--   	print("scr---")
--   	print(self)
--   	print(event)
--    	print(msg)
-- end);
--






