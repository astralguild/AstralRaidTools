local ADDON_NAME, addon = ...

addon.SharedMedia = LibStub('LibSharedMedia-3.0')

addon.Options = {}

AstralRaidOptionsFrame = AstralUI:Template('AstralOptionsFrame', UIParent)
AstralRaidOptionsFrame:Hide()
AstralRaidOptionsFrame:SetPoint('CENTER', 0, 0)
AstralRaidOptionsFrame.HeaderText:SetText('Astral Raid Tools')
AstralRaidOptionsFrame.HeaderText:SetTextColor(1, .82, 0, 1)
AstralRaidOptionsFrame:SetMovable(true)
AstralRaidOptionsFrame:RegisterForDrag('LeftButton')
AstralRaidOptionsFrame:SetScript('OnDragStart', function(self) self:StartMoving() end)
AstralRaidOptionsFrame:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
AstralRaidOptionsFrame:SetScript('OnKeyDown', function (self, key)
	if key == 'ESCAPE' then
		self:SetPropagateKeyboardInput(false)
		AstralRaidOptionsFrame:Hide()
	end
end)
AstralRaidOptionsFrame:SetDontSavePosition(true)
AstralRaidOptionsFrame.MenuBar.Icon:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\planet.png')

-- Paging

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

options:SetScript('OnShow', function(self)
	self:SetPropagateKeyboardInput(true)
  addon.InitializeOptionSettings()
	options.Frames = {}
	for _, f in pairs(options._Frames) do
		local pos = #options.Frames + 1
		framesList.L[pos] = f.name
		framesList.LDisabled[pos] = f.leadProtected and not (addon.IsRaidLead() or addon.IsOfficer())
		options.Frames[pos] = f
	end
	framesList:Update()
	if options.CurrentFrame and options.CurrentFrame.AdditionalOnShow then
		options.CurrentFrame:AdditionalOnShow()
	end
	if type(options.CurrentFrame.OnShow) == 'function' then
		options.CurrentFrame:OnShow()
	end
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
		local frameWidth = type(options.CurrentFrame.isWide)=='number' and options.CurrentFrame.isWide or 850
		options:SetWidth(frameWidth+options.ListWidth)
		options.nowWide = options.CurrentFrame.isWide
	elseif not options.CurrentFrame.isWide and options.nowWide then
		options:SetWidth(options.Width)
		options.nowWide = nil
	end

	if options.CurrentFrame.isWide then
		options.CurrentFrame:SetWidth(type(options.CurrentFrame.isWide)=='number' and options.CurrentFrame.isWide or 850)
	end

	if type(options.CurrentFrame.OnShow) == 'function' then
		options.CurrentFrame:OnShow()
	end
end

function framesList:SetListValue(index)
	options:SetPage(options.Frames[index])
end

function options:Add(moduleName, frameName, leadProtected)
	local self = CreateFrame('FRAME', 'AstralRaidOptions' .. moduleName, options)
	self:SetSize(options.ContentWidth - 12, options.Height - 16 - 45)
	self:SetPoint('TOPLEFT', options.MenuBar, 'TOPRIGHT', options.ListWidth + 12, -45)
  self.moduleName = moduleName
  self.name = frameName or moduleName
	self.leadProtected = leadProtected
	options._Frames[#options._Frames+1] = self
	options.Frames[#options.Frames+1] = self

	if options:IsShown() then
		framesList:Update()
	end
	self:Hide()

	return self
end

addon.Options = options

local generalPage = options:Add('General', 'General')
framesList:SetListValue(1)
framesList.selected = 1
framesList:Update()

local generalHeader = AstralUI:Text(generalPage, 'General Options'):Point('TOPLEFT', 0, 0):Shadow()

local showMinimap = AstralUI:Check(generalPage, 'Show Minimap Button'):Point('TOPLEFT', generalHeader, 'BOTTOMLEFT', 0, -10):OnClick(function (self)
	AstralRaidSettings.general.show_minimap_button.isEnabled = self:GetChecked()
	if AstralRaidSettings.general.show_minimap_button.isEnabled then
		addon.icon:Show(ADDON_NAME)
	else
		addon.icon:Hide(ADDON_NAME)
	end
	if IsAddOnLoaded('ElvUI_Enhanced') then -- Update the layout for the minimap buttons
		ElvUI[1]:GetModule('MinimapButtons'):UpdateLayout()
	end
end)

-- Initializations

function addon.InitializeOptionSettings()
  showMinimap:SetChecked(AstralRaidSettings.general.show_minimap_button.isEnabled)
	AstralRaidOptionsFrame.GuildText:SetFormattedText('Astral - Area 52 (US) %s', addon.CLIENT_VERSION)
end

AstralRaidEvents:Register('PLAYER_LOGIN', addon.InitializeOptionSettings, 'astralRaidInitOptions')

local function toggle()
	AstralRaidOptionsFrame:SetShown(not AstralRaidOptionsFrame:IsShown())
end

OpenAstralRaidWindow = toggle

local ldb = LibStub('LibDataBroker-1.1'):NewDataObject(ADDON_NAME, {
	type = 'data source',
	text = ADDON_NAME,
	icon = 'Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\icon.png',
	OnClick = function(_, button)
		if button == 'LeftButton' then
			toggle()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine('Astral Raid Tools')
		tooltip:AddLine('Left click to toggle options window')
	end,
})
addon.icon = LibStub('LibDBIcon-1.0')

function addon:OnInitialize()
	addon.LoadDefaultSettings()

	self.db = LibStub('AceDB-3.0'):New('AstralRaidMinimap', {
		profile = {
			minimap = {
				hide = not AstralRaidSettings.general.show_minimap_button.isEnabled,
			},
		},
	})
	addon.icon:Register(ADDON_NAME, ldb, self.db.profile.minimap)
end

SLASH_ASTRALRAID1 = '/astralraidtools'
SLASH_ASTRALRAID2 = '/astralraid'
SLASH_ASTRALRAID3 = '/art'

SlashCmdList['ASTRALRAID'] = toggle