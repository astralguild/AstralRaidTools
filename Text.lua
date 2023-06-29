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
local wasShownBeforeTest = false

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

function addon.TestTexts(show)
  if show then
    if AstralRaidText:IsShown() then
      wasShownBeforeTest = true
    else
      AstralRaidText:Show()
      wasShownBeforeTest = false
    end
    for name, r in pairs(texts) do
      state[name] = r:IsShown()
      r:Show()
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
  end
  texts[name]:Show()
end

function addon.HideText(name)
  if not (texts[name] or texts[name]:IsShown()) then
    return
  end
  texts[name]:Hide()
end

-- Event Wiring
-- Semi-recreating the WeakAuras scripting environment

local events = {
  ['enterInstance'] = {},
  ['resurrected'] = {},
  ['dead'] = {},
  ['spellcastSuccess'] = {},
  ['cleu'] = {},
}

local function handle(event, ...)
  local t = texts[event.name]
  if not t then return end
  addon.PrintDebug(tostring(event.f), event)
  if (t.type == 'REMINDER' and IsInRaid() and addon.InInstance and not addon.InEncounter) or (t.type == 'ALERT' and addon.InEncounter) or addon.Debug then
    if event.f(event, ...) then
      addon.ShowText(event.name)
    else
      addon.HideText(event.name)
    end
  end
end

local function enterInstance(...)
  for _, e in pairs(events.enterInstance) do handle(e, 'PLAYER_ENTERING_WORLD', ...) end
end

local function resurrected(...)
  for _, e in pairs(events.resurrected) do handle(e, 'PLAYER_ALIVE', ...) end
end

local function dead(...)
  for _, e in pairs(events.dead) do handle(e, 'PLAYER_DEAD', ...) end
end

local function spellcastSuccess(...)
  for _, e in pairs(events.spellcastSuccess) do handle(e, 'UNIT_SPELLCAST_SUCCEEDED', ...) end
end

local function cleu(...)
  for _, e in pairs(events.cleu) do handle(e, 'COMBAT_LOG_EVENT_UNFILTERED', ...) end
end

function addon.AddTextEventCallback(func, name, event)
  if events[event] then
    table.insert(events[event], {
      f = func,
      name = name,
    })
  end
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', enterInstance, 'astralRaidTextsEnterInstance')
AstralRaidEvents:Register('PLAYER_ALIVE', resurrected, 'astralRaidTextsResurrected')
AstralRaidEvents:Register('PLAYER_DEAD', dead, 'astralRaidTextsDeath')
AstralRaidEvents:Register('UNIT_SPELLCAST_SUCCEEDED', spellcastSuccess, 'astralRaidTextsSpellcastSuccess')
AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'astralRaidTextsCLEU')

local remindersShownBeforeCombat = false
local remindersState = {}

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
    AstralRaidText:Show()
    for name, shown in pairs(remindersState) do
      if texts[name].type == 'REMINDER' then
        texts[name]:SetShown(shown)
      end
    end
    remindersShownBeforeCombat = false
    remindersState = {}
  end
end

AstralRaidEvents:Register('PLAYER_ENTER_COMBAT', hideRemindersForCombat, 'astralRaidEnterCombatHideReminders')
AstralRaidEvents:Register('PLAYER_LEAVE_COMBAT', showRemindersAfterCombat, 'astralRaidLeaveCombatShowReminders')