local _, addon = ...
local L = addon.L

-- Adapted/copied from Early Pull weakaura (https://wago.io/TyN8l9eWg/1)

local sourceFlagMask = COMBATLOG_OBJECT_CONTROL_MASK
local sourceFlagFilter = COMBATLOG_OBJECT_CONTROL_PLAYER
local destFlagMask = bit.bor(COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_REACTION_MASK)
local destFlagFilter1 = bit.bor(COMBATLOG_OBJECT_CONTROL_NPC, COMBATLOG_OBJECT_REACTION_HOSTILE)
local destFlagFilter2 = bit.bor(COMBATLOG_OBJECT_CONTROL_NPC, COMBATLOG_OBJECT_REACTION_NEUTRAL)
local negInfinity = -math.huge

local expectedPullTime = nil
local combatLog = {pos = 0, maxPos = 1000}
local threatLog = {pos = 0, maxPos = 100}
local targetLog = {pos = 0, maxPos = 100}
local bossLog = {pos = 0, maxPos = 100}
local syncLog = {pos = 0, maxPos = 100}
local pullContext = {}
local unitList = {}
local threatScanUnits = {}
local combatLogDamageEventTest, combatLogSwingEventTest, summons, summons2

local function init()
	for i = 1, combatLog.maxPos do
		combatLog[i] = {time = negInfinity, guid = nil, name = nil, event = nil, destGUID = nil, destName = nil, spellID = nil}
	end
	for i = 1, threatLog.maxPos do
		threatLog[i] = {time = negInfinity, threatEntries = {count = 0}}
	end
	for i = 1, targetLog.maxPos do
		targetLog[i] = {time = negInfinity, guid = nil, name = nil}
	end
	for i = 1, bossLog.maxPos do
		bossLog[i] = {time = negInfinity, guid = nil}
	end
	for i = 1, syncLog.maxPos do
		syncLog[i] = {time = negInfinity, message = nil}
	end

	unitList = {raid = {}, raidpet = {}, party = {}, partypet = {}, boss = {}, bosstarget = {}}

	for i = 1, 40 do
		unitList.raid[i] = 'raid'..i
		unitList.raidpet[i] = 'raidpet'..i
	end
	for i = 1, 4 do
		unitList.party[i] = 'party'..i
		unitList.partypet[i] = 'partypet'..i
	end
	for i = 1, 5 do
		unitList.boss[i] = 'boss'..i
		unitList.bosstarget[i] = 'boss'..i..'target'
	end

	combatLogDamageEventTest = {
		SPELL_DAMAGE = true,
		SPELL_PERIODIC_DAMAGE = true,
		SWING_DAMAGE = true,
		RANGE_DAMAGE = true,
	}
	combatLogSwingEventTest = {
		SWING_DAMAGE = true,
		SWING_MISSED = true,
	}

	summons = {counter = 0}
	summons2 = {counter = 0}
end

local function getAnnounceChannel(announceType)
	if announceType == 1 then
		return (addon.InInstance and not UnitIsDeadOrGhost('player')) and 'SAY' or 'PRINT'
	elseif announceType == 2 then
		return addon.GetInstanceChannel() or 'PRINT'
	elseif announceType == 3 then
		return 'OFFICER'
	elseif announceType == 4 then
		return 'PRINT'
	end
end

local function classifyPull(pullTimeDiff)
	local aType, pullDesc
	if not pullTimeDiff then
		aType = AstralRaidSettings.earlypull.announce.untimedPull
		pullDesc = L['BOSS_PULLED']
	elseif pullTimeDiff <= -0.005 then
		aType = AstralRaidSettings.earlypull.announce.earlyPull
		pullDesc = format(L['BOSS_PULLED_EARLY'], -pullTimeDiff)
	elseif pullTimeDiff < 0.005 then
		aType = AstralRaidSettings.earlypull.announce.onTimePull
		pullDesc = L['BOSS_PULLED_ON_TIME']
	else
		aType = AstralRaidSettings.earlypull.announce.latePull
		pullDesc = format(L['BOSS_PULLED_LATE'], pullTimeDiff)
	end
	return getAnnounceChannel(aType), pullDesc
end

local function maySendPullTimer(sender)
	return UnitIsGroupLeader(sender) or UnitIsGroupAssistant(sender) or ((addon.InInstance) and UnitGroupRolesAssigned(sender) == 'TANK') or addon.IsOfficer()
end

local function advanceLog(log)
	local pos = (log.pos % log.maxPos) + 1
	log.pos = pos
	return log[pos]
end

local function addThreatScanUnit(unit)
	local guid = UnitGUID(unit)
	if guid then
		threatScanUnits[guid] = unit
	end
end

local function scanThreat(mob)
	wipe(threatScanUnits)
	if IsInRaid() then
		local raid = unitList.raid
		local raidpet = unitList.raidpet
		for i = 1, GetNumGroupMembers() do
			addThreatScanUnit(raid[i])
			addThreatScanUnit(raidpet[i])
		end
	else
		if IsInGroup() then
			local party = unitList.party
			local partypet = unitList.partypet
			for i = 1, GetNumSubgroupMembers() do
				addThreatScanUnit(party[i])
				addThreatScanUnit(partypet[i])
			end
		end
		addThreatScanUnit('player')
		addThreatScanUnit('pet')
	end
	addThreatScanUnit('target')
	addThreatScanUnit('focus')
	addThreatScanUnit('mouseover')

	local entry = advanceLog(threatLog)
	entry.time = GetTime()
	local threatEntries = entry.threatEntries

	local count = 0
	for guid, unit in pairs(threatScanUnits) do
		if UnitPlayerControlled(unit) then
			local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(unit, mob)
			if state or threatValue then
				count = count + 1
				local threatEntry = threatEntries[count] or {}
				threatEntries[count] = threatEntry
				threatEntry.guid = guid
				threatEntry.name = GetUnitName(unit, true)
				threatEntry.isTanking = isTanking
				threatEntry.threatValue = threatValue
			end
		end
	end
	threatEntries.count = count
end

local function scanBoss(unit, targetUnit)
	local bossGUID = UnitGUID(unit)
	if bossGUID then
		local now = GetTime()
		local bossEntry = advanceLog(bossLog)
		bossEntry.time = now
		bossEntry.guid = bossGUID
		local targetGUID = UnitGUID(targetUnit)
		if targetGUID and UnitPlayerControlled(targetUnit) then
			local targetEntry = advanceLog(targetLog)
			targetEntry.time = now
			targetEntry.guid = targetGUID
			targetEntry.name = GetUnitName(targetUnit, true)
		end
	end
end

local function scanAllBosses()
	local boss, bossTarget = unitList.boss, unitList.bosstarget
	for i = 1, 5 do
		scanBoss(boss[i], bossTarget[i])
	end
end

local function createSyncTable(encounterID)
	local syncPriority = 2 -- low, (normal), high, isolated
	return {addon.CLIENT_VERSION, encounterID, syncPriority, addon.GetGroupRank(), UnitName('player'), GetRealmName()}
end

local function deserializeSyncTable(d)
	local syncTable = {strsplit('\t', d)}
	for i = 1, 6 do
		if i <= 4 then
			syncTable[i] = tonumber(syncTable[i])
		end
		if not syncTable[i] then
			return nil
		end
	end
	return syncTable
end

local function compareSyncTables(a, b)
	if a[1] < b[1] then return true elseif a[1] > b[1] then return false end
	if a[3] < b[3] then return true elseif a[3] > b[3] then return false end
	if a[4] < b[4] then return true elseif a[4] > b[4] then return false end
	if a[5] > b[5] then return true elseif a[5] < b[5] then return false end
	if a[6] > b[6] then return true elseif a[6] < b[6] then return false end
end

local function checkSyncTableEncounter(syncTable, encounterID)
	return syncTable[2] == encounterID
end

local function isMe(syncTable)
	return syncTable[5] == UnitName('player') and syncTable[6] == GetRealmName()
end

local function sendSync(syncTable)
	local channel = addon.GetInstanceChannel()
	if not channel then return end
	local msg = table.concat(syncTable, '\t')
	AstralRaidComms:NewMessage(AstralRaidComms.PREFIX, 'earlyPullSync ' .. msg, channel)
end

local function onSync(channel, msg, sender)
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	addon.PrintDebug(msg)
	local entry = advanceLog(syncLog)
	entry.time = GetTime()
	entry.message = msg
end

-- relPos = pos shifted to be time-monotonic and 0-indexed
-- relPos = (pos - 1 - offset) % maxPos
-- pos = 1 + (relPos + offset) % maxPos

-- returns relPos of first entry.time >= time
-- first: relPos of lower search cutoff (inclusive)
local function binarySearchLogTime(log, time, first)
	local offset = log.pos
	local maxPos = log.maxPos
	local floor = floor
	local count = maxPos - first
	local current
	local step
	while count > 0 do
		step = floor(count / 2)
		current = first + step
		if log[1 + (current + offset) % maxPos].time < time then
			first = current + 1
			count = count - (step + 1)
		else
			count = step
		end
	end
	return first
end

local function iterEmpty()
end

-- [1] = tbl, [2] = max
local function iterRange(state, i)
	i = i + 1
	if i <= state[2] then
		return i, state[1][i]
	end
end

-- [1] = tbl, [2] = j, [3] = max1, [4] = min2, [5] = max3
local function iterTwoRanges(state, i)
	i = i + 1
	local j = state[2]
	if i <= state[j] then
		return i, state[1][i]
	elseif j == 3 then
		i = state[4]
		if i <= state[5] then
			state[2] = 5
			return i, state[1][i]
		end
	end
end

local function iterateLogWindow(log, beginTime, endTime)
	local beginRelPos = binarySearchLogTime(log, beginTime, 0)
	local endRelPos = binarySearchLogTime(log, endTime, beginRelPos)
	if beginRelPos == endRelPos then
		return iterEmpty
	end
	local offset = log.pos
	local maxPos = log.maxPos
	local beginPos = 1 + (beginRelPos + offset) % maxPos
	local endPos = 1 + (endRelPos - 1 + offset) % maxPos -- now inclusive
	if beginPos <= endPos then
		return iterRange, {log, endPos}, beginPos - 1
	else
		return iterTwoRanges, {log, 3, maxPos, 1, endPos}, beginPos - 1
	end
end

local function findPetOwner(guid)
	local summoner = summons[guid] or summons2[guid]
	if summoner then return summoner end

	if IsInRaid() then
		local raid = unitList.raid
		local raidpet = unitList.raidpet
		for i = 1, GetNumGroupMembers() do
			if UnitGUID(raidpet[i]) == guid then
				return GetUnitName(raid[i])
			end
		end
	else
		if IsInGroup() then
			local party = unitList.party
			local partypet = unitList.partypet
			for i = 1, GetNumSubgroupMembers() do
				if UnitGUID(partypet[i]) == guid then
					return GetUnitName(party[i])
				end
			end
		end
		if UnitGUID('pet') == guid then
			return GetUnitName('player')
		end
	end
end

local function finalizeCandidate(cand)
	if not cand then return end
	local entry = cand.combatLogEntry
	if entry then
		cand.name = entry.name
		if cand.combatLogScore >= 25 then
			if combatLogSwingEventTest[entry.event] then
				cand.spellID = 6603 -- Auto Attack
			else
				cand.spellID = entry.spellID
			end
		end
	end
	cand.name = cand.name
			or (cand.threatEntry and cand.threatEntry.name)
			or (cand.targetLogEntry and cand.targetLogEntry.name)
	local guid = cand.guid
	if not guid:find('^Player') then
		cand.petOwner = findPetOwner(guid)
	end
end

local function printCandidateDetails(cand, intro)
	addon.Console(string.format('%s%s (spellID=%s, petOwner=%s); score=%.2f (log=%.2f, threat=%.2f, target=%.2f).',
		intro, tostring(cand.name), tostring(cand.spellID), tostring(cand.petOwner),
		cand.score, cand.combatLogScore, cand.threatScore, cand.targetScore))
end

local function printDetails()
	local ctx = pullContext
	if not ctx then return end

	addon.Console(string.format('%s (id=%d) pulled %.3fs ago (%s) announce=%s.',
		tostring(ctx.encounterName), ctx.encounterID, GetTime() - ctx.pullTime,
		ctx.pullTimeDiff and format('%+.3fs', ctx.pullTimeDiff) or 'UNTIMED',
		tostring(ctx.announceChannel)))

	if ctx.bestCand then
		printCandidateDetails(ctx.bestCand, 'Best pull candidate: ')
		if ctx.secondCand then
			printCandidateDetails(ctx.secondCand, 'Next best pull candidate: ')
		end
	else
		addon.Console('No candidates to blame for pull.')
	end
end

local function getBlameDesc(bestCand, bestScore, secondScore)
	local blameDesc = ' by unknown cause'
	if bestCand then
		local name = bestCand.name or '<Unknown>'
		local spellID = bestCand.spellID
		local petOwner = bestCand.petOwner
		if petOwner then
			blameDesc = ' by ' .. petOwner .. "'s pet " .. name
		else
			blameDesc = ' by ' .. name
		end
		if spellID then
			blameDesc = blameDesc .. ' ' .. (GetSpellLink(spellID) or ('<Spell ' .. spellID .. '>'))
		end
		if bestScore - secondScore < 50 then
			blameDesc = blameDesc..' (?)'
		end
	end
	return blameDesc
end

local function announce(channel, msg)
	if channel == 'PRINT' then
		addon.Console(msg)
	elseif channel then
		if AstralRaidSettings.earlypull.announce.onlyGuild and not IsInGuildGroup() then addon.Console('Not in guild group; not announcing pull.') return end
		SendChatMessage(msg, channel)
	end
end

local function afterPull()
	local ctx = pullContext
	local pullTime = ctx.pullTime
	local cwBeginTime = pullTime - 0.5
	local cwEndTime = pullTime + 0.5
	local timelinessCenter = pullTime
	local timelinessDecayRate = 3
	local function getTimelinessPenalty(entry)
		return 1 - timelinessDecayRate * math.abs(entry.time - timelinessCenter)
	end
	local candidates = {}
	local function getCandidate(guid)
		local cand = candidates[guid] or {guid = guid, combatLogScore = 0, threatScore = 0, targetScore = 0}
		candidates[guid] = cand
		return cand
	end

	-- boss log pass
	local bosses = {}
	for _, entry in iterateLogWindow(bossLog, cwBeginTime, cwEndTime) do
		bosses[entry.guid] = true
	end

	-- combat log pass
	for _, entry in iterateLogWindow(combatLog, cwBeginTime, cwEndTime) do
		local score = 90 * getTimelinessPenalty(entry)
		if not combatLogDamageEventTest[entry.event] then
			score = score * 0.9
		end
		if entry.event == 'SPELL_CAST_SUCCESS' then
			score = score * 0.7
		end
		if not bosses[entry.destGUID] then
			score = score * 0.4
		end
		local cand = getCandidate(entry.guid)
		if score > cand.combatLogScore then
			cand.combatLogScore = score
			cand.combatLogEntry = entry
		end
	end

	-- threat log pass
	local earliestThreatTable
	for _, entry in iterateLogWindow(threatLog, cwBeginTime, cwEndTime) do
		local threatEntries = entry.threatEntries
		local count = threatEntries.count
		if count > 0 then
			earliestThreatTable = earliestThreatTable or entry.time
			local highestThreatValue = 0
			for j = 1, count do
				highestThreatValue = max(highestThreatValue, threatEntries[j].threatValue or 0)
			end
			local notEarliestPenalty = (entry.time == earliestThreatTable) and 1 or 0.4
			for j = 1, count do
				local threatEntry = threatEntries[j]
				local score = 100 * getTimelinessPenalty(entry) * notEarliestPenalty
				if not threatEntry.isTanking then
					if threatEntry.threatValue == highestThreatValue then
						score = score * 0.8
					else
						score = score * 0.7
					end
				end
				local cand = getCandidate(threatEntry.guid)
				if score > cand.threatScore then
					cand.threatScore = score
					cand.threatEntry = threatEntry
				end
			end
		end
	end

	-- target log pass
	local earliestTarget
	for _, entry in iterateLogWindow(targetLog, cwBeginTime, cwEndTime) do
		earliestTarget = earliestTarget or entry.time
		local notEarliestPenalty = (entry.time == earliestTarget) and 1 or 0.4
		local score = 80 * getTimelinessPenalty(entry) * notEarliestPenalty
		local cand = getCandidate(entry.guid)
		if score > cand.targetScore then
			cand.targetScore = score
			cand.targetLogEntry = entry
		end
	end

	-- candidates comparison
	local bestScore, bestCand = 0, nil
	local secondScore, secondCand = 0, nil
	for _, cand in pairs(candidates) do
		local score = cand.combatLogScore + cand.threatScore + cand.targetScore
		cand.score = score
		if score > bestScore then
			secondScore, secondCand = bestScore, bestCand
			bestScore, bestCand = score, cand
		elseif score > secondScore then
			secondScore, secondCand = score, cand
		end
	end

	finalizeCandidate(bestCand)
	finalizeCandidate(secondCand)

	ctx.bestCand = bestCand
	ctx.secondCand = secondCand

	if AstralRaidSettings.earlypull.general.printResults then printDetails() end

	-- sync log pass & announce
	local bestSyncTable
	for _, entry in iterateLogWindow(syncLog, cwBeginTime, cwEndTime) do
		local syncTable = deserializeSyncTable(entry.message)
		if syncTable and checkSyncTableEncounter(syncTable, ctx.encounterID)
		and (not bestSyncTable or compareSyncTables(bestSyncTable, syncTable)) then
			bestSyncTable = syncTable
		end
	end

	if not bestSyncTable or isMe(bestSyncTable) then
		announce(ctx.announceChannel, ctx.pullDesc .. getBlameDesc(bestCand, bestScore, secondScore) .. '.')
	end
end

local function playerEnteringWorld()
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	scanAllBosses()
end

local function chatMsgAddon(prefix, msg, _, sender) -- get pull timer from boss mods
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end

	if prefix ~= 'D5' then return end
	local _, _, ty, duration, instanceID, _ = strsplit('\t', msg)
	if ty ~= 'PT' then return end

	duration = tonumber(duration or 0)
	instanceID = tonumber(instanceID)

	if IsEncounterInProgress()
		or (IsInGroup() and not maySendPullTimer(sender))
		or (duration > 60 or (duration > 0 and duration < 3) or duration < 0)
		or (instanceID and instanceID ~= select(8, GetInstanceInfo())) then
		return
	end

	if duration == 0 then
		expectedPullTime = nil
	else
		expectedPullTime = GetTime() + duration
	end
end

local function unitThreatListUpdate(unit)
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	if unit and unit:find('^boss') then scanThreat(unit) end
end

local function unitTarget(unit)
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	if unit and unit:find('^boss') then scanBoss(unit, unit..'target') end
end

local function cleu(_, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, _, _, auraType)
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end

	if event == 'SPELL_DAMAGE' or event == 'SPELL_MISSED' or event == 'SPELL_PERIODIC_DAMAGE'
		or event == 'SWING_DAMAGE' or event == 'RANGE_DAMAGE' or event == 'RANGE_MISSED'
		or event == 'SPELL_AURA_APPLIED' or event == 'SPELL_CAST_SUCCESS' or event == 'SPELL_SUMMON' then
		-- summons are used for tracking pet owners, not pull detection
		if event == 'SPELL_SUMMON' then
			if not destGUID then return end
			summons[destGUID] = sourceName
			local counter = summons.counter + 1
			if counter >= 1000 then
				summons = summons2
				summons2 = summons
				wipe(summons)
				summons.counter = 0
			else
				summons.counter = counter
			end
			return
		end

		if not (sourceGUID and destGUID) or (event == 'SPELL_AURA_APPLIED' and auraType ~= 'DEBUFF') then return end
		if bit.band(sourceFlags, sourceFlagMask) ~= sourceFlagFilter then return end

		local destFlagsMasked = bit.band(destFlags, destFlagMask)
		if destFlagsMasked ~= destFlagFilter1 and destFlagsMasked ~= destFlagFilter2 then return end

		local entry = advanceLog(combatLog)
		entry.time = GetTime()
		entry.guid = sourceGUID
		entry.name = sourceName
		entry.event = event
		entry.destGUID = destGUID
		entry.destName = destName
		entry.spellID = spellID
	end
end

local function encounterStart(encounterID, encounterName)
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	if not encounterID then return end

	local now = GetTime()
	local pullTimeDiff = expectedPullTime and (now - expectedPullTime)
	if pullTimeDiff and abs(pullTimeDiff) > 10 then
		pullTimeDiff = nil
	end
	expectedPullTime = nil

	local announceChannel, pullDesc = classifyPull(pullTimeDiff)

	if announceChannel and announceChannel ~= 'PRINT' then
		sendSync(createSyncTable(encounterID))
	end

	pullContext = {
		pullTime = now,
		pullTimeDiff = pullTimeDiff,
		announceChannel = announceChannel,
		pullDesc = pullDesc,
		encounterID = encounterID,
		encounterName = encounterName,
	}
	C_Timer.After(1, afterPull)

	scanAllBosses()
end

local function instanceEncounterEngageUnit()
	if not AstralRaidSettings.earlypull.general.isEnabled then return end
	if not (IsInGroup() or IsInRaid()) then return end
	scanAllBosses()
end

init()

AstralRaidEvents:Register('PLAYER_ENTERING_WORLD', playerEnteringWorld, 'astralRaidEarlyPullPlayerEnteringWorld')
AstralRaidEvents:Register('CHAT_MSG_ADDON', chatMsgAddon, 'astralRaidEarlyPullChatMsgAddon')
AstralRaidEvents:Register('UNIT_THREAT_LIST_UPDATE', unitThreatListUpdate, 'astralRaidEarlyPullUnitThreatListUpdate')
AstralRaidEvents:Register('UNIT_TARGET', unitTarget, 'astralRaidEarlyPullUnitTarget')
AstralRaidEvents:Register('COMBAT_LOG_EVENT_UNFILTERED', cleu, 'astralRaidEarlyPullCLEU')
AstralRaidEvents:Register('ENCOUNTER_START', encounterStart, 'astralRaidEarlyPullEncounterStart')
AstralRaidEvents:Register('INSTANCE_ENCOUNTER_ENGAGE_UNIT', instanceEncounterEngageUnit, 'astralRaidEarlyPullInstanceEncounterEngageUnit')

AstralRaidComms:RegisterPrefix('RAID', 'earlyPullSync', function(...) onSync('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'earlyPullSync', function(...) onSync('PARTY', ...) end)
AstralRaidComms:RegisterPrefix('INSTANCE_CHAT', 'earlyPullSync', function(...) onSync('INSTANCE_CHAT', ...) end)

-- addon.AddDefaultSettings('earlypull', 'announce', {earlyPull = 1, onTimePull = 1, latePull = 1, untimedPull = 1})

local module = addon:New(L['EARLY_PULL'], L['EARLY_PULL'])
local enableCheckbox, printResultsCheckbox, onlyGuildGroupsCheckbox, pullHeader, earlyPullDropdown, onTimePullDropdown, latePullDropdown, untimedPullDropdown

local announceKinds = {[1] = 'Say', [2] = 'Group', [3] = 'Officer', [4] = 'Print', [5] = 'None'}

function module.options:Load()
  local header = AstralUI:Text(self, L['EARLY_PULL_DETECTION']):Point('TOPLEFT', 0, 0):Shadow()

  enableCheckbox = AstralUI:Check(self, ENABLE):Point('TOPLEFT', header, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.earlypull.general.isEnabled = self:GetChecked()
		if AstralRaidSettings.earlypull.general.isEnabled then
			init()
			printResultsCheckbox:Show()
			pullHeader:Show()
			onlyGuildGroupsCheckbox:Show()
			earlyPullDropdown:Show()
			onTimePullDropdown:Show()
			latePullDropdown:Show()
			untimedPullDropdown:Show()
		else
			printResultsCheckbox:Hide()
			pullHeader:Hide()
			onlyGuildGroupsCheckbox:Hide()
			earlyPullDropdown:Hide()
			onTimePullDropdown:Hide()
			latePullDropdown:Hide()
			untimedPullDropdown:Hide()
		end
  end)

  printResultsCheckbox = AstralUI:Check(self, L['EARLY_PULL_PRINT_RESULTS'] .. CHAT):Point('LEFT', enableCheckbox, 'RIGHT', 150, 0):OnClick(function(self)
    AstralRaidSettings.earlypull.general.printResults = self:GetChecked()
  end)

	local earlyPullDesc = AstralUI:Text(self, L['EARLY_PULL_DESC']):Point('TOPLEFT', enableCheckbox, 'BOTTOMLEFT', 0, -10):FontSize(9):Shadow()

	pullHeader = AstralUI:Text(self, L['EARLY_PULL_ANNOUNCE']):Point('TOPLEFT', earlyPullDesc, 'BOTTOMLEFT', 0, -20):Shadow()

  onlyGuildGroupsCheckbox = AstralUI:Check(self, 'Only Announce in ' .. GUILD .. ' ' .. GROUPS):Point('TOPLEFT', pullHeader, 'BOTTOMLEFT', 0, -20):OnClick(function(self)
    AstralRaidSettings.earlypull.announce.onlyGuild = self:GetChecked()
  end)

	local function earlyPullDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		earlyPullDropdown:SetText(announceKinds[arg1])
    AstralRaidSettings.earlypull.announce.earlyPull = arg1
	end

	earlyPullDropdown = AstralUI:DropDown(self, 200, 10):Size(250):Point('TOPLEFT', onlyGuildGroupsCheckbox, 'BOTTOMLEFT', 0, -20):AddText(string.format('|cffffce00%s:', L['EARLY_PULL']))
	for i = 1, #announceKinds do
		local info = {}
		earlyPullDropdown.List[i] = info
		info.text = announceKinds[i]
		info.arg1 = i
		info.func = earlyPullDropdownSetValue
		info.justifyH = 'CENTER'
	end

	local function onTimePullDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		onTimePullDropdown:SetText(announceKinds[arg1])
    AstralRaidSettings.earlypull.announce.onTimePull = arg1
	end

	onTimePullDropdown = AstralUI:DropDown(self, 200, 10):Size(250):Point('LEFT', earlyPullDropdown, 'RIGHT', 10, 0):AddText(string.format('|cffffce00%s:', L['ON_TIME_PULL']))
	for i = 1, #announceKinds do
		local info = {}
		onTimePullDropdown.List[i] = info
		info.text = announceKinds[i]
		info.arg1 = i
		info.func = onTimePullDropdownSetValue
		info.justifyH = 'CENTER'
	end

	local function latePullDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		latePullDropdown:SetText(announceKinds[arg1])
    AstralRaidSettings.earlypull.announce.latePull = arg1
	end

	latePullDropdown = AstralUI:DropDown(self, 200, 10):Size(250):Point('TOPLEFT', earlyPullDropdown, 'BOTTOMLEFT', 0, -20):AddText(string.format('|cffffce00%s:', L['LATE_PULL']))
	for i = 1, #announceKinds do
		local info = {}
		latePullDropdown.List[i] = info
		info.text = announceKinds[i]
		info.arg1 = i
		info.func = latePullDropdownSetValue
		info.justifyH = 'CENTER'
	end

	local function untimedPullDropdownSetValue(_, arg1)
		AstralUI:DropDownClose()
		untimedPullDropdown:SetText(announceKinds[arg1])
    AstralRaidSettings.earlypull.announce.untimedPull = arg1
	end

	untimedPullDropdown = AstralUI:DropDown(self, 200, 10):Size(250):Point('LEFT', latePullDropdown, 'RIGHT', 10, 0):AddText(string.format('|cffffce00%s:', L['UNTIMED_PULL']))
	for i = 1, #announceKinds do
		local info = {}
		untimedPullDropdown.List[i] = info
		info.text = announceKinds[i]
		info.arg1 = i
		info.func = untimedPullDropdownSetValue
		info.justifyH = 'CENTER'
	end
end

function module.options:OnShow()
  enableCheckbox:SetChecked(AstralRaidSettings.earlypull.general.isEnabled)
  printResultsCheckbox:SetChecked(AstralRaidSettings.earlypull.general.printResults)
	onlyGuildGroupsCheckbox:SetChecked(AstralRaidSettings.earlypull.announce.onlyGuild)
	earlyPullDropdown:SetText(announceKinds[AstralRaidSettings.earlypull.announce.earlyPull])
	onTimePullDropdown:SetText(announceKinds[AstralRaidSettings.earlypull.announce.onTimePull])
	latePullDropdown:SetText(announceKinds[AstralRaidSettings.earlypull.announce.latePull])
	untimedPullDropdown:SetText(announceKinds[AstralRaidSettings.earlypull.announce.untimedPull])

	if not AstralRaidSettings.earlypull.general.isEnabled then
		printResultsCheckbox:Hide()
		onlyGuildGroupsCheckbox:Hide()
		pullHeader:Hide()
		earlyPullDropdown:Hide()
		onTimePullDropdown:Hide()
		latePullDropdown:Hide()
		untimedPullDropdown:Hide()
	end
end