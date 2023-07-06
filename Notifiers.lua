local _, addon = ...

local module = addon:New('Notifiers', 'Notifiers', true)

local enableCheckbox, toConsoleCheckbox, toOfficerCheckbox, toRaidCheckbox, encounterList, encounterDropdown
local encounterWidgets = {}

function module.UnitTrigger(player, spellID)
  local e = {
    player = player,
    date = date('%x'),
    time = date('%H:%M:%S %p'),
    spellID = spellID,
  }
  local link, _ = GetSpellLink(spellID)
  addon.Console(string.format('%s affected by %s at %s', addon.ClassColorName(player), link, e.time))
end

module.options.lastIndex = 0

function module.options:PopulateEncounter(index)
	local encounter = AstralRaidSettings.notifiers.encounters[index]
	local last = encounterDropdown

	if module.options.lastIndex > 0 then
		for i = 1, #encounterWidgets[module.options.lastIndex] do
			encounterWidgets[module.options.lastIndex][i].ic:Hide()
			encounterWidgets[module.options.lastIndex][i].t:Hide()
			encounterWidgets[module.options.lastIndex][i].e:Hide()
		end
	end

	if encounter.trackedAuras then
		if encounterWidgets[index] then
			for i = 1, #encounterWidgets[index] do
				encounterWidgets[index][i].ic:Show()
				encounterWidgets[index][i].t:Show()
				encounterWidgets[index][i].e:Show()
			end
		else
			encounterWidgets[index] = {}
			for i = 1, #encounter.trackedAuras do
				local a = encounter.trackedAuras[i]
				local name, _, icon, _, _, _, _, _ = GetSpellInfo(a.spellID)
				local ic = AstralUI:Icon(self, icon, 16)
				ic:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -20)
				local t = AstralUI:Text(self, name):Point('LEFT', ic, 'RIGHT', 5, 0):Size(200, 10):FontSize(10)
				local e = AstralUI:Check(self, 'Enable', a.isEnabled):Point('LEFT', t, 'RIGHT', 10, 0):OnClick(function(self)
					AstralRaidSettings.notifiers.encounters[index].trackedAuras[i].isEnabled = self:GetChecked()
				end)
				table.insert(encounterWidgets[index], {ic = ic, t = t, e = e})
				last = t
			end
		end
	end

	module.options.lastIndex = index
end

function module.options:Load()
  local header = AstralUI:Text(self, 'Encounter Notifiers'):Point('TOPLEFT', 0, 0):Shadow()

  enableCheckbox = AstralUI:Check(self, 'Enable'):Point('TOPLEFT', header, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.notifiers.general.isEnabled = self:GetChecked()
  end)

  toConsoleCheckbox = AstralUI:Check(self, 'Send to Local ' .. CHAT):Point('LEFT', enableCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toConsole = self:GetChecked()
  end)

  toOfficerCheckbox = AstralUI:Check(self, 'Send to Officer'):Point('LEFT', toConsoleCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toOfficer = self:GetChecked()
  end)

  toRaidCheckbox = AstralUI:Check(self, 'Send to Raid'):Point('LEFT', toOfficerCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.notifiers.general.toRaid = self:GetChecked()
  end)

  local specificHeader = AstralUI:Text(self, 'Specific Notifiers'):Point('TOPLEFT', enableCheckbox, 'BOTTOMLEFT', 0, -20)

	encounterList = AstralUI:ScrollList(self):Size(200, 450):Point('TOPLEFT', specificHeader, 'BOTTOMLEFT', 0, -20):AddDrag():HideBorders()
	encounterList.selected = 1
	encounterList.LINE_PADDING_LEFT = 2
	encounterList.SCROLL_WIDTH = 12

	local function newEncounterEntry(L)
		local encounter = {
			trackedAuras = {},
		}
		AstralRaidSettings.notifiers.encounters[#AstralRaidSettings.notifiers.encounters + 1] = encounter
	end

  local function updateList()
		encounterList.L = {}
		for i = 1, #AstralRaidSettings.notifiers.encounters do
			if AstralRaidSettings.notifiers.encounters[i].bossID then
				encounterList.L[i] = '|cffffff00'.. addon.GetBossName(AstralRaidSettings.notifiers.encounters[i].bossID) ..'|r'
			else
				encounterList.L[i] = NEW
			end
		end
		if #encounterList.L == 0 then
			newEncounterEntry()
		end
		encounterList.L[#encounterList.L + 1] = '|cfff5e4a8' .. ADD
		encounterList:Update()
	end

  encounterList:SetScript('OnShow',function(self)
		updateList()
	end)

	function encounterList:SetListValue(index)
		if index ~= #self.L then
			encounterDropdown:Enable()
		else
			encounterDropdown:Disable()
		end
		if index == #self.L then
      newEncounterEntry()
			self:Update()
			updateList()
			encounterDropdown:SetText('-')
		else
			encounterDropdown:SetText(addon.GetBossName(AstralRaidSettings.notifiers.encounters[index].bossID) or '-')
			module.options:PopulateEncounter(index)
		end
	end

  local function encounterDropdown_SetValue(self, bossID)
		encounterDropdown:SetText(bossID and addon.GetBossName(bossID) or '-')
		AstralRaidSettings.notifiers.encounters[encounterList.selected].bossID = bossID
		updateList()
		AstralUI:DropDownClose()
	end

  encounterDropdown = AstralUI:DropDown(self, 400, 25):AddText(ENCOUNTER_JOURNAL_ENCOUNTER .. ':'):Point('TOPLEFT', encounterList, 'TOPRIGHT', 10, 0):Size(400):SetText('-')
  do
		local list = encounterDropdown.List
		local encounters = addon.GetEncountersList(true, true)
		for i = 1, #encounters do
			local instance = encounters[i]
			list[#list+1] = {
				text = type(instance[1]) == 'string' and instance[1] or (C_Map.GetMapInfo(instance[1] or 0) or {}).name or '???',
				isTitle = true,
			}
			for j = 2, #instance do
				list[#list+1] = {
					text = addon.GetBossName(instance[j]),
					arg1 = instance[j],
					func = encounterDropdown_SetValue,
				}
			end
		end
	end
  encounterDropdown:HideBorders()
	encounterDropdown.Background:Hide()
	encounterDropdown.Background:SetPoint('BOTTOMRIGHT', 0, 1)
	encounterDropdown.Background:SetColorTexture(1, 1, 1, .3)
	encounterDropdown.Text:SetJustifyH('RIGHT')
	encounterDropdown:SetScript('OnMouseDown',function(self)
		self.Button:Click()
	end)
	encounterDropdown:SetScript('OnEnter',function(self)
		self.Background:Show()
	end)
	encounterDropdown:SetScript('OnLeave',function(self)
		self.Background:Hide()
	end)

	updateList()
end

function module.options:OnShow()
  enableCheckbox:SetChecked(AstralRaidSettings.notifiers.general.isEnabled)
  toConsoleCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toConsole)
  toOfficerCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toOfficer)
  toRaidCheckbox:SetChecked(AstralRaidSettings.notifiers.general.toRaid)
end