local ADDON_NAME, addon = ...

function addon.PrintDebug(...)
  if addon.Debug then
    print('ASTRAL_RAID_DEBUG', ...)
  end
end

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

-- Frames

function addon.OptionsFrame(name)
	local options = CreateFrame('FRAME', name, UIParent)

	options:SetFrameStrata('DIALOG')
	options:SetFrameLevel(5)
	options:SetHeight(455)
	options:SetWidth(650)
	options:SetPoint('CENTER', UIParent, 'CENTER')
	options:SetMovable(true)
	options:EnableMouse(true)
	options:RegisterForDrag('LeftButton')
	options:EnableKeyboard(true)
	options:SetPropagateKeyboardInput(true)
	options:SetClampedToScreen(true)
	options.background = options:CreateTexture(nil, 'BACKGROUND')
	options.background:SetAllPoints(options)
	options.background:SetColorTexture(33/255, 33/255, 33/255, 0.5)
	options:Hide()

	local menuBar = CreateFrame('FRAME', '$parentMenuBar', options)
	menuBar:SetWidth(50)
	menuBar:SetHeight(455)
	menuBar:SetPoint('TOPLEFT', options, 'TOPLEFT')
	menuBar.texture = menuBar:CreateTexture(nil, 'BACKGROUND')
	menuBar.texture:SetAllPoints(menuBar)
	menuBar.texture:SetColorTexture(33/255, 33/255, 33/255, 0.8)
	options.menuBar = menuBar

	local logo = menuBar:CreateTexture(nil, 'ARTWORK')
	logo:SetAlpha(0.8)
	logo:SetSize(32, 32)
	logo:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\Logo@2x')
	logo:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)

	local closeButton = CreateFrame('BUTTON', '$parentCloseButton', options)
	closeButton:SetNormalTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\baseline-close-24px@2x.tga')
	closeButton:SetSize(12, 12)
	closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
	closeButton:SetScript('OnClick', function() options:Hide() end)
	closeButton:SetPoint('TOPRIGHT', options, 'TOPRIGHT', -14, -14)
	closeButton:SetScript('OnEnter', function(self)
		self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
	end)
	closeButton:SetScript('OnLeave', function(self)
		self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	end)

	local contentFrame = CreateFrame('FRAME', '$parentFrameContent', options)
	contentFrame:SetPoint('TOPLEFT', menuBar, 'TOPRIGHT', 15, -15)
	contentFrame:SetSize(550, 360)
	options.contentFrame = contentFrame

	options.guildInfo, options.guildText = addon.GuildInfo(options)

	options:SetScript('OnDragStart', function(self) self:StartMoving() end)
	options:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
	options:SetScript('OnKeyDown', function (self, key)
		if key == 'ESCAPE' then
			self:SetPropagateKeyboardInput(false)
			options:Hide()
		end
	end)

	return options
end

-- Widgets

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

function addon.GuildInfo(frame)
	local backdropButton = {
		bgFile = nil,
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}

	local astralGuildInfo
	local guildVersionString = CreateFrame('BUTTON', nil, frame)
	guildVersionString:SetNormalFontObject(InterUIRegular_Small)
	guildVersionString:SetSize(110, 20)
	guildVersionString:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 10)
	guildVersionString:SetAlpha(0.2)

	guildVersionString:SetScript('OnEnter', function(self)
		self:SetAlpha(.8)
	end)
	guildVersionString:SetScript('OnLeave', function(self)
		self:SetAlpha(0.2)
	end)

	guildVersionString:SetScript('OnClick', function()
		astralGuildInfo:SetShown(not astralGuildInfo:IsShown())
	end)

	astralGuildInfo = CreateFrame('FRAME', 'AstralGuildInfo', frame, "BackdropTemplate")
	astralGuildInfo:Hide()
	astralGuildInfo:SetFrameLevel(8)
	astralGuildInfo:SetSize(200, 100)
	astralGuildInfo:SetBackdrop(backdropButton)
	astralGuildInfo:EnableKeyboard(true)
	astralGuildInfo:SetBackdropBorderColor(.2, .2, .2, 1)
	astralGuildInfo:SetPoint('BOTTOM', UIParent, 'TOP', 0, -300)

	astralGuildInfo.text = astralGuildInfo:CreateFontString(nil, 'OVERLAY', 'InterUIRegular_Normal')
	astralGuildInfo.text:SetPoint('TOP', astralGuildInfo,'TOP', 0, -10)
	astralGuildInfo.text:SetText('Visit Astral at')

	astralGuildInfo.editBox = CreateFrame('EditBox', nil, astralGuildInfo, "BackdropTemplate")
	astralGuildInfo.editBox:SetSize(180, 20)
	astralGuildInfo.editBox:SetPoint('TOP', astralGuildInfo.text, 'BOTTOM', 0, -10)

	astralGuildInfo.tex = astralGuildInfo:CreateTexture('ARTWORK')
	astralGuildInfo.tex:SetSize(198, 98)
	astralGuildInfo.tex:SetPoint('TOPLEFT', astralGuildInfo, 'TOPLEFT', 1, -1)
	astralGuildInfo.tex:SetColorTexture(0, 0, 0)

	astralGuildInfo.editBox:SetBackdrop(backdropButton)
	astralGuildInfo.editBox:SetBackdropBorderColor(.2, .2, .2, 1)
	astralGuildInfo.editBox:SetFontObject(InterUIRegular_Normal)
	astralGuildInfo.editBox:SetText('www.astralguild.com')
	astralGuildInfo.editBox:HighlightText()
	astralGuildInfo.editBox:SetScript('OnChar', function(self)
		self:SetText('www.astralguild.com')
		self:HighlightText()
	end)
	astralGuildInfo.editBox:SetScript("OnEscapePressed", function()
		astralGuildInfo:Hide()
	end)
	astralGuildInfo.editBox:SetScript('OnEditFocusLost', function(self)
		self:SetText('www.astralguild.com')
		self:HighlightText()
	end)
	local button = CreateFrame('BUTTON', nil, astralGuildInfo, "BackdropTemplate")
	button:SetSize(40, 20)
	button:SetNormalFontObject(InterUIRegular_Normal)
	button:SetText('Close')
	button:SetBackdrop(backdropButton)
	button:SetBackdropBorderColor(.2, .2, .2, 1)
	button:SetPoint('BOTTOM', astralGuildInfo, 'BOTTOM', 0, 10)

	button:SetScript('OnClick', function() astralGuildInfo:Hide() end)

	return astralGuildInfo, guildVersionString
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