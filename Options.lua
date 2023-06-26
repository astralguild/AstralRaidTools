local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

local AstralRaidOptionsFrame = CreateFrame('FRAME', 'AstralRaidOptionsFrame', UIParent)
AstralRaidOptionsFrame:SetFrameStrata('DIALOG')
AstralRaidOptionsFrame:SetFrameLevel(5)
AstralRaidOptionsFrame:SetHeight(455)
AstralRaidOptionsFrame:SetWidth(650)
AstralRaidOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
AstralRaidOptionsFrame:SetMovable(true)
AstralRaidOptionsFrame:EnableMouse(true)
AstralRaidOptionsFrame:RegisterForDrag('LeftButton')
AstralRaidOptionsFrame:EnableKeyboard(true)
AstralRaidOptionsFrame:SetPropagateKeyboardInput(true)
AstralRaidOptionsFrame:SetClampedToScreen(true)
AstralRaidOptionsFrame.background = AstralRaidOptionsFrame:CreateTexture(nil, 'BACKGROUND')
AstralRaidOptionsFrame.background:SetAllPoints(AstralRaidOptionsFrame)
AstralRaidOptionsFrame.background:SetColorTexture(33/255, 33/255, 33/255, 0.5)
AstralRaidOptionsFrame:Hide()

local menuBar = CreateFrame('FRAME', '$parentMenuBar', AstralRaidOptionsFrame)
menuBar:SetWidth(50)
menuBar:SetHeight(455)
menuBar:SetPoint('TOPLEFT', AstralRaidOptionsFrame, 'TOPLEFT')
menuBar.texture = menuBar:CreateTexture(nil, 'BACKGROUND')
menuBar.texture:SetAllPoints(menuBar)
menuBar.texture:SetColorTexture(33/255, 33/255, 33/255, 0.8)

AstralRaidOptionsFrame:SetScript('OnDragStart', function(self)
	self:StartMoving()
end)

AstralRaidOptionsFrame:SetScript('OnDragStop', function(self)
	self:StopMovingOrSizing()
end)

-- Setting Widgets

local backdropButton = {
  bgFile = nil,
  edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16, edgeSize = 1,
  insets = {left = 0, right = 0, top = 0, bottom = 0}
}

local logo = menuBar:CreateTexture(nil, 'ARTWORK')
logo:SetAlpha(0.8)
logo:SetSize(32, 32)
logo:SetTexture('Interface\\AddOns\\AstralKeys\\Media\\Texture\\Logo@2x')
logo:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)

local closeButton = CreateFrame('BUTTON', '$parentCloseButton', AstralRaidOptionsFrame)
closeButton:SetNormalTexture('Interface\\AddOns\\AstralKeys\\Media\\Texture\\baseline-close-24px@2x.tga')
closeButton:SetSize(12, 12)
closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
closeButton:SetScript('OnClick', function()
	AstralRaidOptionsFrame:Hide()
end)
closeButton:SetPoint('TOPRIGHT', AstralRaidOptionsFrame, 'TOPRIGHT', -14, -14)
closeButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
closeButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)

local contentFrame = CreateFrame('FRAME', 'AstralRaidOptionsFrameContent', AstralRaidOptionsFrame)
contentFrame:SetPoint('TOPLEFT', menuBar, 'TOPRIGHT', 15, -15)
contentFrame:SetSize(550, 360)

local generalHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
generalHeader:SetText('General Options')
generalHeader:SetPoint('TOPLEFT', contentFrame, 'TOPLEFT')

local showMinimap = addon.Checkbox(contentFrame, 'Show Minimap Button')
showMinimap:SetPoint('TOPLEFT', generalHeader, 'BOTTOMLEFT', 10, -10)
showMinimap:SetScript('OnClick', function(self)
	AstralRaidSettings.general.show_minimap_button.isEnabled = self:GetChecked()
	-- if AstralRaidSettings.general.show_minimap_button.isEnabled then
	-- 	addon.icon:Show('AstralKeys')
	-- else
	-- 	addon.icon:Hide('AstralKeys')
	-- end
	-- if IsAddOnLoaded('ElvUI_Enhanced') then -- Update the layout for the minimap buttons
	-- 	ElvUI[1]:GetModule('MinimapButtons'):UpdateLayout()
	-- end
end)

local remindersHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
remindersHeader:SetText('Reminders Options')
remindersHeader:SetPoint('TOPLEFT', showMinimap, 'BOTTOMLEFT', -10, -20)

local fonts = SharedMedia:List('font')
local fontDropdown = addon.Dropdown(contentFrame, 'Reminders Font', 200)
fontDropdown:SetPoint('TOPLEFT', remindersHeader, 'BOTTOMLEFT', 10, -10)

local testReminders = false
local testRemindersButton = CreateFrame('BUTTON', 'AstralRaidsTestRemindersButton', contentFrame, "UIPanelButtonTemplate")
testRemindersButton:SetPoint('LEFT', fontDropdown, 'RIGHT', -10, 0)
testRemindersButton:SetSize(200, 20)
testRemindersButton:SetText('Test Reminders')
testRemindersButton:SetScript('OnClick', function()
	testReminders = not testReminders
	addon.TestReminders(testReminders)
end)

-- Guild Info

local astralGuildInfo
local guildVersionString = CreateFrame('BUTTON', nil, AstralRaidOptionsFrame)
guildVersionString:SetNormalFontObject(InterUIRegular_Small)
guildVersionString:SetSize(110, 20)
guildVersionString:SetPoint('BOTTOM', AstralRaidOptionsFrame, 'BOTTOM', 0, 10)
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

astralGuildInfo = CreateFrame('FRAME', 'AstralGuildInfo', AstralRaidOptionsFrame, "BackdropTemplate")
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

-- Initializations

function addon.InitializeOptionSettings()
  showMinimap:SetChecked(AstralRaidSettings.general.show_minimap_button.isEnabled)

	addon.InitializeDropdown(fontDropdown, fonts, AstralRaidSettings.general.font.name, function(val)
		AstralRaidSettings.general.font.name = val
		addon.UpdateRemindersFonts()
	end)

	guildVersionString:SetFormattedText('Astral - Area 52 (US) %s', addon.CLIENT_VERSION)
end

AstralRaidEvents:Register('PLAYER_LOGIN', addon.InitializeOptionSettings, 'astralRaidInitOptions')

AstralRaidOptionsFrame:SetScript('OnKeyDown', function (self, key)
  if key == 'ESCAPE' then
    self:SetPropagateKeyboardInput(false)
    AstralRaidOptionsFrame:Hide()
  end
end)

AstralRaidOptionsFrame:SetScript('OnShow', function(self)
  self:SetPropagateKeyboardInput(true)
  addon.InitializeOptionSettings()
end)

local function toggle()
	AstralRaidOptionsFrame:SetShown(not AstralRaidOptionsFrame:IsShown())
end

SLASH_ASTRALRAID1 = '/astralraid'
SLASH_ASTRALRAID2 = '/ar'

SlashCmdList['ASTRALRAID'] = toggle