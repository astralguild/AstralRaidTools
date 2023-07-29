local _, addon = ...

addon.PlayerName = UnitName('player')
addon.PlayerClass = select(2, UnitClass('player'))
addon.PlayerNameRealm = addon.PlayerName .. '-' .. GetRealmName():gsub("%s+", "")

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
  return (IsInRaid() and (UnitIsGroupAssistant('player') or UnitIsGroupLeader('player')))
end

function addon.IsPartyLead()
  return (IsInGroup() and (UnitIsGroupAssistant('player') or UnitIsGroupLeader('player')))
end

function addon.IsOfficer()
  return C_GuildInfo.IsGuildOfficer()
end

function addon.GetGroupRank()
  return UnitIsGroupLeader('player') and 2 or UnitIsGroupAssistant('player') and 1 or 0
end

-- Library Hooks

function AstralRaidLibrary:GetPlayerRole()
  return addon.GetPlayerRole()
end

function AstralRaidLibrary:GetWeakAuras()
  return addon.GetWeakAuras()
end

function AstralRaidLibrary:GetAddons()
  return addon.GetAddons()
end

function AstralRaidLibrary:IsRaidLead()
  return addon.IsRaidLead()
end

function AstralRaidLibrary:IsPartyLead()
  return addon.IsPartyLead()
end

function AstralRaidLibrary:IsOfficer()
  return addon.IsOfficer()
end

function AstralRaidLibrary:GetGroupRank()
  return addon.GetGroupRank()
end