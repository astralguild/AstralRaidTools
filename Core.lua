local ADDON_NAME, addon = ...

ASTRAL_RAID_TOOLS = 'Astral Raid Tools'
ASTRAL_GUILD = 'Astral'
ASTRAL_INFO = ASTRAL_GUILD .. ' - Area 52 (US)'

LibStub('AceAddon-3.0'):NewAddon(addon, ADDON_NAME, 'AceConsole-3.0')

addon.CLIENT_VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, 'Version')

addon.Modules = {}
addon.ModulesOptions = {}
addon.A = {}
addon.W = {}
addon.mod = {}

AstralRaidLibrary = {}

function addon.mod:Event(event, ...)
	return self[event](self, ...)
end

do
	local function mod_LoadOptions(this)
		this:SetScript('OnShow', nil)
		if this.Load then
			this:Load()
		end
		this.Load = nil
		this.isLoaded = true
	end

	function addon:New(moduleName, title, leadProtected, inParty, disabled)
		if addon.A[moduleName] then
			return false
		end
		local m = {}
		for k,v in pairs(addon.mod) do m[k] = v end

		m.options = addon.Options:Add(moduleName, title, leadProtected, inParty, disabled)
		m.options:Hide()
		m.options.moduleName = moduleName
		m.options.name = title or moduleName
		m.options:SetScript('OnShow', mod_LoadOptions)
		addon.ModulesOptions[#addon.ModulesOptions + 1] = m.options

		m.main = CreateFrame('FRAME', nil)
		m.main.events = {}
		m.main:SetScript('OnEvent', addon.mod.Event)

		m.name = moduleName
		table.insert(addon.Modules, m)
		addon.A[moduleName] = m

		return m
	end
end

function addon.Console(...)
	print(WrapTextInColorCode('[' .. ADDON_NAME .. ']', 'fff5e4a8'), ...)
end

function addon.PrintDebug(...)
  if addon.Debug then
    addon.Console(WrapTextInColorCode('D', 'C1E1C1FF'), ...)
  end
end

function addon.PairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

-- WA Library Hooks

AstralRaidLibrary.ClassData = addon.ClassData

function AstralRaidLibrary:Console(...)
	print(WrapTextInColorCode('[' .. ASTRAL_GUILD .. ']', '008888FF'), ...)
end

function AstralRaidLibrary:SendMessage(config, ...)
	if config.officer then
		SendChatMessage(..., 'OFFICER')
	end
	if config.raid then
		SendChatMessage(..., 'RAID')
	end
	if config.raidWarning then
		SendChatMessage(..., 'RAID_WARNING')
	end
	if config.party then
		SendChatMessage(..., 'PARTY')
	end
	if config.instanceChat then
		SendChatMessage(..., 'INSTANCE_CHAT')
	end
	if config.console then
		AstralRaidLibrary:Console(...)
	end
end

function AstralRaidLibrary:GetInstanceChannel()
	return addon.GetInstanceChannel()
end

function AstralRaidLibrary:SendWeakAuraComm(name, msg, channel)
	if addon.W[name] then
		local w = addon.W[name]
		if channel then
			AstralRaidComms:SendChunkedAddonMessages(w.prefix, msg, channel)
		else
			AstralRaidComms:SendChunkedAddonMessages(w.prefix, msg, w.channels[1])
		end
	end
end

function AstralRaidLibrary:RegisterWeakAuraComm(name, prefix, f, channels)
	if not addon.W[name] then
		if not channels then
			channels = {
				[1] = 'RAID',
				[2] = 'PARTY',
				[3] = 'GUILD',
			}
		end
		addon.W[name] = {name = name, prefix = prefix, f = f, channels = channels}
		if f then
			for _, channel in pairs(channels) do
				AstralRaidComms:RegisterPrefix(channel, prefix, function(...)
					local msg, sender = ...
					AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
						local player = Ambiguate(sender, 'short')
						f(channel, player, m)
					end)
				end)
			end
		end
	end
end

function AstralRaidLibrary:GetRoster()
	local l = {}
	for _, name, _, class, guid, rank, level, online, isDead, combatRole in addon.IterateRoster do
		l[#l + 1] = {
			name = name,
			class = class,
			guid = guid,
			rank = rank,
			level = level,
			online = online,
			isDead = isDead,
			combatRole = combatRole,
		}
	end
	return l
end

function AstralRaidLibrary:GetBossAbilities(...)
	return addon.GetBossAbilities(...)
end

function AstralRaidLibrary:GetBossName(bossID)
	return addon.GetBossName(bossID)
end

function AstralRaidLibrary:Encounter()
	return addon.InEncounter, addon.Encounter
end

function AstralRaidLibrary:GetPlayerRole()
  return addon.GetPlayerRole()
end

function AstralRaidLibrary:GetWeakAuras()
  return addon.GetWeakAuras()
end

function AstralRaidLibrary:GetAddons()
  return addon.GetAddons()
end

function AstralRaidLibrary:IsRaidLead()
  return addon.IsRaidLead()
end

function AstralRaidLibrary:IsPartyLead()
  return addon.IsPartyLead()
end

function AstralRaidLibrary:IsOfficer()
  return addon.IsOfficer()
end

function AstralRaidLibrary:GetGroupRank()
  return addon.GetGroupRank()
end