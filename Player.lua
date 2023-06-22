local ADDON_NAME, addon = ...

addon.AddonList = {}
addon.WeakAuraList = {}
addon.PlayerClass = select(2, UnitClass('player'))
addon.PlayerNameRealm = UnitName('player') .. '-' .. GetRealmName():gsub("%s+", "")

function addon.GetWeakAuras()
	if not WeakAurasSaved then
		return
	end
	addon.AddonList['WeakAuras'] = true

	local auras, ind = {}, {}

	for waName, waData in pairs(WeakAurasSaved.displays) do
		local aura = ind[waName]
		if aura then
			aura.name = waName
			aura.data = waData
		else
			aura = {
				name = waName,
				data = waData,
			}
		end

		local parent = waData.parent
		if parent then
			local a = ind[parent] or {}
			ind[parent] = a
			a[#a+1] = aura
		else
			auras[#auras+1] = aura
		end
		ind[waName] = aura
	end

	for i = 1, #auras do
		addon.WeakAuraList[auras[i].name] = auras[i].url
	end
end