local _, addon = ...

function addon.IsAstralGuild()
  local guild = GetGuildInfo('player')
  return guild == 'Astral' and GetRealmName():gsub('%s+', '') == 'Area52'
end

local FACTS_COMMAND = '!facts'

local facts = {
  [1] = "Cryxian bought the deed to Flavortown.",
  [2] = "Ayegon is the mayor of Flavortown.",
  [3] = "Look at Terra's health.",
}

local function sendFact(channel)
  local i = math.random(1, #facts) % (GetNumGroupMembers() or 40)
  for index, name in addon.IterateRoster do
    if name == addon.PlayerName and (index == i or addon.IsOfficer() or addon.IsRaidLead()) then
      SendChatMessage(facts[math.random(1, #facts)], channel)
      return
    end
  end
end

local function parseFactsCmd(text, channel)
  if #facts == 0 then return end
	text = gsub(text, '^%[%a+%] ', '') -- Strip off [SomeName] from message from using Identity-2
	if text:lower() == FACTS_COMMAND and addon.IsAstralGuild() then sendFact(channel) end
end

AstralRaidEvents:Register('CHAT_MSG_RAID', function(t) parseFactsCmd(t, 'RAID') end, 'AstralRaidParseRaidFactsCmd')
AstralRaidEvents:Register('CHAT_MSG_RAID_LEADER', function(t) parseFactsCmd(t, 'RAID') end, 'AstralRaidParseRaidFactsCmd')
AstralRaidEvents:Register('CHAT_MSG_PARTY', function(t) parseFactsCmd(t, 'PARTY') end, 'AstralRaidParsePartyFactsCmd')
AstralRaidEvents:Register('CHAT_MSG_PARTY_LEADER', function(t) parseFactsCmd(t, 'PARTY') end, 'AstralRaidParsePartyFactsCmd')

function AstralRaidLibrary:IsAstralGuild()
  return addon.IsAstralGuild()
end