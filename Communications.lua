local ADDON_NAME, addon = ...

local BNSendGameData, SendAddonMessage, SendChatMessage = BNSendGameData, C_ChatInfo.SendAddonMessage, SendChatMessage

-- Interval times for syncing keys between clients
-- Two different time settings for in a raid or otherwise
-- Creates a random variance between +- [.001, .100] to help prevent
-- disconnects from too many addon messages
-- Borrowed from Astral Keys Communications.lua
local SEND_VARIANCE = ((-1)^math.random(1,2)) * math.random(1, 100)/ 10^3 -- random number to space out messages being sent between clients
local SEND_INTERVAL = {}
SEND_INTERVAL[1] = 0.2 + SEND_VARIANCE -- Normal operations
SEND_INTERVAL[2] = 1 + SEND_VARIANCE -- Used when in a non-raiding environment
SEND_INTERVAL[3] = 2 -- Used for version checks

-- Current setting to be used
-- Changes when player enters a raid instance or not
local SEND_INTERVAL_SETTING = 1 -- What intervel to use for sending normal information

local msgs, newMsg, delMsg

AstralRaidComms = CreateFrame('FRAME', 'AstralRaidComms')

function AstralRaidComms:Init()
	self:RegisterEvent('CHAT_MSG_ADDON')
	self:RegisterEvent('BN_CHAT_MSG_ADDON')

	self:SetScript('OnEvent', self.OnEvent)
	self:SetScript('OnUpdate', self.OnUpdate)

	self.dtbl = {}
	self.queue = {}

	self:Hide()
	self.delay = 0
	self.loadDelay = 0
	self.versionPrint = false
end
AstralRaidComms:Init()

function AstralRaidComms:RegisterPrefix(channel, prefix, f)
	channel = channel or 'RAID'

	if self:IsPrefixRegistered(channel, prefix) then return end -- Did we register something to the same channel with the same name?

	if not self.dtbl[channel] then self.dtbl[channel] = {} end

	local obj = {}
	obj.method = f
	obj.prefix = prefix

	table.insert(self.dtbl[channel], obj)
end

function AstralRaidComms:UnregisterPrefix(channel, prefix)
	local objs = self.dtbl[channel]
	if not objs then return end
	for id, obj in pairs(objs) do
		if obj.prefix == prefix then
			objs[id] = nil
			break
		end
	end
end

function AstralRaidComms:IsPrefixRegistered(channel, prefix)
	local objs = self.dtbl[channel]
	if not objs then return false end
	for _, obj in pairs(objs) do
		if obj.prefix == prefix then
			return true
		end
	end
	return false
end

function AstralRaidComms:OnEvent(event, prefix, msg, channel, sender)
	if not (prefix == ADDON_NAME) then return end
	if event == 'BN_CHAT_MSG_ADDON' then channel = 'BNET' end
	local objs = AstralRaidComms.dtbl[channel]
	if not objs then return end
	local arg, content = msg:match("^(%S*)%s*(.-)$")
	for _, obj in pairs(objs) do
		if obj.prefix == arg then
			obj.method(content, sender, msg)
		end
	end
end

function AstralRaidComms:OnUpdate(elapsed)
	self.delay = self.delay + elapsed
	if self.delay < SEND_INTERVAL[SEND_INTERVAL_SETTING] + self.loadDelay then
		return
	end
	self.loadDelay = 0

	if self.versionPrint then
		AstralRaidComms.loadDelay = 3
		if addon.InInstance and addon.InstanceType == 'raid' then
			SEND_INTERVAL_SETTING = 1
		else
			SEND_INTERVAL_SETTING = 2
		end
		self.versionPrint = false
		addon.PrintCheckResults()
	end

	self.delay = 0
	if #self.queue < 1 then -- Don't have any messages to send
		self:Hide()
		return
	end

	self:SendMessage()
end

function AstralRaidComms:NewMessage(prefix, text, channel, target)
	if channel == 'GUILD' then
		if not IsInGuild() then
			return
		end
	end

	if channel == 'RAID' then
		if not IsInGroup() then
			return
		end
	end

	local msg = newMsg()

	if channel == 'BNET' then
		msg.method = BNSendGameData
		msg[1] = target
		msg[2] = prefix
		msg[3] = text
	else
		msg.method = SendAddonMessage
		msg[1] = prefix
		msg[2] = text
		msg[3] = channel
		msg[4] = channel == 'WHISPER' and target or ''
	end

	--Let's add it to queue
	self.queue[#self.queue + 1] = msg

	if not self:IsShown() then
		self:Show()
	end
end

function AstralRaidComms:SendMessage()
	local msg = table.remove(self.queue, 1)
	if msg[3] == 'BNET' then
		if select(3, BNGetGameAccountInfo(msg[4])) == 'WoW' and BNConnected() then -- Are they logged into WoW and are we connected to BNET?
			msg.method(unpack(msg, 1, #msg))
		end
	elseif msg[3] == 'WHISPER' then
		if addon.IsFriendOnline(msg[4]) then -- Are they still logged into that toon
			msg.method(unpack(msg, 1, #msg))
		end
	else-- Guild/raid message, just send it
		msg.method(unpack(msg, 1, #msg))
		delMsg(msg)
	end
end

local function waRequest(channel, ...)
	local msg, _ = ...
	wipe(addon.WeakAuraList)

	local resp = 'waPush ' .. addon.PlayerClass

	addon.GetWeakAuras()
	for wa, url in string.gmatch(msg, '("[%w%s]+"):("[%w%s]+")') do
		if not addon.WeakAuraList[wa] or not addon.WeakAuraList[wa] == url then
			resp = resp .. string.format(' "%s":"%s"', wa, addon.WeakAuraList[wa])
		end
	end

	SendAddonMessage(ADDON_NAME, resp, channel)
end

local function addonRequest(channel, ...)
	local msg, _ = ...

	local resp = 'addonPush ' .. addon.PlayerClass

	for a, v in string.gmatch(msg, '("[%w%s]+"):("[%w%s]+")') do
		if not addon.AddonList[a] or not addon.AddonList[a] == v then
			resp = resp .. string.format(' "%s":"%s"', a, addon.AddonList[a])
		end
	end

	SendAddonMessage(ADDON_NAME, resp, channel)
end

AstralRaidComms:RegisterPrefix('RAID', 'waRequest', function(...) waRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'waRequest', function(...) waRequest('GUILD', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'addonRequest', function(...) addonRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'addonRequest', function(...) addonRequest('GUILD', ...) end)

-- Message handling

msgs = setmetatable({}, {__mode='k'})

newMsg = function()
	local msg = next(msgs)
	if msg then
		msgs[msg] = nil
		return msg
	end
	return {}
end

delMsg = function(msg)
	msg[1] = nil
	msgs[msg] = true
end