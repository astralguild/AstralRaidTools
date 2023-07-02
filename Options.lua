local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

AstralRaidOptionsFrame = AstralUI:OptionsFrame('AstralRaidOptionsFrame', 'planet')
local contentFrame = AstralRaidOptionsFrame.contentFrame

local generalHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
generalHeader:SetText('General Options')
generalHeader:SetPoint('TOPLEFT', contentFrame, 'TOPLEFT')

local showMinimap = AstralUI:Checkbox(contentFrame, 'Show Minimap Button')
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
local fontDropdown = AstralUI:Dropdown(contentFrame, 'Font', 200)
fontDropdown:SetPoint('TOPLEFT', remindersHeader, 'BOTTOMLEFT', 10, -10)

local fontSizeSlider = AstralUI:Slider(contentFrame, 'Font Size'):Size(200):Point('LEFT', fontDropdown, 'RIGHT', 10, 0):Range(5,120)

local testReminders = false
local testRemindersButton = CreateFrame('BUTTON', 'AstralRaidsTestRemindersButton', contentFrame, "UIPanelButtonTemplate")
testRemindersButton:SetPoint('TOPLEFT', fontDropdown, 'BOTTOMLEFT', 0, -10)
testRemindersButton:SetSize(200, 20)
testRemindersButton:SetText('Test Reminders')
testRemindersButton:SetScript('OnClick', function()
	testReminders = not testReminders
	addon.TestTexts(testReminders, 5)
end)

-- Initializations

function addon.InitializeOptionSettings()
  showMinimap:SetChecked(AstralRaidSettings.general.show_minimap_button.isEnabled)

	AstralUI:InitializeDropdown(fontDropdown, fonts, AstralRaidSettings.general.font.name, function(val)
		AstralRaidSettings.general.font.name = val
		addon.UpdateTextsFonts()
	end)

	fontSizeSlider:SetTo(AstralRaidSettings.general.font.size):OnChange(function(self, event)
		event = event - event%1
		AstralRaidSettings.general.font.size = event
		addon.UpdateTextsFonts()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	AstralRaidOptionsFrame.guildText:SetFormattedText('Astral - Area 52 (US) %s', addon.CLIENT_VERSION)
end

AstralRaidEvents:Register('PLAYER_LOGIN', addon.InitializeOptionSettings, 'astralRaidInitOptions')

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