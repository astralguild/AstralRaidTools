local _, addon = ...

addon.InInstance = false
addon.InstanceType = nil

addon.InEncounter = false
addon.Encounter = nil

function addon.CheckInstanceType()
	local inInstance, instanceType = IsInInstance()
  addon.InInstance = inInstance
  addon.InstanceType = instanceType
end

function addon.InRaidIdle()
  return addon.InInstance and addon.InstanceType == 'raid' and not addon.InEncounter
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

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', addon.CheckInstanceType, 'astralRaidGetInstance')

AstralRaidEvents:Register('ENCOUNTER_START', function(encounterID, encounterName, difficultyID, groupSize)
  addon.InEncounter = true
  addon.Encounter = {
    encounterID = encounterID,
    encounterName = encounterName,
    difficultyID = difficultyID,
    groupSize = groupSize,
    start = GetTime(),
    phase = 1,
  }
  bwClear()
	bw()
end, 'astralRaidStartEncounter')

AstralRaidEvents:Register('ENCOUNTER_END', function()
  addon.InEncounter = false
  addon.Encounter['end'] = GetTime()
end, 'astralRaidEndEncounter')