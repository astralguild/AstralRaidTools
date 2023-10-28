local ADDON_NAME, addon = ...

function addon.GetNormalizedRealmName()
    local result = GetNormalizedRealmName()
    if not result then
        result = GetRealmName()
        result = result:gsub("%s+", "")
        result = result:gsub("%-", "")
    end
    return result
end

function addon.Console(...)
    print(WrapTextInColorCode('[' .. ADDON_NAME .. ']', 'fff5e4a8'), ...)
end

function addon.PrintDebug(...)
    if addon.Debug then
        addon.Console(WrapTextInColorCode('D', 'C1E1C1FF'), ...)
    end
end

function addon.DebugTableToString(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. addon.DebugTableToString(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function addon.PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function addon.IterateRoster(_, index)
    index = (index or 0) + 1

    if IsInRaid() then
        if index > 40 then
            return
        end
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(index)
        if name == nil then
            return addon.IterateRoster(_, index)
        end
        local guid = UnitGUID('raid'..index)
        local _, _, guildRank = GetGuildInfo(UnitGUID('raid'..index))
        local namePart, realmPart = UnitFullName('raid'..index)
        realmPart = realmPart or addon.GetNormalizedRealmName()
        return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole, namePart .. '-' .. realmPart, guildRank
    else
        local name, rank, subgroup, level, class, fileName, online, isDead, combatRole, _, nameWithRealm
        local unit = index == 1 and 'player' or 'party'..(index-1)
        local guid = UnitGUID(unit)
        if not guid then
            return
        end
        subgroup = 1
        name, _ = UnitName(unit)
        if _ then
            name = name .. '-' .. _
            nameWithRealm = name
        else
            nameWithRealm = name .. '-' .. addon.GetNormalizedRealmName()
        end

        class, fileName = UnitClass(unit)
        if UnitIsGroupLeader(unit) then
            rank = 2
        else
            rank = 0
        end
        level = UnitLevel(unit)
        if UnitIsConnected(unit) then
            online = true
        end
        if UnitIsDeadOrGhost(unit) then
            isDead = true
        end
        local _, _, guildRank = GetGuildInfo(unit)
        combatRole = UnitGroupRolesAssigned(unit)
        return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole, nameWithRealm, guildRank
    end
end