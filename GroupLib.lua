local _, addon = ...

AstralGroupLib = {}

AstralGroupLib.RosterRefreshRequested = true
AstralGroupLib.Roster = {}
AstralGroupLib.RosterByPlayerName = {}
AstralGroupLib.RosterByPlayerNameAndRealm = {}
AstralGroupLib.RosterByGuid = {}

local function TimerLoop()
    if AstralGroupLib.RosterRefreshRequested then
        AstralGroupLib.RefreshGroupRoster()
        AstralGroupLib.RosterRefreshRequested = false
    end
    C_Timer.After(1, TimerLoop)
end

function AstralGroupLib:Init()
    AstralRaidEvents:Register('GROUP_ROSTER_UPDATE', self.OnGroupRosterUpdate, 'AstralGroupLibGroupRosterUpdate')
    AstralRaidEvents:Register('PARTY_LEADER_CHANGED', self.OnPartyLeaderChanged, 'AstralGroupLibPartyLeaderChanged')
    TimerLoop()
end

function AstralGroupLib:OnGroupRosterUpdate()
    AstralGroupLib.RosterRefreshRequested = true
end

function AstralGroupLib:OnPartyLeaderChanged()
    AstralGroupLib.RosterRefreshRequested = true
end

function AstralGroupLib:RefreshGroupRoster()
    addon.PrintDebug('AstralGroupLib:RefreshGroupRoster')
    AstralGroupLib.Roster = AstralRaidLibrary:GetRoster()
    AstralGroupLib.RosterByPlayerName = {}
    AstralGroupLib.RosterByPlayerNameAndRealm = {}
    AstralGroupLib.RosterByGuid = {}
    for _, item in pairs(AstralGroupLib.Roster) do
        AstralGroupLib.RosterByPlayerName[item.name] = item
        AstralGroupLib.RosterByPlayerNameAndRealm[item.nameWithRealm] = item
        AstralGroupLib.RosterByGuid[item.guid] = item
    end
    -- addon.PrintDebug(addon.DebugTableToString(AstralGroupLib.Roster))
end

function AstralGroupLib:IsGroupLeaderOrAssist(name)
    local player = AstralGroupLib.RosterByPlayerNameAndRealm[name] or AstralGroupLib.RosterByPlayerName[name]
    if player then
        if player.rank == 2 or player.rank == 1 then
            return true
        end
    end
    return false
end

AstralGroupLib:Init()
