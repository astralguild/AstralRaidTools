local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

local AstralRaidReminders = CreateFrame('FRAME', 'AstralRaidReminders', UIParent)
AstralRaidReminders:SetHeight(1)
AstralRaidReminders:SetWidth(1)
AstralRaidReminders:SetPoint('CENTER', UIParent, 'CENTER')
AstralRaidReminders:Hide()

local reminders = {}
local displayed = {}
local state = {}
local testing = false
local wasShownBeforeTest = false
local wasShownBeforeCombat = false

function addon.CreateReminder(name, text)
  if reminders[name] then
    return reminders[name]
  end

  local fontPath = SharedMedia:Fetch('font', AstralRaidSettings.general.font.name)

  reminders[name] = AstralRaidReminders:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
  reminders[name]:SetPoint('CENTER', 0, 400)
  reminders[name]:SetFont(fontPath, AstralRaidSettings.general.font.size, 'OUTLINE')
  reminders[name]:SetText(text)
  reminders[name]:Hide()

  reminders[name]:SetScript('OnShow', function(self)
    if #displayed > 0 then
      self:SetPoint('TOP', displayed[#displayed], 'BOTTOM', 0, -5)
    else
      self:SetPoint('CENTER', 0, 400)
    end
    displayed[#displayed+1] = self
  end)

  reminders[name]:SetScript('OnHide', function(self)
    local i = 0
    for j = 1, #displayed do
      if displayed[j] == self then
        i = j
      end
    end
    table.remove(displayed, i)
    for j = 1, #displayed do
      if j == 1 then
        displayed[j]:SetPoint('CENTER', 0, 400)
      else
        displayed[j]:SetPoint('TOP', displayed[j-1], 'BOTTOM', 0, -5)
      end
    end
    if #displayed == 0 then
      AstralRaidReminders:Hide()
    end
  end)

  return reminders[name]
end

function addon.UpdateRemindersFonts()
  for _, r in pairs(reminders) do
    r:SetFont(SharedMedia:Fetch('font', AstralRaidSettings.general.font.name), AstralRaidSettings.general.font.size, 'OUTLINE')
  end
end

function addon.TestReminders(show)
  if show then
    if AstralRaidReminders:IsShown() then
      wasShownBeforeTest = true
    else
      AstralRaidReminders:Show()
      wasShownBeforeTest = false
    end
    for name, r in pairs(reminders) do
      state[name] = r:IsShown()
      r:Show()
    end
    testing = true
  else
    AstralRaidReminders:SetShown(wasShownBeforeTest)
    for name, shown in pairs(state) do
      reminders[name]:SetShown(shown)
    end
    testing = false
  end
end

function addon.ShowReminder(name)
  if not reminders[name] then
    return
  end
  if not AstralRaidReminders:IsShown() then
    AstralRaidReminders:Show()
  end
  reminders[name]:Show()
end

function addon.HideReminder(name)
  if not (reminders[name] or reminders[name]:IsShown()) then
    return
  end
  reminders[name]:Hide()
end

local function hideRemindersIfShownForCombat()
  if AstralRaidReminders:IsShown() then
    AstralRaidReminders:Hide()
    wasShownBeforeCombat = true
  end
end

local function showRemindersIfShownAfterCombat()
  if wasShownBeforeCombat then
    AstralRaidReminders:Show()
    wasShownBeforeCombat = false
  end
end

-- Event Wiring
-- Semi-recreating the WeakAuras scripting environment

local enterInstanceChecks, resurrectedChecks, deadChecks, spellcastSuccessChecks, cleuChecks = {}, {}, {}, {}, {}
local eatFoodReminder, feastReminder, cauldronReminder, repairReminder, noReleaseReminder

local function enterInstance(...)
  for _, reminder in pairs(enterInstanceChecks) do
    reminder('PLAYER_ENTERING_WORLD', ...)
  end
end

local function resurrected(...)
  for _, reminder in pairs(resurrectedChecks) do
    reminder('PLAYER_ALIVE', ...)
  end
end

local function dead(...)
  for _, reminder in pairs(deadChecks) do
    reminder('PLAYER_DEAD', ...)
  end
end

local function spellcastSuccess(...)
  for _, reminder in pairs(spellcastSuccessChecks) do
    reminder('UNIT_SPELLCAST_SUCCEEDED', ...)
  end
end

local function cleu(...)
  for _, reminder in pairs(cleuChecks) do
    reminder('COMBAT_LOG_EVENT_UNFILTERED', ...)
  end
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', enterInstance, 'astralRaidRemindersEnterInstance')
AstralRaidEvents:Register('PLAYER_ALIVE', resurrected, 'astralRaidRemindersResurrected')
AstralRaidEvents:Register('PLAYER_DEAD', dead, 'astralRaidRemindersDeath')
AstralRaidEvents:Register('UNIT_SPELLCAST_SUCCEEDED', spellcastSuccess, 'astralRaidRemindersSpellcastSuccess')
AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'astralRaidRemindersCLEU')

AstralRaidEvents:Register('PLAYER_ENTER_COMBAT', hideRemindersIfShownForCombat, 'astralRaidEnterCombatHideReminders')
AstralRaidEvents:Register('PLAYER_LEAVE_COMBAT', showRemindersIfShownAfterCombat, 'astralRaidLeaveCombatShowReminders')

function addon.InitReminders()
  addon.CreateReminder('eatFood', 'EAT FOOD')
  addon.CreateReminder('feastDown', 'FEAST DOWN')
  addon.CreateReminder('cauldronDown', 'CAULDRON DOWN')
  addon.CreateReminder('repairDown', 'REPAIR')
  addon.CreateReminder('healthstones', 'GRAB HEALTHSTONES')
  addon.CreateReminder('infiniteRune', 'RUNE UP')
  addon.CreateReminder('noRelease', 'DONT RELEASE')

  table.insert(enterInstanceChecks, eatFoodReminder)
  table.insert(resurrectedChecks, eatFoodReminder)
  table.insert(spellcastSuccessChecks, feastReminder)
  table.insert(spellcastSuccessChecks, cauldronReminder)
  table.insert(cleuChecks, repairReminder)
  table.insert(cleuChecks, eatFoodReminder)
  table.insert(deadChecks, noReleaseReminder)
end

-- Specific Reminders

local feastSpells = {} -- TODO find feast spellIDs
local cauldronSpells = {} -- TODO find cauldron spellIDs
local repairSpells = {
  [1] = 67826,
  [2] = 199109,
  [3] = 200061,
}

eatFoodReminder = function(e, _, m, ...)
  if addon.InRaidIdle() and e ~= 'COMBAT_LOG_EVENT_UNFILTERED' then
    local wellFedBuff = AuraUtil.FindAuraByName('Well Fed', 'player')
    if not wellFedBuff then
      addon.ShowReminder('eatFood')
    else
      addon.HideReminder('eatFood')
      addon.HideReminder('feastDown')
    end
  elseif e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_AURA_APPLIED' then
    local destGUID = select(6, ...)
    local spellID = select(10, ...)
    if destGUID == UnitGUID('player') then
      local name = select(1, GetSpellInfo(spellID))
      if name == 'Well Fed' then
        addon.HideReminder('eatFood')
        addon.HideReminder('feastDown')
      end
    end
  elseif not testing then
    addon.HideReminder('eatFood')
    addon.HideReminder('feastDown')
  end
end

feastReminder = function(e, ...)
  if addon.InRaidIdle() then
    if e == 'UNIT_SPELLCAST_SUCCEEDED' then
      local spellID = select(3, ...)
      for _, feastSpellID in pairs(feastSpells) do
        if spellID == feastSpellID then
          addon.ShowReminder('feastDown')
          return
        end
      end
    end
  end
  if not testing then
    addon.HideReminder('feastDown')
  end
end

cauldronReminder = function(e, ...)
  if addon.InRaidIdle() then
    if e == 'UNIT_SPELLCAST_SUCCEEDED' then
      local spellID = select(3, ...)
      for _, cauldronSpellID in pairs(cauldronSpells) do
        if spellID == cauldronSpellID then
          addon.ShowReminder('cauldronDown')
          -- find way to hide
          return
        end
      end
    end
  end
  if not testing then
    addon.HideReminder('cauldronDown')
  end
end

repairReminder = function(e, _, m, ...)
  if addon.InRaidIdle() then
    if e == 'COMBAT_LOG_EVENT_UNFILTERED' and m == 'SPELL_CAST_SUCCESS' then
      local spellID = select(10, ...)
      for _, repairSpellID in pairs(repairSpells) do
        if spellID == repairSpellID then
          local cur, max
          for i = 1, 18 do
              cur, max = GetInventoryItemDurability(i);
              if cur and max then
                  if (cur/max) <= 0.9 then
                    addon.ShowReminder('repairDown')
                    return
                  end
              end
              return
          end
        end
      end
    end
  end
  if not testing then
    addon.HideReminder('repairDown')
  end
end

noReleaseReminder = function(e, ...)
  if e == 'PLAYER_DEAD' and UnitHealth('player') == 0 and StaticPopup1:IsShown() and StaticPopup1Button1:GetText() == 'Release Spirit' and addon.InRaidIdle() then
    StaticPopup_Show('WANT_TO_RELEASE')
    if StaticPopup1Button1:GetButtonState() == 'NORMAL' then
      StaticPopup1Button1:Disable()
    end
    addon.ShowReminder('noRelease')
  else
    addon.HideReminder('noRelease')
  end
end