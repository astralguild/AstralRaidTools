local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

AstralRaidOptionsFrame = addon.OptionsFrame('AstralRaidOptionsFrame')
local contentFrame = AstralRaidOptionsFrame.contentFrame

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
	addon.TestTexts(testReminders)
end)

-- Initializations

function addon.InitializeOptionSettings()
  showMinimap:SetChecked(AstralRaidSettings.general.show_minimap_button.isEnabled)

	addon.InitializeDropdown(fontDropdown, fonts, AstralRaidSettings.general.font.name, function(val)
		AstralRaidSettings.general.font.name = val
		addon.UpdateRemindersFonts()
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