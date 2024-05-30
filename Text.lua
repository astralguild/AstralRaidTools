local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

AstralRaidText = CreateFrame('FRAME', 'AstralRaidText', UIParent)
AstralRaidText:SetHeight(1)
AstralRaidText:SetWidth(1)
AstralRaidText:SetPoint('CENTER', UIParent, 'CENTER')
AstralRaidText:Hide()

AstralRaidText.testing = false

local texts = {}
local displayed = {}
local state = {}
local remindersState = {}
local wasShownBeforeTest = false
local remindersShownBeforeCombat = false

function addon.CreateText(name, text, type)
  if texts[name] then
    return texts[name]
  end

  local fontPath = SharedMedia:Fetch('font', AstralRaidSettings.general.font.name)
  texts[name] = AstralRaidText:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
  texts[name]:SetPoint('CENTER', 0, 400)
  texts[name]:SetFont(fontPath, AstralRaidSettings.general.font.size, 'OUTLINE')
  texts[name]:SetText(text)
  texts[name]:Hide()

  texts[name]:SetScript('OnShow', function(self)
    if #displayed > 0 then
      self:SetPoint('TOP', displayed[#displayed], 'BOTTOM', 0, -5)
    else
      self:SetPoint('CENTER', 0, 400)
    end
    displayed[#displayed+1] = self
  end)

  texts[name]:SetScript('OnHide', function(self)
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
      AstralRaidText:Hide()
    end
  end)

  texts[name].type = type

  return texts[name]
end

function addon.UpdateTextsFonts()
  for _, r in pairs(texts) do
    r:SetFont(SharedMedia:Fetch('font', AstralRaidSettings.general.font.name), AstralRaidSettings.general.font.size, 'OUTLINE')
  end
end

function addon.TestTexts(show, numToShow)
  if show then
    if AstralRaidText:IsShown() then
      wasShownBeforeTest = true
    else
      AstralRaidText:Show()
      wasShownBeforeTest = false
    end
    local count = 0
    for name, r in pairs(texts) do
      if count >= numToShow then
        break
      end
      state[name] = r:IsShown()
      r:Show()
      count = count + 1
    end
    AstralRaidText.testing = true
  else
    AstralRaidText:SetShown(wasShownBeforeTest)
    for name, shown in pairs(state) do
      texts[name]:SetShown(shown)
    end
    AstralRaidText.testing = false
  end
end

function addon.ShowText(name)
  if not texts[name] then
    return
  end
  if not AstralRaidText:IsShown() then
    AstralRaidText:Show()
    state[name] = true
    remindersState[name] = true
  end
  texts[name]:Show()
end

function addon.HideText(name)
  if not texts[name] then
    return
  end
  if texts[name]:IsShown() then
    texts[name]:Hide()
  end
  state[name] = false
  remindersState[name] = false
end

-- Basic Checks

local function canShowReminder()
  if addon.IsRemix() then return false end
  return (IsInRaid() or (IsInGroup() and AstralRaidSettings.texts.reminders.inParty)) and addon.InInstance and not addon.InEncounter and not InCombatLockdown() and 
AstralRaidSettings.texts.reminders.enable
end

local function canShowAlert()
  return (IsInRaid() or IsInGroup()) and addon.InInstance and addon.InEncounter and AstralRaidSettings.texts.alerts.enable
end

local function canShowText(type)
  if type == 'REMINDER' then
    return canShowReminder() or (not InCombatLockdown() and AstralRaidSettings.texts.reminders.outsideInstances)
  elseif type == 'ALERT' then
    return canShowAlert() or AstralRaidSettings.texts.alerts.outsideInstances
  end
  return true
end

local function textIsEnabled(name)
  return AstralRaidSettings.texts.enabled[name]
end

-- Event Wiring
-- Semi-recreating the WeakAuras scripting environment

local events = {}

local function handle(e, event, ...)
  local t = texts[e.name]
  if not t then return end
  if t.type == 'REMINDER' and (InCombatLockdown() or C_PvP.IsPVPMap()) then return end
  local action = e.f(event, ...)
  if action then
    if action == 'SHOW' and canShowText(t.type) and textIsEnabled(e.name) then
      if not texts[e.name]:IsShown() then
        addon.PrintDebug('showText', t.type, e.name, event, ...)
        local sound = AstralRaidSettings.texts.sounds[e.name] or e.sound
        if sound and sound ~= 'None' then
          local path = addon.SharedMedia:Fetch('sound', sound, true)
          PlaySoundFile(path or sound, AstralRaidSettings.general.sounds.channel)
        end
      end
      addon.ShowText(e.name)
    elseif action == 'HIDE' and not AstralRaidText.testing then
      if texts[e.name]:IsShown() then
        addon.PrintDebug('hideText', t.type, e.name, event, ...)
      end
      addon.HideText(e.name)
    end
  end
end

local function hideRemindersForCombat()
  if AstralRaidText:IsShown() then
    for name, r in pairs(texts) do
      if r.type == 'REMINDER' then
        remindersState[name] = r:IsShown()
        r:Hide()
      end
    end
    remindersShownBeforeCombat = true
  end
end

local function showRemindersAfterCombat()
  if remindersShownBeforeCombat then
    C_Timer.After(3, function()
      if not InCombatLockdown() then
        AstralRaidText:Show()
        for name, shown in pairs(remindersState) do
          texts[name]:SetShown(shown)
        end
        remindersShownBeforeCombat = false
        remindersState = {}
      end
    end)
  end
end

local function enterInstance(...)
  for _, e in pairs(events.enterInstance) do handle(e, 'PLAYER_ENTERING_WORLD', ...) end
end

local function enterCombat(...)
  hideRemindersForCombat()
  if not events.enterCombat then return end
  for _, e in pairs(events.enterCombat) do
    handle(e, 'PLAYER_ENTER_COMBAT', ...)
  end
end

local function leaveCombat(...)
  showRemindersAfterCombat()
  if not events.leaveCombat then return end
  for _, e in pairs(events.leaveCombat) do
    handle(e, 'PLAYER_LEAVE_COMBAT', ...)
  end
end

local function resurrected(...)
  for _, e in pairs(events.resurrected) do handle(e, 'PLAYER_ALIVE', ...) end
end

local function dead(...)
  for _, e in pairs(events.dead) do handle(e, 'PLAYER_DEAD', ...) end
end

local function alive(...)
  for _, e in pairs(events.alive) do handle(e, 'PLAYER_UNGHOST', ...) end
end

local function cleu(...)
  for _, e in pairs(events.cleu) do handle(e, 'COMBAT_LOG_EVENT_UNFILTERED', CombatLogGetCurrentEventInfo()) end
end

function addon.AddTextEventCallback(func, name, event, sound)
  if not events[event] then
    events[event] = {}
  end
  table.insert(events[event], {f = func, name = name, sound = sound})
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', enterInstance, 'TextsEnterInstance')
AstralRaidEvents:Register('PLAYER_ENTER_COMBAT', enterCombat, 'TextsEnterCombat')
AstralRaidEvents:Register('PLAYER_LEAVE_COMBAT', leaveCombat, 'TextsLeaveCombat')
AstralRaidEvents:Register('PLAYER_ALIVE', resurrected, 'TextsResurrected')
AstralRaidEvents:Register('PLAYER_DEAD', dead, 'TextsDeath')
AstralRaidEvents:Register('PLAYER_UNGHOST', alive, 'TextsAlive')
AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'TextsCLEU')

-- Library Hooks

function AstralRaidLibrary:CreateText(name, text, type)
  return addon.CreateText(name, text, type)
end

function AstralRaidLibrary:AddTextEventCallback(func, name, event, sound)
  addon.AddTextEventCallback(func, name, event, sound)
end
