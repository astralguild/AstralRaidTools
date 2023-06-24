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

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', addon.CheckInstanceType, 'astralRaidEnteringWorld')

AstralRaidEvents:Register('ENCOUNTER_START', function(encounterID, encounterName, difficultyID, groupSize)
  addon.InEncounter = true
  addon.Encounter = {
    encounterID = encounterID,
    encounterName = encounterName,
    difficultyID = difficultyID,
    groupSize = groupSize,
  }
end, 'astralRaidStartEncounter')

AstralRaidEvents:Register('ENCOUNTER_END', function()
  addon.InEncounter = false
end, 'astralRaidEndEncounter')