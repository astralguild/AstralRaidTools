local ADDON_NAME, addon = ...

addon.AddonList = {}
addon.WeakAuraList = {}
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
		return
	end
	addon.AddonList['WeakAuras'] = true

	for waName, waData in pairs(WeakAurasSaved.displays) do
		addon.WeakAuraList[waName] = waData.url
	end
end