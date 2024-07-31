local _, addon = ...
local L = addon.L
local GetSpellLink = C_Spell.GetSpellLink

local function auraTrigger(e, _, m, _, name, ...)
	local encounterID = addon.Encounter.encounterID
	if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_AURA_APPLIED' then -- SPELL_AURA_APPLIED_DOSE for stacks
		local auras = EncounterSettings(encounterID).auras
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
		local casts = EncounterSettings(encounterID).casts
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
	if not addon.InEncounter then return false end
	if next(EncounterSettings(addon.Encounter.encounterID).auras) == nil
			and next(EncounterSettings(addon.Encounter.encounterID).casts) == nil then
		return false
	end
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

local function EncounterSettings(dungeonEncounterID)
	if not AstralRaidSettings.notifiers.encounters[dungeonEncounterID] then
		AstralRaidSettings.notifiers.encounters[dungeonEncounterID] = {
			auras = {},
			casts = {},
		}
	end
	return AstralRaidSettings.notifiers.encounters[dungeonEncounterID]
end

AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'NotifiersCLEU')
AstralRaidEvents:Register('UNIT_SPELLCAST_SUCCEEDED', unitSpellcastSucceeded, 'NotifiersUnitSpellcastSucceeded')

local module = addon:New(L['NOTIFIERS'], L['NOTIFIERS'], true)
local enableCheckbox, toConsoleCheckbox, toOfficerCheckbox, toRaidCheckbox, encounterList, specificHeader, instanceDropdown, encounterDetailsList
local currentInstance = nil

function module.options:Load()
	local header = AstralUI:Text(self, L['NOTIFIERS']):Point('TOPLEFT', 0, 0):Shadow()
	enableCheckbox = AstralUI:Check(self, ENABLE)
			:Point('TOPLEFT', header, 'BOTTOMLEFT', 0, -20)
			:OnClick(function(self)
				AstralRaidSettings.notifiers.general.isEnabled = self:GetChecked()
			end)
	toConsoleCheckbox = AstralUI:Check(self, L['SEND_TO_LOCAL'] .. ' ' .. CHAT)
			:Point('LEFT', enableCheckbox, 'RIGHT', 150, 0)
			:OnClick(function(self)
				AstralRaidSettings.notifiers.general.toConsole = self:GetChecked()
			end)
	toOfficerCheckbox = AstralUI:Check(self, L['SEND_TO_OFFICER'])
			:Point('LEFT', toConsoleCheckbox, 'RIGHT', 150, 0)
			:OnClick(function(self)
				AstralRaidSettings.notifiers.general.toOfficer = self:GetChecked()
			end)
	toRaidCheckbox = AstralUI:Check(self, L['SEND_TO_GROUP'])
			:Point('LEFT', toOfficerCheckbox, 'RIGHT', 150, 0)
			:OnClick(function(self)
				AstralRaidSettings.notifiers.general.toRaid = self:GetChecked()
			end)

	local desc = AstralUI:Text(self, L['NOTIFIERS_DESC']):Point('TOPLEFT', enableCheckbox, 'BOTTOMLEFT', 0, -10):FontSize(9):Shadow()

	specificHeader = AstralUI:Text(self, L['ENCOUNTER_NOTIFIERS']):Point('TOPLEFT', desc, 'BOTTOMLEFT', 0, -20):Size(200, 12)

	local function updateList()
		if not currentInstance then return end
		encounterList.L = {}
		local encountersByIndex = AstralInstanceLib.AllRaidInstances.ByName[currentInstance].Encounters.ByIndex
		for _,encounter in addon.PairsByKeys(encountersByIndex) do
			encounterList.L[#encounterList.L + 1] = encounter.Name
		end
		encounterList:Update()
		encounterDetailsList:Update()
	end

	local function instanceDropdown_SetValue(_, instanceName)
		instanceDropdown:SetText(instanceName or '???')
		currentInstance = instanceName
		updateList()
		AstralUI:DropDownClose()
	end

	instanceDropdown = AstralUI:DropDown(self, 400, 25):AddText('Raid:'):Point('LEFT', specificHeader, 'RIGHT', 10, 0):Size(400):SetText('-') do
		local list = instanceDropdown.List
		local encounters = AstralInstanceLib:GetCurrentExpansionRaidInstances()
		for _,instance in addon.PairsByKeys(encounters, addon.REVERSE) do
			list[#list+1] = {
				text = instance.Name,
				arg1 = instance.Name,
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
		encounterDetailsList:Update()
	end

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

		local function showAbilityTooltip(self)
			local data = self:GetParent().data
			GameTooltip:SetOwner(line.icon, 'ANCHOR_CURSOR')
			GameTooltip:ProcessInfo({ -- Black Magic, pls no break Blizzard
				getterName = "GetSpellByID",
				getterArgs = {data.spell}
			})
			GameTooltip:Show()
		end

		local function openToJournalEntry(self)
			-- TODO: taint issues
			--local ability = self:GetParent().data
			--local instance = AstralInstanceLib.AllRaidInstances.ByName[currentInstance]
			--local encounter = instance.Encounters.ByIndex[encounterList.selected]
			--if not EncounterJournal_OpenJournal then
			--	EncounterJournal_LoadUI()
			--end
			--if EncounterJournal_OpenJournal then
			--	EncounterJournal_OpenJournal(
			--		MYTHIC_DIFFICULTY, -- 16
			--		instance.JournalInstanceID,
			--		encounter.JournalEncounterID,
			--		ability.abilityInfo.JournalSectionID)
			--end
		end

		line.icon = AstralUI:Icon(line, nil, 16, true):Point('LEFT', 10, 0)
				:OnClick(openToJournalEntry)
		line.icon:SetScript('OnEnter', showAbilityTooltip)
		line.icon:SetScript('OnLeave', function() GameTooltip_Hide() end)

		line.spellName = AstralUI:Text(line):Size(225, 10):FontSize(10):Point('LEFT', line.icon, 'RIGHT', 5, 0):Shadow()
		line.spellName:EnableMouse(true)
		line.spellName:SetScript('OnMouseDown', openToJournalEntry)
		line.spellName:SetScript('OnEnter', showAbilityTooltip)
		line.spellName:SetScript('OnLeave', function() GameTooltip_Hide() end)

		line.castChk = AstralUI:Check(line, L['CAST']):Point('LEFT', line.spellName, 'RIGHT', 5, 0):OnClick(function(self)
			local encounter = AstralInstanceLib.AllRaidInstances.ByName[currentInstance].Encounters.ByIndex[encounterList.selected]
			local settings = EncounterSettings(encounter.DungeonEncounterID)
			if self.disabled then
				settings.casts[self:GetParent().data.spell] = nil
				if self:GetChecked() then
					self:SetChecked(false)
				end
			elseif self:GetChecked() then
				settings.casts[self:GetParent().data.spell] = true
			else
				settings.casts[self:GetParent().data.spell] = nil
			end
		end)
		line.auraChk = AstralUI:Check(line, L['AURA']):Point('LEFT', line.castChk, 'RIGHT', 40, 0):OnClick(function(self)
			local encounter = AstralInstanceLib.AllRaidInstances.ByName[currentInstance].Encounters.ByIndex[encounterList.selected]
			local settings = EncounterSettings(encounter.DungeonEncounterID)
			if self.disabled then
				settings.auras[self:GetParent().data.spell] = nil
				if self:GetChecked() then
					self:SetChecked(false)
				end
			elseif self:GetChecked() then
				settings.auras[self:GetParent().data.spell] = true
			else
				settings.auras[self:GetParent().data.spell] = nil
			end
		end)
		line:Hide()
	end

	function encounterDetailsList:Update()
		AstralUI:UpdateScrollList(self, 32, function(self)
			if not currentInstance or not encounterList.selected then return end
			local list = {}
			local encounter = AstralInstanceLib.AllRaidInstances.ByName[currentInstance].Encounters.ByIndex[encounterList.selected]
			local settings = EncounterSettings(encounter.DungeonEncounterID)
			local allAbilities = encounter.Abilities.Mythic.BySpellName
			for _,ability in addon.PairsByKeys(allAbilities) do
				list[#list + 1] = {
					spell = ability.SpellID,
					name = ability.SpellName,
					icon = ability.SpellIcon,
					abilityInfo = ability,
					tracked = {
						aura = settings.auras[ability.SpellID],
						cast = settings.casts[ability.SpellID]
					}
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

	if not currentInstance then
		local currentRaids = AstralInstanceLib:GetCurrentExpansionRaidInstances()
		currentInstance = currentRaids[#currentRaids].Name
	end
	instanceDropdown_SetValue(nil, currentInstance)
end

function module.options:OnShow()
	enableCheckbox:SetChecked(AstralRaidSettings.notifiers.general.isEnabled)
	toConsoleCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toConsole)
	toOfficerCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toOfficer)
	toRaidCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toRaid)
end