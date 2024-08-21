local _, addon = ...

AstralInstanceLib = {}

AstralInstanceLib.InInstance = false
AstralInstanceLib.InstanceType = nil

AstralInstanceLib.InEncounter = false
AstralInstanceLib.Encounter = nil

AstralInstanceLib.BigWigsListenerAdded = false

AstralInstanceLib.Tiers = nil

AstralInstanceLib.NORMAL_RAID_DIFFICULTY = 14
AstralInstanceLib.HEROIC_RAID_DIFFICULTY = 15
AstralInstanceLib.MYTHIC_RAID_DIFFICULTY = 16

AstralInstanceLib.AllRaidInstances = {
    ByName = {}
}
AstralInstanceLib.AllRaidEncounters = {
    ByDungeonEncounterID = {} -- This is the ID used in ENCOUNTER_START.
}

function AstralInstanceLib:Init()
    self:InitEncounterJournalData()
end

function AstralInstanceLib:InitEncounterJournalData(forceRefresh)
    if self.Tiers and (not forceRefresh) then
        return
    end
    self.Tiers = {
        ByName = {},
        ByIndex = {},
    }
    for tierNum=1,EJ_GetNumTiers() do
        local tierInfo = self:_ParseTierInfo(tierNum)
        self.Tiers.ByName[tierInfo.Name] = tierInfo
        self.Tiers.ByIndex[tierInfo.TierIndex] = tierInfo
        addon.PrintDebug('Loaded Tier ' .. tierInfo.Name .. '(' .. tierInfo.TierIndex .. ')' .. ' with ' .. #tierInfo.Instances.ByIndex .. ' instances and ' .. #tierInfo.RaidInstances.ByIndex .. ' raid instances')
    end
    for _,tier in pairs(self.Tiers.ByIndex) do
        for _,instance in pairs(tier.RaidInstances.ByIndex) do
            self.AllRaidInstances.ByName[instance.Name] = instance
            for _,encounter in pairs(instance.Encounters.ByIndex) do
                if encounter.DungeonEncounterID then
                    self.AllRaidEncounters.ByDungeonEncounterID[encounter.DungeonEncounterID] = encounter
                end
            end
        end
    end
end

function AstralInstanceLib:_ParseTierInfo(tierNum)
    tierName, _ = EJ_GetTierInfo(tierNum)
    local tierInfo = {
        TierIndex = tierNum,
        Name = tierName,
        Instances = {
            ByIndex = {},
            ByName = {},
            ByJournalInstanceID = {},
            ByMapID = {},
        },
        RaidInstances = {
            ByIndex = {},
            ByName = {},
            ByJournalInstanceID = {},
            ByMapID = {},
        },
    }

    EJ_SelectTier(tierNum)

    -- Dungeon Instances
    local instanceIndex = 1
    local instanceInfo = self:_ParseInstanceInfo(instanceIndex, --[[ isRaid ]] false)
    while instanceInfo do
        tierInfo.Instances.ByIndex[instanceInfo.IndexInTier] = instanceInfo
        tierInfo.Instances.ByName[instanceInfo.Name] = instanceInfo
        tierInfo.Instances.ByJournalInstanceID[instanceInfo.JournalInstanceID] = instanceInfo
        tierInfo.Instances.ByMapID[instanceInfo.MapID] = instanceInfo
        instanceIndex = instanceIndex + 1
        instanceInfo = self:_ParseInstanceInfo(instanceIndex, --[[ isRaid ]] false)
    end

    -- Raid Instances and World Bosses
    instanceIndex = 1
    instanceInfo = self:_ParseInstanceInfo(instanceIndex, --[[ isRaid ]] true)
    while instanceInfo do
        tierInfo.RaidInstances.ByIndex[instanceInfo.IndexInTier] = instanceInfo
        tierInfo.RaidInstances.ByName[instanceInfo.Name] = instanceInfo
        tierInfo.RaidInstances.ByJournalInstanceID[instanceInfo.JournalInstanceID] = instanceInfo
        tierInfo.RaidInstances.ByMapID[instanceInfo.MapID] = instanceInfo
        instanceIndex = instanceIndex + 1
        instanceInfo = self:_ParseInstanceInfo(instanceIndex, --[[ isRaid ]] true)
    end

    return tierInfo
end

function AstralInstanceLib:_ParseInstanceInfo(instanceIndex, isRaid)
    local journalInstanceID, name, description, bgImage,
    buttonImage1, loreImage, buttonImage2, dungeonAreaMapID,
    link, shouldDisplayDifficulty, instanceID = EJ_GetInstanceByIndex(instanceIndex, isRaid)
    if not name then
        return nil
    end

    local instanceInfo = {
        Name = name,
        Description = description,
        JournalInstanceID = journalInstanceID,
        MapID = instanceID,
        UIMapID = dungeonAreaMapID,
        Encounters = {
            ByIndex = {},
            ByName = {},
            ByJournalEncounterID = {},
            ByDungeonEncounterID = {}
        },
        IndexInTier = instanceIndex,
    }

    EJ_SelectInstance(journalInstanceID)

    encounterIndex = 1
    encounterInfo = self:_ParseEncounterInfo(encounterIndex)
    while encounterInfo do
        instanceInfo.Encounters.ByIndex[encounterInfo.IndexInInstance] = encounterInfo;
        instanceInfo.Encounters.ByName[encounterInfo.Name] = encounterInfo;
        instanceInfo.Encounters.ByJournalEncounterID[encounterInfo.JournalEncounterID] = encounterInfo;
        if encounterInfo.DungeonEncounterID then
            instanceInfo.Encounters.ByDungeonEncounterID[encounterInfo.DungeonEncounterID] = encounterInfo;
        else
            -- addon.PrintDebug('[Warning] No DungeonEncounterID for ' .. encounterInfo.Name)
        end
        encounterIndex = encounterIndex + 1
        encounterInfo = self:_ParseEncounterInfo(encounterIndex)
    end

    return instanceInfo
end

function AstralInstanceLib:_ParseEncounterInfo(encounterIndex)
    local name, description, journalEncounterID, rootSectionID, link,
    journalInstanceID, dungeonEncounterID, instanceID = EJ_GetEncounterInfoByIndex(encounterIndex)

    if not name then
        return nil
    end

    local encounterInfo = {
        Name = name,
        Description = description,
        JournalEncounterID = journalEncounterID,
        DungeonEncounterID = dungeonEncounterID,
        RootSectionID = rootSectionID,
        MapID = instanceID,
        JournalInstanceID = journalInstanceID,
        IndexInInstance = encounterIndex,
        JournalSectionIDs = {
            ByIndex = nil
        },
        Abilities = {
            Normal = {
                ByIndex = {},
                BySpellID = {},
                BySpellName = {},
            },
            Heroic = {
                ByIndex = {},
                BySpellID = {},
                BySpellName = {},
            },
            Mythic = {
                ByIndex = {},
                BySpellID = {},
                BySpellName = {},
            },
        },
    }

    EJ_SetDifficulty(self.MYTHIC_RAID_DIFFICULTY)
    if not rootSectionID then
        addon.PrintDebug(name .. ' has nil rootSectionID')
    end
    local journalSectionIDs = self:_AccumulateJournalSectionIDs({}, rootSectionID);
    encounterInfo.JournalSectionIDs.ByIndex = journalSectionIDs
    for index,ability in ipairs(self:_GetAbilitiesInJournalOrder(journalSectionIDs, self.MYTHIC_RAID_DIFFICULTY)) do
        encounterInfo.Abilities.Mythic.ByIndex[index] = ability
        encounterInfo.Abilities.Mythic.BySpellID[ability.SpellID] = ability
        if ability.SpellName then
            encounterInfo.Abilities.Mythic.BySpellName[ability.SpellName] = ability
        end
    end
    for index,ability in ipairs(self:_GetAbilitiesInJournalOrder(journalSectionIDs, self.HEROIC_RAID_DIFFICULTY)) do
        encounterInfo.Abilities.Heroic.ByIndex[index] = ability
        encounterInfo.Abilities.Heroic.BySpellID[ability.SpellID] = ability
        if ability.SpellName then
            encounterInfo.Abilities.Heroic.BySpellName[ability.SpellName] = ability
        end
    end
    for index,ability in ipairs(self:_GetAbilitiesInJournalOrder(journalSectionIDs, self.NORMAL_RAID_DIFFICULTY)) do
        encounterInfo.Abilities.Normal.ByIndex[index] = ability
        encounterInfo.Abilities.Normal.BySpellID[ability.SpellID] = ability
        if ability.SpellName then
            encounterInfo.Abilities.Normal.BySpellName[ability.SpellName] = ability
        end
    end
    return encounterInfo
end

function AstralInstanceLib:_AccumulateJournalSectionIDs(result, sectionID)
    if sectionID then
        local sectionInfo = C_EncounterJournal.GetSectionInfo(sectionID)
        if sectionInfo then
            result[#result + 1] = sectionID
            self:_AccumulateJournalSectionIDs(result, sectionInfo.firstChildSectionID)
            self:_AccumulateJournalSectionIDs(result, sectionInfo.siblingSectionID)
        end
    end
    return result
end

function AstralInstanceLib:_GetAbilitiesInJournalOrder(journalSections, difficulty)
    EJ_SetDifficulty(difficulty)
    local result = {}
    local spellAlreadyAdded = {}
    for _,journalSectionID in ipairs(journalSections) do
        local sectionInfo = C_EncounterJournal.GetSectionInfo(journalSectionID)
        if not sectionInfo.filteredByDifficulty then
            if sectionInfo.spellID then
                local spellID = sectionInfo.spellID
                if spellID > 0 and not spellAlreadyAdded[spellID] then
					local spellInfo = C_Spell.GetSpellInfo(spellID)
                    result[#result + 1] = {
                        SpellID = spellInfo.spellID,
                        SpellName = spellInfo.name,
                        SpellIcon = spellInfo.iconID,
                        JournalSectionID = journalSectionID,
                    }
                    spellAlreadyAdded[spellID] = true
                end
            end
        end
    end
    return result
end

function AstralInstanceLib:GetInstanceChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and self.InInstance then
        return 'INSTANCE_CHAT'
    elseif IsInRaid() then
        return 'RAID'
    elseif IsInGroup() then
        return 'PARTY'
    end
end

function AstralInstanceLib:getRaidEncounterName(dungeonEncounterID)
    return (self.AllRaidEncounters.ByDungeonEncounterID
            and self.AllRaidEncounters.ByDungeonEncounterID[dungeonEncounterID]
            and self.AllRaidEncounters.ByDungeonEncounterID[dungeonEncounterID].Name) or ''
end

function AstralInstanceLib:GetCurrentExpansionRaidInstances()
    local result = {}
    local raidInstances = self.Tiers.ByIndex[#self.Tiers.ByIndex - 1].RaidInstances.ByIndex
    -- Remove the first item, which is typically world bosses (Mists of Pandaria and onwards)
    for k,v in addon.PairsByKeys(raidInstances) do
        if k ~= 1 then
            result[#result + 1] = v
        end
    end
    return result
end

function AstralInstanceLib:MaybeRegisterBigWigsListener()
    if (self.BigWigsListenerAdded)
            or (not BigWigsLoader)
            or (not BigWigsLoader.RegisterMessage) then
        return
    end
    BigWigsLoader.RegisterMessage(self.OnBigWigsMessage, 'BigWigs_Message')
    self.BigWigsListenerAdded = true
end

function AstralInstanceLib:OnBigWigsMessage(event, module, key, text, ...)
    if (key == 'stages') then
        local phase = tonumber(text:gsub ('.*%s', ''))
        if phase and self.Encounter then
            self.Encounter.phase = phase
        end
    end
end

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD',
        function() AstralInstanceLib:Init() end,
     'AstralInstanceLib_PLAYER_ENTERING_WORLD')