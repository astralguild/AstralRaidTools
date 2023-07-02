local _, addon = ...

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

-- Reminders

local guildBankSpell = 83958
local hsSpell = 29893
local healthstoneItem = 5512
local hpPotionItem = 191380
local cauldronSpells = {} -- TODO find cauldron spellIDs
local repairSpells = {
  [1] = 67826,
  [2] = 199109,
  [3] = 200061,
}

local function notFullHealthstones()
  return GetItemCount(healthstoneItem, false, true) < 3
end

local function noHealthPotions()
  return GetItemCount(hpPotionItem) == 0
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
    if spellID == hsSpell then
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
      untrigger('healthstones', noHealthPotions)
      return 'SHOW'
    end
  elseif not noHealthPotions() then
    return 'HIDE'
  end
end

local function noReleaseReminder(e, ...)
  if e == 'PLAYER_DEAD' and UnitHealth('player') == 0 and StaticPopup1:IsShown() and StaticPopup1Button1:GetText() == 'Release Spirit' then
    StaticPopup_Show('WANT_TO_RELEASE')
    if StaticPopup1Button1:GetButtonState() == 'NORMAL' then
      StaticPopup1Button1:Hide()
    end
    return 'SHOW'
  else
    StaticPopup_Hide('WANT_TO_RELEASE')
    return 'HIDE'
  end
end

AstralRaidEvents:Register('PLAYER_LOGIN', function()
  addon.CreateText('eatFood', 'EAT FOOD', 'REMINDER')
  addon.CreateText('cauldronDown', 'CAULDRON DOWN', 'REMINDER')
  addon.CreateText('repairDown', 'REPAIR', 'REMINDER')
  addon.CreateText('healthstones', 'GRAB HEALTHSTONES', 'REMINDER')
  addon.CreateText('healingPotions', 'GRAB HEALING POTIONS', 'REMINDER')
  addon.CreateText('infiniteRune', 'RUNE UP', 'REMINDER')
  addon.CreateText('noRelease', 'DONT RELEASE', 'REMINDER')

  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'enterInstance')
  addon.AddTextEventCallback(repairReminder, 'repairDown', 'enterInstance')
  addon.AddTextEventCallback(repairReminder, 'repairDown', 'enterCombat')
  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'resurrected')
  addon.AddTextEventCallback(noReleaseReminder, 'noRelease', 'dead')
  addon.AddTextEventCallback(noReleaseReminder, 'noRelease', 'resurrected')
  addon.AddTextEventCallback(noReleaseReminder, 'noRelease', 'alive')
  addon.AddTextEventCallback(cauldronReminder, 'cauldronDown', 'spellcastSuccess')
  addon.AddTextEventCallback(repairReminder, 'repairDown', 'cleu')
  addon.AddTextEventCallback(healthstoneReminder, 'healthstones', 'cleu')
  addon.AddTextEventCallback(healingPotionsReminder, 'healingPotions', 'cleu')
  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'cleu')
end, 'astralRaidInitReminders')

local module = addon:New('Reminders', 'Reminders')
local fontDropdown, fontSizeSlider

local fonts = addon.SharedMedia:List('font')

function module.options:Load()
  fontDropdown = AstralUI:Dropdown(self, 'Font', 200)
  fontDropdown:SetPoint('TOPLEFT')

  fontSizeSlider = AstralUI:Slider(self, 'Font Size'):Size(200):Point('LEFT', fontDropdown, 'RIGHT', 10, 0):Range(5,120)

  local testReminders = false
  local testRemindersButton = CreateFrame('BUTTON', 'AstralRaidsTestRemindersButton', self, 'UIPanelButtonTemplate')
  testRemindersButton:SetPoint('TOPLEFT', fontDropdown, 'BOTTOMLEFT', 0, -10)
  testRemindersButton:SetSize(200, 20)
  testRemindersButton:SetText('Test Reminders')
  testRemindersButton:SetScript('OnClick', function()
    testReminders = not testReminders
    addon.TestTexts(testReminders, 5)
  end)
end

function module.options:OnShow()
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
end