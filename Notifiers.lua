local _, addon = ...
local L = addon.L

local function auraTrigger(e, _, m, _, name, ...)
	local encounterID = addon.Encounter.encounterID
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_AURA_APPLIED' then -- SPELL_AURA_APPLIED_DOSE for stacks
		local auras = AstralRaidSettings.notifiers.encounters[encounterID].auras
		local spellID = select(7, ...)
		for auraSpellID, tracked in pairs(auras) do
			if tracked and auraSpellID == spellID then
				return {
					spellID = spellID,
					encounterID = encounterID,
					encounterStart = addon.Encounter.start,
					unit = UnitName(name),
					date = date('%x'),
					time = date('%H:%M:%S %p'),
				}
			end
		end
  end
end

local function auraNotifier(trigger)
  local link, _ = GetSpellLink(trigger.spellID)
  addon.Console(string.format(L['AURA_NOTIFIER_MSG'], addon.ClassColorName(trigger.unit), link, trigger.time))
end

local function castTrigger(e, ...)
	local encounterID = addon.Encounter.encounterID
  if e == 'UNIT_SPELLCAST_SUCCEEDED' then
		local casts = AstralRaidSettings.notifiers.encounters[encounterID].casts
		local spellID = select(3, ...)
		for castSpellID, tracked in pairs(casts) do
			if tracked and castSpellID == spellID then
				return {
					target = select(1, ...),
					guid = select(2, ...),
					spellID = spellID,
					encounterID = encounterID,
					encounterStart = addon.Encounter.start,
					date = date('%x'),
					time = date('%H:%M:%S %p'),
				}
			end
		end
  end
end

local function castNotifier(trigger)
  local link, _ = GetSpellLink(trigger.spellID)
	local name = 'Boss'
	local target = UnitName(trigger.target) or 'Unknown'
	for i = 1, MAX_BOSS_FRAMES do
		local guid = UnitGUID('boss'..i)
		if guid and guid == trigger.castGUID then
			name = UnitName('boss'..i) or 'Boss'
		end
 	end
  addon.Console(string.format(L['CAST_NOTIFIER_MSG'], name, link, target, trigger.time))
end

local events = {
	['cleu'] = {
		{f = auraTrigger, n = auraNotifier},
	},
	['unitSpellcastSucceeded'] = {
		{f = castTrigger, n = castNotifier},
	},
}

local function isTrackedEncounter()
	if not (AstralRaidSettings.notifiers.general.isEnabled) then return false end
	if not (addon.InEncounter and AstralRaidSettings.notifiers.encounters[addon.Encounter.encounterID]) then return false end
	return true
end

local function handle(e, event, ...)
  local trigger = e.f(event, ...)
  if trigger then
		e.n(trigger)
  end
end

local function cleu(...)
	if not isTrackedEncounter() then return end
	local info = CombatLogGetCurrentEventInfo()
  for _, e in pairs(events.cleu) do
		handle(e, 'COMBAT_LOG_EVENT_UNFILTERED', info)
	end
end

local function unitSpellcastSucceeded(...)
	if not isTrackedEncounter() then return end
  for _, e in pairs(events.unitSpellcastSucceeded) do
		handle(e, 'UNIT_SPELLCAST_SUCCEEDED', ...)
	end
end

AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'astralRaidNotifiersCLEU')
AstralRaidEvents:Register('UNIT_SPELLCAST_SUCCEEDED', unitSpellcastSucceeded, 'astralRaidNotifiersUnitSpellcastSucceeded')

local module = addon:New(L['NOTIFIERS'], L['NOTIFIERS'], true)
local enableCheckbox, toConsoleCheckbox, toOfficerCheckbox, toRaidCheckbox, encounterList, specificHeader, instanceDropdown, encounterDetailsList
local currentInstance = nil

function module.options:Load()
  local header = AstralUI:Text(self, L['NOTIFIERS']):Point('TOPLEFT', 0, 0):Shadow()

  enableCheckbox = AstralUI:Check(self, ENABLE):Point('TOPLEFT', header, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.notifiers.general.isEnabled = self:GetChecked()
  end)

  toConsoleCheckbox = AstralUI:Check(self, L['SEND_TO_LOCAL'] .. ' ' .. CHAT):Point('LEFT', enableCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toConsole = self:GetChecked()
  end)

  toOfficerCheckbox = AstralUI:Check(self, L['SEND_TO_OFFICER']):Point('LEFT', toConsoleCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toOfficer = self:GetChecked()
  end)

  toRaidCheckbox = AstralUI:Check(self, L['SEND_TO_GROUP']):Point('LEFT', toOfficerCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toRaid = self:GetChecked()
  end)

	local desc = AstralUI:Text(self, L['NOTIFIERS_DESC']):Point('TOPLEFT', enableCheckbox, 'BOTTOMLEFT', 0, -10):FontSize(9):Shadow()

  specificHeader = AstralUI:Text(self, L['ENCOUNTER_NOTIFIERS']):Point('TOPLEFT', desc, 'BOTTOMLEFT', 0, -20):Size(200, 12)

  local function updateList()
		if not currentInstance then return end
		local first

		encounterList.L = {}
		for i = 1, #AstralRaidSettings.notifiers.instances[currentInstance].encounters do
			local encounterID = AstralRaidSettings.notifiers.instances[currentInstance].encounters[i]
			if not first then
				first = encounterID
			end
			encounterList.L[i] = addon.GetBossName(encounterID)
		end
		encounterList:Update()
		encounterDetailsList:Update()
	end

  local function instanceDropdown_SetValue(_, instance)
		instanceDropdown:SetText(type(instance) == 'string' and instance or (C_Map.GetMapInfo(instance or 0) or {}).name or '???')
		currentInstance = instance
		updateList()
		AstralUI:DropDownClose()
	end

  instanceDropdown = AstralUI:DropDown(self, 400, 25):AddText('Raid:'):Point('LEFT', specificHeader, 'RIGHT', 10, 0):Size(400):SetText('-')
  do
		local list = instanceDropdown.List
		local encounters = addon.GetEncountersList(true, true)
		for i = 1, #encounters do
			local instance = encounters[i]
			list[#list+1] = {
				text = type(instance[1]) == 'string' and instance[1] or (C_Map.GetMapInfo(instance[1] or 0) or {}).name or '???',
				arg1 = instance[1],
				func = instanceDropdown_SetValue,
			}
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
		local encounters = AstralRaidSettings.notifiers.instances[currentInstance].encounters
		if not encounters then return end
		encounterDetailsList:Update()
	end

	updateList()

	encounterDetailsList = AstralUI:ScrollFrame(self):Point('TOPLEFT', encounterList, 'TOPRIGHT', 10, 0):Size(400, 430)
	encounterDetailsList.lines = {}
  encounterDetailsList.list = {}
  for i = 1, ceil(400/32) do
    local line = CreateFrame('FRAME', nil, encounterDetailsList.C)
    encounterDetailsList.lines[i] = line
    line:SetPoint('TOPLEFT', 0, -(i-1)*32)
    line:SetPoint('RIGHT', 0, 0)
    line:SetHeight(32)
		line.detailType = 'SPELL'
		line.icon = AstralUI:Icon(line, nil, 16):Point('LEFT', 10, 0)
		line.spellName = AstralUI:Text(line):Size(225, 10):FontSize(10):Point('LEFT', line.icon, 'RIGHT', 5, 0):Shadow()
    line.castChk = AstralUI:Check(line, L['CAST']):Point('LEFT', line.spellName, 'RIGHT', 5, 0):OnClick(function(self)
			local index = AstralRaidSettings.notifiers.instances[currentInstance].encounters[encounterList.selected]
			if self.disabled then
				AstralRaidSettings.notifiers.encounters[index].casts[self:GetParent().data.spell] = nil
				if self:GetChecked() then
					self:SetChecked(false)
				end
			elseif self:GetChecked() then
				AstralRaidSettings.notifiers.encounters[index].casts[self:GetParent().data.spell] = true
			else
				AstralRaidSettings.notifiers.encounters[index].casts[self:GetParent().data.spell] = nil
			end
		end)
    line.auraChk = AstralUI:Check(line, L['AURA']):Point('LEFT', line.castChk, 'RIGHT', 40, 0):OnClick(function(self)
			local index = AstralRaidSettings.notifiers.instances[currentInstance].encounters[encounterList.selected]
			if self.disabled then
				AstralRaidSettings.notifiers.encounters[index].auras[self:GetParent().data.spell] = nil
				if self:GetChecked() then
					self:SetChecked(false)
				end
			elseif self:GetChecked() then
				AstralRaidSettings.notifiers.encounters[index].auras[self:GetParent().data.spell] = true
			else
				AstralRaidSettings.notifiers.encounters[index].auras[self:GetParent().data.spell] = nil
			end
		end)
    line:Hide()
  end

	function encounterDetailsList:Update()
    AstralUI:UpdateScrollList(self, 32, function(self)
			local index = AstralRaidSettings.notifiers.instances[currentInstance].encounters[encounterList.selected]
			local encounter = AstralRaidSettings.notifiers.encounters[index]
			local list = {}
			local spells = addon.GetBossAbilities(index) or {}
			for i = 1, #spells do
				local name, _, icon, _, _, _, _, _ = GetSpellInfo(spells[i])
				list[#list+1] = {
					spell = spells[i],
					name = name or UNKNOWN,
					icon = icon,
					tracked = {aura = encounter.auras[spells[i]], cast = encounter.casts[spells[i]]},
				}
			end
			self.list = list
		end,
		function(line, data)
			line.icon.texture:SetTexture(data.icon)
      line.spellName:SetText(string.format('%s (ID: |cfff5e4a8%s|r)', data.name, tostring(data.spell)))
      line.castChk:SetChecked(data.tracked.cast)
      line.auraChk:SetChecked(data.tracked.aura)
    end)
  end

	encounterDetailsList:SetScript('OnShow', function()
    encounterDetailsList:Update()
  end)

  encounterDetailsList.ScrollBar.slider:SetScript('OnValueChanged', function(self)
    self:GetParent():GetParent():Update()
    self:UpdateButtons()
  end)
end

function module.options:OnShow()
  enableCheckbox:SetChecked(AstralRaidSettings.notifiers.general.isEnabled)
  toConsoleCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toConsole)
  toOfficerCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toOfficer)
  toRaidCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toRaid)
end