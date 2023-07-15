local ADDON_NAME, addon = ...

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

function AstralRaidLibrary:Console(...)
	print(WrapTextInColorCode('[Astral]', '008888FF'), ...)
end

function AstralRaidLibrary:SendMessage(config, ...)
	if config.officer then
		SendChatMessage(..., 'OFFICER')
	end
	if config.raid then
		SendChatMessage(..., 'RAID')
	end
	if config.console then
		AstralRaidLibrary:Console(...)
	end
end

function AstralRaidLibrary:RegisterWeakAura(name, prefix)
	if not addon.W[name] then
		addon.W[name] = {prefix = prefix}
	end
end

function AstralRaidLibrary:IterateRoster()
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