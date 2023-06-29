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

-- Reminders

local cauldronSpells = {} -- TODO find cauldron spellIDs
local repairSpells = {
  [1] = 67826,
  [2] = 199109,
  [3] = 200061,
}

local function eatFoodReminder(e, _, m, ...)
  if e ~= 'COMBAT_LOG_EVENT_UNFILTERED' then
    local wellFedBuff = AuraUtil.FindAuraByName('Well Fed', 'player')
    local foodBuff = AuraUtil.FindAuraByName('Food', 'player')
    local drinkBuff = AuraUtil.FindAuraByName('Drink', 'player')
    local foodAndDrinkBuff = AuraUtil.FindAuraByName('Food & Drink', 'player')
    if not (wellFedBuff or foodBuff or drinkBuff or foodAndDrinkBuff) then
      return true
    else
      return false
    end
  elseif e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_AURA_APPLIED' then
    local destGUID = select(6, ...)
    local spellID = select(10, ...)
    if destGUID == UnitGUID('player') then
      local name = select(1, GetSpellInfo(spellID))
      if name == 'Well Fed' then
        return false
      end
    end
  elseif not AstralRaidText.testing then
    return false
  end
end

local function cauldronReminder(e, ...)
  if e == 'UNIT_SPELLCAST_SUCCEEDED' then
    local spellID = select(3, ...)
    for _, cauldronSpellID in pairs(cauldronSpells) do
      if spellID == cauldronSpellID then
        -- find way to hide
        return true
      end
    end
  end
  if not AstralRaidText.testing then
    return false
  end
end

local function repairReminder(e, _, m, ...)
  if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' and lowDurability() then
    local spellID = select(10, ...)
    for _, repairSpellID in pairs(repairSpells) do
      if spellID == repairSpellID then
        return true
      end
    end
  end
  if not AstralRaidText.testing then
    return false
  end
end

local function noReleaseReminder(e, ...)
  if e == 'PLAYER_DEAD' and UnitHealth('player') == 0 and StaticPopup1:IsShown() and StaticPopup1Button1:GetText() == 'Release Spirit' then
    StaticPopup_Show('WANT_TO_RELEASE')
    if StaticPopup1Button1:GetButtonState() == 'NORMAL' then
      StaticPopup1Button1:Disable()
    end
    return true
  else
    return false
  end
end

function addon.InitReminders()
  addon.CreateText('eatFood', 'EAT FOOD', 'REMINDER')
  addon.CreateText('cauldronDown', 'CAULDRON DOWN', 'REMINDER')
  addon.CreateText('repairDown', 'REPAIR', 'REMINDER')
  addon.CreateText('healthstones', 'GRAB HEALTHSTONES', 'REMINDER')
  addon.CreateText('infiniteRune', 'RUNE UP', 'REMINDER')
  addon.CreateText('noRelease', 'DONT RELEASE', 'REMINDER')

  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'enterInstance')
  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'resurrected')
  addon.AddTextEventCallback(noReleaseReminder, 'noRelease', 'dead')
  addon.AddTextEventCallback(cauldronReminder, 'cauldronDown', 'spellcastSuccess')
  addon.AddTextEventCallback(repairReminder, 'repairDown', 'cleu')
  addon.AddTextEventCallback(eatFoodReminder, 'eatFood', 'cleu')
end