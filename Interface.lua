local _, addon = ...

function addon.TextureToText(textureName, widthInText, heightInText, textureWidth, textureHeight, l, r, t, b)
	return "|T"..textureName..":"..(widthInText or 0)..":"..(heightInText or 0)..":0:0:"..textureWidth..":"..textureHeight..":"..
		format("%d",l*textureWidth)..":"..format("%d",r*textureWidth)..":"..format("%d",t*textureHeight)..":"..format("%d",b*textureHeight).."|t"
end

function addon.GetRaidTargetText(icon, size)
	size = size or 0
	return addon.TextureToText([[Interface\TargetingFrame\UI-RaidTargetingIcons]],size,size,256,256,((icon-1)%4)/4,((icon-1)%4+1)/4,floor((icon-1)/4)/4,(floor((icon-1)/4)+1)/4)
end

function addon.LinkItem(itemID, itemLink)
	if not itemLink then
		if not itemID then
			return
		end
		itemLink = select(2, GetItemInfo(itemID))
	end
	if not itemLink then
		return
	end
	if IsModifiedClick("DRESSUP") then
		return DressUpItemLink(itemLink)
	else
		if ChatEdit_GetActiveWindow() then
			ChatEdit_InsertLink(itemLink)
		else
			ChatFrame_OpenChat(itemLink)
		end
	end
end

function addon.Dropdown(parent, label, width)
  local dropdown = CreateFrame('FRAME', nil, parent, "UIDropDownMenuTemplate")
	dropdown.label = label
	UIDropDownMenu_SetWidth(dropdown, width)
	UIDropDownMenu_SetText(dropdown, label)
	return dropdown
end

function addon.InitializeDropdown(dropdown, list, default, func)
	UIDropDownMenu_SetText(dropdown, dropdown.label .. ': ' .. default)
	UIDropDownMenu_Initialize(dropdown, function(frame, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		info.func = function(clicked)
			func(clicked.value)
			UIDropDownMenu_SetText(dropdown, dropdown.label .. ': ' .. clicked.value)
		end
		info.notCheckable = true
		for i, val in pairs(list) do
			info.text, info.arg1 = val, i
			UIDropDownMenu_AddButton(info)
		end
	end)
end

function addon.Checkbox(parent, label, width)
	local checkbox = CreateFrame('CheckButton', nil, parent, "BackdropTemplate")
	checkbox:SetSize(width or 200, 20)
	checkbox:SetBackdrop(nil)
	checkbox:SetBackdropBorderColor(85/255, 85/255, 85/255)
	checkbox:SetNormalFontObject(InterUIRegular_Normal)
	checkbox:SetText(label)

	checkbox:SetBackdropColor(0, 0, 0)

	checkbox:SetPushedTextOffset(1,-1)

	local tex = checkbox:CreateTexture('PUSHED_TEXTURE_BOX', 'BACKGROUND')
	tex:SetSize(12, 12)
	tex:SetPoint('LEFT', checkbox, 'LEFT', -2, 0)
	tex:SetTexture('Interface\\AddOns\\AstralKeys\\Media\\box2.tga')
	tex:SetVertexColor(0.3, 0.3, 0.3)

	checkbox.t = checkbox:CreateTexture('PUSHEDTEXTURE', 'BACKGROUND')
	checkbox.t:SetSize(12, 12)
	checkbox.t:SetPoint('CENTER', tex, 'CENTER', 0, 0)
	checkbox.t:SetTexture('Interface\\AddOns\\AstralKeys\\Media\\Texture\\baseline-done-small@2x.tga')
	checkbox:SetCheckedTexture(checkbox.t)

	if label then
		checkbox:GetFontString():SetPoint('LEFT', tex, 'RIGHT', 5, 0)
	end
	return checkbox
end

-- Dialogs

local reallyRelease
StaticPopupDialogs["WANT_TO_RELEASE"] = {
  text = 'Do you want to release your spirit?',
  button1 = 'Ok',
  OnAccept = function()
      reallyRelease()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = false,
  preferredIndex = 3
}

-- Callbacks

reallyRelease = function()
  if StaticPopup1:IsShown() and StaticPopup1Button1:GetButtonState() == 'NORMAL' then
    StaticPopup1Button1:Enable()
  end
end