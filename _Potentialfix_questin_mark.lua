local function GetItemInfoTexture(name)
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(name);
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"; -- Default to question mark if texture is not found
end

-- ========== Containers ==========
local function ContainerFrame_Update_Hook(frame)
    local id = frame:GetID();
    local name = frame:GetName();
    local itemButton;

    local texture, itemCount, locked, quality, readable;
    for i = 1, frame.size, 1 do


		local index = frame.size + 1 - i

        itemButton = getglobal(name.."Item"..index);
        local itemLink = GetContainerItemLink(id, itemButton:GetID());

        if itemLink then
            texture = GetItemInfoTexture(itemLink);
        else
            texture = nil;
        end
        --_, itemCount, locked, quality, readable = GetContainerItemInfo(id, itemButton:GetID());
		icon, itemCount, locked, quality, readable = GetContainerItemInfo(id, itemButton:GetID());



		if(texture == "Interface\\Icons\\INV_Misc_QuestionMark") then
		print("--")

		itemId = GetContainerItemID(id, itemButton:GetID());
		itemLink = GetContainerItemLink(id, itemButton:GetID());

				print(itemId)
			print(itemLink)
			print(itemName)

			texture = "Interface\\Icons\\INV_Misc_Food_47"

		end


        SetItemButtonTexture(itemButton, texture);
        SetItemButtonCount(itemButton, itemCount);
        SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5);

        if texture then
            ContainerFrame_UpdateCooldown(id, itemButton);
            itemButton.hasItem = 1;
            itemButton.locked = locked;
            itemButton.readable = readable;
        else
            getglobal(name.."Item"..index.."Cooldown"):Hide();
            itemButton.hasItem = nil;
        end
    end
end


-- ========== Bank Buttons ==========
local function BankFrameItemButton_Update_Hook(button)
    local texture = getglobal(button:GetName().."IconTexture");
    local inventoryID = button:GetInventorySlot();
    local textureName = GetInventoryItemTexture("player", inventoryID);
    local id;
    local slotTextureName;
    button.hasItem = nil;

    if button.isBag then
        id, slotTextureName = GetInventorySlotInfo(strsub(button:GetName(), 10));
        local itemLink = GetInventoryItemLink("player", id);
        if itemLink then
            slotTextureName = GetItemInfoTexture(itemLink);
        end
    end

    local itemLink = GetInventoryItemLink("player", inventoryID);
    if itemLink then
        textureName = GetItemInfoTexture(itemLink);
    end

    if textureName then
        texture:SetTexture(textureName);
        texture:Show();
        SetItemButtonCount(button, GetInventoryItemCount("player", inventoryID));
        button.hasItem = 1;
    elseif slotTextureName and button.isBag then
        texture:SetTexture(slotTextureName);
        SetItemButtonCount(button, 0);
        texture:Show();
    else
        texture:Hide();
        SetItemButtonCount(button, 0);
    end

    BankFrameItemButton_UpdateLocked(button);
end

-- ========== Action Buttons ==========
local function ActionButton_Update_Hook()
    local action = this.action;
    local icon = getglobal(this:GetName().."Icon");
    local texture = GetActionTexture(action);
    local name = this:GetName();
    local type, id, subType = GetActionInfo(action);

    if texture == "Interface\\Icons\\INV_Misc_QuestionMark" then
        if type == "item" then
            texture = GetItemInfoTexture(id);
        elseif type == "spell" then
            local spellName = GetSpellName(id, "General");
            if spellName == "Attack" then
                texture = GetInventoryItemTexture("player", 16);
            elseif spellName == "Auto Shot" then
                texture = GetInventoryItemTexture("player", 18);
            end
        end
    end

    -- Update icon
    if texture then
        icon:SetTexture(texture);
        icon:Show();
    else
        icon:Hide();
    end
end

-- ========== Spellbook Attack Button ==========
local function SpellButton_UpdateButton_Hook()
    local id = SpellBook_GetSpellID(this:GetID());
    local name = this:GetName();
    local iconTexture = getglobal(name.."IconTexture");
    local spellString = getglobal(name.."SpellName");
    local subSpellString = getglobal(name.."SubSpellName");

    if SpellBookFrame.bookType == BOOKTYPE_PET then return; end

    local spellName, subSpellName = GetSpellName(id, SpellBookFrame.bookType);
    local texture = GetSpellTexture(id, SpellBookFrame.bookType);

    if texture == "Interface\\Icons\\INV_Misc_QuestionMark" then
        if spellName == "Attack" then
            texture = GetInventoryItemTexture("player", 16);
        elseif spellName == "Auto Shot" then
            texture = GetInventoryItemTexture("player", 18);
        end
    end

    -- Handle missing texture
    if not texture or strlen(texture) == 0 then
        iconTexture:Hide();
        spellString:Hide();
        subSpellString:Hide();
        highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square");
        this:SetChecked(0);
        normalTexture:SetVertexColor(1.0, 1.0, 1.0);
        return;
    end

    iconTexture:SetTexture(texture);
    iconTexture:Show();
    SpellButton_UpdateSelection();
end


-- Secure Hooks
hooksecurefunc("ActionButton_OnEvent", ActionButton_OnEvent_Hook);
hooksecurefunc("ActionButton_Update", ActionButton_Update_Hook);
hooksecurefunc("BankFrameItemButton_Update", BankFrameItemButton_Update_Hook);
hooksecurefunc("BagSlotButton_UpdateChecked", BagSlotButton_UpdateChecked_Hook);
hooksecurefunc("ContainerFrame_Update", ContainerFrame_Update_Hook);
hooksecurefunc("ContainerFrameItemButton_OnEnter", ContainerFrameItemButton_OnEnter_Hook);
hooksecurefunc("ContainerFrameItemButton_OnClick", ContainerFrameItemButton_OnClick_Hook);
hooksecurefunc("SpellButton_OnEvent", SpellButton_OnEvent_Hook);
hooksecurefunc("SpellButton_OnHide", SpellButton_OnHide_Hook);
hooksecurefunc("SpellButton_OnShow", SpellButton_OnShow_Hook);

if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000ArcCorrect has loaded!|r");
end

-- Override for GetContainerItemInfo to fix Question Mark handling
local WOW_GetContainerItemInfo = GetContainerItemInfo;
function GetContainerItemInfo(index, id)
    local texture, itemCount, locked, quality, readable;
    texture, itemCount, locked, quality, readable = WOW_GetContainerItemInfo(index, id);

    if texture and string.find(texture, "INV_Misc_QuestionMark") then
        local itemLink = GetContainerItemLink(index, id);
        local itemid = 0;

        if itemLink then
            local _, _, itemid = string.find(itemLink, "Hitem:(%d+):");
            _, _, texture = GetItemInfo(itemLink);
        end
    end

    return texture, itemCount, locked, quality, readable;
end
