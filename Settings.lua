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
  addon.AddDefaultSettings('general', 'debug', {isEnabled = false, showAllMenus = false})
  addon.AddDefaultSettings('general', 'show_minimap_button', {isEnabled = true})
  addon.AddDefaultSettings('general', 'font', {name = 'PT Sans Narrow', size = 72})
  addon.AddDefaultSettings('general', 'sounds', {channel = 'Master'})
  addon.AddDefaultSettings('bossModules', 'privateAuras', {largeIconSize = 512, smallIconSize = 64})
  addon.AddDefaultSettings('bossModules', 2684, {isEnabled = false, printResults = true, logResults = false, announce = 5, showIcon = true})
  addon.AddDefaultSettings('wa', 'required', {})
  addon.AddDefaultSettings('addons', 'required', {})
  addon.AddDefaultSettings('texts', 'position', {x = 0, y = 400})
  addon.AddDefaultSettings('texts', 'reminders', {inRaid = true, inParty = false, outsideInstances = false, enable = true})
  addon.AddDefaultSettings('texts', 'alerts', {outsideInstances = false, enable = true})
  addon.AddDefaultSettings('texts', 'enabled', {})
  addon.AddDefaultSettings('texts', 'sounds', {})
  addon.AddDefaultSettings('notifiers', 'general', {isEnabled = false, toConsole = true, toOfficer = false, toRaid = false})
  addon.AddDefaultSettings('notifiers', 'instances', {})
  addon.AddDefaultSettings('notifiers', 'encounters', {})
  addon.AddDefaultSettings('earlypull', 'general', {isEnabled = false, printResults = true})
  addon.AddDefaultSettings('earlypull', 'announce', {onlyGuild = false, earlyPull = 1, onTimePull = 1, latePull = 1, untimedPull = 1})

  local encounters = addon.GetEncountersList(true, true)
  for i = 1, #encounters do
    local instance = encounters[i]
    if not AstralRaidSettings.notifiers.instances[instance[1]] then
      AstralRaidSettings.notifiers.instances[instance[1]] = {
        encounters = {},
      }
    end

    for j = 2, #instance do
      if not AstralRaidSettings.notifiers.encounters[instance[j]] then
        AstralRaidSettings.notifiers.encounters[instance[j]] = {
          name = addon.GetBossName(instance[j]),
          auras = {},
          casts = {},
          hps = {},
          pows = {},
        }
        table.insert(AstralRaidSettings.notifiers.instances[instance[1]].encounters, instance[j])
      end
    end
  end

  addon.Debug = AstralRaidSettings.general.debug.isEnabled
end