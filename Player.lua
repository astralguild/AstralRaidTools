local _, addon = ...

addon.PlayerClass = select(2, UnitClass('player'))
addon.PlayerNameRealm = UnitName('player') .. '-' .. GetRealmName():gsub("%s+", "")

function addon.GetPlayerRole()
	local role = UnitGroupRolesAssigned('player')
	local class = addon.PlayerClass
	if role == 'HEALER' then
		return role, (class == 'PALADIN' or class == 'MONK') and 'MHEALER' or 'RHEALER'
	elseif role ~= 'DAMAGER' then
		return role -- tank
	else
		local melee = (class == 'WARRIOR' or class == 'PALADIN' or class == 'ROGUE' or class == 'DEATHKNIGHT' or class == 'MONK' or class == 'DEMONHUNTER')
		if class == 'DRUID' then
			melee = GetSpecialization() ~= 1
		elseif class == 'SHAMAN' then
			melee = GetSpecialization() == 2
		elseif class == 'HUNTER' then
			melee = GetSpecialization() == 3
		end
		local subrole = 'RDD'
		if melee then
			subrole = 'MDD'
		end
		return role, subrole
	end
end

function addon.GetWeakAuras()
	if not WeakAurasSaved then
		return {}
	end
	local wa = {}
	for waName, waData in pairs(WeakAurasSaved.displays) do
		wa[waName] = waData
	end
	return wa
end

function addon.GetAddons()
	local addons = {}
	for i = 1, GetNumAddOns() do
		local name, title, _, _, _, _, _ = GetAddOnInfo(i)
		addons[name] = {
			name = name,
			title = title,
			version = C_AddOns.GetAddOnMetadata(name, 'Version') or '',
		}
	end
	return addons
end

function addon.IsRaidLead()
	return (IsInRaid() and (UnitIsGroupAssistant('player') or UnitIsGroupLeader('player'))) or addon.Debug
end

function addon.IsOfficer()
	return C_GuildInfo.IsGuildOfficer() or addon.Debug
end