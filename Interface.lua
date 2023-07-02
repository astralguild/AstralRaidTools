local ADDON_NAME, addon = ...

AstralUI = {}

function addon.PrintDebug(...)
  if addon.Debug then
    print('ASTRAL_RAID_DEBUG', ...)
  end
end

function AstralUI:TextureToText(textureName, widthInText, heightInText, textureWidth, textureHeight, l, r, t, b)
	return "|T"..textureName..":"..(widthInText or 0)..":"..(heightInText or 0)..":0:0:"..textureWidth..":"..textureHeight..":"..
		format("%d",l*textureWidth)..":"..format("%d",r*textureWidth)..":"..format("%d",t*textureHeight)..":"..format("%d",b*textureHeight).."|t"
end

function AstralUI:GetRaidTargetText(icon, size)
	size = size or 0
	return AstralUI:TextureToText([[Interface\TargetingFrame\UI-RaidTargetingIcons]],size,size,256,256,((icon-1)%4)/4,((icon-1)%4+1)/4,floor((icon-1)/4)/4,(floor((icon-1)/4)+1)/4)
end

function AstralUI:LinkItem(itemID, itemLink)
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

-- Large amount of code copied and modified from ExRT Functions, Library

local templates = {}

local Mod = nil
do
	local function Widget_SetPoint(self,arg1,arg2,arg3,arg4,arg5)
		if arg1 == 'x' then arg1 = self:GetParent() end
		if arg2 == 'x' then arg2 = self:GetParent() end

		if type(arg1) == 'number' and type(arg2) == 'number' then
			arg1, arg2, arg3 = 'TOPLEFT', arg1, arg2
		end

		if type(arg1) == 'table' and not arg2 then
			self:SetAllPoints(arg1)
			return self
		end

		if arg5 then
			self:SetPoint(arg1,arg2,arg3,arg4,arg5)
		elseif arg4 then
			self:SetPoint(arg1,arg2,arg3,arg4)
		elseif arg3 then
			self:SetPoint(arg1,arg2,arg3)
		elseif arg2 then
			self:SetPoint(arg1,arg2)
		else
			self:SetPoint(arg1)
		end

		return self
	end
	local function Widget_SetSize(self,...)
		self:SetSize(...)
		return self
	end
	local function Widget_SetNewPoint(self,...)
		self:ClearAllPoints()
		self:Point(...)
		return self
	end
	local function Widget_SetScale(self,...)
		self:SetScale(...)
		return self
	end
	local function Widget_OnClick(self, func)
		self:SetScript('OnClick',func)
		return self
	end
	local function Widget_OnShow(self, func, disableFirstRun)
		if not func then
			self:SetScript('OnShow',nil)
			return self
		end
		self:SetScript('OnShow', func)
		if not disableFirstRun then
			func(self)
		end
		return self
	end
	local function Widget_Run(self, func, ...)
		func(self,...)
		return self
	end
	local function Widget_Shown(self, bool)
		if bool then
			self:Show()
		else
			self:Hide()
		end
		return self
	end
	local function Widget_OnEnter(self, func)
		self:SetScript('OnEnter',func)
		return self
	end
	local function Widget_OnLeave(self, func)
		self:SetScript('OnLeave',func)
		return self
	end
	function Mod(self,...)
		self.Point = Widget_SetPoint
		self.Size = Widget_SetSize
		self.NewPoint = Widget_SetNewPoint
		self.Scale = Widget_SetScale
		self.OnClick = Widget_OnClick
		self.OnShow = Widget_OnShow
		self.Run = Widget_Run
		self.Shown = Widget_Shown
		self.OnEnter = Widget_OnEnter
		self.OnLeave = Widget_OnLeave

		for i = 1, select('#', ...) do
			if i % 2 == 1 then
				local funcName,func = select(i, ...)
				self[funcName] = func
			end
		end
	end
	AstralUI.ModObjFuncs = Mod
end

do
	local function OnEnter(self)
		if ( self:IsEnabled() ) then
			if ( self.tooltipText ) then
				GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT")
				GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
			end
			if ( self.tooltipRequirement ) then
				GameTooltip:AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, 1.0)
				GameTooltip:Show()
			end
		end
	end
	local function OnLeave(self)
		GameTooltip:Hide()
	end
	function templates:AstralSliderTemplate(parent)
		local self = CreateFrame("Slider",nil,parent, BackdropTemplateMixin and "BackdropTemplate")
		self:SetOrientation("HORIZONTAL")
		self:SetSize(144,17)
		self:SetHitRectInsets(0, 0, -10, -10)

		self:SetBackdrop({
			bgFile="Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile="Interface\\Buttons\\UI-SliderBar-Border",
			tile = true,
			insets = {
				left = 3,
				right = 3,
				top = 6,
				bottom = 6,
			},
			tileSize = 8,
			edgeSize = 8,
		})

		self.Text = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
		self.Text:SetPoint("BOTTOM",self,"TOP")

		self.Low = self:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		self.Low:SetPoint("TOPLEFT",self,"BOTTOMLEFT",-4,3)

		self.High = self:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		self.High:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",4,3)

		self.Thumb = self:CreateTexture()
		self.Thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		self.Thumb:SetSize(32,32)
		self:SetThumbTexture(self.Thumb)

		self:SetScript("OnEnter",OnEnter)
		self:SetScript("OnLeave",OnLeave)

		return self
	end
end

-- Frames

function AstralUI:Template(name, parent)
	if not templates[name] then
		return
	end
	return templates[name](nil, parent)
end

function AstralUI:OptionsFrame(name, iconFileName)
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

	local icon = menuBar:CreateTexture(nil, 'ARTWORK')
	icon:SetAlpha(0.8)
	icon:SetSize(24, 24)
	icon:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\' .. iconFileName .. '.png')
	icon:SetPoint('TOPLEFT', menuBar, 'TOPLEFT', 13, -10)
	menuBar.icon = icon

	local logo = menuBar:CreateTexture(nil, 'ARTWORK')
	logo:SetAlpha(0.8)
	logo:SetSize(32, 32)
	logo:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\Logo@2x')
	logo:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)
	menuBar.logo = logo

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

	options.guildInfo, options.guildText = AstralUI:GuildInfo(options)

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

function AstralUI:Dropdown(parent, label, width)
  local dropdown = CreateFrame('FRAME', nil, parent, "UIDropDownMenuTemplate")
	dropdown.label = label
	UIDropDownMenu_SetWidth(dropdown, width)
	UIDropDownMenu_SetText(dropdown, label)
	return dropdown
end

function AstralUI:InitializeDropdown(dropdown, list, default, func)
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

do
	local function SliderOnMouseWheel(self,delta)
		if tonumber(self:GetValue()) == nil then
			return
		end
		if self.isVertical then
			delta = -delta
		end
		self:SetValue(tonumber(self:GetValue())+delta)
	end
	local function SliderTooltipShow(self)
		local text = self.text:GetText()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltipText or "")
		GameTooltip:AddLine(text or "",1,1,1)
		GameTooltip:Show()
	end
	local function SliderTooltipReload(self)
		if GameTooltip:IsVisible() then
			self:tooltipHide()
			self:tooltipShow()
		end
	end
	local function Widget_Range(self,minVal,maxVal,hideRange)
		self.Low:SetText(minVal)
		self.High:SetText(maxVal)
		self:SetMinMaxValues(minVal, maxVal)
		if not self.isVertical then
			self.Low:SetShown(not hideRange)
			self.High:SetShown(not hideRange)
		end
		return self
	end
	local function Widget_Size(self,size)
		if self:GetOrientation() == "VERTICAL" then
			self:SetHeight(size)
		else
			self:SetWidth(size)
		end
		return self
	end
	local function Widget_SetTo(self,value)
		if not value then
			local min,max = self:GetMinMaxValues()
			value = max
		end
		self.tooltipText = value
		self:SetValue(value)
		return self
	end
	local function Widget_OnChange(self,func)
		self:SetScript("OnValueChanged",func)
		return self
	end
	local function Widget_SetTooltip(self,tooltipText)
		self.tooltipText = tooltipText
		return self
	end
	local function Widget_SetObey(self,bool)
		self:SetObeyStepOnDrag(bool)
		return self
	end

	function AstralUI:Slider(parent, text)
		local self = AstralUI:Template('AstralSliderTemplate', parent)
		self.text = self.Text
		self.text:SetText(text or '')
		self:SetOrientation('HORIZONTAL')
		self:SetValueStep(1)
		self:SetScript("OnMouseWheel", SliderOnMouseWheel)
		self.tooltipShow = SliderTooltipShow
		self.tooltipHide = GameTooltip_Hide
		self.tooltipReload = SliderTooltipReload
		self:SetScript("OnEnter", self.tooltipShow)
		self:SetScript("OnLeave", self.tooltipHide)

		Mod(self)
		self.Size = Widget_Size
		self.Range = Widget_Range
		self.SetTo = Widget_SetTo
		self.OnChange = Widget_OnChange
		self.Tooltip = Widget_SetTooltip
		self.SetObey = Widget_SetObey
		return self
	end
end

function AstralUI:Checkbox(parent, label, width)
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

function AstralUI:GuildInfo(frame)
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

StaticPopupDialogs["WANT_TO_RELEASE"] = {
  text = 'Do you want to release your spirit?',
  button1 = 'Ok',
  OnAccept = function()
		if StaticPopup1:IsShown() then
			StaticPopup1Button1:Show()
		end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = false,
  preferredIndex = 3
}