SLASH_ReloadUI1 = "/reloadui"
SLASH_ReloadUI2 = "/reload"
SlashCmdList["ReloadUI"] = function(msg, editbox)
    ConsoleExec("reloadui")
end

local _G = getfenv(0);
function WHC.HookSecureFunc(arg1, arg2, arg3)
    if type(arg1) == "string" then
        arg1, arg2, arg3 = _G, arg1, arg2
    end
    local orig = arg1[arg2]
    arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
        arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

        return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
    end
end

function WHC.GetItemIDFromLink(itemLink)
    if not itemLink then
        return
    end

    local foundID, _ , itemID = string.find(itemLink, "item:(%d+)")
    if not foundID then
        return
    end

    return tonumber(itemID)
end

-- Function to print debug messages
function WHC.DebugPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
end

-- Function to print table key values
function WHC.DebugDump(o)
    if type(o) == 'table' then
        local s = '{ '
        local idx = 0
        for k,v in pairs(o) do
            local key = k
            if type(k) ~= 'number' then
                key = '"'..key..'"'
            end

            if idx > 0 then
                s = s .. ', '
            end
            s = s .. '['..key..'] = ' .. WHC.DebugDump(v)
            idx = idx + 1
        end
        return s .. '} '
    end

    return tostring(o)
end

-- Print message when the addon is loaded
-- WHC.DebugPrint("ReleaseSpiritMod loaded.")

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






