local ADDON_NAME, addon = ...

LibStub('AceAddon-3.0'):NewAddon(addon, 'AstralRaid', 'AceConsole-3.0')

addon.CLIENT_VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, 'Version')

addon.Modules = {}
addon.ModulesOptions = {}

addon.A = {}

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
	function addon:New(moduleName, title, leadProtected)
		if addon.A[moduleName] then
			return false
		end
		local m = {}
		for k,v in pairs(addon.mod) do m[k] = v end

		m.options = addon.Options:Add(moduleName, title, leadProtected)
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