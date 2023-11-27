local _, addon = ...

AstralGuildLib = {}

AstralGuildLib.GuildRosterUpdateEventTriggered = false
AstralGuildLib.GuildRosterRefreshRequested = true
AstralGuildLib.Roster = {}
AstralGuildLib.RosterByPlayerName = {}
AstralGuildLib.RosterByPlayerNameAndRealm = {}
AstralGuildLib.RosterByGuid = {}

local function TimerLoop()
    if AstralGuildLib.GuildRosterUpdateEventTriggered and AstralGuildLib.GuildRosterRefreshRequested and not InCombatLockdown() then
        AstralGuildLib.RefreshGuildRoster()
        AstralGuildLib.GuildRosterRefreshRequested = false
    end
    C_Timer.After(5, TimerLoop)
end

function AstralGuildLib:Init()
    AstralRaidEvents:Register('GUILD_ROSTER_UPDATE', self.OnGuildRosterUpdate, 'AstralGuildLibGuildRosterUpdate')
    C_GuildInfo.GuildRoster()
    TimerLoop()
end

function AstralGuildLib:OnGuildRosterUpdate()
    AstralGuildLib.GuildRosterUpdateEventTriggered = true
    AstralGuildLib.GuildRosterRefreshRequested = true
end

function AstralGuildLib:RefreshGuildRoster()
    -- addon.PrintDebug('AstralGuildLib:RefreshGuildRoster')
    AstralGuildLib.Roster = AstralRaidLibrary:GetGuildRoster()
    AstralGuildLib.RosterByPlayerName = {}
    AstralGuildLib.RosterByPlayerNameAndRealm = {}
    AstralGuildLib.RosterByGuid = {}
    for _, item in pairs(AstralGuildLib.Roster) do
        AstralGuildLib.RosterByPlayerName[item.name] = item
        AstralGuildLib.RosterByPlayerNameAndRealm[item.nameWithRealm] = item
        AstralGuildLib.RosterByGuid[item.guid] = item
    end
end

function AstralGuildLib:IsInSameGuild(name)
    local player = AstralGuildLib.RosterByPlayerNameAndRealm[name] or AstralGuildLib.RosterByPlayerName[name]
    if player then
        return true
    end
    return false
end

function AstralGuildLib:IsGuildOfficer(name)
    local player = AstralGuildLib.RosterByPlayerNameAndRealm[name] or AstralGuildLib.RosterByPlayerName[name]
    if player then
        return player.isOfficer
    end
    return false
end


AstralGuildLib:Init()
