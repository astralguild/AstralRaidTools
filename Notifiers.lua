local _, addon = ...

local module = addon:New('Notifiers', 'Notifiers', true)

local enableCheckbox, toConsoleCheckbox, toOfficerCheckbox, toRaidCheckbox, encounterList, encounterDropdown
local encounterNewAuraText, encounterNewAuraEdit, encounterNewAuraAddBtn
local encounterWidgets = {}

function module.AuraTrigger(player, spellID)
  local e = {
    player = player,
    date = date('%x'),
    time = date('%H:%M:%S %p'),
    spellID = spellID,
  }
  local link, _ = GetSpellLink(spellID)
  addon.Console(string.format('%s affected by %s at %s', addon.ClassColorName(player), link, e.time))
end

function module.options:PopulateEncounter(index)
	local encounter = AstralRaidSettings.notifiers.encounters[index]
	local last = encounterDropdown

	if #encounterWidgets == 0 then
		-- Make inputs for first time
		encounterNewAuraText = AstralUI:Text(self, 'Add Spell ID:'):FontSize(10)
		encounterNewAuraEdit = CreateFrame('EditBox', nil, self, 'InputBoxTemplate')
		encounterNewAuraEdit:SetSize(180, 20)
		encounterNewAuraEdit:SetAutoFocus(false)
		encounterNewAuraAddBtn = AstralUI:Icon(self, "Interface\\RaidFrame\\ReadyCheck-Ready", 16, true)
	end

	for i = 1, #encounterWidgets do -- clear all widgets
		for j = 1, #encounterWidgets[i] do
			encounterWidgets[i][j].ic:Hide()
			encounterWidgets[i][j].t:Hide()
			encounterWidgets[i][j].d:Hide()
		end
	end

	-- Tracked Auras
	if encounterWidgets[index] then
		for i = 1, #encounterWidgets[index] do
			encounterWidgets[index][i].ic:Show()
			encounterWidgets[index][i].t:Show()
			encounterWidgets[index][i].d:Show()
		end
	else
		encounterWidgets[index] = {}
		for i = 1, #encounter.auras do
			local a = encounter.auras[i]
			local name, _, icon, _, _, _, _, _ = GetSpellInfo(a.spellID)
			local ic = AstralUI:Icon(self, icon, 16)
			ic:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -20)
			local t = AstralUI:Text(self, name):Point('LEFT', ic, 'RIGHT', 5, 0):Size(250, 10):FontSize(10)
			local d = AstralUI:Icon(self, "Interface\\RaidFrame\\ReadyCheck-NotReady", 16, true)
			d:SetPoint('LEFT', t, 'RIGHT', 10, 0)
			d:SetScript('OnClick', function()
				AstralRaidSettings.notifiers.encounters[index].auras[i] = nil
				ic:Hide()
				t:Hide()
				d:Hide()
				encounterWidgets[index][a.spellID] = nil
				module.options:PopulateEncounter(index)
			end)
			encounterWidgets[index][a.spellID] = {ic = ic, t = t, d = d}
			last = ic
		end
	end
	encounterNewAuraText:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -20)
	encounterNewAuraEdit:SetPoint('LEFT', encounterNewAuraText, 'RIGHT', 10, 0)
	encounterNewAuraAddBtn:SetPoint('LEFT', encounterNewAuraEdit, 'RIGHT', 10, 0)
	encounterNewAuraAddBtn:SetScript('OnClick', function()
		local id = tonumber(encounterNewAuraEdit:GetText()) or -1
		if id > 0 and GetSpellInfo(id) then
			AstralRaidSettings.notifiers.encounters[index].auras[#AstralRaidSettings.notifiers.encounters[index].auras+1] = {
				spellID = id,
			}
			module.options:PopulateEncounter(index)
		end
	end)
	encounterNewAuraEdit:SetText('')
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

	local function newEncounterEntry()
		local encounter = {
			auras = {},
			hps = {},
			pows = {},
		}
		AstralRaidSettings.notifiers.encounters[#AstralRaidSettings.notifiers.encounters + 1] = encounter
	end

  local function updateList()
		encounterList.L = {}
		for i = 1, #AstralRaidSettings.notifiers.encounters do
			if AstralRaidSettings.notifiers.encounters[i].bossID then
				encounterList.L[i] = '|cffffff00'.. addon.GetBossName(AstralRaidSettings.notifiers.encounters[i].bossID) ..'|r'
				if i == 1 then
					encounterDropdown:SetText(addon.GetBossName(AstralRaidSettings.notifiers.encounters[i].bossID) or '-')
					module.options:PopulateEncounter(i)
				end
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