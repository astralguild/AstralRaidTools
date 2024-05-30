local ADDON_NAME, addon = ...
local L = addon.L

ASTRAL_RAID_TOOLS = 'Astral Raid Tools'
ASTRAL_GUILD = 'Astral'
ASTRAL_INFO = ASTRAL_GUILD .. ' - Area 52 (US)'

LibStub('AceAddon-3.0'):NewAddon(addon, ADDON_NAME, 'AceConsole-3.0')

addon.icon = LibStub('LibDBIcon-1.0')

addon.CLIENT_VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, 'Version')

addon.Modules = {}
addon.ModulesOptions = {}
addon.A = {}
addon.W = {}
addon.mod = {}

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

local DEFAULT_SETTINGS = {
	profile = {

	},
	global = {
		general = {
			debug = { isEnabled = false, showAllMenus = false },
			show_minimap_button = true,
			font = { name = 'PT Sans Narrow', size = 72 },
			sounds = { channel = 'Master' }
		},
		wa = { required = {} },
		addons = { required = {} },
		texts = {
			position = { x = 0, y = 400 },
			reminders = { inRaid = true, inParty = false, outsideInstances = false, enable = true },
			alerts = { outsideInstances = false, enable = true },
			enabled = {},
			sounds = {},
		},
		notifiers = {
			general = { isEnabled = false, toConsole = true, toOfficer = false, toRaid = false },
			instances = {},
			encounters = {},
		},
		earlypull = {
			general = { isEnabled = false, printResults = true },
			announce = { onlyGuild = false, earlyPull = 1, onTimePull = 1, latePull = 1, untimedPull = 1 },
		}
	}
}


function addon:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New('AstralRaidToolsDB', DEFAULT_SETTINGS)

	-- Shim layer to back the AstralRaidSettings object with the global DB
	AstralRaidSettings = self.db.global

	--AstralRaidSettings.general.debug.isEnabled = true
	addon.Debug = AstralRaidSettings.general.debug.isEnabled

	if addon.Debug then addon.PrintDebug('ADDON_LOADED') end
end

-- WA Library Hooks

AstralRaidLibrary = {}
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

function AstralRaidLibrary:IsRemix()
	return addon.IsRemix()
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
	for _, name, class, guid, rank, level, online, isDead, combatRole, nameWithRealm in addon.IterateRoster do
		l[#l + 1] = {
			name = name,
			class = class,
			guid = guid,
			rank = rank,
			level = level,
			online = online,
			isDead = isDead,
			combatRole = combatRole,
			nameWithRealm = nameWithRealm
		}
	end
	return l
end

function AstralRaidLibrary:GetGuildRoster()
	local l = {}
	for _, name, class, guid, rank, level, online, nameWithRealm, canSpeakInOfficerChat in addon.IterateGuildRoster do
		l[#l + 1] = {
			name = name,
			class = class,
			guid = guid,
			rank = rank,
			level = level,
			online = online,
			nameWithRealm = nameWithRealm,
			isOfficer = canSpeakInOfficerChat,
		}
	end
	return l
end