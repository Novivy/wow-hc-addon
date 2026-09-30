-- Live Honor tab. The stock client only redraws part of the Honor tab while you are in the world:
--   1.12: HonorFrame_Update(updateAll) redraws Yesterday / This Week / Last Week only when updateAll
--         is set, which the client does on PLAYER_ENTERING_WORLD only. The kill and rank events redraw
--         Today, Lifetime and the rank, so after the weekly honor calculation (or at midnight for
--         Yesterday) those three blocks kept showing the login values until a relog or a zone change.
--         HonorFrame has no OnShow either, so reopening the tab did not help.
--   1.14: HonorFrame_Update() redraws every block, but only on the kill / rank / entering world
--         events, not when the tab opens.
-- The server keeps the values current; this only makes the tab read them again: on every event
-- (1.12) and each time the tab opens (both clients).

local function RedrawAll()
    if WHC.client.is1_12 then
        HonorFrame_Update(1)
    else
        HonorFrame_Update()
    end
end

local attached = false

local function Attach()
    if attached or not HonorFrame or not HonorFrame_Update then
        return
    end
    attached = true

    if WHC.client.is1_12 then
        -- every redraw becomes a full one (1.12 has no taint system, replacing the global is safe)
        local blizzardUpdate = HonorFrame_Update
        HonorFrame_Update = function()
            blizzardUpdate(1)
        end

        -- 1.12 HonorFrame has no OnShow script, keep any other addon's one all the same
        local previousOnShow = HonorFrame:GetScript("OnShow")
        HonorFrame:SetScript("OnShow", function(self)
            if previousOnShow then
                previousOnShow(self or this)
            end
            RedrawAll()
        end)
    else
        -- append only, never replace a Blizzard script on 1.14 (taint)
        HonorFrame:HookScript("OnShow", function()
            RedrawAll()
        end)
    end
end

function WHC.InitializeHonorPanel()
    Attach()
    if attached then
        return
    end

    -- HonorFrame is in FrameXML on 1.12 (already there); on 1.14 it comes with Blizzard_UIPanels_Game
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:RegisterEvent("PLAYER_ENTERING_WORLD")
    loader:SetScript("OnEvent", function()
        Attach()
        if attached then
            loader:UnregisterEvent("ADDON_LOADED")
            loader:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
end
