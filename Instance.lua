local _, addon = ...

addon.IsRemix = C_UnitAuras.GetPlayerAuraBySpellID(424143) -- Mists of Pandaria Remix

addon.InInstance = false
addon.InstanceType = nil

addon.InEncounter = false
addon.Encounter = nil

function addon.GetInstanceChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and addon.InInstance then
		return 'INSTANCE_CHAT'
	elseif IsInRaid() then
		return 'RAID'
	elseif IsInGroup() then
		return 'PARTY'
	end
end

local bw, bwClear
do
	local isAdded = nil
	local prevPhase = nil
	function bw()
		if isAdded then
			return
		end
		if (BigWigsLoader) and BigWigsLoader.RegisterMessage then
			local r = {}
			function r:BigWigs_Message(event, module, key, text, ...)
				if (key == 'stages') then
					local phase = text:gsub ('.*%s', '')
					phase = tonumber(phase)
					if (phase and type(phase) == 'number' and prevPhase ~= phase) then
						prevPhase = phase
						addon.Encounter.phase = phase
					end
				end
			end
			BigWigsLoader.RegisterMessage(r, 'BigWigs_Message')
			isAdded = true
		end
	end
	function bwClear()
		prevPhase = nil
	end
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', function()
  addon.InInstance, addon.InstanceType = IsInInstance()
	addon.IsRemix = addon.IsRemix or C_UnitAuras.GetPlayerAuraBySpellID(424143)
end, 'GetInstance')

AstralRaidEvents:Register('ENCOUNTER_START', function(encounterID, encounterName, difficultyID, groupSize)
  addon.InEncounter = true
  addon.Encounter = {
    encounterID = encounterID,
    encounterName = encounterName,
    difficultyID = difficultyID,
    groupSize = groupSize,
    start = GetTime(),
    phase = 1,
		whoPulled = nil,
  }
  bwClear()
	bw()
end, 'StartEncounter')

AstralRaidEvents:Register('ENCOUNTER_END', function()
  addon.InEncounter = false
  addon.Encounter['end'] = GetTime()
end, 'EndEncounter')
