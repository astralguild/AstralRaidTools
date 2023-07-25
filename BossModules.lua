local ADDON_NAME, addon = ...
local L = addon.L

local ABERRUS = 2166
local NELTH = 2684

local log = LibStub('AceDB-3.0'):New('AstralRaidBossModulesLog')

local function getAnnounceChannel(announceType)
	if announceType == 1 then
		return (addon.InInstance and not UnitIsDeadOrGhost('player')) and 'SAY' or 'PRINT'
	elseif announceType == 2 then
		return addon.GetInstanceChannel() or 'PRINT'
	elseif announceType == 3 then
		return 'OFFICER'
	elseif announceType == 4 then
		return 'PRINT'
	end
end

local function announce(print, channel, msg)
	if print then
		addon.Console(msg)
	end
	if channel then
		SendChatMessage(msg, channel)
	end
end

local function sendMessage(m, msg)
	local channel = getAnnounceChannel(m.announce)
	local print = m.printResults
	announce(print, channel, msg)
end

local bdgNelthHeartMacro, bdgNealthHeartMacroPressed, bdgNelthHeartCast, bdgNelthHeartInit, bdgNelthShowHeartIcon

local bossModules = {
	[NELTH] = {
		events = {
			['ENCOUNTER_START'] = bdgNelthHeartInit,
			['UNIT_SPELLCAST_SUCCEEDED'] = bdgNelthHeartCast,
			['CHAT_MSG_ADDON'] = bdgNelthHeartMacro,
		},
		heartSet = 1,
		lastHeartTime = nil,
		debuffs = {},
		settings = nil,
		frame = nil,
		privateAura = nil,
	},
}

local privateAuraAnchors = {
	['LARGE'] = {},
	['SMALL'] = {},
}

local function privateAuraOnShow(self)
	if self.privateAura then
		C_UnitAuras.RemovePrivateAuraAnchor(self.privateAura)
	end
	local privateAnchorArgs = {
		unitToken = 'player',
		auraIndex = 1,
		parent = self,
		showCountdownFrame = true,
		showCountdownNumbers = true,
		iconInfo = {
			iconAnchor = {
				point = 'CENTER',
				relativeTo = self,
				relativePoint = 'CENTER',
				offsetX = 0,
				offsetY = 0
			},
			iconWidth = self:GetWidth(),
			iconHeight = self:GetHeight()
		}
	}
	self.privateAura = C_UnitAuras.AddPrivateAuraAnchor(privateAnchorArgs)
end

bdgNelthHeartMacro = function(...)
	local prefix, text, _, sender = ...
	local m = bossModules[NELTH]
	if addon.Encounter.difficultyID ~= 16 or (not addon.Debug) then return end
	if prefix == 'BDG_NELTH_HEART' and text == 'heart' then
		if m.settings.isEnabled then
			bdgNealthHeartMacroPressed(Ambiguate(sender, 'short'))
			if #m.debuffs == 5 then
				sendMessage(m, string.format(L['BDG_NELTH_HEART_SET_MESSAGE'], m.heartSet, GetTime() - m.lastHeartTime))
				if m.heartSet == 10 then
					m.lastHeartTime = GetTime()
				end
			end
			if Ambiguate(sender, 'short') == UnitName('player') and m.settings.showIcon and m.frame and m.frame:IsShown() then
				m.frame.pressed = true
				m.frame:Hide()
			end
		end
	end
end

bdgNealthHeartMacroPressed = function(player)
	local m = bossModules[NELTH]
	tInsertUnique(m.debuffs, player)
	local heart = {
		player = player,
		date = date('%x'),
		pull = log.bdgNelthHeart.pullCount or 1,
		time = date('%H:%M:%S %p'),
		set = m.heartSet,
		index = #m.debuffs,
	}
	if m.lastHeartTime then
		heart.pressedAt = GetTime() - m.lastHeartTime
	end
	if m.settings.logResults then
		table.insert(log.bdgNelthHeart.hearts, heart)
	end
	if heart.pressedAt then
		sendMessage(m, string.format(L['BDG_NELTH_HEART_PRESSED_MESSAGE'], heart.set, heart.index, player, heart.time, heart.pressedAt))
	else
		sendMessage(m, string.format(L['BDG_NELTH_HEART_PRESSED_MESSAGE_UNKNOWN_TIME'], heart.set, heart.index, player, heart.time))
	end
end

bdgNelthHeartCast = function(...)
	local spellID = select(3, ...)
	local m = bossModules[NELTH]
	if spellID == 410968 then -- Volcanic Heart
		m.lastHeartTime = GetTime()
		m.heartSet = m.heartSet + 1
		m.debuffs = {}
		bdgNelthShowHeartIcon()
	elseif spellID == 407207 then -- Rushing Darkness
		if m.settings.showIcon and m.frame:IsShown() then
			m.frame:Hide()
			C_Timer.After(5.1, function()
				if GetTime() - m.lastHeartTime < 7 then
					m.frame:Show()
				end
			end)
		end
	end
end

bdgNelthShowHeartIcon = function()
	local m = bossModules[NELTH]
	if addon.Encounter.difficultyID ~= 16 and not addon.Debug then return end
	if m.settings.showIcon then
		m.frame:Show()
		C_Timer.After(7, function()
			if m.frame:IsShown() then
				m.frame:Hide()
			end
		end)
	end
end

bdgNelthHeartInit = function(...)
	if not log.bdgNelthHeart then
		log.bdgNelthHeart = {}
	end
	if not log.bdgNelthHeart.hearts then
		log.bdgNelthHeart.hearts = {}
	end

	local m = bossModules[NELTH]
	m.heartSet = 1
	log.bdgNelthHeart.pullCount = log.bdgNelthHeart.pullCount + 1
	m.lastHeartTime = nil
	m.debuffs = {}
	m.settings = AstralRaidSettings.bossModules[NELTH]

	if not m.frame and m.settings.showIcon then
		m.frame = privateAuraAnchors['LARGE']
		m.frame:SetScript('OnShow', function(self)
			m.frame.pressed = false
			privateAuraOnShow(self)
		end)
		m.frame:SetScript('OnHide', function(self)
			if m.privateAura then
				C_UnitAuras.RemovePrivateAuraAnchor(m.privateAura)
			end
			if self.pressed and m.lastHeartTime then
				addon.Console(string.format(L['BDG_NELTH_HEART_PRESSED_MESSAGE_PERSONAL'] , GetTime() - m.lastHeartTime))
			elseif self.pressed then
				addon.Console(L['BDG_NELTH_HEART_PRESSED_MESSAGE_PERSONAL_UNKNOWN_TIME'])
			end
		end)
	end
end

local function handle(e, ...)
	if not (IsInGroup() or IsInRaid()) then return end
	if not (addon.InInstance and addon.InEncounter and bossModules[addon.Encounter.encounterID]) then return end

	local m = bossModules[addon.Encounter.encounterID]
	if m.events and m.events[e] then
		m.events[e](...)
	end
end

AstralRaidEvents:Register('UNIT_SPELLCAST_SUCCEEDED', function(...) handle('UNIT_SPELLCAST_SUCCEEDED', ...) end, 'astralRaidBossModulesUnitSpellcastSucceeded')
AstralRaidEvents:Register('CHAT_MSG_ADDON', function(...) handle('CHAT_MSG_ADDON', ...) end, 'astralRaidBossModulesChatMsgAddon')
AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', function(...) handle('COMBAT_LOG_EVENT_UNFILTERED', GetCurrentCombatTextEventInfo()) end, 'astralRaidBossModulesCLEU')
AstralRaidEvents:Register('ENCOUNTER_START', function(...) handle('ENCOUNTER_START', ...) end, 'astralRaidBossModulesEncounterStart')

local function initPrivateAuraAnchors()
	local frame = CreateFrame('FRAME', nil, UIParent)
	frame:SetHeight(AstralRaidSettings.bossModules.privateAuras.largeIconSize)
	frame:SetWidth(AstralRaidSettings.bossModules.privateAuras.largeIconSize)
	frame:SetAlpha(0.75)
	frame:SetPoint('BOTTOM', UIParent, 'CENTER', 0, 20)
	frame:Hide()
	privateAuraAnchors['LARGE'] = frame

	-- frame = CreateFrame('FRAME', nil, UIParent)
	-- frame:SetHeight(AstralRaidSettings.bossModules.privateAuras.smallIconSize)
	-- frame:SetWidth(AstralRaidSettings.bossModules.privateAuras.smallIconSize)
	-- frame:SetAlpha(0.75)
	-- frame:SetPoint('BOTTOM', UIParent, 'CENTER', 0, 20)
	-- frame:Hide()
	-- privateAuraAnchors['SMALL'] = frame
end

function AstralRaidLibrary:L()
	return log
end

AstralRaidEvents:Register('ADDON_LOADED', function(addonName)
	if addonName == ADDON_NAME then
		initPrivateAuraAnchors()
	end
end, 'AstralRaidBossModulesInit')

local module = addon:New('Boss Modules', 'Boss Modules', false, false, true) -- disabled for now until tested
local instanceDropdown, encounterList, setContent

local nelthHeartMacroEnableCheckbox, nelthHeartMacroPrintCheckbox, nelthHeartMacroLogCheckbox, nelthHeartMacroAnnounceDropdown, nelthHeartIconEnableCheckbox, nelthHeartIconSizeSlider

local announceKinds = {[1] = 'Say', [2] = 'Group', [3] = 'Officer', [4] = 'Print', [5] = 'None'}
local currentInstance = ABERRUS
local currentEncounter = NELTH

function module.options:Load()
	local frames = {
		[ABERRUS] = {}
	}
	local instances = {}
	local encounters = addon.GetEncountersList(true, true)
	for i = 1, #encounters do
		local instance = encounters[i]
		if not instances[instance[1]] then
			instances[instance[1]] = {}
		end
		for j = 2, #instance do
			if not instances[instance[1]].encounters then
				instances[instance[1]].encounters = {}
			end
			table.insert(instances[instance[1]].encounters, instance[j])
		end
	end

	setContent = function()
		if not currentInstance or not frames[currentInstance] then return end
		if not instances[currentInstance].encounters[encounterList.selected] and currentEncounter then
			for i = 1, #instances[currentInstance].encounters do
				local encounterID = instances[currentInstance].encounters[i]
				if encounterID == currentEncounter then
					encounterList.selected = i
				end
			end
		end

		for _, i in pairs(frames) do
			for _, f in pairs(i) do
				f:Hide()
			end
		end
		local encounterID = instances[currentInstance].encounters[encounterList.selected]
		currentEncounter = encounterID
		if frames[currentInstance][encounterID] then
			frames[currentInstance][encounterID]:Show()
		end
	end

	local function updateList()
		if not currentInstance then return end
		local first
		encounterList.L = {}
		encounterList.LDisabled = {}
		for i = 1, #instances[currentInstance].encounters do
			local encounterID = instances[currentInstance].encounters[i]
			if (not first) and frames[currentInstance] and frames[currentInstance][encounterID] then
				first = i
			end
			encounterList.L[i] = addon.GetBossName(encounterID)
			encounterList.LDisabled[i] = not (frames[currentInstance] and frames[currentInstance][encounterID])
		end
		encounterList:Update()
		if first then
			encounterList.selected = first
		end
		setContent()
	end

  local function instanceDropdownSetValue(_, instance)
		instanceDropdown:SetText(type(instance) == 'string' and instance or (C_Map.GetMapInfo(instance or 0) or {}).name or '???')
		currentInstance = instance
		updateList()
		AstralUI:DropDownClose()
	end

  local specificHeader = AstralUI:Text(self, L['BOSS_MODULES']):Point('TOPLEFT', 0, 0):Size(200, 12):Shadow()

  instanceDropdown = AstralUI:DropDown(self, 400, 25):AddText(L['RAID'] .. ':'):Point('LEFT', specificHeader, 'RIGHT', 10, 0):Size(400):SetText('-')
  do
		local list = instanceDropdown.List
		for i = 1, #encounters do
			local instance = encounters[i]
			if frames[instance[1]] then
				list[#list+1] = {
					text = (type(instance[1]) == 'string' and instance[1] or (C_Map.GetMapInfo(instance[1] or 0) or {}).name or '???'),
					arg1 = instance[1],
					func = instanceDropdownSetValue,
				}
			end
		end
	end
  instanceDropdown:HideBorders()
	instanceDropdown.Background:Hide()
	instanceDropdown.Background:SetPoint('BOTTOMRIGHT', 0, 1)
	instanceDropdown.Background:SetColorTexture(1, 1, 1, .3)
	instanceDropdown.Text:SetJustifyH('RIGHT')
	instanceDropdown:SetScript('OnMouseDown',function(self)
		self.Button:Click()
	end)
	instanceDropdown:SetScript('OnEnter',function(self)
		self.Background:Show()
	end)
	instanceDropdown:SetScript('OnLeave',function(self)
		self.Background:Hide()
	end)

	encounterList = AstralUI:ScrollList(self):Size(200, 450):Point('TOPLEFT', specificHeader, 'BOTTOMLEFT', 0, -20):HideBorders()
	encounterList.SCROLL_WIDTH = 12

  encounterList:SetScript('OnShow',function(self)
		updateList()
	end)

	function encounterList:SetListValue(index)
		local encounters = instances[currentInstance].encounters
		if not encounters then return end
		setContent()
	end

	-- Aberrus
	frames[ABERRUS][NELTH] = CreateFrame('FRAME', nil, self)
	frames[ABERRUS][NELTH]:SetPoint('TOPLEFT', encounterList, 'TOPRIGHT', 10, 0)
	frames[ABERRUS][NELTH]:SetSize(400, 430)
	frames[ABERRUS][NELTH]:Hide()

  local nelthHeartHeader = AstralUI:Text(frames[ABERRUS][NELTH], L['BDG_NELTH_HEART_TITLE']):Point('TOPLEFT', 0, 0):Shadow()

  nelthHeartMacroEnableCheckbox = AstralUI:Check(frames[ABERRUS][NELTH], L['ENABLE_NOTIFIER']):Point('TOPLEFT', nelthHeartHeader, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.bossModules[NELTH].isEnabled = self:GetChecked()
  end)

  nelthHeartMacroPrintCheckbox = AstralUI:Check(frames[ABERRUS][NELTH], L['PRINT_RESULTS']):Point('LEFT', nelthHeartMacroEnableCheckbox, 'RIGHT', 100, 0):OnClick(function(self)
    AstralRaidSettings.bossModules[NELTH].printResults = self:GetChecked()
  end)

	nelthHeartMacroLogCheckbox = AstralUI:Check(frames[ABERRUS][NELTH], L['LOG_TO_DISK']):Point('LEFT', nelthHeartMacroPrintCheckbox, 'RIGHT', 100, 0):OnClick(function(self)
    AstralRaidSettings.bossModules[NELTH].logResults = self:GetChecked()
  end)

	local function nelthHeartMacroAnnounceDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		nelthHeartMacroAnnounceDropdown:SetText(announceKinds[arg1])
    AstralRaidSettings.earlypull.announce.earlyPull = arg1
	end

	nelthHeartMacroAnnounceDropdown = AstralUI:DropDown(frames[ABERRUS][NELTH], 200, 10):Size(250):Point('TOPLEFT', nelthHeartMacroEnableCheckbox, 'BOTTOMLEFT', 0, -20):AddText("|cffffce00Announce To:")
	for i = 1, #announceKinds do
		if i ~= 4 then
			local info = {}
			nelthHeartMacroAnnounceDropdown.List[i] = info
			info.text = announceKinds[i]
			info.arg1 = i
			info.func = nelthHeartMacroAnnounceDropdownSetValue
			info.justifyH = 'CENTER'
		end
	end

	local nelthHeartDesc = AstralUI:Text(frames[ABERRUS][NELTH], string.format(L['BDG_NELTH_HEART_DESC'], WrapTextInColorCode('BDG/Angered - Neltharion Portal+Heart Map', 'D1FFADAD'))):Point('TOPLEFT', nelthHeartMacroAnnounceDropdown, 'BOTTOMLEFT', 0, -20):FontSize(9):Shadow()

	nelthHeartIconEnableCheckbox = AstralUI:Check(frames[ABERRUS][NELTH], L['BDG_NELTH_HEART_ENABLE_ICON']):Point('TOPLEFT', nelthHeartDesc, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.bossModules[NELTH].showIcon = self:GetChecked()
  end)

  nelthHeartIconSizeSlider = AstralUI:Slider(frames[ABERRUS][NELTH], L['ICON_SIZE']):Size(200):Point('LEFT', nelthHeartIconEnableCheckbox, 'RIGHT', 150, 0):Range(256,512)

	local vhLink, _ = GetSpellLink(410953)
	local nelthHeartIconDesc = AstralUI:Text(frames[ABERRUS][NELTH], string.format(L['BDG_NELTH_HEART_ICON_DESC'], vhLink)):Point('TOPLEFT', nelthHeartIconEnableCheckbox, 'BOTTOMLEFT', 0, -20):FontSize(9):Shadow()

	local selected = nil
	for i = 1, #encounters do
		local instance = encounters[i]
		if frames[instance[1]] then
			selected = instance[1]
		end
	end
	if selected then instanceDropdownSetValue(_, selected) end
	updateList()
end

function module.options:OnShow()
  nelthHeartMacroEnableCheckbox:SetChecked(AstralRaidSettings.bossModules[NELTH].isEnabled)
  nelthHeartMacroPrintCheckbox:SetChecked(AstralRaidSettings.bossModules[NELTH].printResults)
  nelthHeartMacroLogCheckbox:SetChecked(AstralRaidSettings.bossModules[NELTH].logResults)
	nelthHeartMacroAnnounceDropdown:SetText(announceKinds[AstralRaidSettings.bossModules[NELTH].announce])
	nelthHeartIconEnableCheckbox:SetChecked(AstralRaidSettings.bossModules[NELTH].showIcon)
	nelthHeartIconSizeSlider:SetTo(AstralRaidSettings.bossModules.privateAuras.largeIconSize):OnChange(function(self, event)
		event = event - event % 1
		AstralRaidSettings.bossModules.privateAuras.largeIconSize = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	setContent()
end