local ADDON_NAME, addon = ...

function addon.IsAstralGuild()
  local guild = GetGuildInfo('player')
  return guild == ASTRAL_GUILD and GetRealmName():gsub('%s+', '') == 'Area52'
end

local function printAstral(s)
  print(WrapTextInColorCode(ASTRAL_RAID_TOOLS .. ': ' .. s, 'fff5e4a8'))
end

local facts = {
  [1] = "Cryxian bought the deed to Flavortown",
  [2] = "Ayegon is the mayor of Flavortown",
  [3] = "Look at Terra's health",
  [4] = "Hark the return of the Golden Shower Prince",
  [5] = "Terra: has a cat",
  [6] = "Terra is also a computer case",
  [7] = "Luna can't pronounce 'affix' or 'desiruous'",
}

local function printFact()
  if #facts == 0 then return end
  printAstral(string.format('"%s"', facts[math.random(1, #facts)]))
end

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
  local choices = {strsplit(' ', text)}
  -- send chat addon message
  -- TODO
end

-- Handlers

local commands = {
  ['!facts'] = {f = sendFact},
  --['!poll'] = {f = sendPoll, leadProtected = true},
}

local function parseCmds(text, channel)
	text = gsub(text, '^%[%a+%] ', '') -- Strip off [SomeName] from message from using Identity-2
  local c, t = strsplit(' ', text, 1)
  for cmd, obj in pairs(commands) do
    if c:lower() == cmd then
      if obj.leadProtected and not (addon.IsPartyLead() or addon.IsRaidLead() or addon.IsOfficer()) then return end
      if obj.debug and not addon.Debug then return end
      obj.f(t, channel)
      return
    end
  end
end

AstralRaidEvents:Register('ADDON_LOADED', function(addonName)
	if addonName == ADDON_NAME and addon.IsAstralGuild() then
    -- Login message
		AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', function()
      if AstralRaidSettings.astral.facts.onStartup then printFact() end
      AstralRaidEvents:Unregister('PLAYER_ENTERING_WORLD', 'AstralRaidAstralGuildOnEnterWorld')
    end, 'AstralRaidAstralGuildOnEnterWorld')

    -- Command events
    AstralRaidEvents:Register('CHAT_MSG_RAID', function(t) parseCmds(t, 'RAID') end, 'AstralRaidParseRaidCmd')
    AstralRaidEvents:Register('CHAT_MSG_RAID_LEADER', function(t) parseCmds(t, 'RAID') end, 'AstralRaidParseRaidCmd')
    AstralRaidEvents:Register('CHAT_MSG_PARTY', function(t) parseCmds(t, 'PARTY') end, 'AstralRaidParsePartyCmd')
    AstralRaidEvents:Register('CHAT_MSG_PARTY_LEADER', function(t) parseCmds(t, 'PARTY') end, 'AstralRaidParsePartyCmd')
	end
end, 'AstralRaidAstralGuildInit')

-- Library Hooks

AstralRaidLibrary.Cmds = commands
AstralRaidLibrary.Facts = facts

function AstralRaidLibrary:IsAstralGuild()
  return addon.IsAstralGuild()
end

function AstralRaidLibrary:GetRandomFact()
  return facts[math.random(1, #facts)]
end

function AstralRaidLibrary:RegisterAstralGuildCommand(cmd, f, leadProtected, debug)
  if not commands[cmd] then
    commands[cmd] = {f = f, leadProtected = leadProtected, debug = debug}
  end
end