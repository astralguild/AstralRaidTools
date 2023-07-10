local _, addon = ...
local L = addon.L

local function untrigger(r, func)
  if not func() then
    addon.HideText(r)
    return
  end
  C_Timer.After(3, function()
    untrigger(r, func)
  end)
end

local function hideAfter(r, time)
  C_Timer.After(time, function()
    addon.HideText(r)
  end)
end

local guildBankSpell = 83958
local healthstoneSpell = 29893
local healthstoneItem = 5512
local hpPotionItem = 191380
local combatPotionItems = {
  [1] = 191914,
  [2] = 191913,
  [3] = 191912,
  [4] = 191907,
  [5] = 191906,
  [6] = 191905,
  [7] = 191383,
  [8] = 191382,
  [9] = 191381,
  [10] = 191389,
  [11] = 191388,
  [12] = 191387,
  [13] = 191401,
}
local cauldronSpells = {
  [1] = 371611, -- Prepare Potion Cauldron of Ultimate Power r3
  [2] = 371606, -- Prepare Potion Cauldron of Ultimate Power r2
  [3] = 371535, -- Prepare Potion Cauldron of Ultimate Power r1
}
local repairSpells = {
  [1] = 67826,
  [2] = 199109,
  [3] = 200061,
}

local LOW_COMBAT_POTION_COUNT = 3

local function lowDurability()
  local cur, max
  for i = 1, 18 do
      cur, max = GetInventoryItemDurability(i)
      if cur and max then
          if (cur/max) <= 0.9 then
            return true
          end
      end
  end
end

local function notFullHealthstones()
  return GetItemCount(healthstoneItem, false, true) < 3
end

local function noHealthPotions()
  return GetItemCount(hpPotionItem) == 0
end

local function noCombatPotions()
  local count = 0
  for i = 1, #combatPotionItems do
    count = count + GetItemCount(combatPotionItems[i])
  end
  return count <= LOW_COMBAT_POTION_COUNT
end

local function eatFoodReminder(e, _, m, ...)
  if e ~= 'COMBAT_LOG_EVENT_UNFILTERED' then
    local wellFedBuff = AuraUtil.FindAuraByName('Well Fed', 'player')
    if (not wellFedBuff) and UnitHealth('player') > 0 then
      return 'SHOW'
    else
      return 'HIDE'
    end
  elseif e == 'COMBAT_LOG_EVENT_UNFILTERED' then
    if m == 'SPELL_AURA_APPLIED' then
      local destGUID = select(6, ...)
      local spellID = select(10, ...)
      if destGUID == UnitGUID('player') then
        local name = select(1, GetSpellInfo(spellID))
        if name == 'Well Fed' or name == 'Food' or name == 'Drink' or name == 'Food & Drink' then
          return 'HIDE'
        end
      end
    end
  end
end

local function cauldronReminder(e, ...)
  if e == 'UNIT_SPELLCAST_SUCCEEDED' then
    local spellID = select(3, ...)
    for _, cauldronSpellID in pairs(cauldronSpells) do
      if spellID == cauldronSpellID then
        hideAfter('cauldronDown', 20)
        return 'SHOW'
      end
    end
  end
end

local function repairReminder(e, _, m, ...)
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' and lowDurability() then
    local spellID = select(10, ...)
    for _, repairSpellID in pairs(repairSpells) do
      if spellID == repairSpellID then
        untrigger('repairDown', lowDurability)
        return 'SHOW'
      end
    end
  elseif not lowDurability() then
    return 'HIDE'
  end
end

local function healthstoneReminder(e, _, m, ...)
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' and notFullHealthstones() then
    local spellID = select(10, ...)
    if spellID == healthstoneSpell then
      untrigger('healthstones', notFullHealthstones)
      return 'SHOW'
    end
  elseif not notFullHealthstones() then
    return 'HIDE'
  end
end

local function healingPotionsReminder(e, _, m, ...)
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' and noHealthPotions() then
    local spellID = select(10, ...)
    if spellID == guildBankSpell then
      hideAfter('healingPotions', 20)
      return 'SHOW'
    end
  elseif not noHealthPotions() then
    return 'HIDE'
  end
end

local function combatPotionsReminder(e, _, m, ...)
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' and noCombatPotions() then
    local spellID = select(10, ...)
    if spellID == guildBankSpell then
      hideAfter('combatPotions', 20)
      return 'SHOW'
    end
  elseif not noCombatPotions() then
    return 'HIDE'
  end
end

local function noReleaseReminder(e, ...)
  if UnitHealth('player') == 0 then
    StaticPopup_Show('WANT_TO_RELEASE_ASTRAL')
    if StaticPopup1:IsShown() and StaticPopup1Button1:GetText() == L['RELEASE_SPIRIT'] then StaticPopup1Button1:Hide() end
    return 'SHOW'
  else
    StaticPopup_Hide('WANT_TO_RELEASE_ASTRAL')
    if StaticPopup1:IsShown() and StaticPopup1Button1:GetText() == L['RELEASE_SPIRIT'] then StaticPopup1Button1:Show() end
    return 'HIDE'
  end
end

AstralRaidReminders = {
  ['eatFood'] = {text = L['EAT_FOOD'], sound = 'Details Whip1', callbacks = {'enterInstance', 'resurrected', 'cleu'}, func = eatFoodReminder},
  ['cauldronDown'] = {text = L['CAULDRON_DOWN'], sound = 'Banana Peel Slip', callbacks = {'spellcastSuccess'}, func = cauldronReminder},
  ['repairDown'] =  {text = L['REPAIR'], sound = 2917320, callbacks = {'enterInstance', 'enterCombat', 'cleu'}, func = repairReminder},
  ['healthstones'] = {text = L['GRAB_HEALTHSTONES'], sound = 'Arrow Swoosh', callbacks = {'cleu'}, func = healthstoneReminder},
  ['healingPotions'] = {text = L['GRAB_HEALING_POTIONS'], sound = 'Noot Noot', callbacks = {'cleu'}, func = healingPotionsReminder},
  ['combatPotions'] = {text = L['GRAB_COMBAT_POTIONS'], callbacks = {'cleu'}, func = combatPotionsReminder},
  ['infiniteRune'] = {text = L['RUNE_UP'], callbacks = {}},
  ['noRelease'] = {text = L['DONT_RELEASE'], sound = 'Voice: Don\'t Release', callbacks = {'leaveCombat', 'dead', 'resurrected', 'alive'}, func = noReleaseReminder},
}

AstralRaidEvents:Register('PLAYER_LOGIN', function() -- initialize all reminders
  for name, r in pairs(AstralRaidReminders) do
    addon.CreateText(name, r.text, 'REMINDER')
    for i = 1, #r.callbacks do
      addon.AddTextEventCallback(r.func, name, r.callbacks[i], r.sound)
    end
    if not AstralRaidSettings.texts.sounds[name] then
      AstralRaidSettings.texts.sounds[name] = r.sound or 'None'
    end
    if not AstralRaidSettings.texts.enabled[name] then
      AstralRaidSettings.texts.enabled[name] = true
    end
  end
end, 'astralRaidInitReminders')

local module = addon:New(L['REMINDERS'], L['REMINDERS'])
local fontDropdown, fontSizeSlider, reminderEnableCheckbox, inPartyCheckbox, outsideInstancesCheckbox, reminderWidgets

function module.options:Load()
  -- Get Shared Media

  local fonts = addon.SharedMedia:List('font')
  local sounds = addon.SharedMedia:List('sound')

  for _, r in pairs(AstralRaidReminders) do
    if type(r.sound) ~= 'string' then
      table.insert(sounds, r.sound)
    end
  end
  table.insert(sounds, NONE)

	local function fontDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		fontDropdown:SetText(arg1)
    AstralRaidSettings.general.font.name = arg1
		addon.UpdateTextsFonts()
	end

	local function soundDropdownSetValue(self, arg1)
		AstralUI:DropDownClose()
		self:SetText(arg1)
    if arg1 and arg1 ~= NONE then
      local path = addon.SharedMedia:Fetch('sound', arg1, true)
      PlaySoundFile(path or arg1)
    end
    AstralRaidSettings.texts.sounds[self.rname] = arg1
	end

  -- Start UI

  local generalHeader = AstralUI:Text(self, L['REMINDERS_OPTIONS']):Point('TOPLEFT', 0, 0):Shadow()

	fontDropdown = AstralUI:DropDown(self, 350, 10):Size(320):Point('TOPLEFT', generalHeader, 'BOTTOMLEFT', 0, -10):AddText(string.format('|cffffce00%s:', L['FONT']))
	for i = 1, #fonts do
		local info = {}
		fontDropdown.List[i] = info
		info.text = fonts[i]
		info.arg1 = fonts[i]
		info.func = fontDropdownSetValue
		info.font = addon.SharedMedia:Fetch('font', fonts[i], true) or fonts[i]
		info.justifyH = 'CENTER'
	end

  fontSizeSlider = AstralUI:Slider(self, L['FONT_SIZE']):Size(200):Point('LEFT', fontDropdown, 'RIGHT', 10, 0):Range(36, 120)

  reminderEnableCheckbox = AstralUI:Check(self, ENABLE):Point('LEFT', fontSizeSlider, 'RIGHT', 10, 0):OnClick(function(self)
    AstralRaidSettings.texts.reminders.enable = self:GetChecked()
    if not self:GetChecked() then
      for name, _ in pairs(AstralRaidReminders) do
        addon.HideText(name)
      end
    end
  end)

  inPartyCheckbox = AstralUI:Check(self, L['SHOW_IN_PARTY']):Point('TOPLEFT', fontDropdown, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.texts.reminders.inParty = self:GetChecked()
  end)

  outsideInstancesCheckbox = AstralUI:Check(self, WrapTextInColorCode('Show outside instances', 'C1E1C1FF')):Point('LEFT', inPartyCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.texts.reminders.outsideInstances = self:GetChecked()
  end)

  local testReminders = false
  AstralUI:Button(self, L['TEST_REMINDERS']):Point('LEFT', inPartyCheckbox, 'RIGHT', 445, 0):Size(130,20):OnClick(function(self)
    testReminders = not testReminders
    addon.TestTexts(testReminders, 5)
	end)

  local specificHeader = AstralUI:Text(self, L['SPECIFIC_REMINDERS']):Point('TOPLEFT', inPartyCheckbox, 'BOTTOMLEFT', 0, -20)
  reminderWidgets = {}

  local a = specificHeader
  for name, r in pairs(AstralRaidReminders) do
    local t = AstralUI:Text(self, r.text):Point('TOPLEFT', a, 'BOTTOMLEFT', 0, -20):Size(200, 10):FontSize(10)
    local s = AstralUI:DropDown(self, 250, 10):Size(320):Point('LEFT', t, 'RIGHT', 10, 0):AddText(string.format('|cffffce00%s:', SOUND))
    for i = 1, #sounds do
      local info = {}
      s.List[i] = info
      info.text = sounds[i]
      info.arg1 = sounds[i]
      info.rname = name
      info.func = soundDropdownSetValue
      info.justifyH = 'CENTER'
    end
    local e = AstralUI:Check(self, ENABLE):Point('LEFT', s, 'RIGHT', 10, 0):OnClick(function(self)
      AstralRaidSettings.texts.enabled[name] = self:GetChecked()
      if not self:GetChecked() then
        addon.HideText(name)
      end
    end)
    reminderWidgets[name] = {text = t, soundDropdown = s, enableCheck = e}
    a = t
  end
end

function module.options:OnShow()
  fontDropdown:SetText(AstralRaidSettings.general.font.name)
  reminderEnableCheckbox:SetChecked(AstralRaidSettings.texts.reminders.enable)
  inPartyCheckbox:SetChecked(AstralRaidSettings.texts.reminders.inParty)
  outsideInstancesCheckbox:SetChecked(AstralRaidSettings.texts.reminders.outsideInstances)

  if not addon.Debug then
    outsideInstancesCheckbox:Hide()
  end

  for name, r in pairs(reminderWidgets) do
    r.soundDropdown:SetText(AstralRaidSettings.texts.sounds[name] or NONE)
    r.enableCheck:SetChecked(AstralRaidSettings.texts.enabled[name])
  end

	fontSizeSlider:SetTo(AstralRaidSettings.general.font.size):OnChange(function(self, event)
		event = event - event%1
		AstralRaidSettings.general.font.size = event
		addon.UpdateTextsFonts()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
end