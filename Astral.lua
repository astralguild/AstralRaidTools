local _, addon = ...

function addon.IsAstralGuild()
  local guild = GetGuildInfo('player')
  return guild == 'Astral' and GetRealmName():gsub('%s+', '') == 'Area52'
end

local facts = {
  [1] = "Cryxian bought the deed to Flavortown.",
  [2] = "Ayegon is the mayor of Flavortown.",
  [3] = "Look at Terra's health.",
}

local function sendFact(_, channel)
  if #facts == 0 then return end
  local i = math.random(1, #facts) % (GetNumGroupMembers() or 40)
  for index, name in addon.IterateRoster do
    if name == addon.PlayerName and (index == i or addon.IsOfficer() or addon.IsRaidLead()) then
      SendChatMessage(facts[math.random(1, #facts)], channel)
      return
    end
  end
end

local function sendPoll(text, channel)
  local choices = strsplit(' ', text)
  -- TODO
end

-- Handlers

local commands = {
  ['!facts'] = {f = sendFact},
  ['!poll'] = {f = sendPoll, leadProtected = true},
}

local function parseCmds(text, channel)
	text = gsub(text, '^%[%a+%] ', '') -- Strip off [SomeName] from message from using Identity-2
  local c, t = strsplit(' ', text, 1)
  for cmd, obj in pairs(commands) do
    if c:lower() == cmd and addon.IsAstralGuild() then
      if obj.leadProtected and not (addon.IsPartyLead() or addon.IsRaidLead() or addon.IsOfficer()) then return end
      obj.f(t, channel)
      return
    end
  end
end

AstralRaidEvents:Register('CHAT_MSG_RAID', function(t) parseCmds(t, 'RAID') end, 'AstralRaidParseRaidCmd')
AstralRaidEvents:Register('CHAT_MSG_RAID_LEADER', function(t) parseCmds(t, 'RAID') end, 'AstralRaidParseRaidCmd')
AstralRaidEvents:Register('CHAT_MSG_PARTY', function(t) parseCmds(t, 'PARTY') end, 'AstralRaidParsePartyCmd')
AstralRaidEvents:Register('CHAT_MSG_PARTY_LEADER', function(t) parseCmds(t, 'PARTY') end, 'AstralRaidParsePartyCmd')

-- Library Hooks

AstralRaidLibrary.Cmds = commands

function AstralRaidLibrary:IsAstralGuild()
  return addon.IsAstralGuild()
end