local ADDON_NAME, addon = ...
local L = addon.L

addon.SharedMedia = LibStub('LibSharedMedia-3.0')

addon.Options = {}

AstralRaidOptionsFrame = AstralUI:Template('AstralOptionsFrame', UIParent)
AstralRaidOptionsFrame:Hide()
AstralRaidOptionsFrame:SetPoint('CENTER', 0, 0)
AstralRaidOptionsFrame.HeaderText:SetText(ASTRAL_RAID_TOOLS)
AstralRaidOptionsFrame.HeaderText:SetTextColor(1, .82, 0, 1)
AstralRaidOptionsFrame.GuildInfo.title:SetText(ASTRAL_RAID_TOOLS)
AstralRaidOptionsFrame.GuildInfo.title:SetTextColor(1, .82, 0, 1)
AstralRaidOptionsFrame:SetMovable(true)
AstralRaidOptionsFrame:RegisterForDrag('LeftButton')
AstralRaidOptionsFrame:SetScript('OnDragStart', function(self) self:StartMoving() end)
AstralRaidOptionsFrame:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
AstralRaidOptionsFrame:SetScript('OnKeyDown', function (self, key)
	if key == 'ESCAPE' then
		if not InCombatLockdown() then
			self:SetPropagateKeyboardInput(false)
		end
		AstralRaidOptionsFrame:Hide()
	end
end)
AstralRaidOptionsFrame:SetDontSavePosition(true)

-- Paging

local OPTIONS_FRAME_WIDTH = 1000

local options = AstralRaidOptionsFrame or {}

local framesList = AstralUI:ScrollList(options):LineHeight(24):Size(options.ListWidth - 1, options.Height):Point('TOPLEFT', options.MenuBar, 'TOPRIGHT', 0, 0):HideBorders()
framesList.SCROLL_WIDTH = 10
framesList.LINE_PADDING_LEFT = 7
framesList.LINE_TEXTURE = 'Interface\\Addons\\' .. ADDON_NAME .. '\\Media\\White'
framesList.LINE_TEXTURE_IGNOREBLEND = true
framesList.LINE_TEXTURE_HEIGHT = 24
framesList.LINE_TEXTURE_COLOR_HL = {1, 1, 1, .5}
framesList.LINE_TEXTURE_COLOR_P = {1, .82, 0, .6}
framesList.EnableHoverAnimation = true

framesList.LDisabled = {}
framesList.Frame.ScrollBar:Size(8, 0):Point('TOPRIGHT', 0, 0):Point('BOTTOMRIGHT', 0, 0)
framesList.Frame.ScrollBar.thumb:SetHeight(100)
framesList.Frame.ScrollBar.buttonUP:Hide()
framesList.Frame.ScrollBar.buttonDown:Hide()

options.Frames = {}
options._Frames = {}

local function isDisabled(f)
	return (f.leadProtected and not (addon.IsRaidLead() or addon.IsOfficer() or (f.inParty and addon.IsPartyLead()) or (addon.Debug and AstralRaidSettings.general.debug.showAllMenus))) or (f._disabled and not (addon.Debug and AstralRaidSettings.general.debug.showAllMenus))
end

local function updateFrames()
	options.Frames = {}
	for _, f in pairs(options._Frames) do
		local pos = #options.Frames + 1
		framesList.L[pos] = f.name
		framesList.LDisabled[pos] = isDisabled(f)
		options.Frames[pos] = f
	end
	framesList:Update()
	if options.CurrentFrame and options.CurrentFrame.AdditionalOnShow then
		options.CurrentFrame:AdditionalOnShow()
	end
	if type(options.CurrentFrame.OnShow) == 'function' then
		options.CurrentFrame:OnShow()
	end
end

options:SetScript('OnShow', function(self)
	if not InCombatLockdown() then
		self:SetPropagateKeyboardInput(true)
	end
  addon.InitializeOptionSettings()
	updateFrames()
end)

function options:SetPage(page)
	if options.CurrentFrame then
		options.CurrentFrame:Hide()
	end
	options.CurrentFrame = page
	if options.CurrentFrame.AdditionalOnShow then
		options.CurrentFrame:AdditionalOnShow()
	end

	options.CurrentFrame:Show()

	if options.CurrentFrame.isWide and options.nowWide ~= options.CurrentFrame.isWide then
		local frameWidth = type(options.CurrentFrame.isWide) == 'number' and options.CurrentFrame.isWide or OPTIONS_FRAME_WIDTH
		options:SetWidth(frameWidth + options.ListWidth)
		options.nowWide = options.CurrentFrame.isWide
	elseif not options.CurrentFrame.isWide and options.nowWide then
		options:SetWidth(options.Width)
		options.nowWide = nil
	end

	if options.CurrentFrame.isWide then
		options.CurrentFrame:SetWidth(type(options.CurrentFrame.isWide) == 'number' and options.CurrentFrame.isWide or OPTIONS_FRAME_WIDTH)
	end

	if type(options.CurrentFrame.OnShow) == 'function' then
		options.CurrentFrame:OnShow()
	end
end

function framesList:SetListValue(index)
	options:SetPage(options.Frames[index])
end

function options:Add(moduleName, frameName, leadProtected, inParty, disabled)
	local self = CreateFrame('FRAME', 'AstralRaidOptions' .. moduleName, options)
	self:SetSize(options.ContentWidth - 12, options.Height - 16 - 45)
	self:SetPoint('TOPLEFT', options.MenuBar, 'TOPRIGHT', options.ListWidth + 12, -45)
  	self.moduleName = moduleName
  	self.name = frameName or moduleName
	self.leadProtected = leadProtected
	self.inParty = inParty
	self._disabled = disabled
	options._Frames[#options._Frames+1] = self
	options.Frames[#options.Frames+1] = self

	if options:IsShown() then
		framesList:Update()
	end
	self:Hide()

	return self
end

addon.Options = options

-- General tab

local generalPage = options:Add(GENERAL, GENERAL)
framesList:SetListValue(1)
framesList.selected = 1
framesList:Update()

local generalHeader = AstralUI:Text(generalPage, L['GENERAL_OPTIONS']):Point('TOPLEFT', 0, 0):Shadow()

local showMinimap = AstralUI:Check(generalPage, L['SHOW_MINIMAP_BUTTON']):Point('TOPLEFT', generalHeader, 'BOTTOMLEFT', 0, -10):OnClick(function (self)
	AstralRaidSettings.general.show_minimap_button = self:GetChecked()
	if AstralRaidSettings.general.show_minimap_button then
		addon.icon:Show(ADDON_NAME)
	else
		addon.icon:Hide(ADDON_NAME)
	end
	if IsAddOnLoaded('ElvUI_Enhanced') and ElvUI then -- Update the layout for the minimap buttons
		ElvUI[1]:GetModule('MinimapButtons'):UpdateLayout()
	end
end)

local debugMode = AstralUI:Check(generalPage, WrapTextInColorCode('Debug Mode', 'C1E1C1FF')):Point('LEFT', showMinimap, 'RIGHT', 175, 0):OnClick(function (self)
	AstralRaidSettings.general.debug.isEnabled = self:GetChecked()
end)

local debugShowAllMenus = AstralUI:Check(generalPage, WrapTextInColorCode('Show all menus', 'C1E1C1FF')):Point('LEFT', debugMode, 'RIGHT', 175, 0):OnClick(function (self)
	AstralRaidSettings.general.debug.showAllMenus = self:GetChecked()
	updateFrames()
end)

-- Initializations

function addon.InitializeOptionSettings()
  showMinimap:SetChecked(AstralRaidSettings.general.show_minimap_button)
  debugMode:SetChecked(AstralRaidSettings.general.debug.isEnabled)
  debugShowAllMenus:SetChecked(AstralRaidSettings.general.debug.showAllMenus)
	if not addon.Debug then
		debugMode:Hide()
		debugShowAllMenus:Hide()
	end
	AstralRaidOptionsFrame.GuildText:SetFormattedText(ASTRAL_INFO .. ' %s', addon.CLIENT_VERSION)
end

AstralRaidEvents:Register('GROUP_ROSTER_UPDATE', function() if options:IsShown() then updateFrames() end end, 'GroupRosterUpdateOptions')
AstralRaidEvents:Register('PARTY_LEADER_CHANGED', function() if options:IsShown() then updateFrames() end end, 'PartyLeaderChangedOptions')

local function toggle()
	AstralRaidOptionsFrame:SetShown(not AstralRaidOptionsFrame:IsShown())
end

OpenAstralRaidWindow = toggle

local ldb = LibStub('LibDataBroker-1.1'):NewDataObject(ADDON_NAME, {
	type = 'data source',
	text = ADDON_NAME,
	icon = 'Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\minimap.png',
	OnClick = function(_, button)
		if button == 'LeftButton' then toggle() end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(ASTRAL_RAID_TOOLS)
		tooltip:AddLine(L['TOGGLE_OPTIONS'])
	end,
})

local function onPlayerLogin()
	addon.icon:Register(ADDON_NAME, ldb, {
		hide = not AstralRaidSettings.general.show_minimap_button,
	})
end

AstralRaidEvents:Register('PLAYER_LOGIN', onPlayerLogin, 'Options_PLAYER_LOGIN')

SLASH_ASTRALRAID1 = '/astralraidtools'
SLASH_ASTRALRAID2 = '/astralraid'
SLASH_ASTRALRAID3 = '/art'

SlashCmdList['ASTRALRAID'] = toggle