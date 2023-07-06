local _, addon = ...

if not AstralRaidSettings then
  AstralRaidSettings = {}
end

function addon.AddDefaultSettings(category, name, data)
  if not category or type(category) ~= 'string' then
		error('AddDefaultSettings(category, name, data) category: string expected, received ' .. type(category))
	end
	if data == nil then
		error('AddDefaultSettings(data, name, data) data expected, received ' .. type(data))
	end

	if not AstralRaidSettings[category] then
		AstralRaidSettings[category] = {}
	end

	if AstralRaidSettings[category][name] == nil then
		AstralRaidSettings[category][name] = data
	else
		if type(data) == 'table' then
			for newKey, newValue in pairs(data) do
				local found = false
				for oldKey in pairs(AstralRaidSettings[category][name]) do
					if oldKey == newKey then
						found = true
						break
					end
				end

				if not found then
					AstralRaidSettings[category][name][newKey] = newValue
				end
			end
		end
	end
end

function addon.LoadDefaultSettings()
	addon.AddDefaultSettings('general', 'debug', {isEnabled = false})
	addon.AddDefaultSettings('general', 'show_minimap_button', {isEnabled = true})
	addon.AddDefaultSettings('general', 'font', {name = 'PT Sans Narrow', size = 72})
	addon.AddDefaultSettings('general', 'sounds', {channel = 'Master'})
	addon.AddDefaultSettings('wa', 'required', {})
	addon.AddDefaultSettings('addons', 'required', {})
	addon.AddDefaultSettings('texts', 'position', {x = 0, y = 400})
	addon.AddDefaultSettings('texts', 'reminders', {inRaid = true, inParty = false, outsideInstances = false, enable = true})
	addon.AddDefaultSettings('texts', 'alerts', {outsideInstances = false, enable = true})
	addon.AddDefaultSettings('texts', 'enabled', {})
	addon.AddDefaultSettings('texts', 'sounds', {})
	addon.AddDefaultSettings('notifiers', 'general', {isEnabled = true, toConsole = true, toOfficer = false, toRaid = false})
	addon.AddDefaultSettings('notifiers', 'encounters', {})
	addon.AddDefaultSettings('frame', 'orientation', 1)
	addon.AddDefaultSettings('frame', 'rank_filter',
	{
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = true,
		[9] = true,
		[10] = true,
	})

	addon.Debug = AstralRaidSettings.general.debug.isEnabled
end